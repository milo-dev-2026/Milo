//
//  ThemeAnimation.swift
//  Milo
//
//  动画工具类 - 对齐安卓端动画资源
//  包含：转场动画、弹窗动画、按钮动画等
//

import UIKit

// MARK: - 动画时长
struct AnimationDuration {
    static let fast: TimeInterval = 0.15      // 快速动画
    static let normal: TimeInterval = 0.25    // 标准动画
    static let slow: TimeInterval = 0.35      // 慢速动画
    static let pageTransition: TimeInterval = 0.3  // 页面转场
    static let bottomSheet: TimeInterval = 0.3    // 底部弹窗
    static let alert: TimeInterval = 0.25         // 弹窗
    static let toast: TimeInterval = 0.3          // Toast
    static let shimmer: TimeInterval = 1.5        // 骨架屏闪烁
}

// MARK: - 动画插值器 (iOS 对应)
struct AnimationCurve {
    /// 线性
    static let linear: UIView.AnimationOptions = .curveLinear
    /// 缓入
    static let easeIn: UIView.AnimationOptions = .curveEaseIn
    /// 缓出
    static let easeOut: UIView.AnimationOptions = .curveEaseOut
    /// 缓入缓出
    static let easeInOut: UIView.AnimationOptions = .curveEaseInOut
    /// 弹性（弹簧）
    static let spring: UISpringTimingParameters = UISpringTimingParameters(
        dampingRatio: 0.7,
        initialVelocity: CGVector(dx: 0.5, dy: 0)
    )
}

// MARK: - UIView 动画扩展
extension UIView {

    // MARK: - 淡入淡出

    /// 淡入动画
    func fadeIn(duration: TimeInterval = AnimationDuration.normal, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        self.alpha = 0
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut) {
            self.alpha = 1
        } completion: { _ in
            completion?()
        }
    }

    /// 淡出动画
    func fadeOut(duration: TimeInterval = AnimationDuration.normal, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        self.alpha = 1
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseIn) {
            self.alpha = 0
        } completion: { _ in
            completion?()
        }
    }

    // MARK: - 缩放动画

    /// 缩放进入
    func scaleIn(duration: TimeInterval = AnimationDuration.normal, delay: TimeInterval = 0, fromScale: CGFloat = 0.9, completion: (() -> Void)? = nil) {
        self.transform = CGAffineTransform(scaleX: fromScale, y: fromScale)
        self.alpha = 0
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut) {
            self.transform = .identity
            self.alpha = 1
        } completion: { _ in
            completion?()
        }
    }

    /// 缩放退出
    func scaleOut(duration: TimeInterval = AnimationDuration.normal, delay: TimeInterval = 0, toScale: CGFloat = 0.9, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseIn) {
            self.transform = CGAffineTransform(scaleX: toScale, y: toScale)
            self.alpha = 0
        } completion: { _ in
            completion?()
        }
    }

    // MARK: - 平移动画

    /// 从底部滑入
    func slideInFromBottom(duration: TimeInterval = AnimationDuration.bottomSheet, delay: TimeInterval = 0, offset: CGFloat? = nil, completion: (() -> Void)? = nil) {
        let offset = offset ?? bounds.height
        self.transform = CGAffineTransform(translationX: 0, y: offset)
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut) {
            self.transform = .identity
        } completion: { _ in
            completion?()
        }
    }

    /// 从底部滑出
    func slideOutToBottom(duration: TimeInterval = AnimationDuration.bottomSheet, delay: TimeInterval = 0, offset: CGFloat? = nil, completion: (() -> Void)? = nil) {
        let offset = offset ?? bounds.height
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseIn) {
            self.transform = CGAffineTransform(translationX: 0, y: offset)
        } completion: { _ in
            completion?()
        }
    }

    /// 从顶部滑入
    func slideInFromTop(duration: TimeInterval = AnimationDuration.normal, delay: TimeInterval = 0, offset: CGFloat = 50, completion: (() -> Void)? = nil) {
        self.transform = CGAffineTransform(translationX: 0, y: -offset)
        self.alpha = 0
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut) {
            self.transform = .identity
            self.alpha = 1
        } completion: { _ in
            completion?()
        }
    }

    // MARK: - 弹簧动画

    /// 弹簧缩放（按钮点击效果）
    func springScale(duration: TimeInterval = AnimationDuration.fast, scale: CGFloat = 0.95) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        } completion: { _ in
            UIView.animate(withDuration: duration) {
                self.transform = .identity
            }
        }
    }

    // MARK: - 抖动动画

    /// 左右抖动（错误提示）
    func shake(duration: TimeInterval = 0.5) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -10, 10, -10, 10, 0]
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "shake")
    }

    /// 错误抖动 + 红色边框闪烁
    func shakeWithError(duration: TimeInterval = 0.5, borderColor: UIColor = .systemRed) {
        // 抖动动画
        shake(duration: duration)

        // 保存原始边框
        let originalBorderColor = layer.borderColor
        let originalBorderWidth = layer.borderWidth

        // 边框变红
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = 1.5

        // 闪烁效果
        let flash = CABasicAnimation(keyPath: "borderColor")
        flash.fromValue = borderColor.cgColor
        flash.toValue = originalBorderColor ?? UIColor.clear.cgColor
        flash.duration = 0.3
        flash.beginTime = CACurrentMediaTime() + duration - 0.3
        flash.fillMode = .forwards
        flash.isRemovedOnCompletion = false
        layer.add(flash, forKey: "borderFlash")

        // 恢复原始边框
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            self.layer.borderColor = originalBorderColor
            self.layer.borderWidth = originalBorderWidth
            self.layer.removeAnimation(forKey: "borderFlash")
        }
    }

    // MARK: - 旋转动画

    /// 旋转动画（加载中）
    func startRotating(duration: TimeInterval = 1.0) {
        if layer.animation(forKey: "rotation") != nil { return }

        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(animation, forKey: "rotation")
    }

    /// 停止旋转
    func stopRotating() {
        layer.removeAnimation(forKey: "rotation")
    }
}

