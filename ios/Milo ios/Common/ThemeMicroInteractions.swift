//
//  ThemeMicroInteractions.swift
//  Milo
//
//  微交互组件库
//  包含：进度条、滑块、分段控件、标签切换、步骤指示器等
//

import UIKit

// MARK: - 动画进度条
final class AnimatedProgressBar: UIView {

    // MARK: - 配置
    var trackColor: UIColor = .themeBgInput {
        didSet { trackLayer.backgroundColor = trackColor.cgColor }
    }

    var progressColor: UIColor = .themeColorPrimary {
        didSet { progressLayer.backgroundColor = progressColor.cgColor }
    }

    var cornerRadius: CGFloat = 4 {
        didSet {
            trackLayer.cornerRadius = cornerRadius
            progressLayer.cornerRadius = cornerRadius
        }
    }

    private(set) var progress: CGFloat = 0.0

    // MARK: - Layer
    private let trackLayer = CALayer()
    private let progressLayer = CALayer()

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        trackLayer.backgroundColor = trackColor.cgColor
        trackLayer.cornerRadius = cornerRadius
        layer.addSublayer(trackLayer)

        progressLayer.backgroundColor = progressColor.cgColor
        progressLayer.cornerRadius = cornerRadius
        progressLayer.masksToBounds = true
        trackLayer.addSublayer(progressLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        trackLayer.frame = bounds
        updateProgressLayer()
    }

    /// 设置进度（带动画）
    func setProgress(_ progress: CGFloat, animated: Bool = true, duration: TimeInterval = 0.5) {
        let clampedProgress = min(max(progress, 0), 1)
        self.progress = clampedProgress

        if animated {
            let animation = CABasicAnimation(keyPath: "bounds.size.width")
            animation.fromValue = progressLayer.bounds.width
            animation.toValue = bounds.width * clampedProgress
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false

            progressLayer.add(animation, forKey: "progress")
        }

        updateProgressLayer()
    }

    private func updateProgressLayer() {
        var frame = bounds
        frame.size.width = bounds.width * progress
        progressLayer.frame = frame
    }

    /// 渐变进度条样式
    func setGradientColors(_ colors: [UIColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius

        // 移除旧的
        progressLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        progressLayer.addSublayer(gradientLayer)
        progressLayer.backgroundColor = UIColor.clear.cgColor
    }
}

// MARK: - 圆形进度条
final class CircularProgressView: UIView {

    var progress: CGFloat = 0 {
        didSet { updateProgress() }
    }

    var lineWidth: CGFloat = 4 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
        }
    }

    var trackColor: UIColor = .themeBgInput {
        didSet { trackLayer.strokeColor = trackColor.cgColor }
    }

    var progressColor: UIColor = .themeColorPrimary {
        didSet { progressLayer.strokeColor = progressColor.cgColor }
    }

    var isClockwise: Bool = true

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let centerLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = startAngle + .pi * 2

        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)

        // 轨道
        trackLayer.path = path.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        // 进度
        progressLayer.path = path.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)

        // 中心文字
        centerLabel.font = ThemeFont.title2(18)
        centerLabel.textColor = .themeTextPrimary
        centerLabel.textAlignment = .center
        addSubview(centerLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let radius = min(bounds.width, bounds.height) / 2 - lineWidth
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = startAngle + .pi * 2

        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath

        centerLabel.frame = bounds
    }

    func setProgress(_ progress: CGFloat, animated: Bool = true, duration: TimeInterval = 0.8) {
        self.progress = min(max(progress, 0), 1)

        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = self.progress
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            progressLayer.add(animation, forKey: "progress")
        }

        progressLayer.strokeEnd = self.progress
        centerLabel.text = String(format: "%.0f%%", self.progress * 100)
    }

    private func updateProgress() {
        progressLayer.strokeEnd = progress
        centerLabel.text = String(format: "%.0f%%", progress * 100)
    }
}

// MARK: - 自定义分段控件（带动画）
final class AnimatedSegmentedControl: UIControl {

    // MARK: - 配置
    var items: [String] = [] {
        didSet { updateItems() }
    }

    var selectedIndex: Int = 0 {
        didSet { updateSelected(animated: true) }
    }

    var selectedColor: UIColor = .themeColorPrimary {
        didSet {
            indicatorView.backgroundColor = selectedColor
            updateTextColors()
        }
    }

    var normalColor: UIColor = .themeTextSecondary {
        didSet { updateTextColors() }
    }

    var indicatorHeight: CGFloat = 3

