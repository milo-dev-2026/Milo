//
//  ThemeChatAnimations.swift
//  Milo
//
//  聊天页面专属动画
//  包含：消息气泡弹出、输入栏升降、表情面板切换、打字指示器等
//

import UIKit

// MARK: - 消息气泡动画类型
enum BubbleAnimationStyle {
    case pop          // 弹出（默认）
    case slideUp      // 从下往上滑入
    case fadeIn       // 淡入
    case scaleIn      // 缩放进入
    case spring       // 弹簧弹入
}

// MARK: - 消息气泡动画工具
final class BubbleAnimator {

    /// 给消息气泡添加入场动画
    static func animateBubble(_ bubbleView: UIView,
                              style: BubbleAnimationStyle = .pop,
                              delay: TimeInterval = 0,
                              completion: (() -> Void)? = nil) {
        switch style {
        case .pop:
            animatePop(bubbleView, delay: delay, completion: completion)
        case .slideUp:
            animateSlideUp(bubbleView, delay: delay, completion: completion)
        case .fadeIn:
            animateFadeIn(bubbleView, delay: delay, completion: completion)
        case .scaleIn:
            animateScaleIn(bubbleView, delay: delay, completion: completion)
        case .spring:
            animateSpring(bubbleView, delay: delay, completion: completion)
        }
    }

    private static func animatePop(_ view: UIView, delay: TimeInterval, completion: (() -> Void)?) {
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)

        UIView.animate(withDuration: 0.4,
                       delay: delay,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) {
            view.alpha = 1
            view.transform = .identity
        } completion: { _ in
            completion?()
        }
    }

    private static func animateSlideUp(_ view: UIView, delay: TimeInterval, completion: (() -> Void)?) {
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: 20)

        UIView.animate(withDuration: 0.3,
                       delay: delay,
                       options: .curveEaseOut) {
            view.alpha = 1
            view.transform = .identity
        } completion: { _ in
            completion?()
        }
    }

    private static func animateFadeIn(_ view: UIView, delay: TimeInterval, completion: (() -> Void)?) {
        view.alpha = 0
        UIView.animate(withDuration: 0.25, delay: delay, options: .curveEaseOut) {
            view.alpha = 1
        } completion: { _ in
            completion?()
        }
    }

    private static func animateScaleIn(_ view: UIView, delay: TimeInterval, completion: (() -> Void)?) {
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(withDuration: 0.25,
                       delay: delay,
                       options: .curveEaseOut) {
            view.alpha = 1
            view.transform = .identity
        } completion: { _ in
            completion?()
        }
    }

    private static func animateSpring(_ view: UIView, delay: TimeInterval, completion: (() -> Void)?) {
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        UIView.animate(withDuration: 0.5,
                       delay: delay,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.6,
                       options: .curveEaseOut) {
            view.alpha = 1
            view.transform = .identity
        } completion: { _ in
            completion?()
        }
    }
}

// MARK: - 输入栏升降动画
final class InputBarAnimator {

    /// 输入栏从底部升起
    static func animateShow(_ inputBar: UIView,
                            height: CGFloat,
                            duration: TimeInterval = 0.25,
                            completion: (() -> Void)? = nil) {
        inputBar.isHidden = false
        inputBar.transform = CGAffineTransform(translationX: 0, y: height)

        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            inputBar.transform = .identity
        } completion: { _ in
            completion?()
        }

        // 触觉反馈
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
    }

    /// 输入栏降下隐藏
    static func animateHide(_ inputBar: UIView,
                            height: CGFloat,
                            duration: TimeInterval = 0.2,
                            completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseIn) {
            inputBar.transform = CGAffineTransform(translationX: 0, y: height)
        } completion: { _ in
            inputBar.isHidden = true
            inputBar.transform = .identity
            completion?()
        }
    }

    /// 表情面板切换（淡入淡出+上下移动）
    static func animatePanelSwitch(from fromPanel: UIView,
                                   to toPanel: UIView,
                                   direction: Bool = true, // true = 向上, false = 向下
                                   duration: TimeInterval = 0.2) {
        let offset: CGFloat = direction ? 10 : -10

        fromPanel.alpha = 1
        fromPanel.transform = .identity
        toPanel.alpha = 0
        toPanel.transform = CGAffineTransform(translationX: 0, y: offset)
        toPanel.isHidden = false

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseInOut) {
            fromPanel.alpha = 0
            fromPanel.transform = CGAffineTransform(translationX: 0, y: -offset)
            toPanel.alpha = 1
            toPanel.transform = .identity
        } completion: { _ in
            fromPanel.isHidden = true
            fromPanel.transform = .identity
        }
    }
}

