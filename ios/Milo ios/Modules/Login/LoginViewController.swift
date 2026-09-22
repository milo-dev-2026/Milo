import UIKit
import SnapKit
import PhotosUI

// MARK: - 液态玻璃分段控件
class GlassSegmentedControl: UIView {

    var selectedIndex: Int = 0 {
        didSet { updateSelection(animated: true) }
    }

    var onSelected: ((Int) -> Void)?

    private let items: [String]
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialLight))
    private let selectorView = UIView()
    private var buttons: [UIButton] = []
    private let stackView = UIStackView()

    init(items: [String]) {
        self.items = items
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = ScreenAdapter.scaleH(22)
        layer.masksToBounds = true

        addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 白色半透明背景叠加，增加玻璃质感
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 选中滑块
        selectorView.backgroundColor = .white
        selectorView.layer.cornerRadius = ScreenAdapter.scaleH(18)
        selectorView.layer.shadowColor = UIColor.black.cgColor
        selectorView.layer.shadowOffset = CGSize(width: 0, height: 2)
        selectorView.layer.shadowRadius = 4
        selectorView.layer.shadowOpacity = 0.1
        addSubview(selectorView)

        // 按钮
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        addSubview(stackView)

        for (index, title) in items.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = ScreenAdapter.mediumFont(14)
            btn.tag = index
            btn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(btn)
            stackView.addArrangedSubview(btn)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        updateSelection(animated: false)
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        onSelected?(selectedIndex)
    }

    private func updateSelection(animated: Bool) {
        for (index, btn) in buttons.enumerated() {
            if index == selectedIndex {
                btn.setTitleColor(.themePrimary, for: .normal)
                btn.titleLabel?.font = ScreenAdapter.mediumFont(14)
            } else {
                btn.setTitleColor(.secondaryLabel, for: .normal)
                btn.titleLabel?.font = ScreenAdapter.font(14)
            }
        }

        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            self.layoutIfNeeded()
            let totalWidth = self.bounds.width
            let itemWidth = totalWidth / CGFloat(self.items.count)
            let selectorInset = ScreenAdapter.scaleW(4)
            let selectorWidth = itemWidth - selectorInset * 2
            let selectorX = itemWidth * CGFloat(self.selectedIndex) + selectorInset
            self.selectorView.frame = CGRect(
                x: selectorX,
                y: ScreenAdapter.scaleH(4),
                width: selectorWidth,
                height: ScreenAdapter.scaleH(36)
            )
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateSelection(animated: false)
    }
}

// MARK: - 玻璃卡片容器
class GlassCardView: UIView {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialLight))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.6)
        layer.cornerRadius = ScreenAdapter.scaleW(28)
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 24
        layer.shadowOpacity = 0.08

        addSubview(blurView)
        sendSubviewToBack(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blurView.layer.cornerRadius = ScreenAdapter.scaleW(28)
        blurView.layer.masksToBounds = true
    }
}

// MARK: - 胶囊形输入框（玻璃风格）
class CapsuleTextField: UIView {

    let textField = UITextField()

    var placeholder: String? {
        didSet { updatePlaceholder() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.white
        layer.cornerRadius = ScreenAdapter.scaleH(24)
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.88, green: 0.90, blue: 0.94, alpha: 1.0).cgColor

        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(16)
        textField.textColor = .label
        textField.backgroundColor = .clear
        addSubview(textField)

        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.centerY.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    private func updatePlaceholder() {
        guard let placeholder = placeholder else {
            textField.attributedPlaceholder = nil
            return
        }
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
    }
}

// MARK: - 带区号的胶囊输入框
class CapsulePhoneField: UIView {

    let countryCodeButton = UIButton(type: .system)
    private let dividerView = UIView()
    let textField = UITextField()

    var countryCode: String = "+86" {
        didSet { countryCodeButton.setTitle(countryCode, for: .normal) }
    }

    var placeholder: String? {
        didSet { updatePlaceholder() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.white
        layer.cornerRadius = ScreenAdapter.scaleH(24)
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.88, green: 0.90, blue: 0.94, alpha: 1.0).cgColor

        countryCodeButton.setTitle("+86", for: .normal)
        countryCodeButton.setTitleColor(.label, for: .normal)
        countryCodeButton.titleLabel?.font = ScreenAdapter.font(16)
        addSubview(countryCodeButton)

        dividerView.backgroundColor = UIColor(red: 0.85, green: 0.86, blue: 0.88, alpha: 1.0)
        addSubview(dividerView)

        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(16)
        textField.textColor = .label
        textField.keyboardType = .numberPad
        textField.backgroundColor = .clear
        addSubview(textField)

        countryCodeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.equalTo(ScreenAdapter.scaleW(50))
        }

        dividerView.snp.makeConstraints { make in
            make.leading.equalTo(countryCodeButton.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.centerY.equalToSuperview()
            make.width.equalTo(1)
            make.height.equalTo(ScreenAdapter.scaleH(20))
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(dividerView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.centerY.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    private func updatePlaceholder() {
        guard let placeholder = placeholder else {
            textField.attributedPlaceholder = nil
            return
        }
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
    }
}

// MARK: - 带获取验证码按钮的胶囊输入框
class CapsuleCodeField: UIView {

    let textField = UITextField()
    let sendCodeButton = UIButton(type: .system)

    var placeholder: String? {
        didSet { updatePlaceholder() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.white
        layer.cornerRadius = ScreenAdapter.scaleH(24)
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.88, green: 0.90, blue: 0.94, alpha: 1.0).cgColor

        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(16)
        textField.textColor = .label
        textField.keyboardType = .numberPad
        textField.backgroundColor = .clear
        addSubview(textField)

        sendCodeButton.setTitle("获取验证码", for: .normal)
        sendCodeButton.setTitleColor(.themePrimary, for: .normal)
        sendCodeButton.titleLabel?.font = ScreenAdapter.font(14)
        addSubview(sendCodeButton)

        sendCodeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(ScreenAdapter.scaleW(100))
        }

        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalTo(sendCodeButton.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.centerY.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    private func updatePlaceholder() {
        guard let placeholder = placeholder else {
            textField.attributedPlaceholder = nil
            return
        }
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
    }
}

// MARK: - 带眼睛图标的胶囊密码输入框
class CapsulePasswordField: UIView {

    let textField = UITextField()
    private let toggleButton = UIButton(type: .custom)

    var placeholder: String? {
        didSet { updatePlaceholder() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.white
        layer.cornerRadius = ScreenAdapter.scaleH(24)
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.88, green: 0.90, blue: 0.94, alpha: 1.0).cgColor

        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(16)
        textField.textColor = .label
        textField.isSecureTextEntry = true
        textField.backgroundColor = .clear
        addSubview(textField)

        toggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        toggleButton.setImage(UIImage(systemName: "eye"), for: .selected)
        toggleButton.tintColor = .secondaryLabel
        toggleButton.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)
        addSubview(toggleButton)

        toggleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(22))
        }

        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalTo(toggleButton.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.centerY.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    @objc private func togglePassword() {
        textField.isSecureTextEntry.toggle()
        toggleButton.isSelected = !textField.isSecureTextEntry
    }

    private func updatePlaceholder() {
        guard let placeholder = placeholder else {
            textField.attributedPlaceholder = nil
            return
        }
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
    }
}

// MARK: - 只读胶囊显示框（用于脱敏手机号显示）
class CapsuleDisplayField: UIView {

    let label = UILabel()

    var text: String? {
        didSet { label.text = text }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1.0)
        layer.cornerRadius = ScreenAdapter.scaleH(24)
        layer.masksToBounds = true

        label.font = ScreenAdapter.font(16)
        label.textColor = .secondaryLabel
        addSubview(label)

        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.centerY.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }
}

// MARK: - 浮动标签输入框
class FloatingLabelTextField: UIView {

    private let borderView = UIView()
    private let floatingLabel = UILabel()
    let textField = UITextField()

    var placeholder: String = "" {
        didSet { floatingLabel.text = placeholder }
    }

    var borderColor: UIColor = .themeSeparator {
        didSet { borderView.layer.borderColor = borderColor.cgColor }
    }

    var labelColor: UIColor = .secondaryLabel {
        didSet { floatingLabel.textColor = labelColor }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = borderColor.cgColor
        borderView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        borderView.backgroundColor = .white
        addSubview(borderView)

        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(17)
        textField.textColor = .label
        addSubview(textField)

        floatingLabel.text = placeholder
        floatingLabel.font = ScreenAdapter.font(13)
        floatingLabel.textColor = labelColor
        floatingLabel.backgroundColor = .white
        floatingLabel.textAlignment = .center
        addSubview(floatingLabel)

        borderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(56))
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(borderView).offset(ScreenAdapter.scaleW(14))
            make.trailing.equalTo(borderView).offset(-ScreenAdapter.scaleW(14))
            make.centerY.equalTo(borderView)
        }

        floatingLabel.snp.makeConstraints { make in
            make.leading.equalTo(borderView).offset(ScreenAdapter.scaleW(14))
            make.top.equalToSuperview()
        }

        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
    }