// MARK: - UIViewController 转场动画
extension UIViewController {

    /// 从底部 present 一个视图控制器
    func presentBottomSheet(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: animated, completion: completion)
    }
}

// MARK: - 自定义转场 - 从右滑入
class SlideFromRightTransition: NSObject, UIViewControllerAnimatedTransitioning {

    var isDismissing: Bool = false
    var duration: TimeInterval = AnimationDuration.pageTransition

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        if isDismissing {
            guard let fromView = transitionContext.view(forKey: .from) else { return }

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
                fromView.transform = CGAffineTransform(translationX: fromView.bounds.width, y: 0)
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            guard let toView = transitionContext.view(forKey: .to) else { return }

            containerView.addSubview(toView)
            toView.transform = CGAffineTransform(translationX: toView.bounds.width, y: 0)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toView.transform = .identity
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - 自定义转场 - 底部弹出（带半透明背景）
class BottomSheetTransition: NSObject, UIViewControllerAnimatedTransitioning {

    var isDismissing: Bool = false
    var duration: TimeInterval = AnimationDuration.bottomSheet
    var sheetHeight: CGFloat = 300

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        if isDismissing {
            guard let fromView = transitionContext.view(forKey: .from) else { return }

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
                fromView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
                if let bgView = containerView.viewWithTag(999) {
                    bgView.alpha = 0
                }
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            guard let toView = transitionContext.view(forKey: .to) else { return }

            // 半透明背景
            let bgView = UIView(frame: containerView.bounds)
            bgView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            bgView.tag = 999
            bgView.alpha = 0
            containerView.addSubview(bgView)

            containerView.addSubview(toView)
            toView.frame = CGRect(x: 0, y: containerView.bounds.height - sheetHeight,
                                  width: containerView.bounds.width, height: sheetHeight)
            toView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toView.transform = .identity
                bgView.alpha = 1
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - 列表入场动画
extension UITableView {

    /// 列表项逐个淡入上移动画（克制版：位移10pt，避免过大跳跃）
    func animateCellsFadeInUp(duration: TimeInterval = AnimationDuration.normal, delayPerItem: TimeInterval = 0.03) {
        let cells = visibleCells
        for (index, cell) in cells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 10)

            UIView.animate(withDuration: duration,
                           delay: delayPerItem * Double(index),
                           options: .curveEaseOut) {
                cell.alpha = 1
                cell.transform = .identity
            }
        }
    }

    /// 列表项逐个缩放弹入动画（克制版：缩放0.92，弹性更内敛）
    func animateCellsSpringIn(duration: TimeInterval = AnimationDuration.slow, delayPerItem: TimeInterval = 0.03) {
        let cells = visibleCells
        for (index, cell) in cells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)

            UIView.animate(withDuration: duration,
                           delay: delayPerItem * Double(index),
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.4,
                           options: .curveEaseOut) {
                cell.alpha = 1
                cell.transform = .identity
            }
        }
    }

