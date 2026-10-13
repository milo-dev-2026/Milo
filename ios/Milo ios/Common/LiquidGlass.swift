//
//  LiquidGlass.swift
//  Milo
//
//  液态玻璃效果系统 - iOS 15+ 高级视觉效果
//  包含：LiquidGlassView, LiquidGlassButton, LiquidGlassCard
//  特点：毛玻璃 + 饱和度调整 + 柔和边框 + 顶部高光
//  深色模式：自动适配模糊样式、边框透明度、高光强度、色调叠加
//
import UIKit
import SnapKit

// MARK: - 液态玻璃视图
/// 可复用的液态玻璃视图组件
/// 毛玻璃 + 半透明叠加 + 内描边 + 顶部高光渐变
/// 自动适配深色模式：边框透明度、高光强度、色调叠加层均会自动切换
@available(iOS 15.0, *)
class LiquidGlassView: UIView {

    // MARK: - 可配置属性

    /// 圆角大小，默认 16
    var cornerRadius: CGFloat = 16 {
        didSet { updateCornerRadius() }
    }

    /// 玻璃不透明度，默认 0.6
    var glassOpacity: CGFloat = 0.6 {
        didSet { updateGlassOpacity() }
    }

    /// 边框宽度，默认 0.5
    var borderWidth: CGFloat = 0.5 {
        didSet { updateBorder() }
    }

    /// 边框颜色 - 设置后会覆盖自动深色模式适配
    /// 如需要自动适配，请使用默认值或设置为 .liquidGlassBorder
    var borderColor: UIColor = .liquidGlassBorder {
        didSet { updateBorder() }
    }

    /// 模糊样式，默认 .systemMaterial
    /// traitCollectionDidChange 会根据明暗模式自动切换对应样式
    var blurStyle: UIBlurEffect.Style = .systemMaterial {
        didSet { updateBlurStyle() }
    }

    /// 顶部高光不透明度，默认 0.15
    /// 深色模式下会自动降低（如果 useAutomaticHighlight 为 true）
    var highlightOpacity: CGFloat = 0.15 {
        didSet { updateHighlight() }
    }

    /// 是否自动适配深色模式的高光和边框
    var useAutomaticDarkModeAdaptation: Bool = true {
        didSet { updateForTraitCollection() }
    }

    /// 色调叠加层颜色 - 玻璃的颜色倾向
    /// 浅色: 白色偏透明  深色: 黑色偏透明
    var tintColorForGlass: UIColor = .liquidGlassTint {
        didSet { updateGlassOpacity() }
    }

    // MARK: - 内部层

