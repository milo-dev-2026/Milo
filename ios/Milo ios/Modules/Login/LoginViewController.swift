import UIKit
import SnapKit
import PhotosUI

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

    private let logoView = UIImageView()

    private let tabContainer = UIView()
    private let phoneTabButton = UIButton(type: .custom)
    private let emailTabButton = UIButton(type: .custom)
    private var isEmailMode = false

    private let phoneField = PhoneFloatingLabelField()
    private let emailField = FloatingLabelTextField()

    private let agreementCheckBox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private let userAgreementButton = UIButton(type: .system)
    private let privacyPolicyButton = UIButton(type: .system)
    private var isAgreed = false

    private let loginButton = UIButton(type: .system)
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .themeBackground
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Logo
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        // 副标题
        let subtitleLabel = UILabel()
        subtitleLabel.text = "欢迎使用Milo 输入手机号或者邮箱继续"
        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Tab 按钮
        phoneTabButton.setTitle("手机号", for: .normal)
        phoneTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        phoneTabButton.setTitleColor(.themePrimary, for: .normal)
        phoneTabButton.setTitleColor(.secondaryLabel, for: .normal)
        phoneTabButton.addTarget(self, action: #selector(switchToPhone), for: .touchUpInside)

        emailTabButton.setTitle("邮箱", for: .normal)
        emailTabButton.titleLabel?.font = ScreenAdapter.font(16)
        emailTabButton.setTitleColor(.themePrimary, for: .normal)
        emailTabButton.setTitleColor(.secondaryLabel, for: .normal)
        emailTabButton.addTarget(self, action: #selector(switchToEmail), for: .touchUpInside)

        let tabStack = UIStackView(arrangedSubviews: [phoneTabButton, emailTabButton])
        tabStack.axis = .horizontal
        tabStack.spacing = ScreenAdapter.scaleW(32)
        tabStack.alignment = .center

        // 输入框
        phoneField.placeholder = "手机号"
        phoneField.textField.keyboardType = .numberPad
        phoneField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        emailField.placeholder = "邮箱地址"
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocapitalizationType = .none
        emailField.isHidden = true
        emailField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // 协议勾选
        agreementCheckBox.setImage(UIImage(systemName: "circle"), for: .normal)
        agreementCheckBox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        agreementCheckBox.tintColor = .themePrimary
        agreementCheckBox.addTarget(self, action: #selector(toggleAgreement), for: .touchUpInside)

        agreementLabel.text = "我已阅读并同意"
        agreementLabel.font = ScreenAdapter.font(14)
        agreementLabel.textColor = .secondaryLabel

        userAgreementButton.setTitle("《用户协议》", for: .normal)
        userAgreementButton.titleLabel?.font = ScreenAdapter.font(14)
        userAgreementButton.setTitleColor(.themePrimary, for: .normal)
        userAgreementButton.addTarget(self, action: #selector(openUserAgreement), for: .touchUpInside)

        privacyPolicyButton.setTitle("《隐私政策》", for: .normal)
        privacyPolicyButton.titleLabel?.font = ScreenAdapter.font(14)
        privacyPolicyButton.setTitleColor(.themePrimary, for: .normal)
        privacyPolicyButton.addTarget(self, action: #selector(openPrivacyPolicy), for: .touchUpInside)

        let agreementStack = UIStackView(arrangedSubviews: [
            agreementCheckBox, agreementLabel, userAgreementButton, privacyPolicyButton
        ])
        agreementStack.axis = .horizontal
        agreementStack.spacing = ScreenAdapter.scaleW(4)
        agreementStack.alignment = .center

        agreementCheckBox.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(22))
        }

        // 登录/注册按钮
        loginButton.setTitle("登录/注册", for: .normal)
        loginButton.backgroundColor = .themePrimary
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        loginButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        loginButton.alpha = 0.5
        loginButton.isEnabled = false
        loginButton.addTarget(self, action: #selector(loginOrRegister), for: .touchUpInside)

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [logoView, subtitleLabel, tabStack, phoneField, emailField, agreementStack, loginButton])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(24)
        mainStack.alignment = .fill
        contentView.addSubview(mainStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(60))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(40))
        }
        logoView.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(100))
            make.centerX.equalToSuperview()
        }
        tabStack.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(30))
            make.centerX.equalToSuperview()
        }
        loginButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
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
        loginButton.isEnabled = enabled && !isLoading
        loginButton.alpha = enabled ? 1.0 : 0.5
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

    @objc private func switchToPhone() {
        isEmailMode = false
        phoneTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        phoneTabButton.setTitleColor(.themePrimary, for: .normal)
        emailTabButton.titleLabel?.font = ScreenAdapter.font(16)
        emailTabButton.setTitleColor(.secondaryLabel, for: .normal)
        phoneField.isHidden = false
        emailField.isHidden = true
        updateLoginButtonState()
    }

    @objc private func switchToEmail() {
        isEmailMode = true
        phoneTabButton.titleLabel?.font = ScreenAdapter.font(16)
        phoneTabButton.setTitleColor(.secondaryLabel, for: .normal)
        emailTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        emailTabButton.setTitleColor(.themePrimary, for: .normal)
        phoneField.isHidden = true
        emailField.isHidden = false
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
        loginButton.isEnabled = false
        loginButton.setTitle("检查中...", for: .normal)

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
                            self.navigationController?.pushViewController(vc, animated: true)
                        } else {
                            // 未注册 → 注册页
                            let vc = RegisterViewController(email: email, isEmail: true)
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                } catch {
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
                            self.navigationController?.pushViewController(vc, animated: true)
                        } else {
                            // 未注册 → 注册页
                            let vc = RegisterViewController(phone: phone, isEmail: false)
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                } catch {
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
        loginButton.isEnabled = true
        loginButton.setTitle("登录/注册", for: .normal)
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

    private let phoneField = PhoneFloatingLabelField()
    private let emailField = FloatingLabelTextField()
    private let passwordField = PasswordFloatingLabelField()
    private let codeField = CodeFloatingLabelField()

    private let bottomBar = UIView()
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)

    private let loginButton = UIButton(type: .system)
    private var isLoading = false

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
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        title = "登录"
        view.backgroundColor = .themeBackground

        // Logo
        let logoView = UIImageView()
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        // 副标题
        let subtitleLabel = UILabel()
        subtitleLabel.text = "欢迎使用Milo"
        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        // 手机号/邮箱输入框
        phoneField.placeholder = "手机号"
        phoneField.textField.text = isEmail ? "" : account
        phoneField.textField.keyboardType = .numberPad
        phoneField.isHidden = isEmail

        emailField.placeholder = "邮箱地址"
        emailField.textField.text = isEmail ? account : ""
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocapitalizationType = .none
        emailField.isHidden = !isEmail

        // 密码输入框
        passwordField.placeholder = "密码"
        passwordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // 验证码输入框
        codeField.placeholder = "验证码"
        codeField.sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        codeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        codeField.isHidden = true

        // 底部按钮栏
        leftButton.setTitle("忘记密码？", for: .normal)
        leftButton.titleLabel?.font = ScreenAdapter.font(14)
        leftButton.setTitleColor(.themePrimary, for: .normal)
        leftButton.addTarget(self, action: #selector(goForgotPassword), for: .touchUpInside)

        rightButton.setTitle("验证码登录", for: .normal)
        rightButton.titleLabel?.font = ScreenAdapter.font(14)
        rightButton.setTitleColor(.themePrimary, for: .normal)
        rightButton.addTarget(self, action: #selector(switchLoginMode), for: .touchUpInside)

        bottomBar.addSubview(leftButton)
        bottomBar.addSubview(rightButton)

        leftButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        rightButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
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

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [logoView, subtitleLabel, phoneField, emailField, passwordField, codeField, loginButton, bottomBar])
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
        loginButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
        logoView.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(70))
            make.centerX.equalToSuperview()
        }
        bottomBar.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(30))
        }

        updateLoginButtonState()
    }

    // MARK: - 交互
    @objc private func textFieldDidChange() {
        updateLoginButtonState()
    }

    private func updateLoginButtonState() {
        let hasAccount = isEmail
            ? !(emailField.textField.text ?? "").isEmpty
            : AppUtility.isValidPhone(phoneField.textField.text ?? "")
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

    @objc private func switchLoginMode() {
        if loginMode == .password {
            loginMode = .code
            passwordField.isHidden = true
            codeField.isHidden = false
            rightButton.setTitle("密码登录", for: .normal)
            leftButton.isHidden = true
        } else {
            loginMode = .password
            passwordField.isHidden = false
            codeField.isHidden = true
            rightButton.setTitle("验证码登录", for: .normal)
            leftButton.isHidden = false
        }
        updateLoginButtonState()
    }

    @objc private func goForgotPassword() {
        let vc = ForgotPasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 发送验证码
    @objc private func sendCode() {
        if isEmail {
            let email = emailField.textField.text ?? ""
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
            let phone = phoneField.textField.text ?? ""
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

        let phone = phoneField.textField.text ?? ""
        let email = emailField.textField.text ?? ""

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

    private let tabContainer = UIView()
    private let phoneTabButton = UIButton(type: .custom)
    private let emailTabButton = UIButton(type: .custom)
    private var isEmailMode: Bool

    private let phoneField = PhoneFloatingLabelField()
    private let emailField = FloatingLabelTextField()
    private let codeField = CodeFloatingLabelField()
    private let passwordField = PasswordFloatingLabelField()

    private let registerButton = UIButton(type: .system)
    private var isLoading = false

    private var countdown = 0
    private var countdownTimer: Timer?

    init(phone: String? = nil, email: String? = nil, isEmail: Bool) {
        self.phone = phone
        self.email = email
        self.isEmail = isEmail
        self.isEmailMode = isEmail
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        title = "注册账号"
        view.backgroundColor = .themeBackground

        // Logo
        let logoView = UIImageView()
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        // 副标题
        let subtitleLabel = UILabel()
        subtitleLabel.text = "创建您的Milo账号"
        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        // Tab 切换
        phoneTabButton.setTitle("手机号注册", for: .normal)
        phoneTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        phoneTabButton.setTitleColor(.themePrimary, for: .normal)
        phoneTabButton.setTitleColor(.secondaryLabel, for: .normal)
        phoneTabButton.addTarget(self, action: #selector(switchToPhone), for: .touchUpInside)

        emailTabButton.setTitle("邮箱注册", for: .normal)
        emailTabButton.titleLabel?.font = ScreenAdapter.font(16)
        emailTabButton.setTitleColor(.themePrimary, for: .normal)
        emailTabButton.setTitleColor(.secondaryLabel, for: .normal)
        emailTabButton.addTarget(self, action: #selector(switchToEmail), for: .touchUpInside)

        let tabStack = UIStackView(arrangedSubviews: [phoneTabButton, emailTabButton])
        tabStack.axis = .horizontal
        tabStack.spacing = ScreenAdapter.scaleW(32)
        tabStack.alignment = .center

        // 输入框
        phoneField.placeholder = "手机号"
        phoneField.textField.text = phone ?? ""
        phoneField.textField.keyboardType = .numberPad
        phoneField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        phoneField.isHidden = isEmail

        emailField.placeholder = "邮箱地址"
        emailField.textField.text = email ?? ""
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocapitalizationType = .none
        emailField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        emailField.isHidden = !isEmail

        codeField.placeholder = "验证码"
        codeField.sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        codeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        passwordField.placeholder = "密码(6-20位)"
        passwordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // 注册按钮
        registerButton.setTitle("注册", for: .normal)
        registerButton.backgroundColor = .themePrimary
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        registerButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        registerButton.alpha = 0.5
        registerButton.isEnabled = false
        registerButton.addTarget(self, action: #selector(doRegister), for: .touchUpInside)

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [logoView, subtitleLabel, tabStack, phoneField, emailField, codeField, passwordField, registerButton])
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
        tabStack.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(30))
            make.centerX.equalToSuperview()
        }
        registerButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }

        updateRegisterButtonState()
    }

    // MARK: - 交互
    @objc private func textFieldDidChange() {
        updateRegisterButtonState()
    }

    private func updateRegisterButtonState() {
        let hasAccount: Bool
        if isEmailMode {
            hasAccount = !(emailField.textField.text ?? "").isEmpty
        } else {
            hasAccount = AppUtility.isValidPhone(phoneField.textField.text ?? "")
        }
        let hasCode = !(codeField.textField.text ?? "").isEmpty
        let hasPassword = (passwordField.textField.text ?? "").count >= 6
        let enabled = hasAccount && hasCode && hasPassword && !isLoading
        registerButton.isEnabled = enabled
        registerButton.alpha = enabled ? 1.0 : 0.5
    }

    @objc private func switchToPhone() {
        isEmailMode = false
        phoneTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        phoneTabButton.setTitleColor(.themePrimary, for: .normal)
        emailTabButton.titleLabel?.font = ScreenAdapter.font(16)
        emailTabButton.setTitleColor(.secondaryLabel, for: .normal)
        phoneField.isHidden = false
        emailField.isHidden = true
        updateRegisterButtonState()
    }

    @objc private func switchToEmail() {
        isEmailMode = true
        phoneTabButton.titleLabel?.font = ScreenAdapter.font(16)
        phoneTabButton.setTitleColor(.secondaryLabel, for: .normal)
        emailTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        emailTabButton.setTitleColor(.themePrimary, for: .normal)
        phoneField.isHidden = true
        emailField.isHidden = false
        updateRegisterButtonState()
    }

    // MARK: - 发送验证码
    @objc private func sendCode() {
        if isEmailMode {
            let email = emailField.textField.text ?? ""
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
            let phone = phoneField.textField.text ?? ""
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

        if isEmailMode {
            let email = emailField.textField.text ?? ""
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
            let phone = phoneField.textField.text ?? ""
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
