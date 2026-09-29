//
//  ThemeAdvancedComponents.swift
//  Milo
//
//  高级UI组件 - 对齐安卓端高级组件
//  包含：BottomSheet, AlertDialog, PwdInputView, SwipeCaptchaView 等
//

import UIKit
import SnapKit

// MARK: - BottomSheetViewController 底部弹窗
/// 可滑动的底部弹窗，支持手势关闭，保留液态玻璃效果
class BottomSheetViewController: UIViewController {

    // MARK: - 配置
    enum SheetStyle {
        case fixed(CGFloat)      // 固定高度
        case flexible(CGFloat)   // 弹性高度（最大高度比例）
        case fullScreen           // 全屏
    }

    var sheetStyle: SheetStyle = .flexible(0.8) {
        didSet { updateSheetHeight() }
    }

    var cornerRadius: CGFloat = 16 {
        didSet { containerView.layer.cornerRadius = cornerRadius }
    }

    var showHandle: Bool = true {
        didSet { handleView.isHidden = !showHandle }
    }

    var enableSwipeToDismiss: Bool = true
    var enableTapToDismiss: Bool = true

    /// 内容视图，子类应该将内容添加到此视图
    let contentView = UIView()

    // MARK: - 私有视图
    private let containerView = UIView()
    private let handleView = UIView()
    private let dimView = UIView()

    private var containerHeightConstraint: Constraint!
    private var containerBottomConstraint: Constraint!
    private var panGesture: UIPanGestureRecognizer!
    private var initialY: CGFloat = 0

    // MARK: - 初始化
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatePresent()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        // 遮罩
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimView.alpha = 0
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if enableTapToDismiss {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleDimTap))
            dimView.addGestureRecognizer(tap)
        }

        // 容器
        containerView.backgroundColor = .themeBottomSheetBg
        containerView.layer.cornerRadius = cornerRadius
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            containerBottomConstraint = make.bottom.equalToSuperview().constraint
            containerHeightConstraint = make.height.equalTo(300).constraint
        }

        // 把手
        handleView.backgroundColor = .themeBottomSheetHandle
        handleView.layer.cornerRadius = 2
        containerView.addSubview(handleView)
        handleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(4)
        }

        // 内容视图
        containerView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(handleView.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func setupGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        containerView.addGestureRecognizer(panGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSheetHeight()
    }

    private func updateSheetHeight() {
        guard isViewLoaded else { return }

        let height: CGFloat
        switch sheetStyle {
        case .fixed(let h):
            height = h
        case .flexible(let ratio):
            height = view.bounds.height * ratio
        case .fullScreen:
            height = view.bounds.height - ScreenAdapter.safeAreaTop
        }

        containerHeightConstraint.update(offset: height)
        view.layoutIfNeeded()
    }

    // MARK: - 动画

    private func animatePresent() {
        containerBottomConstraint.update(offset: containerView.bounds.height)
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimView.alpha = 1
            self.containerBottomConstraint.update(offset: 0)
            self.view.layoutIfNeeded()
        }
    }

    func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.dimView.alpha = 0
            self.containerBottomConstraint.update(offset: self.containerView.bounds.height)
            self.view.layoutIfNeeded()
        } { _ in
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }

    // MARK: - 手势处理

    @objc private func handleDimTap() {
        guard enableTapToDismiss else { return }
        dismissSheet()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard enableSwipeToDismiss else { return }

        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            initialY = containerView.frame.origin.y

        case .changed:
            let newY = max(initialY + translation.y, view.bounds.height - containerView.bounds.height)
            let offset = view.bounds.height - newY - containerView.bounds.height
            containerBottomConstraint.update(offset: -translation.y)

            // 更新遮罩透明度
            let progress = max(0, min(1, translation.y / containerView.bounds.height))
            dimView.alpha = 1 - progress * 0.5

        case .ended, .cancelled:
            let translationY = translation.y
            if translationY > 100 || velocity.y > 500 {
                dismissSheet()
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.containerBottomConstraint.update(offset: 0)
                    self.dimView.alpha = 1
                    self.view.layoutIfNeeded()
                }
            }

        default:
            break
        }
    }
}