    // MARK: - UI
    private let stackView = UIStackView()
    private let indicatorView = UIView()
    private var buttons: [UIButton] = []

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

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        indicatorView.backgroundColor = selectedColor
        indicatorView.layer.cornerRadius = indicatorHeight / 2
        addSubview(indicatorView)
    }

    private func updateItems() {
        // 移除旧按钮
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(item, for: .normal)
            button.titleLabel?.font = ThemeFont.body(15)
            button.tag = index
            button.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }

        updateTextColors()
        layoutIfNeeded()
        updateSelected(animated: false)
    }

    private func updateTextColors() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            button.setTitleColor(isSelected ? selectedColor : normalColor, for: .normal)
            button.titleLabel?.font = isSelected ? ThemeFont.title3(15) : ThemeFont.body(15)
        }
    }

    private func updateSelected(animated: Bool) {
        guard !buttons.isEmpty else { return }

        let button = buttons[selectedIndex]
        let indicatorWidth = bounds.width / CGFloat(buttons.count)
        let x = indicatorWidth * CGFloat(selectedIndex) + (indicatorWidth - 24) / 2

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                self.indicatorView.frame = CGRect(x: x, y: self.bounds.height - self.indicatorHeight - 4,
                                                  width: 24, height: self.indicatorHeight)
            }
        } else {
            indicatorView.frame = CGRect(x: x, y: bounds.height - indicatorHeight - 4,
                                         width: 24, height: indicatorHeight)
        }

        updateTextColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateSelected(animated: false)
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        HapticManager.shared.selectionChanged()
        sendActions(for: .valueChanged)
    }
}

// MARK: - 标签切换器（Scrollable）
final class ScrollableTabBar: UIView {

    var items: [String] = [] {
        didSet { reloadData() }
    }

    var selectedIndex: Int = 0 {
        didSet { scrollToSelected(animated: true) }
    }

    var onSelected: ((Int) -> Void)?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let indicatorView = UIView()
    private var buttons: [UIButton] = []

    private let normalFont = ThemeFont.body(14)
    private let selectedFont = ThemeFont.title3(16)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.alignment = .center
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalToSuperview()
        }

        indicatorView.backgroundColor = .themeColorPrimary
        indicatorView.layer.cornerRadius = 2
        scrollView.addSubview(indicatorView)
    }

    private func reloadData() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(item, for: .normal)
            button.titleLabel?.font = index == selectedIndex ? selectedFont : normalFont
            button.setTitleColor(index == selectedIndex ? .themeTextPrimary : .themeTextSecondary, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons.append(button)

            button.sizeToFit()
        }

        layoutIfNeeded()
        updateIndicatorPosition(animated: false)
    }

    @objc private func tabTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        HapticManager.shared.selectionChanged()
        onSelected?(sender.tag)
    }

    private func scrollToSelected(animated: Bool) {
        updateIndicatorPosition(animated: animated)

        // 更新按钮状态
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            UIView.animate(withDuration: 0.25) {
                button.titleLabel?.font = isSelected ? self.selectedFont : self.normalFont
                button.setTitleColor(isSelected ? .themeTextPrimary : .themeTextSecondary, for: .normal)
            }
        }

        // 滚动到可见区域
        if let button = buttons[safe: selectedIndex] {
            let targetRect = button.frame.insetBy(dx: -20, dy: 0)
            scrollView.scrollRectToVisible(targetRect, animated: animated)
        }
    }

    private func updateIndicatorPosition(animated: Bool) {
        guard let button = buttons[safe: selectedIndex] else { return }

        let width = button.bounds.width
        let x = button.frame.minX + 16 // + padding

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                self.indicatorView.frame = CGRect(
                    x: x + (width - 20) / 2,
                    y: self.bounds.height - 4,
                    width: 20,
                    height: 3
                )
            }
        } else {
            indicatorView.frame = CGRect(
                x: x + (width - 20) / 2,
                y: bounds.height - 4,
                width: 20,
                height: 3
            )
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateIndicatorPosition(animated: false)
    }
}

// MARK: - 安全数组访问
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 步骤指示器
final class StepIndicator: UIView {

    var steps: [String] = [] {
        didSet { updateSteps() }
    }

    var currentStep: Int = 0 {
        didSet { updateCurrentStep() }
    }

    private let stackView = UIStackView()
    private var stepViews: [StepItemView] = []

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

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func updateSteps() {
        stepViews.forEach { $0.removeFromSuperview() }
        stepViews.removeAll()

        for (index, step) in steps.enumerated() {
            let stepView = StepItemView()
            stepView.setTitle(step)
            stepView.setIndex(index + 1)
            stepView.setState(index < currentStep ? .completed : (index == currentStep ? .current : .pending))
            stackView.addArrangedSubview(stepView)
            stepViews.append(stepView)
        }
    }