    /// 左侧滑入动画（克制版：位移15pt）
    func animateCellsSlideFromLeft(duration: TimeInterval = AnimationDuration.normal, delayPerItem: TimeInterval = 0.03) {
        let cells = visibleCells
        for (index, cell) in cells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: -15, y: 0)

            UIView.animate(withDuration: duration,
                           delay: delayPerItem * Double(index),
                           options: .curveEaseOut) {
                cell.alpha = 1
                cell.transform = .identity
            }
        }
    }
}

// MARK: - 按钮点击效果
extension UIButton {

    /// 按下缩放效果
    func addPressScaleEffect() {
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.transform = .identity
        }
    }
}

// MARK: - 涟漪效果（Ripple）
class RippleEffectView: UIView {

    private var rippleLayer: CAShapeLayer?
    private var rippleColor: UIColor = UIColor.white.withAlphaComponent(0.3)

    func startRipple(at point: CGPoint, color: UIColor? = nil) {
        if let color = color { rippleColor = color }

        let ripple = CAShapeLayer()
        ripple.fillColor = rippleColor.cgColor
        ripple.opacity = 0
        let initialSize: CGFloat = 10
        let path = UIBezierPath(ovalIn: CGRect(x: point.x - initialSize/2, y: point.y - initialSize/2,
                                               width: initialSize, height: initialSize))
        ripple.path = path.cgPath
        layer.insertSublayer(ripple, at: 0)

        // 放大动画
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = 30
        scaleAnimation.duration = 0.6

        // 透明度动画
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.6
        opacityAnimation.toValue = 0
        opacityAnimation.duration = 0.6

        // 组动画
        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, opacityAnimation]
        group.duration = 0.6
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.delegate = self
        ripple.add(group, forKey: "ripple")

        rippleLayer = ripple
    }
}

extension RippleEffectView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        rippleLayer?.removeFromSuperlayer()
        rippleLayer = nil
    }
}

// MARK: - 数字跳动动画
class CountingLabel: UILabel {

    private var startValue: Double = 0
    private var endValue: Double = 0
    private var duration: TimeInterval = 0.8
    private var startTime: Date?
    private var displayLink: CADisplayLink?
    private var format: ((Double) -> String)?

    func count(from startValue: Double, to endValue: Double, duration: TimeInterval = 0.8,
               format: @escaping (Double) -> String = { String(format: "%.0f", $0) }) {
        self.startValue = startValue
        self.endValue = endValue
        self.duration = duration
        self.format = format
        self.startTime = Date()

        displayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(updateValue))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func updateValue() {
        guard let startTime = startTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / duration, 1.0)

