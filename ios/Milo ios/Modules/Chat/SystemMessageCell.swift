import UIKit
import SnapKit

// MARK: - 系统消息内容解析
struct SystemMessageContent {
    let text: String

    /// 解析系统消息内容
    /// - Parameter content: 原始内容（可能是 JSON 或纯文本）
    /// - Returns: 解析后的显示文本
    static func parse(_ content: String) -> String {
        guard !content.isEmpty else { return "" }

        // 尝试解析为 JSON
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // 不是 JSON，直接返回原文
            return content
        }

        // 从 JSON 中提取模板和额外参数
        guard let template = json["content"] as? String else {
            // 没有 content 字段，直接返回原文
            return content
        }

        // 尝试提取 extra 数组中的 name 字段
        if let extra = json["extra"] as? [[String: Any]] {
            var result = template
            for (index, item) in extra.enumerated() {
                let name = item["name"] as? String ?? ""
                let placeholder = "{\(index)}"
                result = result.replacingOccurrences(of: placeholder, with: name)
            }
            return result
        }

        // extra 不是数组，尝试作为单对象处理
        if let extraObj = json["extra"] as? [String: Any],
           let name = extraObj["name"] as? String {
            return template.replacingOccurrences(of: "{0}", with: name)
        }

        // 没有有效 extra，直接返回模板
        return template
    }
}

// MARK: - 系统消息 Cell
class SystemMessageCell: UITableViewCell, TimeHeaderConfigurable {

    // MARK: - UI 元素
    private let containerView = UIView()
    private let messageLabel = UILabel()
    let timeLabel = UILabel()

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
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 消息标签
        messageLabel.font = ScreenAdapter.font(12)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        // 容器（灰色圆角背景）
        containerView.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.6)
        containerView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        containerView.clipsToBounds = true

        // 时间分隔头
        timeHeaderLabel.font = ScreenAdapter.font(12)
        timeHeaderLabel.textColor = .tertiaryLabel
        timeHeaderLabel.textAlignment = .center
        timeHeaderLabel.isHidden = true
        timeHeaderLabel.alpha = 0

        contentView.addSubviews(timeHeaderLabel, containerView)
        containerView.addSubview(messageLabel)

        // 时间分隔头约束
        timeHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(0)
        }

        // 容器约束（居中，左右边距 16pt）
        containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.top.equalTo(timeHeaderLabel.snp.bottom).offset(ScreenAdapter.scaleH(6))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(6))
        }

        // 文字约束（上下 6pt，左右 12pt 内边距）
        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(6))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(6))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
        }
    }

    // MARK: - 配置数据
    func configure(with message: Message) {
        messageLabel.text = SystemMessageContent.parse(message.content)
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

        // 更新容器顶部约束
        containerView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(16))
            if shouldShow {
                make.top.equalTo(timeHeaderLabel.snp.bottom).offset(ScreenAdapter.scaleH(6))
            } else {
                make.top.equalToSuperview().offset(ScreenAdapter.scaleH(6))
            }
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(6))
        }

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