    @objc private func editingDidBegin() {
        borderView.layer.borderColor = UIColor.themePrimary.cgColor
        floatingLabel.textColor = .themePrimary
    }

    @objc private func editingDidEnd() {
        borderView.layer.borderColor = UIColor.themeSeparator.cgColor
        floatingLabel.textColor = .secondaryLabel
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: ScreenAdapter.scaleH(66))
    }
}

// MARK: - 带国家代码的浮动标签输入框
class PhoneFloatingLabelField: UIView {

    private let borderView = UIView()
    private let floatingLabel = UILabel()
    let countryCodeButton = UIButton(type: .system)
    private let dividerView = UIView()
    let textField = UITextField()

    var placeholder: String = "" {
        didSet { floatingLabel.text = placeholder }
    }

    var countryCode: String = "+86" {
        didSet { countryCodeButton.setTitle(countryCode, for: .normal) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor.themeSeparator.cgColor
        borderView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        borderView.backgroundColor = .white
        addSubview(borderView)

        countryCodeButton.setTitle("+86", for: .normal)
        countryCodeButton.setTitleColor(.label, for: .normal)
        countryCodeButton.titleLabel?.font = ScreenAdapter.font(17)
        addSubview(countryCodeButton)

        dividerView.backgroundColor = .themeSeparator
        addSubview(dividerView)

        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(17)
        textField.textColor = .label
        textField.keyboardType = .numberPad
        addSubview(textField)

        floatingLabel.text = placeholder
        floatingLabel.font = ScreenAdapter.font(13)
        floatingLabel.textColor = .secondaryLabel
        floatingLabel.backgroundColor = .white
        floatingLabel.textAlignment = .center
        addSubview(floatingLabel)

        borderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(56))
        }

        countryCodeButton.snp.makeConstraints { make in
            make.leading.equalTo(borderView).offset(ScreenAdapter.scaleW(14))
            make.centerY.equalTo(borderView)
            make.width.equalTo(ScreenAdapter.scaleW(50))
        }

        dividerView.snp.makeConstraints { make in
            make.leading.equalTo(countryCodeButton.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.centerY.equalTo(borderView)
            make.width.equalTo(1)
            make.height.equalTo(ScreenAdapter.scaleH(22))
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(dividerView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.equalTo(borderView).offset(-ScreenAdapter.scaleW(14))
            make.centerY.equalTo(borderView)
        }

        floatingLabel.snp.makeConstraints { make in
            make.leading.equalTo(borderView).offset(ScreenAdapter.scaleW(14))
            make.top.equalToSuperview()
        }

        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
    }

    @objc private func editingDidBegin() {
        borderView.layer.borderColor = UIColor.themePrimary.cgColor
        floatingLabel.textColor = .themePrimary
    }

    @objc private func editingDidEnd() {
        borderView.layer.borderColor = UIColor.themeSeparator.cgColor
        floatingLabel.textColor = .secondaryLabel
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: ScreenAdapter.scaleH(66))
    }
}

// MARK: - 验证码浮动标签输入框
class CodeFloatingLabelField: UIView {

    private let borderView = UIView()
    private let floatingLabel = UILabel()
    let textField = UITextField()
    let sendCodeButton = UIButton(type: .system)

    var placeholder: String = "" {
        didSet { floatingLabel.text = placeholder }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor.themeSeparator.cgColor
        borderView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        borderView.backgroundColor = .white
        addSubview(borderView)

        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(17)
        textField.textColor = .label
        textField.keyboardType = .numberPad
        addSubview(textField)

        sendCodeButton.setTitle("获取验证码", for: .normal)
        sendCodeButton.setTitleColor(.themePrimary, for: .normal)
        sendCodeButton.titleLabel?.font = ScreenAdapter.font(15)
        addSubview(sendCodeButton)

        floatingLabel.text = placeholder
        floatingLabel.font = ScreenAdapter.font(13)
        floatingLabel.textColor = .secondaryLabel
        floatingLabel.backgroundColor = .white
        floatingLabel.textAlignment = .center
        addSubview(floatingLabel)

        borderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(56))
        }

        sendCodeButton.snp.makeConstraints { make in
            make.trailing.equalTo(borderView).offset(-ScreenAdapter.scaleW(14))
            make.centerY.equalTo(borderView)
            make.width.lessThanOrEqualTo(ScreenAdapter.scaleW(110))
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(borderView).offset(ScreenAdapter.scaleW(14))
            make.trailing.equalTo(sendCodeButton.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.centerY.equalTo(borderView)
        }

        floatingLabel.snp.makeConstraints { make in
            make.leading.equalTo(borderView).offset(ScreenAdapter.scaleW(14))
            make.top.equalToSuperview()
        }

        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
    }

    @objc private func editingDidBegin() {
        borderView.layer.borderColor = UIColor.themePrimary.cgColor
        floatingLabel.textColor = .themePrimary
    }

    @objc private func editingDidEnd() {
        borderView.layer.borderColor = UIColor.themeSeparator.cgColor
        floatingLabel.textColor = .secondaryLabel
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: ScreenAdapter.scaleH(66))
    }
}