extension BottomSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

// MARK: - AlertDialog 自定义弹窗
/// 样式对齐安卓端自定义弹窗
class AlertDialog: UIViewController {

    // MARK: - 配置
    var alertTitle: String? {
        didSet { titleLabel.text = alertTitle }
    }

    var message: String? {
        didSet { messageLabel.text = message }
    }

    var confirmTitle: String = "确定" {
        didSet { confirmButton.setTitle(confirmTitle, for: .normal) }
    }

    var cancelTitle: String = "取消" {
        didSet { cancelButton.setTitle(cancelTitle, for: .normal) }
    }

    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    /// 自定义内容视图
    var customView: UIView? {
        didSet { updateCustomView() }
    }

    // MARK: - 子视图
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let customContainer = UIView()
    private let buttonStackView = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let dimView = UIView()

    // MARK: - 初始化
    init(title: String? = nil, message: String? = nil) {
        self.alertTitle = title
        self.message = message
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        // 遮罩
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimView.alpha = 0
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 容器
        containerView.backgroundColor = .themePopupBg
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.75)
            make.width.lessThanOrEqualTo(320)
        }

        // 标题
        titleLabel.font = ThemeFont.title2(18)
        titleLabel.textColor = .themeTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = alertTitle
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(20)
        }

        // 消息
        messageLabel.font = ThemeFont.bodySmall(14)
        messageLabel.textColor = .themeTextSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.text = message
        containerView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
        }

        // 自定义内容
        containerView.addSubview(customContainer)
        customContainer.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(0)
        }

        // 按钮
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12
        containerView.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(customContainer.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(40)
        }

        cancelButton.setTitle(cancelTitle, for: .normal)
        cancelButton.titleLabel?.font = ThemeFont.body(16)
        cancelButton.setTitleColor(.themeTextSecondary, for: .normal)
        cancelButton.backgroundColor = .themeBgInput
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(cancelButton)

        confirmButton.setTitle(confirmTitle, for: .normal)
        confirmButton.titleLabel?.font = ThemeFont.bodyMedium(16)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.backgroundColor = .themeColorPrimary
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(confirmButton)
    }

    private func updateCustomView() {
        guard isViewLoaded else { return }
        customContainer.subviews.forEach { $0.removeFromSuperview() }

        if let customView = customView {
            customContainer.addSubview(customView)
            customView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            customContainer.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(customView.intrinsicContentSize.height)
            }
        } else {
            customContainer.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
    }

    private func animateIn() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.dimView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    func dismissAlert(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.dimView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } { _ in
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }

    @objc private func confirmTapped() {
        dismissAlert { [weak self] in
            self?.onConfirm?()
        }
    }

    @objc private func cancelTapped() {
        dismissAlert { [weak self] in
            self?.onCancel?()
        }
    }
}

// MARK: - PwdInputView 密码输入框
/// 点阵式密码输入框，对齐安卓端 PwdView
class PwdInputView: UIView {

    // MARK: - 配置
    var passwordLength: Int = 6 {
        didSet { setupDotViews() }
    }

    var dotRadius: CGFloat = 6 {
        didSet { setNeedsLayout() }
    }

    var borderColor: UIColor = .themePwdOutline {
        didSet { layer.borderColor = borderColor.cgColor }
    }

    var dotColor: UIColor = .themeTextPrimary {
        didSet { dotViews.forEach { $0.backgroundColor = dotColor } }
    }

    var onComplete: ((String) -> Void)?

    private(set) var password: String = ""

    // MARK: - 子视图
    private var dotViews: [UIView] = []
    private let stackView = UIStackView()
    private let textField = UITextField()

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .themePwdSurface
        layer.borderWidth = 1
        layer.borderColor = borderColor.cgColor
        layer.cornerRadius = 8
        clipsToBounds = true

        // 隐藏的输入框
        textField.isHidden = true
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        addSubview(textField)

        // 点阵
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupDotViews()

        // 点击弹出键盘
        let tap = UITapGestureRecognizer(target: self, action: #selector(becomeFirstResponder))
        addGestureRecognizer(tap)
    }