// MARK: - 打字指示器动画
final class TypingIndicatorView: UIView {

    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()

    var dotColor: UIColor = .themeTextSecondary {
        didSet {
            dot1.backgroundColor = dotColor
            dot2.backgroundColor = dotColor
            dot3.backgroundColor = dotColor
        }
    }

    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(6)
            make.width.equalTo(26)
        }

        [dot1, dot2, dot3].forEach { dot in
            dot.backgroundColor = dotColor
            dot.layer.cornerRadius = 3
            dot.clipsToBounds = true
            stack.addArrangedSubview(dot)
            dot.snp.makeConstraints { make in
                make.width.height.equalTo(6)
            }
        }
    }

    /// 开始打字动画
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        animateDot(dot1, delay: 0)
        animateDot(dot2, delay: 0.15)
        animateDot(dot3, delay: 0.3)
    }

    /// 停止打字动画
    func stopAnimating() {
        isAnimating = false
        [dot1, dot2, dot3].forEach { dot in
            dot.layer.removeAllAnimations()
            dot.transform = .identity
            dot.alpha = 1
        }
    }

    private func animateDot(_ dot: UIView, delay: TimeInterval) {
        dot.transform = CGAffineTransform(translationX: 0, y: -3)
        dot.alpha = 0.5

        UIView.animate(withDuration: 0.4,
                       delay: delay,
                       options: [.repeat, .autoreverse, .curveEaseInOut]) {
            dot.transform = CGAffineTransform(translationX: 0, y: 3)
            dot.alpha = 1
        }
    }
}

// MARK: - 已读回执动画
final class ReadReceiptAnimator {

    /// 已读小勾动画
    static func animateReadCheck(_ imageView: UIImageView, isRead: Bool) {
        guard isRead else {
            imageView.image = UIImage(systemName: "checkmark")
            imageView.tintColor = .themeTextTertiary
            return
        }

        // 双勾 + 颜色变化动画
        imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        imageView.alpha = 0

        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve) {
            imageView.image = UIImage(systemName: "checkmark.circle.fill")
            imageView.tintColor = .themeColorPrimary
        }

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) {
            imageView.transform = .identity
            imageView.alpha = 1
        }

        // 触觉反馈（轻微）
        if AnimationIntegration.shared.config.enableHapticFeedback {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticManager.shared.playCustomPattern(intensity: 0.3, sharpness: 0.2)
            }
        }
    }
}

// MARK: - 语音消息波形动画
final class VoiceWaveformView: UIView {

    private var waveformLayers: [CAShapeLayer] = []
    private var isAnimating = false
    private var barCount: Int = 4
    private var barWidth: CGFloat = 3
    private var barSpacing: CGFloat = 2

    var barColor: UIColor = .white {
        didSet {
            waveformLayers.forEach { $0.fillColor = barColor.cgColor }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWaves()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWaves()
    }

    private func setupWaves() {
        backgroundColor = .clear
        clipsToBounds = false

        for i in 0..<barCount {
            let layer = CAShapeLayer()
            layer.fillColor = barColor.cgColor
            layer.cornerRadius = barWidth / 2
            waveformLayers.append(layer)
            layer.add(singleWaveAnimation(delay: Double(i) * 0.15), forKey: "wave_\(i)")
            layer.speed = 0 // 初始暂停
            layer.timeOffset = 0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalWidth) / 2

        for (index, layer) in waveformLayers.enumerated() {
            let x = startX + CGFloat(index) * (barWidth + barSpacing)
            let height = bounds.height * 0.6
            let y = (bounds.height - height) / 2
            let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: barWidth, height: height),
                                    cornerRadius: barWidth / 2)
            layer.path = path.cgPath
            layer.frame = CGRect(x: x, y: y, width: barWidth, height: height)
        }
    }

    private func singleWaveAnimation(delay: TimeInterval) -> CAAnimationGroup {
        // 高度变化
        let heightAnim = CABasicAnimation(keyPath: "bounds.size.height")
        heightAnim.fromValue = bounds.height * 0.3
        heightAnim.toValue = bounds.height
        heightAnim.duration = 0.5
        heightAnim.autoreverses = true
        heightAnim.beginTime = delay
        heightAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        // Y 位置变化（保持底部对齐）
        let yAnim = CABasicAnimation(keyPath: "position.y")
        yAnim.fromValue = bounds.height - bounds.height * 0.15
        yAnim.toValue = bounds.height / 2
        yAnim.duration = 0.5
        yAnim.autoreverses = true
        yAnim.beginTime = delay
        yAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let group = CAAnimationGroup()
        group.animations = [heightAnim, yAnim]
        group.duration = 1.0
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false

        return group
    }

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        for layer in waveformLayers {
            let pausedTime = layer.timeOffset
            layer.speed = 1.0
            layer.timeOffset = 0.0
            layer.beginTime = 0.0
            let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            layer.beginTime = timeSincePause
        }
    }

    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false

        for layer in waveformLayers {
            let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
            layer.speed = 0.0
            layer.timeOffset = pausedTime
        }
    }
}

