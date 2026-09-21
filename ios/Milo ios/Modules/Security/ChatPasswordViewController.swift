import UIKit
import SnapKit

class ChatPasswordViewController: UIViewController {

    private let loginPwdField = UITextField()
    private let chatPwdField = UITextField()
    private let confirmPwdField = UITextField()
    private let submitButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "聊天密码"
        view.backgroundColor = .themeBackground

        loginPwdField.placeholder = "请输入登录密码"
        loginPwdField.isSecureTextEntry = true
        loginPwdField.borderStyle = .roundedRect
        loginPwdField.font = ScreenAdapter.font(16)

        chatPwdField.placeholder = "请输入6位聊天密码"
        chatPwdField.isSecureTextEntry = true
        chatPwdField.borderStyle = .roundedRect
        chatPwdField.keyboardType = .numberPad
        chatPwdField.font = ScreenAdapter.font(16)

        confirmPwdField.placeholder = "请确认聊天密码"
        confirmPwdField.isSecureTextEntry = true
        confirmPwdField.borderStyle = .roundedRect
        confirmPwdField.keyboardType = .numberPad
        confirmPwdField.font = ScreenAdapter.font(16)

        submitButton.setTitle("设置聊天密码", for: .normal)
        submitButton.titleLabel?.font = ScreenAdapter.font(17)
        submitButton.backgroundColor = .themePrimary
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [loginPwdField, chatPwdField, confirmPwdField, submitButton])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }

        loginPwdField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        chatPwdField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        confirmPwdField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        submitButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }

        let existing = UserDefaults.standard.bool(forKey: "chat_password_enabled")
        if existing {
            submitButton.setTitle("修改聊天密码", for: .normal)
        }
    }

    @objc private func submit() {
        guard let loginPwd = loginPwdField.text, !loginPwd.isEmpty else {
            AppUtility.showToast("请输入登录密码"); return
        }
        guard let chatPwd = chatPwdField.text, chatPwd.count == 6 else {
            AppUtility.showToast("聊天密码必须为6位"); return
        }
        guard let confirmPwd = confirmPwdField.text, confirmPwd == chatPwd else {
            AppUtility.showToast("两次密码不一致"); return
        }

        submitButton.isEnabled = false
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.verifyLoginPwd(pwd: loginPwd))
                let status = resp["status"] as? Int ?? 0
                guard status == 200 else {
                    DispatchQueue.main.async {
                        self.submitButton.isEnabled = true
                        AppUtility.showToast(resp["msg"] as? String ?? "登录密码错误")
                    }
                    return
                }

                UserDefaults.standard.set(true, forKey: "chat_password_enabled")
                UserDefaults.standard.set(chatPwd, forKey: "chat_password")
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    AppUtility.showToast("聊天密码设置成功")
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }
}