    /// 主毛玻璃层
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))

    /// 活力效果层（可选，增强内容可见性）
    private let vibrancyEffectView = UIVisualEffectView()

    /// 边框层（内描边，模拟玻璃边缘）
    private let borderLayer = CAShapeLayer()

    /// 顶部高光渐变（模拟玻璃反光）
    private let highlightLayer = CAGradientLayer()

    /// 内容容器（添加子视图用这个）
    let contentContainer: UIView = UIView()

    /// 半透明颜色叠加层（调节玻璃色调）
    private let tintOverlayView = UIView()

    // MARK: - 关联对象键
    private static let liquidGlassAssociationKey = UnsafeRawPointer(
        bitPattern: "com.milo.liquidGlass.view".hashValue
    )
    private static let liquidGlassBlurAssociationKey = UnsafeRawPointer(
        bitPattern: "com.milo.liquidGlass.blur".hashValue
    )

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    convenience init(style: UIBlurEffect.Style = .systemMaterial, cornerRadius: CGFloat = 16) {
        self.init(frame: .zero)
        self.blurStyle = style
        self.cornerRadius = cornerRadius
        updateBlurStyle()
        updateCornerRadius()
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false
        layer.masksToBounds = false

        // 1. 毛玻璃层
        blurEffectView.effect = UIBlurEffect(style: blurStyle)
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 2. 活力效果层（嵌套在毛玻璃内）
        let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: blurStyle), style: .label)
        vibrancyEffectView.effect = vibrancyEffect
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        vibrancyEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 3. 半透明色调叠加
        tintOverlayView.backgroundColor = tintColorForGlass
        addSubview(tintOverlayView)
        sendSubviewToBack(tintOverlayView)
        insertSubview(tintOverlayView, aboveSubview: blurEffectView)
        tintOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 4. 顶部高光渐变
        highlightLayer.colors = [
            UIColor.white.withAlphaComponent(highlightOpacity).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        highlightLayer.startPoint = CGPoint(x: 0.5, y: 0)
        highlightLayer.endPoint = CGPoint(x: 0.5, y: 1)
        highlightLayer.locations = [0, 1]
        layer.addSublayer(highlightLayer)

        // 5. 边框层（内描边）
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.frame = bounds
        layer.addSublayer(borderLayer)

        // 6. 内容容器
        contentContainer.backgroundColor = .clear
        addSubview(contentContainer)
        bringSubviewToFront(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 初始设置
        updateCornerRadius()
        updateBorder()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBorder()
        updateHighlight()
    }

    // MARK: - 深色模式适配

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateForTraitCollection()
        }
    }

    private func updateForTraitCollection() {
        guard useAutomaticDarkModeAdaptation else { return }

        let isDark = traitCollection.userInterfaceStyle == .dark

        // 1. 根据当前样式自动适配深色模式对应的模糊样式
        switch blurStyle {
        case .systemMaterial, .systemMaterialDark:
            let newStyle: UIBlurEffect.Style = isDark ? .systemMaterialDark : .systemMaterial
            if newStyle != blurStyle {
                blurStyle = newStyle
            }
        case .systemUltraThinMaterialLight, .systemUltraThinMaterialDark:
            let newStyle: UIBlurEffect.Style = isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
            if newStyle != blurStyle {
                blurStyle = newStyle
            }
        case .systemThinMaterialLight, .systemThinMaterialDark:
            let newStyle: UIBlurEffect.Style = isDark ? .systemThinMaterialDark : .systemThinMaterialLight
            if newStyle != blurStyle {
                blurStyle = newStyle
            }
        case .systemMaterialLight:
            let newStyle: UIBlurEffect.Style = isDark ? .systemMaterialDark : .systemMaterialLight
            if newStyle != blurStyle {
                blurStyle = newStyle
            }
        case .systemChromeMaterialLight, .systemChromeMaterialDark:
            let newStyle: UIBlurEffect.Style = isDark ? .systemChromeMaterialDark : .systemChromeMaterialLight
            if newStyle != blurStyle {
                blurStyle = newStyle
            }
        default:
            break
        }

        // 2. 更新边框颜色（深色模式透明度降低）
        borderColor = .liquidGlassBorder

        // 3. 更新色调叠加层
        tintColorForGlass = .liquidGlassTint

        // 4. 更新高光（深色模式下更暗）
        updateHighlight()
    }

    // MARK: - 公开方法

    /// 添加内容到玻璃容器
    func addContent(_ view: UIView) {
        contentContainer.addSubview(view)
    }

    /// 更新模糊样式
    func updateGlassStyle(_ style: UIBlurEffect.Style) {
        blurStyle = style
    }

    /// 圆角动画
    func animateCornerRadius(to radius: CGFloat, duration: TimeInterval = 0.3) {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.fromValue = cornerRadius
        animation.toValue = radius
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "cornerRadius")
        blurEffectView.layer.add(animation, forKey: "cornerRadius")
        tintOverlayView.layer.add(animation, forKey: "cornerRadius")

        cornerRadius = radius
        updateCornerRadius()

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        updateBorder()
        updateHighlight()
        CATransaction.commit()
    }

    // MARK: - 私有方法

    func updateCornerRadius() {
        layer.cornerRadius = cornerRadius
        blurEffectView.layer.cornerRadius = cornerRadius
        blurEffectView.clipsToBounds = true
        tintOverlayView.layer.cornerRadius = cornerRadius
        tintOverlayView.clipsToBounds = true
        contentContainer.layer.cornerRadius = cornerRadius
        contentContainer.clipsToBounds = true
        setNeedsLayout()
    }

    private func updateGlassOpacity() {
        tintOverlayView.backgroundColor = tintColorForGlass
    }

    private func updateBorder() {
        let inset = borderWidth / 2
        let rect = bounds.insetBy(dx: inset, dy: inset)
        borderLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius - inset).cgPath
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.frame = bounds
    }

    private func updateBlurStyle() {
        blurEffectView.effect = UIBlurEffect(style: blurStyle)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: blurStyle), style: .label)
        vibrancyEffectView.effect = vibrancyEffect
    }

    private func updateHighlight() {
        highlightLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height * 0.5)
        highlightLayer.cornerRadius = cornerRadius
        highlightLayer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        // 深色模式下自动降低高光强度
        let actualOpacity: CGFloat
        if useAutomaticDarkModeAdaptation && traitCollection.userInterfaceStyle == .dark {
            actualOpacity = highlightOpacity * 0.6  // 深色模式下高光更柔和
        } else {
            actualOpacity = highlightOpacity
        }

        highlightLayer.colors = [
            UIColor.white.withAlphaComponent(actualOpacity).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
    }
}

