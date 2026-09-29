//
//  ThemeHaptics.swift
//  Milo
//
//  触觉反馈管理器 + 增强骨架屏
//

import UIKit
import CoreHaptics

// MARK: - 触觉反馈管理器
final class HapticManager {

    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var isHapticsEnabled: Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private init() {
        prepareEngine()
    }

    // MARK: - 初始化引擎
    private func prepareEngine() {
        guard isHapticsEnabled else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            // 引擎重置时自动重启
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("Haptic engine restart failed: \(error)")
                }
            }
        } catch {
            print("Haptic engine init failed: \(error)")
        }
    }

    // MARK: - 公共方法

    /// 轻量级触感（按钮点击）
    func impactLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// 中等触感（开关切换）
    func impactMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// 重量级触感（重要操作）
    func impactHeavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// 柔软触感
    func impactSoft() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        } else {
            impactLight()
        }
    }

    /// 刚性触感
    func impactRigid() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        } else {
            impactMedium()
        }
    }

    /// 成功反馈
    func notificationSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// 警告反馈
    func notificationWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// 错误反馈
    func notificationError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// 选择反馈
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// 自定义连续震动（用于进度条、滑动等）
    func playCustomPattern(intensity: Float = 0.5, sharpness: Float = 0.5) {
        guard isHapticsEnabled, let engine = engine else { return }

        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0,
                duration: 0.1
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Custom haptic failed: \(error)")
        }
    }

    /// 心跳节奏
    func playHeartbeat() {
        guard isHapticsEnabled, let engine = engine else { return }

        do {
            var events: [CHHapticEvent] = []

            // 第一声（强）
            let beat1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            )
            events.append(beat1)

            // 第二声（稍弱）
            let beat2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.2
            )
            events.append(beat2)

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Heartbeat haptic failed: \(error)")
        }
    }

    /// 上升节奏（成功、完成）
    func playAscend() {
        guard isHapticsEnabled, let engine = engine else { return }

        do {
            var events: [CHHapticEvent] = []

            for i in 0..<3 {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.3 + Double(i) * 0.25)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.3 + Double(i) * 0.2))
                    ],
                    relativeTime: Double(i) * 0.1
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Ascend haptic failed: \(error)")
        }
    }

    /// 下降节奏（失败、取消）
    func playDescend() {
        guard isHapticsEnabled, let engine = engine else { return }

        do {
            var events: [CHHapticEvent] = []

            for i in 0..<3 {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.8 - Double(i) * 0.25)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.7 - Double(i) * 0.2))
                    ],
                    relativeTime: Double(i) * 0.1
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Descend haptic failed: \(error)")
        }
    }
}

// MARK: - UIView 触觉反馈便捷方法
extension UIView {

    /// 添加点击触觉反馈
    func addHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(_triggerHaptic))
        tap.name = "haptic_tap_\(style.rawValue)"
        addGestureRecognizer(tap)
    }

    @objc private func _triggerHaptic() {
        HapticManager.shared.impactLight()
    }
}

// MARK: - UIButton 触觉反馈
extension UIButton {

    /// 添加点击触觉反馈
    func addHapticTapFeedback() {
        addTarget(self, action: #selector(_hapticTap), for: .touchUpInside)
    }

    @objc private func _hapticTap() {
        HapticManager.shared.impactLight()
    }
}

// MARK: - 增强骨架屏视图
final class SkeletonContentView: UIView {

    // MARK: - 配置
    enum SkeletonStyle {
        case text           // 文字行
        case circle         // 圆形头像
        case rectangle      // 矩形卡片
        case custom(CGSize) // 自定义尺寸
    }

    private let gradientLayer = CAGradientLayer()
    private var isAnimating = false

    var animationDuration: TimeInterval = AnimationDuration.shimmer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSkeleton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSkeleton()
    }

