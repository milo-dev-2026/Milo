import UIKit
import SnapKit

/// 头像来源（加载走 /v1/users/{uid}/avatar 或 /v1/groups/{gid}/avatar）
struct ChatAvatarSource {
    let channelId: String
    let channelType: Int
    let name: String
}

extension Message {
    /// 聊天页气泡头像来源（发送者个人头像）
    var chatAvatar: ChatAvatarSource {
        ChatAvatarSource(channelId: fromUID, channelType: 1, name: fromUID)
    }
}

/// 聊天页统一气泡版式（对齐 iMessage 参考图）：
/// 不显示昵称、气泡外时间与尾巴；气泡连同头像紧贴左右 16pt，气泡最宽不超过屏宽 82%；
/// 同方向连续消息间距收紧，跨方向放宽；相隔超过 5 分钟的消息之间插入居中时间分隔。
enum ChatBubbleLayout {

    /// 气泡距屏幕左右边缘
    static let sideInset = ScreenAdapter.scaleW(16)
    /// 相邻同方向消息的间距（单侧），整条约 3pt
    static let runGap = ScreenAdapter.scaleH(1.5)
    /// 不同方向消息之间的间距（单侧），整条约 10pt
    static let groupGap = ScreenAdapter.scaleH(5)
    /// 气泡最大宽度
    static let maxWidth: CGFloat = ScreenAdapter.screenWidth * 0.82
    /// 头像尺寸与头像-气泡间距
    static let avatarSize = ScreenAdapter.scaleW(36)
    static let avatarGap = ScreenAdapter.scaleW(8)
    /// 文字气泡左右内边距
    static let textPadLR = ScreenAdapter.scaleW(14)
    /// 文字气泡上下内边距
    static let textPadTB = ScreenAdapter.scaleH(9)

    /// 时间分隔头所占高度（含上下留白）
    static var timeHeaderHeight: CGFloat { ScreenAdapter.scaleH(26) }

    private static let timeHeaderTag = 987_001
    private static let avatarTag = 987_002
    private static let statusTag = 987_003