// MARK: - 密码输入框（带眼睛图标）
class PasswordFloatingLabelField: UIView {

    private let borderView = UIView()
    private let floatingLabel = UILabel()
    let textField = UITextField()
    private let toggleButton = UIButton(type: .system)

    var placeholder: String = "" {
        didSet { floatingLabel.text = placeholder }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor.themeSeparator.cgColor
        borderView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        borderView.backgroundColor = .white
        addSubview(borderView)

        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(17)
        textField.textColor = .label
        textField.isSecureTextEntry = true
        addSubview(textField)

        toggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        toggleButton.setImage(UIImage(systemName: "eye"), for: .selected)
        toggleButton.tintColor = .secondaryLabel
        toggleButton.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)
        addSubview(toggleButton)

        floatingLabel.text = placeholder
        floatingLabel.font = ScreenAdapter.font(13)
        floatingLabel.textColor = .secondaryLabel
        floatingLabel.backgroundColor = .white
        floatingLabel.textAlignment = .center
        addSubview(floatingLabel)

        borderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(56))
        }

        toggleButton.snp.makeConstraints { make in
            make.trailing.equalTo(borderView).offset(-ScreenAdapter.scaleW(14))
            make.centerY.equalTo(borderView)
            make.width.height.equalTo(ScreenAdapter.scaleW(24))
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(borderView).offset(ScreenAdapter.scaleW(14))
            make.trailing.equalTo(toggleButton.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.centerY.equalTo(borderView)
        }

        floatingLabel.snp.makeConstraints { make in
            make.leading.equalTo(borderView).offset(ScreenAdapter.scaleW(14))
            make.top.equalToSuperview()
        }

        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
    }

    @objc private func togglePassword() {
        textField.isSecureTextEntry.toggle()
        toggleButton.isSelected = !textField.isSecureTextEntry
    }

    @objc private func editingDidBegin() {
        borderView.layer.borderColor = UIColor.themePrimary.cgColor
        floatingLabel.textColor = .themePrimary
    }

    @objc private func editingDidEnd() {
        borderView.layer.borderColor = UIColor.themeSeparator.cgColor
        floatingLabel.textColor = .secondaryLabel
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: ScreenAdapter.scaleH(66))
    }
}

// MARK: - 页面1：入口页
class EntryLoginViewController: UIViewController {

    // 顶部区域
    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // 玻璃卡片
    private let glassCard = GlassCardView()
    private let segmentedControl = GlassSegmentedControl(items: ["手机号", "邮箱"])
    private var isEmailMode = false

    private let phoneField = CapsulePhoneField()
    private let emailField = CapsuleTextField()

    // 卡片外协议勾选行
    private let agreementCheckBox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private let userAgreementButton = UIButton(type: .system)
    private let privacyPolicyButton = UIButton(type: .system)
    private var isAgreed = false

    // 下一步按钮
    private let nextButton = UIButton(type: .system)
    private var isLoading = false

