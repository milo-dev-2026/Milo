import UIKit
import SnapKit

// MARK: - 合并转发消息解析
struct MultiForwardMessageInfo {
    struct SubMessage {
        var fromUID: String
        var fromName: String
        var content: String
        var type: Int
    }

    var messages: [SubMessage]
    var title: String

    /// 从消息内容解析合并转发信息
    static func parse(from content: String) -> MultiForwardMessageInfo? {
        guard !content.isEmpty else { return nil }

        // 尝试 JSON 解析
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let title = json["title"] as? String ?? "聊天记录"

        var subMessages: [SubMessage] = []
        if let msgs = json["msgs"] as? [[String: Any]] {
            for msgDict in msgs {
                let fromUID = msgDict["from_uid"] as? String ?? ""
                let fromName = msgDict["from_name"] as? String ?? fromUID
                let payload = msgDict["payload"] as? String ?? ""
                let type = msgDict["type"] as? Int ?? 1

                // 解析 payload 获取内容预览
                var contentPreview = ""
                if let payloadData = Data(base64Encoded: payload),
                   let payloadJson = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                    contentPreview = payloadJson["content"] as? String ?? ""
                } else if !payload.isEmpty {
                    // payload 不是 base64，直接使用
                    contentPreview = payload
                }

                subMessages.append(SubMessage(
                    fromUID: fromUID,
                    fromName: fromName,
                    content: contentPreview,
                    type: type
                ))
            }
        }

        return MultiForwardMessageInfo(messages: subMessages, title: title)
    }

    /// 将子消息转换为 Message 数组（用于详情页）
    func toMessages(channelID: String, channelType: Int, baseTimestamp: Int64) -> [Message] {
        return messages.enumerated().map { index, subMsg in
            Message(
                messageID: "mf_\(channelID)_\(index)",
                channelID: channelID,
                channelType: channelType,
                fromUID: subMsg.fromUID,
                content: subMsg.content,
                type: MessageType(rawValue: subMsg.type) ?? .text,
                timestamp: baseTimestamp + Int64(index),
                status: 1
            )
        }
    }
}

// MARK: - 合并转发消息 Cell
class MultiForwardMessageCell: UITableViewCell, TimeHeaderConfigurable {

    // MARK: - UI 元素
    let bubbleView = UIView()
    let timeLabel = UILabel()
    let avatarView = UIImageView()

    // 气泡内部元素
    private let titleLabel = UILabel()
    private let titleIcon = UIImageView()
    private let dividerLine = UIView()
    private let summaryStackView = UIStackView()
    private let bottomLabel = UILabel()
    private let bottomArrow = UIImageView()

    // MARK: - 状态
    private var isFromMe = false
    private var forwardInfo: MultiForwardMessageInfo?

    // 点击回调
    var onBubbleTapped: (() -> Void)?

    // MARK: - 时间分隔头
    let timeHeaderLabel = UILabel()
    private var showsTimeHeader = false

    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupPressGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI 设置
    private func setupUI() {
        selectionStyle = .none

        let avatarSize = ScreenAdapter.scaleW(36)

        // 气泡
        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        bubbleView.backgroundColor = .white
        bubbleView.isUserInteractionEnabled = true
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.08
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        bubbleView.layer.shadowRadius = 4

        // 时间标签
        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel

        // 头像
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        // 标题
        titleLabel.font = ScreenAdapter.mediumFont(15)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        // 标题图标
        titleIcon.image = UIImage(systemName: "message.and.message.fill")
        titleIcon.tintColor = .themePrimary
        titleIcon.contentMode = .scaleAspectFit

        // 分割线
        dividerLine.backgroundColor = .systemGray5

        // 摘要 stack
        summaryStackView.axis = .vertical
        summaryStackView.spacing = ScreenAdapter.scaleH(4)
        summaryStackView.alignment = .fill
        summaryStackView.distribution = .fillEqually

        // 底部标签
        bottomLabel.font = ScreenAdapter.font(12)
        bottomLabel.textColor = .secondaryLabel

        // 底部箭头
        bottomArrow.image = UIImage(systemName: "chevron.right")
        bottomArrow.tintColor = .tertiaryLabel
        bottomArrow.contentMode = .scaleAspectFit

        // 时间分隔头
        timeHeaderLabel.font = ScreenAdapter.font(12)
        timeHeaderLabel.textColor = .tertiaryLabel
        timeHeaderLabel.textAlignment = .center
        timeHeaderLabel.isHidden = true
        timeHeaderLabel.alpha = 0

        // 组装视图
        bubbleView.addSubviews(titleIcon, titleLabel, dividerLine, summaryStackView, bottomLabel, bottomArrow)
        contentView.addSubviews(timeHeaderLabel, avatarView, bubbleView, timeLabel)

        // 时间分隔头约束
        timeHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(0)
        }