// MARK: - 液态玻璃按钮
/// 液态玻璃风格按钮
/// 玻璃背景 + 文字，按下时缩小+玻璃变暗，松开弹簧弹回
/// 自动适配深色模式
@available(iOS 15.0, *)
class LiquidGlassButton: UIControl {

    // MARK: - 可配置属性

    /// 按钮标题
    var title: String? {
        didSet { titleLabel.text = title }
    }

    /// 标题字体
    var titleFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium) {
        didSet { titleLabel.font = titleFont }
    }

    /// 标题颜色
    var titleColor: UIColor = .label {
        didSet { titleLabel.textColor = titleColor }
    }

    /// 圆角大小
    var cornerRadius: CGFloat = 16 {
        didSet { glassView.cornerRadius = cornerRadius }
    }

    /// 模糊样式
    var blurStyle: UIBlurEffect.Style = .systemMaterial {
        didSet { glassView.blurStyle = blurStyle }
    }

    /// 图标
    var icon: UIImage? {
        didSet {
            iconView.image = icon
            iconView.isHidden = icon == nil
            updateIconConstraints()
        }
    }

    /// 图标颜色
    var iconTintColor: UIColor = .label {
        didSet { iconView.tintColor = iconTintColor }
    }

    /// 按压缩放比例
    var pressScale: CGFloat = 0.95

    // MARK: - 内部视图

    private let glassView = LiquidGlassView()
    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    private let contentStack = UIStackView()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    convenience init(title: String, fontSize: CGFloat = 16) {
        self.init(frame: .zero)
        self.title = title
        self.titleLabel.text = title
        self.titleFont = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        self.titleLabel.font = titleFont
    }

    convenience init(icon: UIImage, tintColor: UIColor = .label) {
        self.init(frame: .zero)
        self.icon = icon
        self.iconView.image = icon
        self.iconTintColor = tintColor
        self.iconView.tintColor = tintColor
        self.titleLabel.isHidden = true
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false

        // 玻璃背景
        glassView.cornerRadius = cornerRadius
        glassView.glassOpacity = 0.5
        addSubview(glassView)
        glassView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 内容栈
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 6
        contentStack.isUserInteractionEnabled = false
        glassView.addContent(contentStack)

        // 图标
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = iconTintColor
        iconView.isHidden = true
        contentStack.addArrangedSubview(iconView)

        // 标题
        titleLabel.text = title
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = false
        contentStack.addArrangedSubview(titleLabel)

        contentStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }

        // 阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
    }

    private func updateIconConstraints() {
        iconView.isHidden = icon == nil
    }

    // MARK: - 触摸事件

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let result = super.beginTracking(touch, with: event)
        if result {
            animatePress()
        }
        return result
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        animateRelease()
    }

    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        animateRelease()
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let result = super.continueTracking(touch, with: event)
        let isInside = bounds.contains(touch.location(in: self))
        if isInside && transform == .identity {
            // 保持按下状态
        } else if !isInside && transform != .identity {
            animateRelease()
        } else if isInside && transform != .identity {
            animatePress()
        }
        return result
    }

    // MARK: - 动画

    private func animatePress() {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else {
            return
        }

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) { [weak self] in
            guard let self = self else { return }
            self.transform = CGAffineTransform(scaleX: self.pressScale, y: self.pressScale)
            self.glassView.glassOpacity = 0.3
            self.alpha = 0.9
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
    }

    private func animateRelease() {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else {
            return
        }

        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) { [weak self] in
            guard let self = self else { return }
            self.transform = .identity
            self.glassView.glassOpacity = 0.5
            self.alpha = 1.0
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glassView.cornerRadius = min(cornerRadius, bounds.height / 2)
    }
}