// MARK: - 消息已读/未读状态标签动画
final class UnreadCountBadge: UIView {

    private let countLabel = UILabel()
    private var count: Int = 0

    var badgeColor: UIColor = .themeError {
        didSet { backgroundColor = badgeColor }
    }

    var textColor: UIColor = .white {
        didSet { countLabel.textColor = textColor }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = badgeColor
        layer.cornerRadius = 9
        layer.masksToBounds = true

        countLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        countLabel.textColor = textColor
        countLabel.textAlignment = .center
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.minimumScaleFactor = 0.5
        addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }
    }

    /// 设置数量（带动画）
    func setCount(_ count: Int, animated: Bool = true) {
        let oldCount = self.count
        self.count = count

        if count <= 0 {
            isHidden = true
            return
        }

        isHidden = false

        let displayText = count > 99 ? "99+" : "\(count)"
        countLabel.text = displayText

        if animated && count != oldCount {
            // 弹跳动画
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.8,
                           options: .curveEaseInOut) {
                self.transform = .identity
            }

            // 触觉反馈
            if AnimationIntegration.shared.config.enableHapticFeedback && count > oldCount {
                HapticManager.shared.playCustomPattern(intensity: 0.4, sharpness: 0.3)
            }
        }

        // 调整宽度
        setNeedsLayout()
        layoutIfNeeded()
    }

    override var intrinsicContentSize: CGSize {
        let text = count > 99 ? "99+" : "\(count)"
        let width = min(max(text.width(withConstrainedHeight: 18,
                                         font: countLabel.font ?? UIFont.systemFont(ofSize: 11)) + 8, 18), 36)
        return CGSize(width: width, height: 18)
    }
}

// MARK: - 聊天气泡长按弹出菜单动画
final class MenuPopAnimator {

    /// 弹出菜单（从气泡位置缩放出现）
    static func presentMenu(_ menuView: UIView,
                            from fromView: UIView,
                            in containerView: UIView,
                            completion: (() -> Void)? = nil) {
        menuView.alpha = 0
        menuView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        containerView.addSubview(menuView)

        // 从气泡中心缩放
        let fromFrame = fromView.convert(fromView.bounds, to: containerView)
        menuView.center = CGPoint(x: fromFrame.midX, y: fromFrame.midY)

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.6,
                       options: .curveEaseOut) {
            menuView.alpha = 1
            menuView.transform = .identity
        } completion: { _ in
            completion?()
        }

        // 触觉反馈
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }
    }

    /// 隐藏菜单
    static func dismissMenu(_ menuView: UIView, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: .curveEaseIn) {
            menuView.alpha = 0
            menuView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            menuView.removeFromSuperview()
            menuView.transform = .identity
            completion?()
        }
    }
}

// MARK: - 表情/功能面板展开动画
final class PanelExpandAnimator {

    /// 面板从底部展开
    static func expand(_ panelView: UIView,
                       in containerView: UIView,
                       height: CGFloat,
                       duration: TimeInterval = 0.25,
                       completion: (() -> Void)? = nil) {
        panelView.frame = CGRect(x: 0, y: containerView.bounds.height,
                                 width: containerView.bounds.width, height: height)
        containerView.addSubview(panelView)

        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            panelView.frame.origin.y = containerView.bounds.height - height
        } completion: { _ in
            completion?()
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
    }

    /// 面板收起
    static func collapse(_ panelView: UIView,
                         duration: TimeInterval = 0.2,
                         completion: (() -> Void)? = nil) {
        let targetY = panelView.superview?.bounds.height ?? panelView.bounds.height

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseIn) {
            panelView.frame.origin.y = targetY
        } completion: { _ in
            panelView.removeFromSuperview()
            completion?()
        }
    }
}