        // 头像初始约束
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.width.height.equalTo(avatarSize)
        }

        // 标题图标
        titleIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.width.height.equalTo(ScreenAdapter.scaleW(18))
        }

        // 标题
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleIcon.snp.trailing).offset(ScreenAdapter.scaleW(6))
            make.centerY.equalTo(titleIcon)
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(12))
        }

        // 分割线
        dividerLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalTo(titleIcon.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(0.5)
        }

        // 摘要 stack
        summaryStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalTo(dividerLine.snp.bottom).offset(ScreenAdapter.scaleH(10))
        }

        // 底部箭头
        bottomArrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalTo(bottomLabel)
            make.width.equalTo(ScreenAdapter.scaleW(10))
            make.height.equalTo(ScreenAdapter.scaleW(12))
        }

        // 底部标签
        bottomLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(summaryStackView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(12))
            make.trailing.lessThanOrEqualTo(bottomArrow.snp.leading).offset(-ScreenAdapter.scaleW(4))
        }
    }

    // MARK: - 配置数据
    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

        // 解析合并转发信息
        forwardInfo = MultiForwardMessageInfo.parse(from: message.content)
        let info = forwardInfo

        // 设置标题
        titleLabel.text = info?.title ?? "聊天记录"

        // 构建摘要（最多 3 条）
        buildSummaryViews(with: info?.messages ?? [])

        // 设置底部文字
        let count = info?.messages.count ?? 0
        bottomLabel.text = "查看 \(count) 条消息"

        // 更新布局
        updateLayoutForFromMe()
    }

    private func buildSummaryViews(with messages: [MultiForwardMessageInfo.SubMessage]) {
        // 清空旧的摘要
        summaryStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let maxCount = min(messages.count, 3)

        for i in 0..<maxCount {
            let msg = messages[i]
            let label = UILabel()
            label.font = ScreenAdapter.font(12)
            label.textColor = .secondaryLabel
            label.numberOfLines = 1
            label.textAlignment = .left

            // 内容截断（20字）
            let contentPreview = msg.content.count > 20
                ? String(msg.content.prefix(20)) + "..."
                : msg.content

            let name = msg.fromName.isEmpty ? msg.fromUID : msg.fromName
            label.text = "\(name): \(contentPreview)"

            summaryStackView.addArrangedSubview(label)
        }

        // 如果消息不足 3 条，用空 label 填充以保持高度一致
        if maxCount < 3 {
            for _ in maxCount..<3 {
                let emptyLabel = UILabel()
                emptyLabel.font = ScreenAdapter.font(12)
                emptyLabel.textColor = .clear
                emptyLabel.text = " "
                summaryStackView.addArrangedSubview(emptyLabel)
            }
        }
    }

    private func updateLayoutForFromMe() {
        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let bubbleWidth = ScreenAdapter.scaleW(270)

        if isFromMe {
            // 自己发的：右边
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                if showsTimeHeader {
                    make.top.equalTo(timeHeaderLabel.snp.bottom).offset(vPad)
                } else {
                    make.top.equalToSuperview().offset(vPad)
                }
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = .themeBubbleOutgoing
            titleLabel.textColor = .white
            bottomLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
            }
            timeLabel.snp.remakeConstraints { make in
                make.trailing.equalTo(bubbleView.snp.trailing)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        } else {
            // 对方发的：左边
            avatarView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(hPad)
                if showsTimeHeader {
                    make.top.equalTo(timeHeaderLabel.snp.bottom).offset(vPad)
                } else {
                    make.top.equalToSuperview().offset(vPad)
                }
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = .themeBubbleIncoming
            titleLabel.textColor = .label
            bottomLabel.textColor = .secondaryLabel
            bubbleView.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }
    }

    // MARK: - 按压缩放效果
    private func setupPressGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBubbleTap))
        bubbleView.addGestureRecognizer(tapGesture)
        bubbleView.isUserInteractionEnabled = true

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleBubbleLongPress))
        longPress.minimumPressDuration = 0
        longPress.cancelsTouchesInView = false
        longPress.delegate = self
        bubbleView.addGestureRecognizer(longPress)
    }

    @objc private func handleBubbleTap() {
        // 触觉反馈
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }

        // 按压缩放动画
        if AnimationIntegration.shared.config.enableButtonPressAnimation {
            bubbleView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            UIView.animate(withDuration: 0.15,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut) {
                self.bubbleView.transform = .identity
            }
        }

        // 回调
        onBubbleTapped?()
    }

    @objc private func handleBubbleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }

        switch gesture.state {
        case .began:
            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.impactLight()
            }
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) {
                self.bubbleView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.15,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut) {
                self.bubbleView.transform = .identity
            }
        default:
            break
        }
    }

    // MARK: - 时间分隔头配置
    func configureTimeHeader(text: String?, isNew: Bool = false) {
        let shouldShow = text != nil
        showsTimeHeader = shouldShow

        if shouldShow {
            timeHeaderLabel.text = text
            timeHeaderLabel.isHidden = false
            timeHeaderLabel.snp.updateConstraints { make in
                make.height.equalTo(18)
            }
        } else {
            timeHeaderLabel.text = nil
            timeHeaderLabel.isHidden = true
            timeHeaderLabel.alpha = 0
            timeHeaderLabel.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }

        // 更新头像和气泡布局
        updateLayoutForFromMe()

        // 新时间分隔头动画
        if shouldShow && isNew && AnimationIntegration.shared.config.enableListEntranceAnimation {
            timeHeaderLabel.alpha = 0
            timeHeaderLabel.transform = CGAffineTransform(translationX: 0, y: -5)
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: .curveEaseOut) {
                self.timeHeaderLabel.alpha = 1
                self.timeHeaderLabel.transform = .identity
            }
        } else if shouldShow {
            timeHeaderLabel.alpha = 1
            timeHeaderLabel.transform = .identity
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MultiForwardMessageCell: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