    private static let hmFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
    private static let mdFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "M月d日"; return f
    }()
    private static let ymdFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy年M月d日"; return f
    }()

    /// 消息簇时间分隔文案：今天只显示时分，昨天带「昨天」，更早带日期
    static func clusterTimeText(timestampMs: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000)
        let time = hmFormatter.string(from: date)
        let cal = Calendar.current
        if cal.isDateInToday(date) { return time }
        if cal.isDateInYesterday(date) { return "昨天 \(time)" }
        let sameYear = cal.component(.year, from: date) == cal.component(.year, from: Date())
        let day = (sameYear ? mdFormatter : ymdFormatter).string(from: date)
        return "\(day) \(time)"
    }

    /// 安装标准气泡约束：一侧贴边、宽度收敛到 maxWidth；时间分隔头按需插入。
    /// - Parameters:
    ///   - width: 期望宽度（固定尺寸内容或有测量值的文本），超出 maxWidth 会被截断
    ///   - height: 固定高度；传 nil 表示由内部内容约束撑开
    ///   - minHeight: 最小高度（height 为 nil 时生效）
    ///   - timeHeader: 非空时在气泡上方插入居中时间分隔文字
    ///   - groupedAbove / groupedBelow: 与上/下一条同方向消息时间距收紧
    ///   - avatar: 非空时在气泡外侧显示发送者头像（顶部与气泡对齐）
    ///   - status: 己方消息状态（0 发送中 / 1 已发送 / 2 已读 / -1 失败），nil 不显示
    static func install(bubble: UIView,
                        tail: ChatBubbleTailView,
                        isFromMe: Bool,
                        width: CGFloat,
                        height: CGFloat? = nil,
                        minHeight: CGFloat = 0,
                        timeHeader: String? = nil,
                        groupedAbove: Bool = false,
                        groupedBelow: Bool = false,
                        fillColor: UIColor,
                        avatar: ChatAvatarSource? = nil,
                        status: Int? = nil) {
        // 参考样式不显示尾巴
        tail.isHidden = true

        guard let contentView = bubble.superview else { return }
        let headerLabel = timeHeaderLabel(in: contentView)
        let headerH: CGFloat
        if let timeHeader = timeHeader {
            headerLabel.text = timeHeader
            headerLabel.isHidden = false
            headerH = timeHeaderHeight
        } else {
            headerLabel.text = nil
            headerLabel.isHidden = true
            headerH = 0
        }

        // 头像（每个 cell contentView 内按 tag 复用）
        let avatarView = avatarImageView(in: contentView)
        if let avatar = avatar {
            avatarView.isHidden = false
            // 记录头像对应的频道，供点击进入个人主页/群资料
            avatarView.accessibilityIdentifier = "\(avatar.channelId)|\(avatar.channelType)|\(avatar.name)"
            AppUtility.loadChannelAvatar(
                channelId: avatar.channelId,
                channelType: avatar.channelType,
                name: avatar.name,
                into: avatarView
            )
            avatarView.snp.remakeConstraints { make in
                if isFromMe {
                    make.trailing.equalToSuperview().offset(-sideInset)
                } else {
                    make.leading.equalToSuperview().offset(sideInset)
                }
                make.top.equalTo(bubble.snp.top)
                make.width.height.equalTo(avatarSize)
            }
        } else {
            avatarView.isHidden = true
        }

        var available = maxWidth
        if avatar != nil {
            // 带头像时整行宽 = sideInset + 头像 + 间距 + 气泡，不超出屏幕
            available = min(available, ScreenAdapter.screenWidth - sideInset * 2 - avatarSize - avatarGap)
        }
        let clampedWidth = min(width, available)
        bubble.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(headerH + (groupedAbove ? runGap : groupGap))
            make.bottom.equalToSuperview().offset(-(groupedBelow ? runGap : groupGap))
            if isFromMe {
                if avatar != nil {
                    make.trailing.equalTo(avatarView.snp.leading).offset(-avatarGap)
                } else {
                    make.trailing.equalToSuperview().offset(-sideInset)
                }
            } else {
                if avatar != nil {
                    make.leading.equalTo(avatarView.snp.trailing).offset(avatarGap)
                } else {
                    make.leading.equalToSuperview().offset(sideInset)
                }
            }
            make.width.equalTo(clampedWidth)
            if let height = height {
                make.height.equalTo(height)
            } else if minHeight > 0 {
                make.height.greaterThanOrEqualTo(minHeight)
            }
        }

        // 己方消息状态图标（发送中/单勾/双勾/失败），放在气泡左下外侧空白区（对齐安卓）
        let statusView = statusIconView(in: contentView)
        if isFromMe, let status = status {
            statusView.isHidden = false
            configureStatusView(statusView, status: status)
            statusView.snp.remakeConstraints { make in
                make.trailing.equalTo(bubble.snp.leading).offset(-ScreenAdapter.scaleW(4))
                make.bottom.equalTo(bubble.snp.bottom)
                make.width.equalTo(ScreenAdapter.scaleW(20))
                make.height.equalTo(ScreenAdapter.scaleH(14))
            }
        } else {
            statusView.isHidden = true
        }
    }

    /// 状态图标内容：0 时钟 / 1 单勾 / 2 双勾（主题色） / -1 红色感叹号
    private static func configureStatusView(_ container: UIView, status: Int) {
        container.subviews.forEach { $0.removeFromSuperview() }

        let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .medium)
        func makeIcon(_ name: String, _ color: UIColor) -> UIImageView {
            let iv = UIImageView(image: UIImage(systemName: name, withConfiguration: config))
            iv.tintColor = color
            iv.contentMode = .scaleAspectFit
            return iv
        }

        switch status {
        case 0:
            let iv = makeIcon("clock", .tertiaryLabel)
            container.addSubview(iv)
            iv.snp.makeConstraints { make in make.center.equalToSuperview() }
        case 2:
            // 双勾：两个对勾错位叠加
            let iv1 = makeIcon("checkmark", .themePrimary)
            let iv2 = makeIcon("checkmark", .themePrimary)
            container.addSubviews(iv1, iv2)
            iv1.snp.makeConstraints { make in
                make.leading.centerY.equalToSuperview()
            }
            iv2.snp.makeConstraints { make in
                make.leading.equalTo(iv1.snp.centerX).offset(1)
                make.centerY.equalToSuperview()
            }
        case -1:
            let iv = makeIcon("exclamationmark.circle.fill", .systemRed)
            container.addSubview(iv)
            iv.snp.makeConstraints { make in make.center.equalToSuperview() }
        default:
            // 1 = 已发送：单勾
            let iv = makeIcon("checkmark", .tertiaryLabel)
            container.addSubview(iv)
            iv.snp.makeConstraints { make in make.center.equalToSuperview() }
        }
    }

    /// 每个 cell contentView 内复用同一个状态图标容器（按 tag 查找，缺失则创建）
    private static func statusIconView(in contentView: UIView) -> UIView {
        if let view = contentView.viewWithTag(statusTag) { return view }
        let view = UIView()
        view.tag = statusTag
        view.isUserInteractionEnabled = false
        contentView.addSubview(view)
        return view
    }

    /// 每个 cell contentView 内复用同一个头像视图（按 tag 查找，缺失则创建）
    private static func avatarImageView(in contentView: UIView) -> UIImageView {
        if let imageView = contentView.viewWithTag(avatarTag) as? UIImageView { return imageView }
        let imageView = UIImageView()
        imageView.tag = avatarTag
        imageView.layer.cornerRadius = ScreenAdapter.scaleW(6)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: ChatAvatarTapRelay.shared, action: #selector(ChatAvatarTapRelay.handle(_:)))
        imageView.addGestureRecognizer(tap)
        contentView.addSubview(imageView)
        return imageView
    }

    /// 每个 cell contentView 内复用同一个时间分隔 label（按 tag 查找，缺失则创建）
    private static func timeHeaderLabel(in contentView: UIView) -> UILabel {
        if let label = contentView.viewWithTag(timeHeaderTag) as? UILabel { return label }
        let label = UILabel()
        label.tag = timeHeaderTag
        label.font = ScreenAdapter.font(11)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        contentView.insertSubview(label, at: 0)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(6))
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        return label
    }
}

// MARK: - 头像点击中继（气泡布局为静态方法，无法直接持有控制器引用）
final class ChatAvatarTapRelay: NSObject {

    static let shared = ChatAvatarTapRelay()
    static let notification = Notification.Name("ChatAvatarTapped")

    @objc func handle(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let raw = view.accessibilityIdentifier else { return }
        let parts = raw.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3 else { return }
        let channelId = String(parts[0])
        let channelType = Int(parts[1]) ?? 1
        let name = String(parts[2])
        guard !channelId.isEmpty else { return }
        NotificationCenter.default.post(
            name: ChatAvatarTapRelay.notification,
            object: nil,
            userInfo: ["channelId": channelId, "channelType": channelType, "name": name]
        )
    }
}