    private func setupDotViews() {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        for i in 0..<passwordLength {
            let container = UIView()
            stackView.addArrangedSubview(container)

            let dot = UIView()
            dot.backgroundColor = dotColor
            dot.layer.cornerRadius = dotRadius
            dot.isHidden = true
            container.addSubview(dot)
            dot.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(dotRadius * 2)
            }
            dotViews.append(dot)

            // 分隔线
            if i < passwordLength - 1 {
                let divider = UIView()
                divider.backgroundColor = .themeSeparator
                container.addSubview(divider)
                divider.snp.makeConstraints { make in
                    make.right.equalToSuperview()
                    make.top.bottom.equalToSuperview().inset(8)
                    make.width.equalTo(0.5)
                }
            }
        }
    }

    // MARK: - 公开方法

    /// 清空密码
    func clear() {
        password = ""
        updateDots()
    }

    /// 显示错误状态
    func showError() {
        layer.borderColor = UIColor.themeError.cgColor
        // 抖动动画
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -10, 10, -10, 10, 0]
        animation.duration = 0.5
        layer.add(animation, forKey: "shake")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.layer.borderColor = self?.borderColor.cgColor
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return super.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
        return super.resignFirstResponder()
    }

    // MARK: - 私有方法

    @objc private func textDidChange() {
        guard let text = textField.text else { return }

        // 只保留数字
        let filtered = text.filter { $0.isNumber }
        let limited = String(filtered.prefix(passwordLength))
        password = limited
        textField.text = limited

        updateDots()

        if limited.count == passwordLength {
            onComplete?(limited)
        }
    }

    private func updateDots() {
        for (index, dot) in dotViews.enumerated() {
            dot.isHidden = index >= password.count
        }
    }
}

extension PwdInputView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= passwordLength && updatedText.allSatisfy({ $0.isNumber })
    }
}

// MARK: - SwipeCaptchaView 滑动验证码
/// 滑块拼图验证码组件
class SwipeCaptchaView: UIView {

    // MARK: - 配置
    var trackColor: UIColor = .themeBgInput {
        didSet { trackView.backgroundColor = trackColor }
    }

    var sliderColor: UIColor = .themeColorPrimary {
        didSet { sliderView.backgroundColor = sliderColor }
    }

    var successColor: UIColor = .themeSuccess {
        didSet {}
    }

    var onVerify: ((@escaping (Bool) -> Void) -> Void)?

    private(set) var isVerified: Bool = false

    // MARK: - 子视图
    private let trackView = UIView()
    private let sliderView = UIView()
    private let hintLabel = UILabel()
    private let iconImageView = UIImageView()

