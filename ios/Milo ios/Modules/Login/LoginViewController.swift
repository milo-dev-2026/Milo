import UIKit
import SnapKit

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

        // 监听编辑状态
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

// MARK: - 登录页
class LoginViewController: UIViewController {

    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let cardView = UIView()
    private let tabContainer = UIView()
    private let phoneTabButton = UIButton(type: .custom)
    private let emailTabButton = UIButton(type: .custom)

    private let phoneField = PhoneFloatingLabelField()
    private let emailField = FloatingLabelTextField()
    private let codeField = CodeFloatingLabelField()

    private let agreementCheckBox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private let userAgreementButton = UIButton(type: .system)
    private let privacyPolicyButton = UIButton(type: .system)
    private var isAgreed = false

    private let loginButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)

    private var countdownTimer: Timer?
    private var countdown = 0
    private var isEmailMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        view.backgroundColor = .themeBackground
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Logo
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        // 标题
        titleLabel.text = "登录"
        titleLabel.font = ScreenAdapter.boldFont(28)
        titleLabel.textColor = .label

        // 副标题
        subtitleLabel.text = "欢迎回来，登录您的账号"
        subtitleLabel.font = ScreenAdapter.font(16)
        subtitleLabel.textColor = .secondaryLabel

        // 顶部标题区域
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = ScreenAdapter.scaleH(6)

        let headerStack = UIStackView(arrangedSubviews: [logoView, titleStack])
        headerStack.axis = .horizontal
        headerStack.spacing = ScreenAdapter.scaleW(16)
        headerStack.alignment = .center

        // 卡片
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(20)
        cardView.layer.masksToBounds = false

        // Tab 容器
        tabContainer.backgroundColor = .themeBackground
        tabContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)

        phoneTabButton.setTitle("手机号登录", for: .normal)
        phoneTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        phoneTabButton.setTitleColor(.themePrimary, for: .selected)
        phoneTabButton.setTitleColor(.secondaryLabel, for: .normal)
        phoneTabButton.backgroundColor = .white
        phoneTabButton.layer.cornerRadius = ScreenAdapter.scaleW(6)
        phoneTabButton.isSelected = true
        phoneTabButton.addTarget(self, action: #selector(switchToPhone), for: .touchUpInside)

        emailTabButton.setTitle("邮箱登录", for: .normal)
        emailTabButton.titleLabel?.font = ScreenAdapter.font(16)
        emailTabButton.setTitleColor(.themePrimary, for: .selected)
        emailTabButton.setTitleColor(.secondaryLabel, for: .normal)
        emailTabButton.backgroundColor = .clear
        emailTabButton.layer.cornerRadius = ScreenAdapter.scaleW(6)
        emailTabButton.addTarget(self, action: #selector(switchToEmail), for: .touchUpInside)

        tabContainer.addSubview(phoneTabButton)
        tabContainer.addSubview(emailTabButton)

        phoneTabButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(4))
            make.top.bottom.equalToSuperview().inset(ScreenAdapter.scaleH(4))
            make.width.equalTo(emailTabButton)
        }
        emailTabButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
            make.top.bottom.equalToSuperview().inset(ScreenAdapter.scaleH(4))
            make.leading.equalTo(phoneTabButton.snp.trailing).offset(ScreenAdapter.scaleW(4))
        }

        // 输入框
        phoneField.placeholder = "手机号"
        phoneField.textField.keyboardType = .numberPad
        phoneField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        emailField.placeholder = "邮箱地址"
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocapitalizationType = .none
        emailField.isHidden = true
        emailField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        codeField.placeholder = "验证码"
        codeField.sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        codeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

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

        // 登录按钮
        loginButton.setTitle("下一步", for: .normal)
        loginButton.backgroundColor = .themePrimary
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        loginButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        loginButton.alpha = 0.5
        loginButton.isEnabled = false
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)

        // 注册按钮
        registerButton.setTitle("没有账号？去注册", for: .normal)
        registerButton.titleLabel?.font = ScreenAdapter.font(14)
        registerButton.setTitleColor(.secondaryLabel, for: .normal)
        registerButton.addTarget(self, action: #selector(goRegister), for: .touchUpInside)

        // 卡片内内容
        let cardContentStack = UIStackView(arrangedSubviews: [
            tabContainer, phoneField, emailField, codeField, agreementStack
        ])
        cardContentStack.axis = .vertical
        cardContentStack.spacing = ScreenAdapter.scaleH(16)

        cardView.addSubview(cardContentStack)
        cardContentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(28))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(20))
        }

        tabContainer.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let bottomStack = UIStackView(arrangedSubviews: [loginButton, registerButton])
        bottomStack.axis = .vertical
        bottomStack.spacing = ScreenAdapter.scaleH(12)
        bottomStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [headerStack, cardView, bottomStack])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(24)
        contentView.addSubview(mainStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(40))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(20))
        }
        logoView.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(68))
        }
        loginButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
            make.leading.trailing.equalToSuperview()
        }
    }

    @objc private func textFieldDidChange() {
        updateLoginButtonState()
    }

    private func updateLoginButtonState() {
        let hasAccount = isEmailMode
            ? isValidEmail(emailField.textField.text ?? "")
            : AppUtility.isValidPhone(phoneField.textField.text ?? "")
        let hasCode = !(codeField.textField.text ?? "").isEmpty
        let enabled = hasAccount && hasCode && isAgreed
        loginButton.isEnabled = enabled
        loginButton.alpha = enabled ? 1.0 : 0.5
    }

    @objc private func toggleAgreement() {
        isAgreed.toggle()
        agreementCheckBox.isSelected = isAgreed
        updateLoginButtonState()
    }

    @objc private func openUserAgreement() {
        // TODO: 打开用户协议页面
        AppUtility.showToast("用户协议")
    }

    @objc private func openPrivacyPolicy() {
        // TODO: 打开隐私政策页面
        AppUtility.showToast("隐私政策")
    }

    @objc private func switchToPhone() {
        isEmailMode = false
        phoneTabButton.isSelected = true
        phoneTabButton.backgroundColor = .white
        phoneTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        emailTabButton.isSelected = false
        emailTabButton.backgroundColor = .clear
        emailTabButton.titleLabel?.font = ScreenAdapter.font(16)
        phoneField.isHidden = false
        emailField.isHidden = true
        codeField.textField.text = ""
        updateLoginButtonState()
    }

    @objc private func switchToEmail() {
        isEmailMode = true
        phoneTabButton.isSelected = false
        phoneTabButton.backgroundColor = .clear
        phoneTabButton.titleLabel?.font = ScreenAdapter.font(16)
        emailTabButton.isSelected = true
        emailTabButton.backgroundColor = .white
        emailTabButton.titleLabel?.font = ScreenAdapter.mediumFont(16)
        phoneField.isHidden = true
        emailField.isHidden = false
        codeField.textField.text = ""
        updateLoginButtonState()
    }

    // MARK: - 发送验证码
    @objc private func sendCode() {
        if isEmailMode {
            let email = emailField.textField.text ?? ""
            guard isValidEmail(email) else {
                AppUtility.showToast("请输入正确的邮箱")
                return
            }
            Task {
                do {
                    let response: APIResponse<EmptyData> = try await APIClient.shared.request(.sendEmailCode(email: email))
                    if response.status == 200 {
                        AppUtility.showToast("验证码已发送")
                        startCountdown()
                    } else {
                        AppUtility.showToast(response.msg)
                    }
                } catch {
                    AppUtility.showToast("发送失败: \(error.localizedDescription)")
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
                    let response: APIResponse<EmptyData> = try await APIClient.shared.request(.sendSMSCode(phone: phone))
                    if response.status == 200 {
                        AppUtility.showToast("验证码已发送")
                        startCountdown()
                    } else {
                        AppUtility.showToast(response.msg)
                    }
                } catch {
                    AppUtility.showToast("发送失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
        return predicate.evaluate(with: email)
    }

    // MARK: - 登录
    @objc private func login() {
        guard isAgreed else {
            AppUtility.showToast("请先同意用户协议和隐私政策")
            return
        }

        let code = codeField.textField.text ?? ""
        guard code.count >= 4 else {
            AppUtility.showToast("请输入验证码")
            return
        }

        loginButton.isEnabled = false
        loginButton.setTitle("登录中...", for: .normal)

        if isEmailMode {
            let email = emailField.textField.text ?? ""
            guard isValidEmail(email) else {
                AppUtility.showToast("请输入正确的邮箱")
                resetLoginButton()
                return
            }
            Task {
                do {
                    let response = try await APIClient.shared.requestRaw(.loginWithEmail(email: email, code: code))
                    self.handleLoginResponse(response)
                } catch {
                    AppUtility.showToast("登录失败: \(error.localizedDescription)")
                    self.resetLoginButton()
                }
            }
        } else {
            let phone = phoneField.textField.text ?? ""
            guard AppUtility.isValidPhone(phone) else {
                AppUtility.showToast("请输入正确的手机号")
                resetLoginButton()
                return
            }
            Task {
                do {
                    let response = try await APIClient.shared.requestRaw(.login(phone: phone, code: code))
                    self.handleLoginResponse(response)
                } catch {
                    AppUtility.showToast("登录失败: \(error.localizedDescription)")
                    self.resetLoginButton()
                }
            }
        }
    }

    private func resetLoginButton() {
        loginButton.isEnabled = true
        loginButton.setTitle("下一步", for: .normal)
    }

    private func handleLoginResponse(_ response: [String: Any]) {
        guard let data = response["data"] as? [String: Any],
              let uid = data["uid"] as? String,
              let token = data["token"] as? String else {
            AppUtility.showToast(response["msg"] as? String ?? "登录失败")
            self.resetLoginButton()
            return
        }

        UserDefaults.standard.set(uid, forKey: "uid")
        UserDefaults.standard.set(token, forKey: "token")
        if let phone = data["phone"] as? String {
            UserDefaults.standard.set(phone, forKey: "phone")
        }
        if let email = data["email"] as? String {
            UserDefaults.standard.set(email, forKey: "email")
        }
        if let name = data["name"] as? String {
            UserDefaults.standard.set(name, forKey: "name")
        }

        self.resetLoginButton()

        IMManager.shared.connect()
        self.showMainScreen()
    }

    // MARK: - 跳转注册
    @objc private func goRegister() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
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
        navigationController?.setViewControllers([vc], animated: true)
    }
}

// MARK: - 注册页
class RegisterViewController: UIViewController {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let cardView = UIView()

    private let phoneField = PhoneFloatingLabelField()
    private let nameField = FloatingLabelTextField()
    private let codeField = CodeFloatingLabelField()

    private let agreementCheckBox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private let userAgreementButton = UIButton(type: .system)
    private let privacyPolicyButton = UIButton(type: .system)
    private var isAgreed = false

    private let registerButton = UIButton(type: .system)
    private var countdown = 0
    private var countdownTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        view.backgroundColor = .themeBackground
        title = "注册"
        navigationController?.setNavigationBarHidden(false, animated: false)

        // 标题
        titleLabel.text = "注册账号"
        titleLabel.font = ScreenAdapter.boldFont(28)
        titleLabel.textColor = .label

        subtitleLabel.text = "创建您的 Milo 账号"
        subtitleLabel.font = ScreenAdapter.font(16)
        subtitleLabel.textColor = .secondaryLabel

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = ScreenAdapter.scaleH(6)

        // 卡片
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(20)
        cardView.layer.masksToBounds = false

        // 输入框
        phoneField.placeholder = "手机号"
        phoneField.textField.keyboardType = .numberPad
        phoneField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        nameField.placeholder = "昵称"
        nameField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        codeField.placeholder = "验证码"
        codeField.sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        codeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

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

        privacyPolicyButton.setTitle("《隐私政策》", for: .normal)
        privacyPolicyButton.titleLabel?.font = ScreenAdapter.font(14)
        privacyPolicyButton.setTitleColor(.themePrimary, for: .normal)

        let agreementStack = UIStackView(arrangedSubviews: [
            agreementCheckBox, agreementLabel, userAgreementButton, privacyPolicyButton
        ])
        agreementStack.axis = .horizontal
        agreementStack.spacing = ScreenAdapter.scaleW(4)
        agreementStack.alignment = .center

        agreementCheckBox.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(22))
        }

        // 注册按钮
        registerButton.setTitle("注册", for: .normal)
        registerButton.backgroundColor = .themePrimary
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        registerButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        registerButton.alpha = 0.5
        registerButton.isEnabled = false
        registerButton.addTarget(self, action: #selector(register), for: .touchUpInside)

        // 卡片内容
        let cardContentStack = UIStackView(arrangedSubviews: [
            phoneField, nameField, codeField, agreementStack
        ])
        cardContentStack.axis = .vertical
        cardContentStack.spacing = ScreenAdapter.scaleH(16)

        cardView.addSubview(cardContentStack)
        cardContentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(28))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(20))
        }

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [titleStack, cardView, registerButton])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(24)
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
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(20))
        }
        registerButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
            make.leading.trailing.equalToSuperview()
        }
    }

    @objc private func textFieldDidChange() {
        updateRegisterButtonState()
    }

    private func updateRegisterButtonState() {
        let hasPhone = AppUtility.isValidPhone(phoneField.textField.text ?? "")
        let hasName = !(nameField.textField.text ?? "").isEmpty
        let hasCode = !(codeField.textField.text ?? "").isEmpty
        let enabled = hasPhone && hasName && hasCode && isAgreed
        registerButton.isEnabled = enabled
        registerButton.alpha = enabled ? 1.0 : 0.5
    }

    @objc private func toggleAgreement() {
        isAgreed.toggle()
        agreementCheckBox.isSelected = isAgreed
        updateRegisterButtonState()
    }

    @objc private func sendCode() {
        let phone = phoneField.textField.text ?? ""
        guard AppUtility.isValidPhone(phone) else {
            AppUtility.showToast("请输入正确的手机号")
            return
        }
        Task {
            do {
                let response: APIResponse<EmptyData> = try await APIClient.shared.request(.sendSMSCode(phone: phone))
                if response.status == 200 {
                    AppUtility.showToast("验证码已发送")
                    startCountdown()
                }
            } catch {
                AppUtility.showToast("发送失败")
            }
        }
    }

    @objc private func register() {
        guard isAgreed else {
            AppUtility.showToast("请先同意用户协议和隐私政策")
            return
        }

        let phone = phoneField.textField.text ?? ""
        let name = nameField.textField.text ?? ""
        let code = codeField.textField.text ?? ""

        guard AppUtility.isValidPhone(phone) else {
            AppUtility.showToast("请输入正确的手机号")
            return
        }
        guard !name.isEmpty else {
            AppUtility.showToast("请输入昵称")
            return
        }
        guard code.count >= 4 else {
            AppUtility.showToast("请输入验证码")
            return
        }

        registerButton.isEnabled = false
        registerButton.setTitle("注册中...", for: .normal)

        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.register(phone: phone, code: code, name: name))
                DispatchQueue.main.async {
                    self.registerButton.isEnabled = true
                    self.registerButton.setTitle("注册", for: .normal)
                    if response["status"] as? Int == 200 {
                        AppUtility.showToast("注册成功")
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        AppUtility.showToast(response["msg"] as? String ?? "注册失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.registerButton.isEnabled = true
                    self.registerButton.setTitle("注册", for: .normal)
                    AppUtility.showToast("注册失败")
                }
            }
        }
    }

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

struct EmptyData: Codable {}
