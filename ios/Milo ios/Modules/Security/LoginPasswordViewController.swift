import UIKit
import SnapKit

class LoginPasswordViewController: UIViewController {

    private enum VerifyMode { case phone, email }
    private var verifyMode: VerifyMode = .phone

    private let accountLabel = UILabel()
    private let pwdField = UITextField()
    private let codeField = UITextField()
    private let getCodeButton = UIButton(type: .system)
    private let submitButton = UIButton(type: .system)
    private var countdownTimer: Timer?
    private var countdown = 0

    private var bindPhone: String { UserDefaults.standard.string(forKey: "bind_phone") ?? "" }
    private var bindEmail: String { UserDefaults.standard.string(forKey: "bind_email") ?? "" }

    override func viewDidLoad() {
        super.viewDidLoad()
        verifyMode = bindPhone.isEmpty ? .email : .phone
        setupUI()
    }

    private func setupUI() {
        title = "修改登录密码"
        view.backgroundColor = .themeBackground

        accountLabel.font = ScreenAdapter.font(14)
        accountLabel.textColor = .secondaryLabel

        pwdField.placeholder = "请输入新密码(6-20位)"
        pwdField.isSecureTextEntry = true
        pwdField.borderStyle = .roundedRect
        pwdField.font = ScreenAdapter.font(16)

        codeField.placeholder = "请输入验证码"
        codeField.borderStyle = .roundedRect
        codeField.keyboardType = .numberPad
        codeField.font = ScreenAdapter.font(16)

        getCodeButton.setTitle("获取验证码", for: .normal)
        getCodeButton.titleLabel?.font = ScreenAdapter.font(14)
        getCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)

        let codeRow = UIStackView(arrangedSubviews: [codeField, getCodeButton])
        codeRow.axis = .horizontal
        codeRow.spacing = 12
        codeRow.distribution = .fill

        submitButton.setTitle("确认修改", for: .normal)
        submitButton.titleLabel?.font = ScreenAdapter.font(17)
        submitButton.backgroundColor = .themePrimary
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [accountLabel, pwdField, codeRow, submitButton])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(16)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }

        pwdField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        codeField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        getCodeButton.snp.makeConstraints { make in make.width.equalTo(ScreenAdapter.scaleW(100)) }
        submitButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }

        updateAccountLabel()
    }

    private func updateAccountLabel() {
        switch verifyMode {
        case .phone:
            let p = bindPhone
            if p.count >= 7 {
                accountLabel.text = "手机号: \(p.prefix(3))****\(p.suffix(4))"
            } else {
                accountLabel.text = "未绑定手机号"
            }
        case .email:
            accountLabel.text = "邮箱: \(bindEmail)"
        }
    }

    @objc private func getCode() {
        switch verifyMode {
        case .phone:
            guard !bindPhone.isEmpty else { AppUtility.showToast("未绑定手机号"); return }
            sendCode(zone: "+86", phone: bindPhone)
        case .email:
            guard !bindEmail.isEmpty else { AppUtility.showToast("未绑定邮箱"); return }
            sendEmailCode(email: bindEmail)
        }
    }

    private func sendCode(zone: String, phone: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.sendChangePwdPhoneCode(zone: zone, phone: phone))
                DispatchQueue.main.async { self.startCountdown() }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("发送失败") }
            }
        }
    }

    private func sendEmailCode(email: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.sendChangePwdEmailCode(email: email))
                DispatchQueue.main.async { self.startCountdown() }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("发送失败") }
            }
        }
    }

    private func startCountdown() {
        countdown = 60
        getCodeButton.isEnabled = false
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 {
                t.invalidate()
                self.getCodeButton.setTitle("获取验证码", for: .normal)
                self.getCodeButton.isEnabled = true
            } else {
                self.getCodeButton.setTitle("\(self.countdown)秒", for: .normal)
            }
        }
    }

    @objc private func submit() {
        guard let pwd = pwdField.text, pwd.count >= 6, pwd.count <= 20 else {
            AppUtility.showToast("密码需6-20位"); return
        }
        guard let code = codeField.text, code.count == 6 else {
            AppUtility.showToast("请输入6位验证码"); return
        }

        submitButton.isEnabled = false
        Task {
            do {
                let resp: [String: Any]
                switch self.verifyMode {
                case .phone:
                    resp = try await APIClient.shared.requestRaw(.changePwdByPhone(zone: "+86", phone: self.bindPhone, code: code, pwd: pwd))
                case .email:
                    resp = try await APIClient.shared.requestRaw(.changePwdByEmail(email: self.bindEmail, code: code, pwd: pwd))
                }
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    if status == 200 {
                        AppUtility.showToast("密码修改成功，请重新登录")
                        self.exitLogin()
                    } else {
                        AppUtility.showToast(resp["msg"] as? String ?? "修改失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }

    private func exitLogin() {
        IMManager.shared.disconnect()
        LocalStore.shared.clearAll()
        let loginVC = LoginViewController()
        view.window?.rootViewController = UINavigationController(rootViewController: loginVC)
    }
}
