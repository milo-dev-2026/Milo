import UIKit
import SnapKit

// MARK: - 修改类型（对照 Android UpdateUserInfoActivity 的 updateType）
enum UpdateUserInfoType {
    case name
    case shortNo
}

// MARK: - 修改用户信息（昵称 / Milo号）
class UpdateUserInfoViewController: UIViewController {

    // MARK: - 属性
    private let type: UpdateUserInfoType

    private var maxLength: Int {
        switch type {
        case .name: return 100
        case .shortNo: return 20
        }
    }

    // MARK: - UI 元素
    private let inputCard = UIView()
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)

    // MARK: - 初始化
    init(type: UpdateUserInfoType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentValue()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    // MARK: - 布局
    private func setupUI() {
        title = (type == .name) ? "修改昵称" : "修改Milo号"
        view.backgroundColor = .themeBackground

        // 输入框卡片（白色圆角）
        inputCard.backgroundColor = .white
        inputCard.layer.cornerRadius = ScreenAdapter.scaleW(8)
        inputCard.layer.borderWidth = 1
        inputCard.layer.borderColor = UIColor.themeSeparator.cgColor
        view.addSubview(inputCard)
        inputCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(56))
        }

        textField.placeholder = (type == .name) ? "请输入昵称" : "请输入Milo号"
        textField.font = ScreenAdapter.font(16)
        textField.textColor = .label
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.delegate = self
        textField.autocapitalizationType = (type == .shortNo) ? .none : .sentences
        inputCard.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.centerY.equalToSuperview()
        }

        // 保存按钮（主题色背景、白色文字、圆角）
        saveButton.setTitle("保存", for: .normal)
        saveButton.configureAsThemeButton(fontSize: 17)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(24))
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    // MARK: - 预填当前值
    private func loadCurrentValue() {
        let defaults = UserDefaults.standard
        let key = (type == .name) ? "name" : "short_no"
        let current = defaults.string(forKey: key) ?? ""
        textField.text = current
        if !current.isEmpty {
            textField.selectedTextRange = textField.textRange(
                from: textField.endOfDocument,
                to: textField.endOfDocument
            )
        }
    }

    // MARK: - 输入验证
    private func validate(_ value: String) -> Bool {
        switch type {
        case .name:
            if value.isEmpty {
                AppUtility.showToast("昵称不能为空")
                return false
            }
        case .shortNo:
            if value.isEmpty {
                AppUtility.showToast("Milo号不能为空")
                return false
            }
            let predicate = NSPredicate(format: "SELF MATCHES %@", "^[a-zA-Z0-9]+$")
            if !predicate.evaluate(with: value) {
                AppUtility.showToast("Milo号只能包含字母和数字")
                return false
            }
        }
        return true
    }

    // MARK: - 保存
    @objc private func save() {
        let value = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard validate(value) else { return }

        saveButton.isEnabled = false
        saveButton.setTitle("保存中...", for: .normal)

        Task {
            do {
                switch type {
                case .name:
                    _ = try await APIClient.shared.requestRaw(.updateUserInfo(name: value, avatar: nil))
                    UserDefaults.standard.set(value, forKey: "name")
                case .shortNo:
                    _ = try await APIClient.shared.requestRaw(.updateUserInfo(name: nil, avatar: nil, shortNo: value))
                    UserDefaults.standard.set(value, forKey: "short_no")
                }
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("UserInfoUpdated"), object: nil)
                    AppUtility.showToast("保存成功")
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.saveButton.setTitle("保存", for: .normal)
                    AppUtility.showToast(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension UpdateUserInfoViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        save()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 禁止换行
        if string.contains("\n") { return false }
        // 限制最大长度（昵称100，Milo号20）
        let current = textField.text ?? ""
        guard let stringRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: stringRange, with: string)
        return updated.count <= maxLength
    }
}
