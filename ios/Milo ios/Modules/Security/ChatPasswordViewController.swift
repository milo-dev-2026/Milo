import UIKit
import SnapKit

// MARK: - 聊天密码（对照 Android 聊天密码设置页）
class ChatPasswordViewController: UIViewController {

    private let loginPwdField = UITextField()
    private let chatPwdField = UITextField()
    private let confirmPwdField = UITextField()
    private let submitButton = UIButton(type: .system)

    private var uid: String { UserDefaults.standard.string(forKey: "uid") ?? "" }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "聊天密码"
        view.backgroundColor = .themeBackground
        setupUI()
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "验证您的登录密码"
        titleLabel.font = ScreenAdapter.boldFont(22)
        titleLabel.textColor = .label
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }

        let descLabel = UILabel()
        descLabel.text = "请确认您的登录密码后，再设定6位数字的聊天密码"
        descLabel.font = ScreenAdapter.font(13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        view.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }

        styleField(loginPwdField, placeholder: "请输入登录密码", keyboardType: .default)
        styleField(chatPwdField, placeholder: "请输入6位数字聊天密码", keyboardType: .numberPad)
        styleField(confirmPwdField, placeholder: "再次输入6位数字聊天密码", keyboardType: .numberPad)

        let stack = UIStackView(arrangedSubviews: [loginPwdField, chatPwdField, confirmPwdField])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(14)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(ScreenAdapter.scaleH(24))
            make.leading.trailing.equalTo(titleLabel)
        }

        for field in [loginPwdField, chatPwdField, confirmPwdField] {
            field.snp.makeConstraints { make in
                make.height.equalTo(ScreenAdapter.scaleH(50))
            }
        }

        submitButton.setTitle("确认", for: .normal)
        submitButton.titleLabel?.font = ScreenAdapter.boldFont(17)
        submitButton.backgroundColor = .themePrimary
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        view.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
    }

    private func styleField(_ field: UITextField, placeholder: String, keyboardType: UIKeyboardType) {
        field.placeholder = placeholder
        field.isSecureTextEntry = true
        field.keyboardType = keyboardType
        field.font = ScreenAdapter.font(16)
        field.backgroundColor = .white
        field.layer.cornerRadius = 10
        field.layer.borderWidth = 0.5
        field.layer.borderColor = UIColor.themeSeparatorLight.cgColor
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftView = padding
        field.leftViewMode = .always
        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.rightView = rightPadding
        field.rightViewMode = .always
    }

    @objc private func submit() {
        guard let loginPwd = loginPwdField.text, !loginPwd.isEmpty else {
            AppUtility.showToast("请输入登录密码")
            return
        }
        guard let pwd = chatPwdField.text, pwd.count == 6, pwd.allSatisfy({ $0.isNumber }) else {
            AppUtility.showToast("聊天密码需为6位数字")
            return
        }
        guard pwd == confirmPwdField.text else {
            AppUtility.showToast("两次输入的聊天密码不一致")
            return
        }

        UserDefaults.standard.set(pwd, forKey: "chat_pwd_\(uid)")
        UserDefaults.standard.set(true, forKey: "chat_pwd_set_\(uid)")
        AppUtility.showToast("设置成功")
        navigationController?.popViewController(animated: true)
    }
}