        // easeOut 缓动
        let easedProgress = 1 - pow(1 - progress, 3)
        let currentValue = startValue + (endValue - startValue) * easedProgress

        text = format?(currentValue) ?? String(format: "%.0f", currentValue)

        if progress >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    deinit {
        displayLink?.invalidate()
    }
}

// MARK: - 下拉刷新动画
class RefreshIndicatorView: UIView {

    private let circleLayer = CAShapeLayer()
    private let arrowLayer = CAShapeLayer()
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        // 圆形轨道
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                      radius: 12, startAngle: -CGFloat.pi/2,
                                      endAngle: CGFloat.pi * 1.5, clockwise: true)
        circleLayer.path = circlePath.cgPath
        circleLayer.strokeColor = UIColor.themeColorPrimary.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = 2
        circleLayer.strokeEnd = 0
        layer.addSublayer(circleLayer)

        // 箭头
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: bounds.midX, y: bounds.midY - 6))
        arrowPath.addLine(to: CGPoint(x: bounds.midX - 4, y: bounds.midY + 2))
        arrowPath.addLine(to: CGPoint(x: bounds.midX + 4, y: bounds.midY + 2))
        arrowPath.close()
        arrowLayer.path = arrowPath.cgPath
        arrowLayer.fillColor = UIColor.themeColorPrimary.cgColor
        layer.addSublayer(arrowLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }

    /// 更新下拉进度 (0 ~ 1)
    func updateProgress(_ progress: CGFloat) {
        guard !isAnimating else { return }
        let clamped = min(max(progress, 0), 1)
        circleLayer.strokeEnd = clamped * 0.8
        arrowLayer.opacity = Float(1 - clamped)
    }

    /// 开始加载动画
    func startAnimating() {
        isAnimating = true
        circleLayer.strokeEnd = 0.8
        arrowLayer.opacity = 0

        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1.0
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        circleLayer.add(rotation, forKey: "spin")
    }

    /// 停止动画
    func stopAnimating() {
        isAnimating = false
        circleLayer.removeAnimation(forKey: "spin")
        circleLayer.strokeEnd = 0
        arrowLayer.opacity = 1
    }
}

// MARK: - 气泡弹出动画
extension UIView {

    /// 气泡弹出效果（从小变大并带轻微回弹）
    func popIn(duration: TimeInterval = AnimationDuration.normal, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        self.transform = CGAffineTransform(scaleX: 0, y: 0)
        self.alpha = 0

        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) {
            self.transform = .identity
            self.alpha = 1
        } completion: { _ in
            completion?()
        }
    }

    /// 气泡消失效果
    func popOut(duration: TimeInterval = AnimationDuration.fast, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseIn) {
            self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.alpha = 0
        } completion: { _ in
            completion?()
        }
    }

    /// 心跳动画（循环跳动）
    func startHeartbeat(duration: TimeInterval = 1.0, scale: CGFloat = 1.1) {
        UIView.animate(withDuration: duration / 2,
                       delay: 0,
                       options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    /// 停止心跳动画
    func stopHeartbeat() {
        layer.removeAllAnimations()
        transform = .identity
    }

    /// 呼吸动画（透明度变化）
    func startBreathing(duration: TimeInterval = 2.0, minAlpha: CGFloat = 0.6) {
        UIView.animate(withDuration: duration / 2,
                       delay: 0,
                       options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.alpha = minAlpha
        }
    }

    /// 停止呼吸动画
    func stopBreathing() {
        layer.removeAllAnimations()
        alpha = 1
    }
}

// MARK: - TabBar 弹跳动画
extension UITabBarController {

    /// TabBar item 点击弹跳效果
    func animateTabSelection(at index: Int) {
        guard let items = tabBar.items, index < items.count else { return }

        let itemView = tabBar.subviews.filter { $0 is UIControl }[index]
        itemView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseInOut) {
            itemView.transform = .identity
        }
    }
}