    private var sliderLeadingConstraint: Constraint!
    private var panGesture: UIPanGestureRecognizer!
    private var initialX: CGFloat = 0

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // 轨道
        trackView.backgroundColor = trackColor
        trackView.layer.cornerRadius = 4
        trackView.clipsToBounds = true
        addSubview(trackView)
        trackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }

        // 提示文字
        hintLabel.text = "向右滑动验证"
        hintLabel.font = ThemeFont.bodySmall(14)
        hintLabel.textColor = .themeTextHint
        hintLabel.textAlignment = .center
        trackView.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 滑块
        sliderView.backgroundColor = sliderColor
        sliderView.layer.cornerRadius = 4
        sliderView.clipsToBounds = true
        sliderView.isUserInteractionEnabled = true
        addSubview(sliderView)
        sliderView.snp.makeConstraints { make in
            sliderLeadingConstraint = make.left.equalToSuperview().constraint
            make.centerY.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(40)
        }

        // 滑块图标
        iconImageView.image = UIImage(systemName: "chevron.right")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        sliderView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }

        // 手势
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sliderView.addGestureRecognizer(panGesture)
    }

    // MARK: - 手势处理

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isVerified else { return }

        let translation = gesture.translation(in: self)
        let maxX = bounds.width - 40

        switch gesture.state {
        case .began:
            initialX = sliderLeadingConstraint.layoutConstraints.first?.constant ?? 0

        case .changed:
            var newX = initialX + translation.x
            newX = max(0, min(newX, maxX))
            sliderLeadingConstraint.update(offset: newX)

            // 更新提示文字透明度
            let progress = newX / maxX
            hintLabel.alpha = 1 - progress

        case .ended, .cancelled:
            let currentX = sliderLeadingConstraint.layoutConstraints.first?.constant ?? 0

            // 如果滑到底了，开始验证
            if currentX >= maxX - 5 {
                startVerify()
            } else {
                // 回弹
                UIView.animate(withDuration: 0.3) {
                    self.sliderLeadingConstraint.update(offset: 0)
                    self.hintLabel.alpha = 1
                    self.layoutIfNeeded()
                }
            }

        default:
            break
        }
    }

    private func startVerify() {
        hintLabel.text = "验证中..."
        hintLabel.alpha = 1
        iconImageView.image = UIImage(systemName: "hourglass")

        onVerify? { [weak self] success in
            DispatchQueue.main.async {
                self?.handleVerifyResult(success)
            }
        }
    }

    private func handleVerifyResult(_ success: Bool) {
        isVerified = success

        if success {
            sliderView.backgroundColor = successColor
            iconImageView.image = UIImage(systemName: "checkmark")
            hintLabel.text = "验证成功"
            hintLabel.textColor = successColor
        } else {
            // 失败，回弹
            iconImageView.image = UIImage(systemName: "xmark")
            hintLabel.text = "验证失败，请重试"
            hintLabel.textColor = .themeError

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                self.reset()
            }
        }
    }

    /// 重置
    func reset() {
        isVerified = false
        sliderView.backgroundColor = sliderColor
        iconImageView.image = UIImage(systemName: "chevron.right")
        hintLabel.text = "向右滑动验证"
        hintLabel.textColor = .themeTextHint
        hintLabel.alpha = 1

        UIView.animate(withDuration: 0.3) {
            self.sliderLeadingConstraint.update(offset: 0)
            self.layoutIfNeeded()
        }
    }
}

// MARK: - CustomSwitch 自定义开关
/// 对齐安卓端自定义 Switch 样式
class CustomSwitch: UIControl {

    var isOn: Bool = false {
        didSet { updateState(animated: false) }
    }

    var onTintColor: UIColor = .themeColorPrimary {
        didSet { if isOn { trackView.backgroundColor = onTintColor } }
    }

    var offTintColor: UIColor = .themeSwitchTrackOff {
        didSet { if !isOn { trackView.backgroundColor = offTintColor } }
    }

    var thumbColor: UIColor = .themeSwitchThumb {
        didSet { thumbView.backgroundColor = thumbColor }
    }

    private let trackView = UIView()
    private let thumbView = UIView()
    private var thumbLeadingConstraint: Constraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // 轨道
        trackView.backgroundColor = offTintColor
        trackView.layer.cornerRadius = 15
        trackView.clipsToBounds = true
        addSubview(trackView)
        trackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 滑块
        thumbView.backgroundColor = thumbColor
        thumbView.layer.cornerRadius = 12
        thumbView.layer.shadowColor = UIColor.black.cgColor
        thumbView.layer.shadowOpacity = 0.2
        thumbView.layer.shadowOffset = CGSize(width: 0, height: 1)
        thumbView.layer.shadowRadius = 2
        addSubview(thumbView)
        thumbView.snp.makeConstraints { make in
            thumbLeadingConstraint = make.left.equalToSuperview().offset(3).constraint
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        // 点击
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        setOn(!isOn, animated: true)
        sendActions(for: .valueChanged)
    }

    func setOn(_ on: Bool, animated: Bool) {
        isOn = on
        updateState(animated: animated)
    }

    private func updateState(animated: Bool) {
        let offset = isOn ? bounds.width - 27 : 3

        let block = {
            self.thumbLeadingConstraint.update(offset: offset)
            self.trackView.backgroundColor = self.isOn ? self.onTintColor : self.offTintColor
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                block()
            }
        } else {
            block()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 51, height: 30)
    }
}
