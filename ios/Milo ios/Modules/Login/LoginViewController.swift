import UIKit
import SnapKit

// MARK: - 登录页
class LoginViewController: UIViewController {

    private let phoneField = UITextField()
    private let emailField = UITextField()
    private let codeField = UITextField()
    private let sendCodeButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)
    private let phoneTabButton = UIButton(type: .system)
    private let emailTabButton = UIButton(type: .system)
    private var countdownTimer: Timer?
    private var countdown = 0
    private var isEmailMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .themeBackground

        let logoLabel = UILabel()
        logoLabel.text = "Milo"
        logoLabel.font = ScreenAdapter.boldFont(32)
        logoLabel.textColor = .themePrimary
        logoLabel.textAlignment = .center

        phoneTabButton.setTitle("手机号登录", for: .normal)
        phoneTabButton.titleLabel?.font = ScreenAdapter.mediumFont(15)
        phoneTabButton.setTitleColor(.themePrimary, for: .selected)
        phoneTabButton.setTitleColor(.secondaryLabel, for: .normal)
        phoneTabButton.isSelected = true
        phoneTabButton.addTarget(self, action: #selector(switchToPhone), for: .touchUpInside)

        emailTabButton.setTitle("邮箱登录", for: .normal)
        emailTabButton.titleLabel?.font = ScreenAdapter.mediumFont(15)
        emailTabButton.setTitleColor(.themePrimary, for: .selected)
        emailTabButton.setTitleColor(.secondaryLabel, for: .normal)
        emailTabButton.addTarget(self, action: #selector(switchToEmail), for: .touchUpInside)

        let tabStack = UIStackView(arrangedSubviews: [phoneTabButton, emailTabButton])
        tabStack.axis = .horizontal
        tabStack.spacing = ScreenAdapter.scaleW(24)
        tabStack.distribution = .fillEqually

        phoneField.placeholder = "请输入手机号"
        phoneField.borderStyle = .roundedRect
        phoneField.keyboardType = .numberPad
        phoneField.font = ScreenAdapter.font(16)

        emailField.placeholder = "请输入邮箱"
        emailField.borderStyle = .roundedRect
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.font = ScreenAdapter.font(16)
        emailField.isHidden = true

        codeField.placeholder = "请输入验证码"
        codeField.borderStyle = .roundedRect
        codeField.keyboardType = .numberPad
        codeField.font = ScreenAdapter.font(16)

        sendCodeButton.setTitle("获取验证码", for: .normal)
        sendCodeButton.titleLabel?.font = ScreenAdapter.font(14)
        sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)

        loginButton.setTitle("登录", for: .normal)
        loginButton.backgroundColor = .themePrimary
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        loginButton.layer.cornerRadius = ScreenAdapter.scaleW(8)
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)

        registerButton.setTitle("没有账号？去注册", for: .normal)
        registerButton.titleLabel?.font = ScreenAdapter.font(14)
        registerButton.addTarget(self, action: #selector(goRegister), for: .touchUpInside)

        let codeStack = UIStackView(arrangedSubviews: [codeField, sendCodeButton])
        codeStack.axis = .horizontal
        codeStack.spacing = ScreenAdapter.scaleW(8)
        sendCodeButton.widthAnchor.constraint(equalToConstant: ScreenAdapter.scaleW(100)).isActive = true

        let stack = UIStackView(arrangedSubviews: [logoLabel, tabStack, phoneField, emailField, codeStack, loginButton, registerButton])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let horizontalPadding = ScreenAdapter.scaleW(24)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: ScreenAdapter.scaleH(-40))
        ])
    }

    @objc private func switchToPhone() {
        isEmailMode = false
        phoneTabButton.isSelected = true
        emailTabButton.isSelected = false
        phoneField.isHidden = false
        emailField.isHidden = true
        codeField.text = ""
    }

    @objc private func switchToEmail() {
        isEmailMode = true
        phoneTabButton.isSelected = false
        emailTabButton.isSelected = true
        phoneField.isHidden = true
        emailField.isHidden = false
        codeField.text = ""
    }

    // MARK: - 发送验证码
    @objc private func sendCode() {
        if isEmailMode {
            let email = emailField.text ?? ""
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
            let phone = phoneField.text ?? ""
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
        let code = codeField.text ?? ""
        guard code.count >= 4 else {
            AppUtility.showToast("请输入验证码")
            return
        }

        loginButton.isEnabled = false
        loginButton.setTitle("登录中...", for: .normal)

        if isEmailMode {
            let email = emailField.text ?? ""
            guard isValidEmail(email) else {
                AppUtility.showToast("请输入正确的邮箱")
                loginButton.isEnabled = true
                loginButton.setTitle("登录", for: .normal)
                return
            }
            Task {
                do {
                    let response = try await APIClient.shared.requestRaw(.loginWithEmail(email: email, code: code))
                    self.handleLoginResponse(response)
                } catch {
                    AppUtility.showToast("登录失败: \(error.localizedDescription)")
                    self.loginButton.isEnabled = true
                    self.loginButton.setTitle("登录", for: .normal)
                }
            }
        } else {
            let phone = phoneField.text ?? ""
            guard AppUtility.isValidPhone(phone) else {
                AppUtility.showToast("请输入正确的手机号")
                loginButton.isEnabled = true
                loginButton.setTitle("登录", for: .normal)
                return
            }
            Task {
                do {
                    let response = try await APIClient.shared.requestRaw(.login(phone: phone, code: code))
                    self.handleLoginResponse(response)
                } catch {
                    AppUtility.showToast("登录失败: \(error.localizedDescription)")
                    self.loginButton.isEnabled = true
                    self.loginButton.setTitle("登录", for: .normal)
                }
            }
        }
    }

    private func handleLoginResponse(_ response: [String: Any]) {
        guard let data = response["data"] as? [String: Any],
              let uid = data["uid"] as? String,
              let token = data["token"] as? String else {
            AppUtility.showToast(response["msg"] as? String ?? "登录失败")
            self.loginButton.isEnabled = true
            self.loginButton.setTitle("登录", for: .normal)
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

        self.loginButton.isEnabled = true
        self.loginButton.setTitle("登录", for: .normal)

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
        sendCodeButton.isEnabled = false
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.countdown <= 0 {
                self.sendCodeButton.setTitle("获取验证码", for: .normal)
                self.sendCodeButton.isEnabled = true
                self.countdownTimer?.invalidate()
            } else {
                self.sendCodeButton.setTitle("\(self.countdown)s", for: .normal)
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

    private let phoneField = UITextField()
    private let nameField = UITextField()
    private let codeField = UITextField()
    private let sendCodeButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)
    private var countdown = 0
    private var countdownTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .themeBackground
        title = "注册"

        phoneField.placeholder = "手机号"
        phoneField.borderStyle = .roundedRect
        phoneField.keyboardType = .numberPad
        phoneField.font = ScreenAdapter.font(16)

        nameField.placeholder = "昵称"
        nameField.borderStyle = .roundedRect
        nameField.font = ScreenAdapter.font(16)

        codeField.placeholder = "验证码"
        codeField.borderStyle = .roundedRect
        codeField.keyboardType = .numberPad
        codeField.font = ScreenAdapter.font(16)

        sendCodeButton.setTitle("获取验证码", for: .normal)
        sendCodeButton.titleLabel?.font = ScreenAdapter.font(14)
        sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)

        registerButton.setTitle("注册", for: .normal)
        registerButton.backgroundColor = .themePrimary
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        registerButton.layer.cornerRadius = ScreenAdapter.scaleW(8)
        registerButton.addTarget(self, action: #selector(register), for: .touchUpInside)

        let codeStack = UIStackView(arrangedSubviews: [codeField, sendCodeButton])
        codeStack.axis = .horizontal
        codeStack.spacing = ScreenAdapter.scaleW(8)
        sendCodeButton.widthAnchor.constraint(equalToConstant: ScreenAdapter.scaleW(100)).isActive = true

        let stack = UIStackView(arrangedSubviews: [phoneField, nameField, codeStack, registerButton])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let horizontalPadding = ScreenAdapter.scaleW(24)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScreenAdapter.scaleH(40))
        ])
    }

    @objc private func sendCode() {
        let phone = phoneField.text ?? ""
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
        let phone = phoneField.text ?? ""
        let name = nameField.text ?? ""
        let code = codeField.text ?? ""

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

        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.register(phone: phone, code: code, name: name))
                if response["status"] as? Int == 200 {
                    AppUtility.showToast("注册成功")
                    navigationController?.popViewController(animated: true)
                } else {
                    AppUtility.showToast(response["msg"] as? String ?? "注册失败")
                }
            } catch {
                AppUtility.showToast("注册失败")
            }
        }
    }

    private func startCountdown() {
        countdown = 60
        sendCodeButton.isEnabled = false
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.countdown <= 0 {
                self.sendCodeButton.setTitle("获取验证码", for: .normal)
                self.sendCodeButton.isEnabled = true
                self.countdownTimer?.invalidate()
            } else {
                self.sendCodeButton.setTitle("\(self.countdown)s", for: .normal)
                self.countdown -= 1
            }
        }
    }
}

struct EmptyData: Codable {}