    // 底部协议提示
    private let bottomAgreementLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        // 顶部淡蓝色渐变
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.357, green: 0.482, blue: 1.0, alpha: 0.08).cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        let gradientView = UIView()
        gradientView.layer.addSublayer(gradientLayer)
        view.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(300))
        }
        DispatchQueue.main.async {
            gradientLayer.frame = gradientView.bounds
        }

        // 顶部：左侧Logo + 右侧标题+副标题
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        titleLabel.text = "欢迎使用Milo"
        titleLabel.font = ScreenAdapter.mediumFont(22)
        titleLabel.textColor = .label

        subtitleLabel.text = "输入手机号或者邮箱继续"
        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel

        // 右侧标题+副标题垂直排列
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = ScreenAdapter.scaleH(4)
        titleStack.alignment = .leading

        // 整体：左logo + 右标题
        let headerStack = UIStackView(arrangedSubviews: [logoView, titleStack])
        headerStack.axis = .horizontal
        headerStack.spacing = ScreenAdapter.scaleW(12)
        headerStack.alignment = .center

        let headerContainer = UIView()
        headerContainer.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        logoView.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleH(48))
        }

        // 玻璃卡片
        view.addSubview(glassCard)

        // 分段控件
        segmentedControl.onSelected = { [weak self] index in
            self?.switchMode(index)
        }
        glassCard.addSubview(segmentedControl)

        // 输入框
        phoneField.placeholder = "请输入手机号"
        phoneField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        emailField.placeholder = "请输入邮箱地址"
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocapitalizationType = .none
        emailField.isHidden = true
        emailField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        glassCard.addSubview(phoneField)
        glassCard.addSubview(emailField)

        // 卡片内布局
        segmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        phoneField.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(20))
        }
        emailField.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(20))
        }

        // 协议勾选行（卡片外）
        agreementCheckBox.setImage(UIImage(systemName: "circle"), for: .normal)
        agreementCheckBox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        agreementCheckBox.tintColor = .themePrimary
        agreementCheckBox.addTarget(self, action: #selector(toggleAgreement), for: .touchUpInside)

        agreementLabel.text = "我已阅读并同意"
        agreementLabel.font = ScreenAdapter.font(13)
        agreementLabel.textColor = .secondaryLabel

        userAgreementButton.setTitle("《用户协议》", for: .normal)
        userAgreementButton.titleLabel?.font = ScreenAdapter.font(13)
        userAgreementButton.setTitleColor(.themePrimary, for: .normal)
        userAgreementButton.addTarget(self, action: #selector(openUserAgreement), for: .touchUpInside)

        privacyPolicyButton.setTitle("《隐私政策》", for: .normal)
        privacyPolicyButton.titleLabel?.font = ScreenAdapter.font(13)
        privacyPolicyButton.setTitleColor(.themePrimary, for: .normal)
        privacyPolicyButton.addTarget(self, action: #selector(openPrivacyPolicy), for: .touchUpInside)

        let agreementStack = UIStackView(arrangedSubviews: [
            agreementCheckBox, agreementLabel, userAgreementButton, privacyPolicyButton
        ])
        agreementStack.axis = .horizontal
        agreementStack.spacing = ScreenAdapter.scaleW(3)
        agreementStack.alignment = .center

        agreementCheckBox.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(18))
        }

        // 下一步按钮
        nextButton.setTitle("下一步", for: .normal)
        nextButton.backgroundColor = .themePrimary
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        nextButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        nextButton.alpha = 0.5
        nextButton.isEnabled = false
        nextButton.addTarget(self, action: #selector(loginOrRegister), for: .touchUpInside)

        // 底部小字
        bottomAgreementLabel.text = "登录即表示同意《用户协议》和《隐私政策》"
        bottomAgreementLabel.font = ScreenAdapter.font(12)
        bottomAgreementLabel.textColor = .tertiaryLabel
        bottomAgreementLabel.textAlignment = .center
        bottomAgreementLabel.numberOfLines = 0

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [
            headerContainer, glassCard, agreementStack, nextButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(20)
        mainStack.alignment = .fill
        contentView.addSubview(mainStack)
        contentView.addSubview(bottomAgreementLabel)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(16))
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        nextButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
        bottomAgreementLabel.snp.makeConstraints { make in
            make.top.equalTo(mainStack.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(20))
        }
    }

    // MARK: - 交互
    @objc private func textFieldDidChange() {
        updateLoginButtonState()
    }

    private func updateLoginButtonState() {
        let hasAccount = isEmailMode
            ? isValidEmail(emailField.textField.text ?? "")
            : AppUtility.isValidPhone(phoneField.textField.text ?? "")
        let enabled = hasAccount && isAgreed
        nextButton.isEnabled = enabled && !isLoading
        nextButton.alpha = enabled ? 1.0 : 0.5
    }

    @objc private func toggleAgreement() {
        isAgreed.toggle()
        agreementCheckBox.isSelected = isAgreed
        updateLoginButtonState()
    }

    @objc private func openUserAgreement() {
        AppUtility.showToast("用户协议")
    }

    @objc private func openPrivacyPolicy() {
        AppUtility.showToast("隐私政策")
    }

    private func switchMode(_ index: Int) {
        isEmailMode = (index == 1)
        phoneField.isHidden = isEmailMode
        emailField.isHidden = !isEmailMode
        updateLoginButtonState()
    }

    // MARK: - 登录/注册入口
    @objc private func loginOrRegister() {
        guard isAgreed else {
            AppUtility.showToast("请先同意用户协议和隐私政策")
            return
        }

        view.endEditing(true)
        isLoading = true
        nextButton.isEnabled = false
        nextButton.setTitle("检查中...", for: .normal)

        if isEmailMode {
            let email = emailField.textField.text ?? ""
            guard isValidEmail(email) else {
                AppUtility.showToast("请输入正确的邮箱")
                resetButton()
                return
            }
            Task {
                do {
                    let resp: SendCodeResponse = try await APIClient.shared.request(.isRegister(phone: nil, email: email))
                    DispatchQueue.main.async {
                        self.resetButton()
                        if resp.exist == 1 {
                            // 已注册 → 登录页
                            let vc = LoginViewController(account: email, isEmail: true)
                            print("push vc: \(type(of: vc))")
                            self.navigationController?.pushViewController(vc, animated: true)
                            print("push completed: \(type(of: vc))")
                        } else {
                            // 未注册 → 注册页
                            let vc = RegisterViewController(email: email, isEmail: true)
                            print("push vc: \(type(of: vc))")
                            self.navigationController?.pushViewController(vc, animated: true)
                            print("push completed: \(type(of: vc))")
                        }
                    }
                } catch {
                    print("loginOrRegister error: \(error)")
                    print("error details: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.resetButton()
                        AppUtility.showToast("检查失败: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let phone = phoneField.textField.text ?? ""
            guard AppUtility.isValidPhone(phone) else {
                AppUtility.showToast("请输入正确的手机号")
                resetButton()
                return
            }
            Task {
                do {
                    let resp: SendCodeResponse = try await APIClient.shared.request(.isRegister(phone: phone, email: nil))
                    DispatchQueue.main.async {
                        self.resetButton()
                        if resp.exist == 1 {
                            // 已注册 → 登录页
                            let vc = LoginViewController(account: phone, isEmail: false)
                            print("push vc: \(type(of: vc))")
                            self.navigationController?.pushViewController(vc, animated: true)
                            print("push completed: \(type(of: vc))")
                        } else {
                            // 未注册 → 注册页
                            let vc = RegisterViewController(phone: phone, isEmail: false)
                            print("push vc: \(type(of: vc))")
                            self.navigationController?.pushViewController(vc, animated: true)
                            print("push completed: \(type(of: vc))")
                        }
                    }
                } catch {
                    print("loginOrRegister error: \(error)")
                    print("error details: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.resetButton()
                        AppUtility.showToast("检查失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func resetButton() {
        isLoading = false
        nextButton.isEnabled = true
        nextButton.setTitle("下一步", for: .normal)
        updateLoginButtonState()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
        return predicate.evaluate(with: email)
    }
}

// MARK: - 页面2：登录页
class LoginViewController: UIViewController {

    private let account: String
    private let isEmail: Bool

    private enum LoginMode { case password, code }
    private var loginMode: LoginMode = .password

    // 顶部区域
    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // 玻璃卡片
    private let glassCard = GlassCardView()
    private let segmentedControl = GlassSegmentedControl(items: ["密码登录", "验证码登录"])

    // 账号显示（只读脱敏）
    private let accountDisplayField = CapsuleDisplayField()
    private let emailInputField = CapsuleTextField()

    private let passwordField = CapsulePasswordField()
    private let codeField = CapsuleCodeField()

    // 忘记密码链接
    private let forgotPwdButton = UIButton(type: .system)

    // 登录按钮
    private let loginButton = UIButton(type: .system)
    private var isLoading = false

    // 底部注册提示
    private let registerTipLabel = UILabel()

    private var countdown = 0
    private var countdownTimer: Timer?

    init(account: String, isEmail: Bool) {
        self.account = account
        self.isEmail = isEmail
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[\(type(of: self))] viewDidLoad")
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        view.backgroundColor = .white

        // 顶部：左侧Logo + 右侧标题+副标题
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        titleLabel.text = "登录"
        titleLabel.font = ScreenAdapter.mediumFont(22)
        titleLabel.textColor = .label

        subtitleLabel.text = "欢迎回来，登录您的账号"
        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel

        // 右侧标题+副标题垂直排列
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = ScreenAdapter.scaleH(4)
        titleStack.alignment = .leading

        // 整体：左logo + 右标题
        let headerStack = UIStackView(arrangedSubviews: [logoView, titleStack])
        headerStack.axis = .horizontal
        headerStack.spacing = ScreenAdapter.scaleW(12)
        headerStack.alignment = .center

        let headerContainer = UIView()
        headerContainer.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        logoView.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleH(48))
        }

        // 玻璃卡片
        view.addSubview(glassCard)

        // 分段控件
        segmentedControl.onSelected = { [weak self] index in
            self?.switchLoginMode(index)
        }
        glassCard.addSubview(segmentedControl)

        // 账号显示/输入
        if isEmail {
            accountDisplayField.isHidden = true
            emailInputField.placeholder = "请输入邮箱地址"
            emailInputField.textField.text = account
            emailInputField.textField.keyboardType = .emailAddress
            emailInputField.textField.autocapitalizationType = .none
            glassCard.addSubview(emailInputField)
        } else {
            emailInputField.isHidden = true
            accountDisplayField.text = "+86 \(maskPhone(account))"
            glassCard.addSubview(accountDisplayField)
        }

        // 密码输入框
        passwordField.placeholder = "请输入密码"
        passwordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        glassCard.addSubview(passwordField)

        // 验证码输入框
        codeField.placeholder = "请输入验证码"
        codeField.sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        codeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        codeField.isHidden = true
        glassCard.addSubview(codeField)

        // 忘记密码链接
        forgotPwdButton.setTitle("忘记密码？", for: .normal)
        forgotPwdButton.titleLabel?.font = ScreenAdapter.font(13)
        forgotPwdButton.setTitleColor(.themePrimary, for: .normal)
        forgotPwdButton.contentHorizontalAlignment = .right
        forgotPwdButton.addTarget(self, action: #selector(goForgotPassword), for: .touchUpInside)
        glassCard.addSubview(forgotPwdButton)

        // 卡片内布局
        segmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }

        if isEmail {
            emailInputField.snp.makeConstraints { make in
                make.top.equalTo(segmentedControl.snp.bottom).offset(ScreenAdapter.scaleH(16))
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            }
            passwordField.snp.makeConstraints { make in
                make.top.equalTo(emailInputField.snp.bottom).offset(ScreenAdapter.scaleH(12))
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            }
            codeField.snp.makeConstraints { make in
                make.top.equalTo(emailInputField.snp.bottom).offset(ScreenAdapter.scaleH(12))
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            }
        } else {
            accountDisplayField.snp.makeConstraints { make in
                make.top.equalTo(segmentedControl.snp.bottom).offset(ScreenAdapter.scaleH(16))
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            }
            passwordField.snp.makeConstraints { make in
                make.top.equalTo(accountDisplayField.snp.bottom).offset(ScreenAdapter.scaleH(12))
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            }
            codeField.snp.makeConstraints { make in
                make.top.equalTo(accountDisplayField.snp.bottom).offset(ScreenAdapter.scaleH(12))
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            }
        }

        forgotPwdButton.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.height.equalTo(ScreenAdapter.scaleH(20))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(20))
        }

        // 登录按钮
        loginButton.setTitle("登录", for: .normal)
        loginButton.backgroundColor = .themePrimary
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        loginButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        loginButton.alpha = 0.5
        loginButton.isEnabled = false
        loginButton.addTarget(self, action: #selector(doLogin), for: .touchUpInside)

        // 底部注册提示
        registerTipLabel.text = "还没有账号？去注册"
        registerTipLabel.font = ScreenAdapter.font(14)
        registerTipLabel.textColor = .secondaryLabel
        registerTipLabel.textAlignment = .center
        registerTipLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(goRegister))
        registerTipLabel.addGestureRecognizer(tapGesture)

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [
            headerContainer, glassCard, loginButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(20)
        mainStack.alignment = .fill
        contentView.addSubview(mainStack)
        contentView.addSubview(registerTipLabel)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(16))
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        loginButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
        registerTipLabel.snp.makeConstraints { make in
            make.top.equalTo(mainStack.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(20))
        }

        updateLoginButtonState()
    }

    private func maskPhone(_ phone: String) -> String {
        guard phone.count >= 7 else { return phone }
        let prefix = phone.prefix(3)
        let suffix = phone.suffix(4)
        return "\(prefix)****\(suffix)"
    }

    // MARK: - 交互
    @objc private func textFieldDidChange() {
        updateLoginButtonState()
    }

    private func updateLoginButtonState() {
        let hasAccount = isEmail
            ? !(emailInputField.textField.text ?? "").isEmpty
            : !account.isEmpty
        let hasInput: Bool
        switch loginMode {
        case .password:
            hasInput = !(passwordField.textField.text ?? "").isEmpty
        case .code:
            hasInput = !(codeField.textField.text ?? "").isEmpty
        }
        let enabled = hasAccount && hasInput && !isLoading
        loginButton.isEnabled = enabled
        loginButton.alpha = enabled ? 1.0 : 0.5
    }

    private func switchLoginMode(_ index: Int) {
        if index == 1 {
            loginMode = .code
            passwordField.isHidden = true
            codeField.isHidden = false
            forgotPwdButton.isHidden = true
        } else {
            loginMode = .password
            passwordField.isHidden = false
            codeField.isHidden = true
            forgotPwdButton.isHidden = false
        }
        updateLoginButtonState()
    }

    @objc private func goForgotPassword() {
        let vc = ForgotPasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func goRegister() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - 发送验证码
    @objc private func sendCode() {
        if isEmail {
            let email = emailInputField.textField.text ?? ""
            guard !email.isEmpty else {
                AppUtility.showToast("请输入邮箱")
                return
            }
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.sendEmailCode(email: email))
                    DispatchQueue.main.async {
                        AppUtility.showToast("验证码已发送")
                        self.startCountdown()
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("发送失败: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let phone = account
            guard AppUtility.isValidPhone(phone) else {
                AppUtility.showToast("请输入正确的手机号")
                return
            }
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.sendSMSCode(phone: phone))
                    DispatchQueue.main.async {
                        AppUtility.showToast("验证码已发送")
                        self.startCountdown()
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("发送失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - 登录
    @objc private func doLogin() {
        view.endEditing(true)
        isLoading = true
        loginButton.isEnabled = false
        loginButton.setTitle("登录中...", for: .normal)

        let phone = account
        let email = emailInputField.textField.text ?? ""

        switch loginMode {
        case .password:
            let password = passwordField.textField.text ?? ""
            guard password.count >= 6 else {
                AppUtility.showToast("请输入密码")
                resetButton()
                return
            }
            // username = "0086{phone}" 或 邮箱
            let username = isEmail ? email : "0086\(phone)"
            Task {
                do {
                    let resp: LoginResponse = try await APIClient.shared.request(.login(username: username, password: password, device: nil))
                    DispatchQueue.main.async {
                        self.handleLoginSuccess(resp)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.resetButton()
                        AppUtility.showToast("登录失败: \(error.localizedDescription)")
                    }
                }
            }
        case .code:
            let code = codeField.textField.text ?? ""
            guard code.count >= 4 else {
                AppUtility.showToast("请输入验证码")
                resetButton()
                return
            }
            // 验证码登录：先发送 registercode 获取验证码（已在 sendCode 完成），
            // 然后用验证码注册（后端已存在用户会用相同密码登录）
            if isEmail {
                Task {
                    do {
                        // 用验证码做注册操作，后端对已存在用户走登录逻辑
                        let resp: LoginResponse = try await APIClient.shared.requestRawLogin(.register(zone: "0086", phone: "", code: code, password: ""))
                        DispatchQueue.main.async {
                            // 邮箱验证码登录降级处理
                            self.handleCodeLoginFallback(resp, phone: "", email: email)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.resetButton()
                            AppUtility.showToast("登录失败: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                guard AppUtility.isValidPhone(phone) else {
                    AppUtility.showToast("请输入正确的手机号")
                    resetButton()
                    return
                }
                Task {
                    do {
                        let resp: LoginResponse = try await APIClient.shared.requestRawLogin(.register(zone: "0086", phone: phone, code: code, password: ""))
                        DispatchQueue.main.async {
                            self.handleCodeLoginFallback(resp, phone: phone, email: "")
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.resetButton()
                            AppUtility.showToast("登录失败: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    private func handleCodeLoginFallback(_ resp: LoginResponse, phone: String, email: String) {
        // 验证码登录走 register 接口，后端对已注册用户返回登录结果
        guard let uid = resp.uid, let token = resp.token else {
            resetButton()
            AppUtility.showToast("登录失败")
            return
        }
        var loginResp = resp
        if !phone.isEmpty { loginResp.phone = phone }
        if !email.isEmpty { loginResp.email = email }
        handleLoginSuccess(loginResp)
    }

    private func handleLoginSuccess(_ resp: LoginResponse) {
        guard let uid = resp.uid, let token = resp.token else {
            resetButton()
            AppUtility.showToast("登录失败")
            return
        }

        UserDefaults.standard.set(uid, forKey: "uid")
        UserDefaults.standard.set(token, forKey: "token")
        let imToken = resp.im_token ?? token
        UserDefaults.standard.set(imToken, forKey: "im_token")
        if let phone = resp.phone { UserDefaults.standard.set(phone, forKey: "phone") }
        if let email = resp.email { UserDefaults.standard.set(email, forKey: "email") }
        if let shortNo = resp.short_no { UserDefaults.standard.set(shortNo, forKey: "short_no") }
        if let zone = resp.zone { UserDefaults.standard.set(zone, forKey: "zone") }

        IMManager.shared.connect()
        DataSyncManager.shared.syncAll()
        showMainScreen()
    }

    private func resetButton() {
        isLoading = false
        loginButton.isEnabled = true
        loginButton.setTitle("登录", for: .normal)
        updateLoginButtonState()
    }

    // MARK: - 倒计时
    private func startCountdown() {
        countdown = 60
        codeField.sendCodeButton.isEnabled = false
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdown <= 0 {
                self.codeField.sendCodeButton.setTitle("获取验证码", for: .normal)
                self.codeField.sendCodeButton.isEnabled = true
                self.countdownTimer?.invalidate()
            } else {
                self.codeField.sendCodeButton.setTitle("\(self.countdown)s", for: .normal)
                self.countdown -= 1
            }
        }
    }

    private func showMainScreen() {
        let vc = MainTabBarController()
        view.window?.rootViewController = vc
    }
}

// MARK: - 页面3：注册页
class RegisterViewController: UIViewController {

    private let phone: String?
    private let email: String?
    private let isEmail: Bool

    // 顶部区域
    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // 玻璃卡片
    private let glassCard = GlassCardView()

    // 账号显示（只读）
    private let accountDisplayField = CapsuleDisplayField()

    private let codeField = CapsuleCodeField()
    private let passwordField = CapsulePasswordField()

    // 协议勾选（卡片内底部）
    private let agreementCheckBox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private let userAgreementButton = UIButton(type: .system)
    private let privacyPolicyButton = UIButton(type: .system)
    private var isAgreed = false

    // 注册按钮
    private let registerButton = UIButton(type: .system)
    private var isLoading = false

    // 底部登录提示
    private let loginTipLabel = UILabel()

    private var countdown = 0
    private var countdownTimer: Timer?

    init(phone: String? = nil, email: String? = nil, isEmail: Bool) {
        self.phone = phone
        self.email = email
        self.isEmail = isEmail
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[\(type(of: self))] viewDidLoad")
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        view.backgroundColor = .white

        // 顶部：左侧Logo + 右侧标题+副标题
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        titleLabel.text = "注册"
        titleLabel.font = ScreenAdapter.mediumFont(22)
        titleLabel.textColor = .label

        subtitleLabel.text = "创建您的Milo账号"
        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel

        // 右侧标题+副标题垂直排列
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = ScreenAdapter.scaleH(4)
        titleStack.alignment = .leading

        // 整体：左logo + 右标题
        let headerStack = UIStackView(arrangedSubviews: [logoView, titleStack])
        headerStack.axis = .horizontal
        headerStack.spacing = ScreenAdapter.scaleW(12)
        headerStack.alignment = .center

        let headerContainer = UIView()
        headerContainer.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        logoView.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleH(48))
        }

        // 玻璃卡片
        view.addSubview(glassCard)

        // 账号显示
        if isEmail {
            accountDisplayField.text = email ?? ""
        } else {
            accountDisplayField.text = "+86 \(phone ?? "")"
        }
        glassCard.addSubview(accountDisplayField)

        // 验证码输入框
        codeField.placeholder = "请输入验证码"
        codeField.sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        codeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        glassCard.addSubview(codeField)

        // 密码输入框
        passwordField.placeholder = "请设置密码(6-20位)"
        passwordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        glassCard.addSubview(passwordField)

        // 协议勾选（卡片内底部）
        agreementCheckBox.setImage(UIImage(systemName: "circle"), for: .normal)
        agreementCheckBox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        agreementCheckBox.tintColor = .themePrimary
        agreementCheckBox.addTarget(self, action: #selector(toggleAgreement), for: .touchUpInside)

        agreementLabel.text = "我已阅读并同意"
        agreementLabel.font = ScreenAdapter.font(12)
        agreementLabel.textColor = .secondaryLabel

        userAgreementButton.setTitle("《用户协议》", for: .normal)
        userAgreementButton.titleLabel?.font = ScreenAdapter.font(12)
        userAgreementButton.setTitleColor(.themePrimary, for: .normal)
        userAgreementButton.addTarget(self, action: #selector(openUserAgreement), for: .touchUpInside)

        privacyPolicyButton.setTitle("《隐私政策》", for: .normal)
        privacyPolicyButton.titleLabel?.font = ScreenAdapter.font(12)
        privacyPolicyButton.setTitleColor(.themePrimary, for: .normal)
        privacyPolicyButton.addTarget(self, action: #selector(openPrivacyPolicy), for: .touchUpInside)

        let agreementStack = UIStackView(arrangedSubviews: [
            agreementCheckBox, agreementLabel, userAgreementButton, privacyPolicyButton
        ])
        agreementStack.axis = .horizontal
        agreementStack.spacing = ScreenAdapter.scaleW(3)
        agreementStack.alignment = .center
        glassCard.addSubview(agreementStack)

        agreementCheckBox.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(16))
        }

        // 卡片内布局
        accountDisplayField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        codeField.snp.makeConstraints { make in
            make.top.equalTo(accountDisplayField.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(codeField.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        agreementStack.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(ScreenAdapter.scaleH(14))
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(20))
        }

        // 注册按钮
        registerButton.setTitle("注册", for: .normal)
        registerButton.backgroundColor = .themePrimary
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        registerButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        registerButton.alpha = 0.5
        registerButton.isEnabled = false
        registerButton.addTarget(self, action: #selector(doRegister), for: .touchUpInside)

        // 底部登录提示
        loginTipLabel.text = "已有账号？去登录"
        loginTipLabel.font = ScreenAdapter.font(14)
        loginTipLabel.textColor = .secondaryLabel
        loginTipLabel.textAlignment = .center
        loginTipLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(goLogin))
        loginTipLabel.addGestureRecognizer(tapGesture)

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [
            headerContainer, glassCard, registerButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(20)
        mainStack.alignment = .fill
        contentView.addSubview(mainStack)
        contentView.addSubview(loginTipLabel)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(16))
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        registerButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
        loginTipLabel.snp.makeConstraints { make in
            make.top.equalTo(mainStack.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(20))
        }

        updateRegisterButtonState()
    }

    // MARK: - 交互
    @objc private func textFieldDidChange() {
        updateRegisterButtonState()
    }

    private func updateRegisterButtonState() {
        let hasAccount = isEmail ? !(email ?? "").isEmpty : !(phone ?? "").isEmpty
        let hasCode = !(codeField.textField.text ?? "").isEmpty
        let hasPassword = (passwordField.textField.text ?? "").count >= 6
        let enabled = hasAccount && hasCode && hasPassword && isAgreed && !isLoading
        registerButton.isEnabled = enabled
        registerButton.alpha = enabled ? 1.0 : 0.5
    }

    @objc private func toggleAgreement() {
        isAgreed.toggle()
        agreementCheckBox.isSelected = isAgreed
        updateRegisterButtonState()
    }

    @objc private func openUserAgreement() {
        AppUtility.showToast("用户协议")
    }

    @objc private func openPrivacyPolicy() {
        AppUtility.showToast("隐私政策")
    }

    @objc private func goLogin() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - 发送验证码
    @objc private func sendCode() {
        if isEmail {
            let email = email ?? ""
            guard !email.isEmpty else {
                AppUtility.showToast("请输入邮箱")
                return
            }
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.sendEmailCode(email: email))
                    DispatchQueue.main.async {
                        AppUtility.showToast("验证码已发送")
                        self.startCountdown()
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("发送失败: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let phone = phone ?? ""
            guard AppUtility.isValidPhone(phone) else {
                AppUtility.showToast("请输入正确的手机号")
                return
            }
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.sendSMSCode(phone: phone))
                    DispatchQueue.main.async {
                        AppUtility.showToast("验证码已发送")
                        self.startCountdown()
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("发送失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - 注册
    @objc private func doRegister() {
        guard isAgreed else {
            AppUtility.showToast("请先同意用户协议和隐私政策")
            return
        }

        view.endEditing(true)
        let code = codeField.textField.text ?? ""
        let password = passwordField.textField.text ?? ""
        guard code.count >= 4 else {
            AppUtility.showToast("请输入验证码")
            return
        }
        guard password.count >= 6, password.count <= 20 else {
            AppUtility.showToast("密码需6-20位")
            return
        }

        isLoading = true
        registerButton.isEnabled = false
        registerButton.setTitle("注册中...", for: .normal)

        if isEmail {
            let email = email ?? ""
            guard !email.isEmpty else {
                AppUtility.showToast("请输入邮箱")
                resetButton()
                return
            }
            // 邮箱注册：后端邮箱注册接口暂用 register + email 字段扩展
            // 此处先发送注册验证码已在上一步完成，这里用 register 接口
            // 由于后端 register 走手机号，邮箱注册需通过 register 接口适配
            Task {
                do {
                    // 尝试用邮箱注册（后端可能支持 email 参数）
                    let resp: LoginResponse = try await APIClient.shared.requestRawLogin(.register(zone: "0086", phone: email, code: code, password: password))
                    DispatchQueue.main.async {
                        self.handleRegisterSuccess(resp, email: email)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.resetButton()
                        AppUtility.showToast("注册失败: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let phone = phone ?? ""
            guard AppUtility.isValidPhone(phone) else {
                AppUtility.showToast("请输入正确的手机号")
                resetButton()
                return
            }
            Task {
                do {
                    let resp: LoginResponse = try await APIClient.shared.requestRawLogin(.register(zone: "0086", phone: phone, code: code, password: password))
                    DispatchQueue.main.async {
                        self.handleRegisterSuccess(resp, phone: phone)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.resetButton()
                        AppUtility.showToast("注册失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func handleRegisterSuccess(_ resp: LoginResponse, phone: String = "", email: String = "") {
        guard let uid = resp.uid, let token = resp.token else {
            resetButton()
            AppUtility.showToast("注册失败")
            return
        }

        UserDefaults.standard.set(uid, forKey: "uid")
        UserDefaults.standard.set(token, forKey: "token")
        let imToken = resp.im_token ?? token
        UserDefaults.standard.set(imToken, forKey: "im_token")
        if !phone.isEmpty { UserDefaults.standard.set(phone, forKey: "phone") }
        if !email.isEmpty { UserDefaults.standard.set(email, forKey: "email") }
        if let shortNo = resp.short_no { UserDefaults.standard.set(shortNo, forKey: "short_no") }

        // 跳转编辑资料
        let vc = ProfileEditViewController()
        vc.hidesBackButton = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func resetButton() {
        isLoading = false
        registerButton.isEnabled = true
        registerButton.setTitle("注册", for: .normal)
        updateRegisterButtonState()
    }

    // MARK: - 倒计时
    private func startCountdown() {
        countdown = 60
        codeField.sendCodeButton.isEnabled = false
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdown <= 0 {
                self.codeField.sendCodeButton.setTitle("获取验证码", for: .normal)
                self.codeField.sendCodeButton.isEnabled = true
                self.countdownTimer?.invalidate()
            } else {
                self.codeField.sendCodeButton.setTitle("\(self.countdown)s", for: .normal)
                self.countdown -= 1
            }
        }
    }
}

// MARK: - 页面4：忘记密码
class ForgotPasswordViewController: UIViewController {

    private let phoneField = PhoneFloatingLabelField()
    private let codeField = CodeFloatingLabelField()
    private let passwordField = PasswordFloatingLabelField()
    private let resetButton = UIButton(type: .system)
    private var isLoading = false

    private var countdown = 0
    private var countdownTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        title = "重置密码"
        view.backgroundColor = .themeBackground

        // Logo
        let logoView = UIImageView()
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        // 副标题
        let subtitleLabel = UILabel()
        subtitleLabel.text = "重置您的账号密码"
        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        phoneField.placeholder = "手机号"
        phoneField.textField.keyboardType = .numberPad
        phoneField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        codeField.placeholder = "验证码"
        codeField.sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        codeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        passwordField.placeholder = "新密码(6-20位)"
        passwordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        resetButton.setTitle("重置密码", for: .normal)
        resetButton.backgroundColor = .themePrimary
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        resetButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        resetButton.alpha = 0.5
        resetButton.isEnabled = false
        resetButton.addTarget(self, action: #selector(doReset), for: .touchUpInside)

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [logoView, subtitleLabel, phoneField, codeField, passwordField, resetButton])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(20)
        contentView.addSubview(mainStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(40))
        }
        logoView.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(70))
            make.centerX.equalToSuperview()
        }
        resetButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    // MARK: - 交互
    @objc private func textFieldDidChange() {
        updateResetButtonState()
    }

    private func updateResetButtonState() {
        let hasPhone = AppUtility.isValidPhone(phoneField.textField.text ?? "")
        let hasCode = !(codeField.textField.text ?? "").isEmpty
        let hasPassword = (passwordField.textField.text ?? "").count >= 6
        let enabled = hasPhone && hasCode && hasPassword && !isLoading
        resetButton.isEnabled = enabled
        resetButton.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - 发送验证码
    @objc private func sendCode() {
        let phone = phoneField.textField.text ?? ""
        guard AppUtility.isValidPhone(phone) else {
            AppUtility.showToast("请输入正确的手机号")
            return
        }
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.sendForgetSMSCode(phone: phone))
                DispatchQueue.main.async {
                    AppUtility.showToast("验证码已发送")
                    self.startCountdown()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("发送失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 重置密码
    @objc private func doReset() {
        view.endEditing(true)
        let phone = phoneField.textField.text ?? ""
        let code = codeField.textField.text ?? ""
        let password = passwordField.textField.text ?? ""

        guard AppUtility.isValidPhone(phone) else {
            AppUtility.showToast("请输入正确的手机号")
            return
        }
        guard code.count >= 4 else {
            AppUtility.showToast("请输入验证码")
            return
        }
        guard password.count >= 6, password.count <= 20 else {
            AppUtility.showToast("密码需6-20位")
            return
        }

        isLoading = true
        resetButton.isEnabled = false
        resetButton.setTitle("重置中...", for: .normal)

        Task {
            do {
                let resp: ResetPasswordResponse = try await APIClient.shared.request(.resetPasswordByPhone(phone: phone, code: code, password: password))
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.resetButton.isEnabled = true
                    self.resetButton.setTitle("重置密码", for: .normal)
                    self.updateResetButtonState()
                    if resp.status == 200 || resp.status == nil {
                        AppUtility.showToast("密码重置成功")
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        AppUtility.showToast(resp.msg ?? "重置失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.resetButton.isEnabled = true
                    self.resetButton.setTitle("重置密码", for: .normal)
                    self.updateResetButtonState()
                    AppUtility.showToast("重置失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 倒计时
    private func startCountdown() {
        countdown = 60
        codeField.sendCodeButton.isEnabled = false
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdown <= 0 {
                self.codeField.sendCodeButton.setTitle("获取验证码", for: .normal)
                self.codeField.sendCodeButton.isEnabled = true
                self.countdownTimer?.invalidate()
            } else {
                self.codeField.sendCodeButton.setTitle("\(self.countdown)s", for: .normal)
                self.countdown -= 1
            }
        }
    }
}

// MARK: - 页面5：编辑资料
class ProfileEditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var hidesBackButton: Bool = false

    private let avatarView = UIImageView()
    private let avatarAddIcon = UIImageView()
    private let nameField = UITextField()
    private let submitButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "编辑资料"
        view.backgroundColor = .themeBackground
        if hidesBackButton {
            navigationItem.hidesBackButton = true
        }

        // 头像
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .lightGray
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(60)
        avatarView.layer.masksToBounds = true
        avatarView.isUserInteractionEnabled = true
        avatarView.backgroundColor = .systemGray6

        avatarAddIcon.image = UIImage(systemName: "camera.fill")
        avatarAddIcon.tintColor = .white
        avatarAddIcon.backgroundColor = .themePrimary
        avatarAddIcon.layer.cornerRadius = ScreenAdapter.scaleW(14)
        avatarAddIcon.layer.masksToBounds = true

        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarView)
        avatarContainer.addSubview(avatarAddIcon)
        avatarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(120))
        }
        avatarAddIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(pickAvatar))
        avatarContainer.addGestureRecognizer(tap)

        // 昵称输入框
        let nameContainer = UIView()
        nameContainer.backgroundColor = .white
        nameContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        nameContainer.layer.borderWidth = 1
        nameContainer.layer.borderColor = UIColor.themeSeparator.cgColor

        nameField.placeholder = "请输入昵称"
        nameField.font = ScreenAdapter.font(17)
        nameField.borderStyle = .none
        nameField.returnKeyType = .done
        nameField.addTarget(self, action: #selector(nameFieldDidEnd), for: .editingDidEnd)
        nameContainer.addSubview(nameField)
        nameField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.centerY.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(56))
        }

        // 完成按钮
        submitButton.setTitle("完成", for: .normal)
        submitButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        submitButton.backgroundColor = .themePrimary
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [avatarContainer, nameContainer, submitButton])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(28)
        mainStack.alignment = .center
        contentView.addSubview(mainStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(48))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(40))
        }
        nameContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(66))
        }
        submitButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    @objc private func pickAvatar() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.originalImage] as? UIImage {
            avatarView.image = img
        }
        picker.dismiss(animated: true)
    }

    @objc private func nameFieldDidEnd() {
        // 边框恢复
    }

    @objc private func submit() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            AppUtility.showToast("请输入昵称")
            return
        }

        submitButton.isEnabled = false
        submitButton.setTitle("提交中...", for: .normal)

        Task {
            do {
                // 更新昵称
                _ = try await APIClient.shared.requestRaw(.updateUserInfo(name: name, avatar: nil))
                UserDefaults.standard.set(name, forKey: "name")
                DispatchQueue.main.async {
                    // 进入主界面
                    IMManager.shared.connect()
                    let vc = MainTabBarController()
                    self.view.window?.rootViewController = vc
                }
            } catch {
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    self.submitButton.setTitle("完成", for: .normal)
                    // 即使更新失败也进入主界面（注册后已拿到 token）
                    IMManager.shared.connect()
                    let vc = MainTabBarController()
                    self.view.window?.rootViewController = vc
                }
            }
        }
    }
}

// MARK: - APIClient 扩展：LoginResponse 解码辅助
extension APIClient {
    /// 尝试用 LoginResponse 解码（用于 register 接口返回登录数据体的情况）
    func requestRawLogin(_ router: APIRouter) async throws -> LoginResponse {
        let response = await session.request(router).serializingData().response
        if let statusCode = response.response?.statusCode, !(200...299).contains(statusCode) {
            if let data = response.data {
                if let errorResp = try? JSONDecoder().decode(MessageResponse.self, from: data) {
                    throw APIError.serverError(message: errorResp.msg ?? "未知错误", code: statusCode)
                }
            }
            throw APIError.serverError(message: "请求失败(\(statusCode))", code: statusCode)
        }
        guard let data = response.data else {
            throw APIError.noData
        }
        // 尝试直接解码 LoginResponse
        if let resp = try? JSONDecoder().decode(LoginResponse.self, from: data) {
            return resp
        }
        // 尝试解析 APIResponse 包装体中的 data
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let innerData = json["data"] as? [String: Any] {
            let innerJson = try? JSONSerialization.data(withJSONObject: innerData)
            if let innerJson = innerJson,
               let resp = try? JSONDecoder().decode(LoginResponse.self, from: innerJson) {
                return resp
            }
        }
        throw APIError.decodingError(NSError(domain: "LoginResponse", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析登录响应失败"]))
    }
}

// MARK: - EmptyData（兼容旧代码引用）
struct EmptyData: Codable {}