    private func updateCurrentStep() {
        for (index, stepView) in stepViews.enumerated() {
            let state: StepItemView.StepState = index < currentStep ? .completed : (index == currentStep ? .current : .pending)
            stepView.setState(state, animated: true)
        }
    }
}

// MARK: - 单个步骤视图
final class StepItemView: UIView {

    enum StepState {
        case pending    // 待完成
        case current    // 当前
        case completed  // 已完成
    }

    private let circleView = UIView()
    private let numberLabel = UILabel()
    private let checkImageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        circleView.layer.cornerRadius = 14
        circleView.backgroundColor = .themeBgInput
        addSubview(circleView)
        circleView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(28)
        }

        numberLabel.font = ThemeFont.bodySmall(13)
        numberLabel.textColor = .themeTextTertiary
        numberLabel.textAlignment = .center
        addSubview(numberLabel)
        numberLabel.snp.makeConstraints { make in
            make.center.equalTo(circleView)
        }

        checkImageView.image = UIImage(systemName: "checkmark")
        checkImageView.tintColor = .white
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.alpha = 0
        addSubview(checkImageView)
        checkImageView.snp.makeConstraints { make in
            make.center.equalTo(circleView)
            make.width.height.equalTo(16)
        }

        titleLabel.font = ThemeFont.caption(12)
        titleLabel.textColor = .themeTextSecondary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(circleView.snp.bottom).offset(6)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func setIndex(_ index: Int) {
        numberLabel.text = "\(index)"
    }

    func setState(_ state: StepState, animated: Bool = false) {
        let duration = animated ? 0.3 : 0

        if animated {
            switch state {
            case .current:
                HapticManager.shared.impactSoft()
            case .completed:
                HapticManager.shared.notificationSuccess()
            case .pending:
                break
            }
        }

        UIView.animate(withDuration: duration) {
            switch state {
            case .pending:
                self.circleView.backgroundColor = .themeBgInput
                self.numberLabel.textColor = .themeTextTertiary
                self.titleLabel.textColor = .themeTextSecondary
                self.checkImageView.alpha = 0
                self.numberLabel.alpha = 1

            case .current:
                self.circleView.backgroundColor = .themeColorPrimary
                self.numberLabel.textColor = .white
                self.titleLabel.textColor = .themeTextPrimary
                self.checkImageView.alpha = 0
                self.numberLabel.alpha = 1

                // 轻微缩放动画
                self.circleView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    UIView.animate(withDuration: 0.2) {
                        self.circleView.transform = .identity
                    }
                }

            case .completed:
                self.circleView.backgroundColor = .themeSuccess
                self.titleLabel.textColor = .themeTextSecondary
                self.checkImageView.alpha = 1
                self.numberLabel.alpha = 0
            }
        }
    }
}

// MARK: - 点赞/收藏动画按钮
final class LikeButton: UIButton {

    var isLiked: Bool = false {
        didSet { updateState(animated: true) }
    }

    private let iconImageView = UIImageView()
    private let countLabel = CountingLabel()

    var likeCount: Int = 0 {
        didSet {
            countLabel.count(from: Double(oldValue), to: Double(likeCount), duration: 0.3)
        }
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
        iconImageView.image = UIImage(systemName: "heart")
        iconImageView.tintColor = .themeTextSecondary
        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        countLabel.font = ThemeFont.bodySmall(13)
        countLabel.textColor = .themeTextSecondary
        countLabel.text = "0"
        addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @objc private func handleTap() {
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1

        // 触觉反馈
        if isLiked {
            HapticManager.shared.notificationSuccess()
        } else {
            HapticManager.shared.impactLight()
        }

        // 弹跳动画（更细腻：先放大再弹回）
        iconImageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       options: .curveEaseIn) {
            self.iconImageView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        } completion: { _ in
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.8,
                           options: .curveEaseOut) {
                self.iconImageView.transform = .identity
            }
        }
    }

    private func updateState(animated: Bool) {
        let duration = animated ? 0.2 : 0

        UIView.transition(with: iconImageView, duration: duration, options: .transitionCrossDissolve) {
            self.iconImageView.image = UIImage(systemName: self.isLiked ? "heart.fill" : "heart")
            self.iconImageView.tintColor = self.isLiked ? .themeError : .themeTextSecondary
        }

        countLabel.textColor = isLiked ? .themeError : .themeTextSecondary
    }
}
