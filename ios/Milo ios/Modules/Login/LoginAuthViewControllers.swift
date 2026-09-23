import UIKit
import SnapKit

// MARK: - 登录授权验证页
class LoginAuthViewController: UIViewController {

    private let uid: String
    private let phone: String

    private let shieldIcon = UIImageView()
    private let descLabel = UILabel()
    private let phoneLabel = UILabel()
    private let startButton = UIButton(type: .system)

    init(uid: String, phone: String) {
        self.uid = uid
        self.phone = phone
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "登录授权"
        view.backgroundColor = .themeBackground
        setupUI()
    }

    private func setupUI() {
        shieldIcon.image = UIImage(systemName: "checkmark.shield.fill")
        shieldIcon.tintColor = .themePrimary
        shieldIcon.contentMode = .scaleAspectFit

        descLabel.text = "为保障账号安全，请进行身份验证"
        descLabel.font = ScreenAdapter.font(15)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0

        phoneLabel.text = "手机号  \(phone)"
        phoneLabel.font = ScreenAdapter.mediumFont(17)
        phoneLabel.textColor = .label
        phoneLabel.textAlignment = .center

        startButton.setTitle("开始验证", for: .normal)
        startButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        startButton.backgroundColor = .themePrimary
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        startButton.addTarget(self, action: #selector(startVerify), for: .touchUpInside)

        view.addSubviews(shieldIcon, descLabel, phoneLabel, startButton)

        shieldIcon.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(60))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(80))
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(shieldIcon.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(32))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(32))
        }
        phoneLabel.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.centerX.equalToSuperview()
        }
        startButton.snp.makeConstraints { make in
            make.top.equalTo(phoneLabel.snp.bottom).offset(ScreenAdapter.scaleH(40))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
    }

    @objc private func startVerify() {
        startButton.isEnabled = false
        Task {
            do {
                let resp: APIResponse<EmptyData> = try await APIClient.shared.request(.sendLoginAuthCode(uid: uid))
                DispatchQueue.main.async {
                    self.startButton.isEnabled = true
                    if resp.status == 200 {
                        let vc = InputLoginAuthCodeViewController(uid: self.uid, phone: self.phone)
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        AppUtility.showToast(resp.msg ?? "操作失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.startButton.isEnabled = true
                    AppUtility.showToast("发送验证码失败")
                }
            }
        }
    }
}

// MARK: - 登录验证码二次输入页
class InputLoginAuthCodeViewController: UIViewController {

    private let uid: String
    private let phone: String

    private let descLabel = UILabel()
    private let codeField = UITextField()
    private let sendCodeButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private var countdown = 0
    private var countdownTimer: Timer?

    init(uid: String, phone: String) {
        self.uid = uid
        self.phone = phone
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "验证"
        view.backgroundColor = .themeBackground
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        descLabel.text = "已发送至 \(phone) 的验证码"
        descLabel.font = ScreenAdapter.font(14)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center

        codeField.placeholder = "请输入验证码"
        codeField.borderStyle = .roundedRect
        codeField.keyboardType = .numberPad
        codeField.font = ScreenAdapter.font(16)
        codeField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        sendCodeButton.setTitle("获取验证码", for: .normal)
        sendCodeButton.titleLabel?.font = ScreenAdapter.font(14)
        sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)

        let codeStack = UIStackView(arrangedSubviews: [codeField, sendCodeButton])
        codeStack.axis = .horizontal
        codeStack.spacing = ScreenAdapter.scaleW(8)
        sendCodeButton.widthAnchor.constraint(equalToConstant: ScreenAdapter.scaleW(100)).isActive = true

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        confirmButton.backgroundColor = .themePrimary
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.setTitleColor(.lightText, for: .disabled)
        confirmButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        confirmButton.isEnabled = false
        confirmButton.alpha = 0.3
        confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [descLabel, codeStack, confirmButton])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(20)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(40))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        codeStack.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        confirmButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }

        startCountdown()
    }

    @objc private func textChanged() {
        let hasText = !(codeField.text ?? "").isEmpty
        confirmButton.isEnabled = hasText
        confirmButton.alpha = hasText ? 1.0 : 0.3
    }

    @objc private func sendCode() {
        Task {
            do {
                let resp: APIResponse<EmptyData> = try await APIClient.shared.request(.sendLoginAuthCode(uid: uid))
                if resp.status == 200 {
                    AppUtility.showToast("验证码已发送")
                    startCountdown()
                } else {
                    AppUtility.showToast(resp.msg ?? "操作失败")
                }
            } catch {
                AppUtility.showToast("发送失败")
            }
        }
    }

    @objc private func confirm() {
        let code = codeField.text ?? ""
        guard !code.isEmpty else { return }

        confirmButton.isEnabled = false
        confirmButton.setTitle("验证中...", for: .normal)

        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.checkLoginAuth(uid: uid, code: code))
                DispatchQueue.main.async {
                    self.confirmButton.isEnabled = true
                    self.confirmButton.setTitle("确定", for: .normal)
                    if resp["status"] as? Int == 200 {
                        let name = UserDefaults.standard.string(forKey: "name") ?? ""
                        if name.isEmpty {
                            self.navigationController?.pushViewController(PerfectUserInfoViewController(), animated: true)
                        } else {
                            IMManager.shared.connect()
                            self.showMainScreen()
                        }
                    } else {
                        AppUtility.showToast(resp["msg"] as? String ?? "验证失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.confirmButton.isEnabled = true
                    self.confirmButton.setTitle("确定", for: .normal)
                    AppUtility.showToast("验证失败")
                }
            }
        }
    }

    private func startCountdown() {
        countdown = 60
        sendCodeButton.isEnabled = false
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
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
