import UIKit
import SnapKit

// MARK: - 通话消息内容解析
struct CallMessageContent {
    enum CallType: String {
        case voice = "voice"
        case video = "video"
        case unknown

        var displayText: String {
            switch self {
            case .voice: return "语音通话"
            case .video: return "视频通话"
            case .unknown: return "通话"
            }
        }
    }

    enum CallStatus: String {
        case connected = "connected"
        case missed = "missed"
        case cancelled = "cancelled"
        case unknown

        var displayText: String {
            switch self {
            case .connected: return ""
            case .missed: return "未接通"
            case .cancelled: return "已取消"
            case .unknown: return ""
            }
        }

        var isMissed: Bool {
            return self == .missed || self == .cancelled
        }
    }

    let type: CallType
    let status: CallStatus
    let duration: Int // 秒

    /// 解析通话消息内容
    static func parse(_ content: String) -> CallMessageContent {
        guard !content.isEmpty else {
            return CallMessageContent(type: .unknown, status: .unknown, duration: 0)
        }

        // 尝试解析为 JSON
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // 不是 JSON，尝试简单格式
            return CallMessageContent(type: .unknown, status: .unknown, duration: 0)
        }

        let typeStr = json["type"] as? String ?? ""
        let duration = json["duration"] as? Int ?? 0
        let statusStr = json["status"] as? String ?? ""

        let callType = CallType(rawValue: typeStr) ?? .unknown
        let callStatus = CallStatus(rawValue: statusStr) ?? .unknown

        return CallMessageContent(type: callType, status: callStatus, duration: duration)
    }

    /// 格式化时长为 mm:ss
    var durationText: String {
        if status.isMissed {
            return status.displayText
        }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 通话消息 Cell
class CallMessageCell: UITableViewCell, TimeHeaderConfigurable {

    // MARK: - UI 元素
    let bubbleView = UIView()
    let callIcon = UIImageView()
    let callTypeLabel = UILabel()
    let durationLabel = UILabel()
    let timeLabel = UILabel()
    let avatarView = UIImageView()

    // MARK: - 状态
    private var isFromMe = false
    private var callContent: CallMessageContent?

    // 点击回调
    var onBubbleTapped: (() -> Void)?

    // MARK: - 时间分隔头
    let timeHeaderLabel = UILabel()
    private var showsTimeHeader = false

    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI 设置
    private func setupUI() {
        selectionStyle = .none

        let avatarSize = ScreenAdapter.scaleW(36)
        let bubblePad = ScreenAdapter.scaleW(12)

        // 气泡
        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        bubbleView.backgroundColor = .white
        bubbleView.isUserInteractionEnabled = true

        // 电话图标
        callIcon.contentMode = .scaleAspectFit
        callIcon.tintColor = .themePrimary

        // 通话类型标签
        callTypeLabel.font = ScreenAdapter.font(15)
        callTypeLabel.textColor = .label

        // 时长标签
        durationLabel.font = ScreenAdapter.font(12)
        durationLabel.textColor = .secondaryLabel

        // 时间标签
        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel

        // 头像
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        // 时间分隔头
        timeHeaderLabel.font = ScreenAdapter.font(12)
        timeHeaderLabel.textColor = .tertiaryLabel
        timeHeaderLabel.textAlignment = .center
        timeHeaderLabel.isHidden = true
        timeHeaderLabel.alpha = 0

        contentView.addSubviews(timeHeaderLabel, avatarView, bubbleView, timeLabel)
        bubbleView.addSubviews(callIcon, callTypeLabel, durationLabel)

        // 点击手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(bubbleTapped))
        bubbleView.addGestureRecognizer(tap)

        // 时间分隔头约束
        timeHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(0)
        }

        // 头像初始约束（左，后续根据 isFromMe 更新）
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.width.height.equalTo(avatarSize)
        }

        // 图标约束
        callIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(bubblePad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }

        // 通话类型标签约束
        callTypeLabel.snp.makeConstraints { make in
            make.leading.equalTo(callIcon.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.trailing.lessThanOrEqualToSuperview().offset(-bubblePad)
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(8))
        }

        // 时长标签约束
        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(callTypeLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-bubblePad)
            make.top.equalTo(callTypeLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(8))
        }
    }

    // MARK: - 配置数据
    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

        // 解析通话内容
        let content = CallMessageContent.parse(message.content)
        callContent = content

        // 设置通话类型文字
        callTypeLabel.text = content.type.displayText

        // 设置时长/状态文字
        durationLabel.text = content.durationText

        // 设置图标和颜色
        configureCallIcon(content: content)

        // 设置头像（与其他消息 Cell 保持一致，使用默认占位图）
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        // 更新布局（左右方向）
        updateLayoutForFromMe()
    }

    private func configureCallIcon(content: CallMessageContent) {
        let isMissed = content.status.isMissed

        // 图标
        switch content.type {
        case .video:
            callIcon.image = UIImage(systemName: "video.fill")
        case .voice:
            if isFromMe {
                callIcon.image = UIImage(systemName: "phone.arrow.up.right.fill")
            } else {
                callIcon.image = UIImage(systemName: "phone.arrow.down.left.fill")
            }
        case .unknown:
            callIcon.image = UIImage(systemName: "phone.fill")
        }

        // 颜色
        if isMissed {
            callIcon.tintColor = .systemGray
            callTypeLabel.textColor = .systemGray
            durationLabel.textColor = .systemGray2
        } else if isFromMe {
            callIcon.tintColor = .themePrimary
            callTypeLabel.textColor = .label
            durationLabel.textColor = .secondaryLabel
        } else {
            callIcon.tintColor = .systemBlue
            callTypeLabel.textColor = .label
            durationLabel.textColor = .secondaryLabel
        }
    }

    private func updateLayoutForFromMe() {
        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let bubbleWidth = ScreenAdapter.scaleW(140)

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
            callTypeLabel.textColor = .white
            durationLabel.textColor = UIColor.white.withAlphaComponent(0.8)
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
            callTypeLabel.textColor = .label
            durationLabel.textColor = .secondaryLabel
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

    // MARK: - 点击事件
    @objc private func bubbleTapped() {
        // 触觉反馈
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }

        // 按压缩放动画
        if AnimationIntegration.shared.config.enableButtonPressAnimation {
            bubbleView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            UIView.animate(withDuration: 0.15,
                           delay: 0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.8,
                           options: .curveEaseOut) {
                self.bubbleView.transform = .identity
            }
        }

        // 回调
        onBubbleTapped?()
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
