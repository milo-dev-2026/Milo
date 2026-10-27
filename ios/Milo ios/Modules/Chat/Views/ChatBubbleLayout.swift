import UIKit
import SnapKit

/// 聊天页统一气泡版式（对齐 iMessage 参考图）：
/// 不显示头像、昵称、气泡外时间；气泡紧贴左右 16pt，最宽为屏宽 82%，尾巴仅在一串同方向消息的末条显示。
enum ChatBubbleLayout {

    /// 气泡距屏幕左右边缘
    static let sideInset = ScreenAdapter.scaleW(16)
    /// 单条消息的上下留白（相邻两条合计 8pt）
    static let rowGap = ScreenAdapter.scaleH(4)
    /// 气泡最大宽度
    static let maxWidth: CGFloat = ScreenAdapter.screenWidth * 0.82
    /// 文字气泡左右内边距
    static let textPadLR = ScreenAdapter.scaleW(14)
    /// 文字气泡上下内边距
    static let textPadTB = ScreenAdapter.scaleH(9)

    /// 安装标准气泡约束：一侧贴边、宽度收敛到 maxWidth、尾巴按需显示。
    /// - Parameters:
    ///   - width: 期望宽度（固定尺寸内容或有测量值的文本），超出 maxWidth 会被截断
    ///   - height: 固定高度；传 nil 表示由内部内容约束撑开
    ///   - minHeight: 最小高度（height 为 nil 时生效）
    static func install(bubble: UIView,
                        tail: ChatBubbleTailView,
                        isFromMe: Bool,
                        width: CGFloat,
                        height: CGFloat? = nil,
                        minHeight: CGFloat = 0,
                        showTail: Bool,
                        fillColor: UIColor) {
        let clampedWidth = min(width, maxWidth)
        bubble.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(rowGap)
            make.bottom.equalToSuperview().offset(-rowGap)
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
        tail.attach(to: bubble, direction: isFromMe ? .outgoing : .incoming, fillColor: fillColor)
        tail.isHidden = !showTail
    }
}