// MARK: - 液态玻璃卡片
/// 液态玻璃卡片，继承自 LiquidGlassView
/// 自带柔和阴影，支持点击手势和悬停/按下动画
/// 自动适配深色模式
@available(iOS 15.0, *)
class LiquidGlassCard: LiquidGlassView {

    // MARK: - 可配置属性

    /// 点击回调
    var onTap: (() -> Void)?

    /// 是否启用点击动画
    var enableTapAnimation: Bool = true

    /// 阴影颜色
    var shadowColor: UIColor = UIColor.black {
        didSet { layer.shadowColor = shadowColor.cgColor }
    }

    /// 阴影不透明度
    var shadowOpacity: Float = 0.15 {
        didSet { layer.shadowOpacity = shadowOpacity }
    }

    /// 阴影偏移
    var shadowOffset: CGSize = CGSize(width: 0, height: 8) {
        didSet { layer.shadowOffset = shadowOffset }
    }

    /// 阴影半径
    var shadowRadius: CGFloat = 20 {
        didSet { layer.shadowRadius = shadowRadius }
    }

    // MARK: - 私有属性

    private let tapGesture = UITapGestureRecognizer()
    private var isPressed = false

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCard()
    }

    convenience init(cornerRadius: CGFloat = 20) {
        self.init(frame: .zero)
        self.cornerRadius = cornerRadius
        updateCornerRadius()
    }

    private func setupCard() {
        // 阴影配置 - 模拟浮起效果
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius

        // 玻璃效果稍强
        glassOpacity = 0.7
        highlightOpacity = 0.2
        borderWidth = 0.5

        // 点击手势
        tapGesture.addTarget(self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    // MARK: - 深色模式适配 - 阴影优化

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // 深色模式下阴影更柔和（因为背景已经很暗）
            let isDark = traitCollection.userInterfaceStyle == .dark
            layer.shadowOpacity = isDark ? shadowOpacity * 0.5 : shadowOpacity
            layer.shadowRadius = isDark ? shadowRadius * 0.7 : shadowRadius
        }
    }

    // MARK: - 点击处理

    @objc private func handleTap() {
        onTap?()

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
    }

    // MARK: - 触摸动画

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard enableTapAnimation else { return }
        animatePress()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard enableTapAnimation else { return }
        animateRelease()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard enableTapAnimation else { return }
        animateRelease()
    }

    private func animatePress() {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }
        isPressed = true

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) { [weak self] in
            guard let self = self else { return }
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            self.layer.shadowOpacity = self.shadowOpacity * 0.6
            self.layer.shadowRadius = self.shadowRadius * 0.8
            self.layer.shadowOffset = CGSize(width: 0, height: self.shadowOffset.height * 0.5)
        }
    }

    private func animateRelease() {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }
        isPressed = false

        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.7,
                       options: .curveEaseOut) { [weak self] in
            guard let self = self else { return }
            self.transform = .identity
            self.layer.shadowOpacity = self.shadowOpacity
            self.layer.shadowRadius = self.shadowRadius
            self.layer.shadowOffset = self.shadowOffset
        }
    }
}