    private func setupSkeleton() {
        backgroundColor = .themeBgInput
        clipsToBounds = true

        // 渐变层
        gradientLayer.colors = [
            UIColor.themeBgInput.cgColor,
            UIColor.themeBgWhite.cgColor,
            UIColor.themeBgInput.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.locations = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    /// 开始骨架动画
    func startShimmer() {
        guard !isAnimating else { return }
        isAnimating = true

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = animationDuration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(animation, forKey: "shimmer")
    }

    /// 停止骨架动画
    func stopShimmer() {
        isAnimating = false
        gradientLayer.removeAnimation(forKey: "shimmer")
    }

    /// 显示真实内容（渐入替换）
    func showContent(_ contentView: UIView, duration: TimeInterval = 0.3) {
        stopShimmer()

        contentView.alpha = 0
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        UIView.animate(withDuration: duration, animations: {
            contentView.alpha = 1
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - 骨架屏 Cell 生成器
final class SkeletonFactory {

    /// 创建文字行骨架
    static func textSkeleton(width: CGFloat = 200, height: CGFloat = 16, cornerRadius: CGFloat = 4) -> SkeletonContentView {
        let view = SkeletonContentView()
        view.layer.cornerRadius = cornerRadius
        view.snp.makeConstraints { make in
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
        return view
    }

    /// 创建圆形骨架
    static func circleSkeleton(size: CGFloat = 44) -> SkeletonContentView {
        let view = SkeletonContentView()
        view.layer.cornerRadius = size / 2
        view.snp.makeConstraints { make in
            make.width.height.equalTo(size)
        }
        return view
    }

    /// 创建矩形骨架
    static func rectangleSkeleton(width: CGFloat = 100, height: CGFloat = 100, cornerRadius: CGFloat = 8) -> SkeletonContentView {
        let view = SkeletonContentView()
        view.layer.cornerRadius = cornerRadius
        view.snp.makeConstraints { make in
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
        return view
    }

    /// 创建列表行骨架（头像 + 两行文字）
    static func listRowSkeleton() -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let avatar = circleSkeleton(size: 44)
        container.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        let titleLine = textSkeleton(width: 120, height: 14)
        container.addSubview(titleLine)
        titleLine.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar.snp.top).offset(4)
            make.width.equalTo(120)
            make.height.equalTo(14)
        }

        let subtitleLine = textSkeleton(width: 180, height: 12)
        container.addSubview(subtitleLine)
        subtitleLine.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.bottom.equalTo(avatar.snp.bottom).offset(-4)
            make.width.equalTo(180)
            make.height.equalTo(12)
        }

        return container
    }

    /// 创建卡片骨架
    static func cardSkeleton(width: CGFloat) -> UIView {
        let container = UIView()
        container.backgroundColor = .themeBgCard
        container.layer.cornerRadius = 12

        let imageRect = rectangleSkeleton(width: width - 32, height: 120, cornerRadius: 8)
        container.addSubview(imageRect)
        imageRect.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(120)
        }

        let titleLine = textSkeleton(width: width * 0.6, height: 14)
        container.addSubview(titleLine)
        titleLine.snp.makeConstraints { make in
            make.top.equalTo(imageRect.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(14)
        }

        let descLine = textSkeleton(width: width * 0.8, height: 12)
        container.addSubview(descLine)
        descLine.snp.makeConstraints { make in
            make.top.equalTo(titleLine.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(12)
        }

        return container
    }
}

// MARK: - 页面骨架屏容器
final class SkeletonLoadingView: UIView {

    enum SkeletonType {
        case list           // 列表样式
        case grid           // 网格样式
        case profile        // 个人资料样式
        case detail         // 详情页样式
    }

    private var type: SkeletonType = .list
    private var skeletonViews: [SkeletonContentView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .themeBg
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .themeBg
    }

    /// 显示骨架屏
    func show(type: SkeletonType = .list, in view: UIView) {
        self.type = type
        frame = view.bounds
        view.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupSkeletons()
        startAnimating()
    }

    /// 隐藏骨架屏
    func hide(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 0
            }) { _ in
                self.removeFromSuperview()
            }
        } else {
            removeFromSuperview()
        }
    }

    private func setupSkeletons() {
        subviews.forEach { $0.removeFromSuperview() }
        skeletonViews.removeAll()

        switch type {
        case .list:
            setupListSkeleton()
        case .grid:
            setupGridSkeleton()
        case .profile:
            setupProfileSkeleton()
        case .detail:
            setupDetailSkeleton()
        }
    }

    private func setupListSkeleton() {
        var lastView: UIView = self

        for i in 0..<6 {
            let row = SkeletonFactory.listRowSkeleton()
            addSubview(row)
            row.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(60)

                if i == 0 {
                    make.top.equalToSuperview().offset(20)
                } else {
                    make.top.equalTo(lastView.snp.bottom).offset(16)
                }
            }

            // 收集所有骨架视图
            if let container = row as? SkeletonContentView {
                skeletonViews.append(container)
            } else {
                for subview in row.subviews {
                    if let sk = subview as? SkeletonContentView {
                        skeletonViews.append(sk)
                    }
                }
            }

            lastView = row
        }
    }

    private func setupGridSkeleton() {
        let itemWidth = (bounds.width - 48) / 2

        for row in 0..<3 {
            for col in 0..<2 {
                let card = SkeletonFactory.cardSkeleton(width: itemWidth)
                addSubview(card)
                card.snp.makeConstraints { make in
                    make.width.equalTo(itemWidth)
                    make.height.equalTo(itemWidth * 1.2)
                    make.left.equalToSuperview().offset(16 + CGFloat(col) * (itemWidth + 16))
                    make.top.equalToSuperview().offset(20 + CGFloat(row) * (itemWidth * 1.2 + 16))
                }

                for subview in card.subviews {
                    if let sk = subview as? SkeletonContentView {
                        skeletonViews.append(sk)
                    }
                }
            }
        }
    }

    private func setupProfileSkeleton() {
        // 头像
        let avatar = SkeletonFactory.circleSkeleton(size: 80)
        addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        skeletonViews.append(avatar)

        // 名字
        let name = SkeletonFactory.textSkeleton(width: 100, height: 16)
        addSubview(name)
        name.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(16)
        }
        skeletonViews.append(name)

        // 描述
        let desc = SkeletonFactory.textSkeleton(width: 150, height: 12)
        addSubview(desc)
        desc.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(150)
            make.height.equalTo(12)
        }
        skeletonViews.append(desc)
    }

    private func setupDetailSkeleton() {
        // 大图
        let image = SkeletonFactory.rectangleSkeleton(width: bounds.width - 32, height: 200, cornerRadius: 12)
        addSubview(image)
        image.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(200)
        }
        skeletonViews.append(image)

        // 标题行
        let title = SkeletonFactory.textSkeleton(width: bounds.width * 0.7, height: 18)
        addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalTo(image.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(18)
        }
        skeletonViews.append(title)

        // 多行内容
        for i in 0..<4 {
            let line = SkeletonFactory.textSkeleton(width: bounds.width - 48 - CGFloat(i) * 30, height: 14)
            addSubview(line)
            line.snp.makeConstraints { make in
                make.top.equalTo(title.snp.bottom).offset(12 + CGFloat(i) * 20)
                make.left.equalToSuperview().offset(16)
                make.height.equalTo(14)
            }
            skeletonViews.append(line)
        }
    }

    private func startAnimating() {
        // 错峰启动，营造流动感
        for (index, skeleton) in skeletonViews.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                skeleton.startShimmer()
            }
        }
    }
}
