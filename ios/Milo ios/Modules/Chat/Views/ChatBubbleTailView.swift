import UIKit
import SnapKit

/// 气泡小尾巴（iMessage 风格）。
/// 连续同方向消息只在末条显示，由各类型消息 Cell 复用，
/// 保证尾巴的形状、尺寸、偏移在所有气泡上完全一致。
final class ChatBubbleTailView: UIView {

    /// 尾巴尖的朝向：发送消息朝右下，接收消息朝左下
    enum Direction { case incoming, outgoing }

    var direction: Direction = .outgoing { didSet { setNeedsDisplay() } }
    /// 填充色必须与所属气泡底色一致，否则会出现色差断层
    var fillColor: UIColor = .white { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 统一安装尾巴约束：贴气泡右下（发送）/ 左下（接收），9×13，水平外扩 3pt、底部上移 2pt。
    /// 调用前需确保 tailView 已加入父视图。
    func attach(to bubble: UIView, direction: Direction, fillColor: UIColor) {
        self.direction = direction
        self.fillColor = fillColor
        snp.remakeConstraints { make in
            switch direction {
            case .outgoing:
                make.trailing.equalTo(bubble.snp.trailing).offset(ScreenAdapter.scaleW(3))
            case .incoming:
                make.leading.equalTo(bubble.snp.leading).offset(-ScreenAdapter.scaleW(3))
            }
            make.bottom.equalTo(bubble.snp.bottom).offset(-ScreenAdapter.scaleW(2))
            make.width.equalTo(ScreenAdapter.scaleW(9))
            make.height.equalTo(ScreenAdapter.scaleW(13))
        }
    }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        let w = rect.width, h = rect.height
        switch direction {
        case .outgoing:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addCurve(to: CGPoint(x: w, y: h),
                          controlPoint1: CGPoint(x: w * 0.30, y: h * 0.15),
                          controlPoint2: CGPoint(x: w * 0.75, y: h * 0.85))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.close()
        case .incoming:
            path.move(to: CGPoint(x: w, y: 0))
            path.addCurve(to: CGPoint(x: 0, y: h),
                          controlPoint1: CGPoint(x: w * 0.70, y: h * 0.15),
                          controlPoint2: CGPoint(x: w * 0.25, y: h * 0.85))
            path.addLine(to: CGPoint(x: w, y: h))
            path.close()
        }
        fillColor.setFill()
        path.fill()
    }
}