// MARK: - UIView 液态玻璃扩展
@available(iOS 15.0, *)
extension UIView {

    private struct LiquidGlassKeys {
        static var glassViewKey = "liquidGlassView"
        static var glassBlurViewKey = "liquidGlassBlurView"
    }

    /// 液态玻璃视图引用
    private var lg_glassView: LiquidGlassView? {
        get {
            return objc_getAssociatedObject(self, &LiquidGlassKeys.glassViewKey) as? LiquidGlassView
        }
        set {
            objc_setAssociatedObject(self, &LiquidGlassKeys.glassViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 给任意 view 添加液态玻璃效果
    /// - Parameters:
    ///   - cornerRadius: 圆角大小
    ///   - blurStyle: 模糊样式（会自动适配深色模式）
    func applyLiquidGlassEffect(cornerRadius: CGFloat = 16, blurStyle: UIBlurEffect.Style = .systemMaterial) {
        // 避免重复添加
        if lg_glassView != nil { return }

        let glassView = LiquidGlassView(style: blurStyle, cornerRadius: cornerRadius)
        glassView.isUserInteractionEnabled = false
        insertSubview(glassView, at: 0)
        glassView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        lg_glassView = glassView

        // 确保背景透明
        if backgroundColor == .white || backgroundColor == .systemBackground {
            backgroundColor = .clear
        }
    }

    /// 移除液态玻璃效果
    func removeLiquidGlassEffect() {
        lg_glassView?.removeFromSuperview()
        lg_glassView = nil
    }
}

// MARK: - 液态玻璃动画扩展
@available(iOS 15.0, *)
extension UIView {

    /// 玻璃显现动画（从透明到玻璃）
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    func animateGlassAppear(duration: TimeInterval = AnimationDuration.slow,
                            delay: TimeInterval = 0,
                            completion: (() -> Void)? = nil) {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.95, y: 0.95)

        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) { [weak self] in
            self?.alpha = 1
            self?.transform = .identity
        } completion: { _ in
            completion?()
        }
    }

    /// 玻璃消失动画
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    func animateGlassDisappear(duration: TimeInterval = AnimationDuration.normal,
                               delay: TimeInterval = 0,
                               completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseIn) { [weak self] in
            self?.alpha = 0
            self?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            completion?()
        }
    }

    /// 玻璃按压动画
    /// - Parameters:
    ///   - scale: 按压缩放比例
    ///   - duration: 动画时长
    func animateGlassPress(scale: CGFloat = 0.96,
                           duration: TimeInterval = 0.1) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) { [weak self] in
            self?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    /// 玻璃释放动画（弹簧弹回）
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - damping: 弹簧阻尼
    func animateGlassRelease(duration: TimeInterval = 0.4,
                             damping: CGFloat = 0.5) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: damping,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) { [weak self] in
            self?.transform = .identity
        }
    }
}

// MARK: - 液态玻璃样式工厂
/// 预定义的液态玻璃样式（自动适配深色模式）
@available(iOS 15.0, *)
enum LiquidGlassStyle {

    /// 导航栏样式
    static var navigationBar: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemMaterial
    }

    /// 卡片样式
    static var card: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemUltraThinMaterialLight
    }

    /// 按钮样式
    static var button: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
    }

    /// 浮层样式
    static var floating: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemMaterial
    }

    /// 输入框样式
    static var input: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
    }

    /// 提示条样式
    static var banner: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemMaterial
    }

    /// 搜索栏样式
    static var searchBar: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
    }

    /// TabBar 样式
    static var tabBar: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemMaterial
    }
}
