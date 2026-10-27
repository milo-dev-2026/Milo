import UIKit
import SnapKit

/// 聊天页统一气泡版式（对齐 iMessage 参考图）：
/// 不显示头像、昵称、气泡外时间与尾巴；气泡紧贴左右 16pt，最宽为屏宽 82%；
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
    /// 文字气泡左右内边距
    static let textPadLR = ScreenAdapter.scaleW(14)
    /// 文字气泡上下内边距
    static let textPadTB = ScreenAdapter.scaleH(9)

    /// 时间分隔头所占高度（含上下留白）
    static var timeHeaderHeight: CGFloat { ScreenAdapter.scaleH(26) }

    private static let timeHeaderTag = 987_001

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
    static func install(bubble: UIView,
                        tail: ChatBubbleTailView,
                        isFromMe: Bool,
                        width: CGFloat,
                        height: CGFloat? = nil,
                        minHeight: CGFloat = 0,
                        timeHeader: String? = nil,
                        groupedAbove: Bool = false,
                        groupedBelow: Bool = false,
                        fillColor: UIColor) {
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

        let clampedWidth = min(width, maxWidth)
        bubble.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(headerH + (groupedAbove ? runGap : groupGap))
            make.bottom.equalToSuperview().offset(-(groupedBelow ? runGap : groupGap))
            if isFromMe {
                make.trailing.equalToSuperview().offset(-sideInset)
            } else {
                make.leading.equalToSuperview().offset(sideInset)
            }
            make.width.equalTo(clampedWidth)
            if let height = height {
                make.height.equalTo(height)
            } else if minHeight > 0 {
                make.height.greaterThanOrEqualTo(minHeight)
            }
        }
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
