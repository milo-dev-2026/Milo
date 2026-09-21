import UIKit
import SnapKit

// MARK: - 密码管理（统一入口）
class PwdManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad(); title = "密码管理"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PMCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData() }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 3 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "密码管理" }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PMCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator; cell.imageView?.tintColor = .themePrimary
        switch indexPath.row {
        case 0: cell.textLabel?.text = "登录密码"; cell.imageView?.image = UIImage(systemName: "key.viewfinder"); cell.detailTextLabel?.text = "已设置"
        case 1: cell.textLabel?.text = "聊天密码"; cell.imageView?.image = UIImage(systemName: "key"); cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "chat_password_enabled") ? "已设置" : "未设置"
        case 2: cell.textLabel?.text = "锁屏密码"; cell.imageView?.image = UIImage(systemName: "lock"); cell.detailTextLabel?.text = LocalStore.shared.isAppLockEnabled ? "已设置" : "未设置"
        default: break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0: navigationController?.pushViewController(LoginPasswordViewController(), animated: true)
        case 1: navigationController?.pushViewController(ChatPasswordViewController(), animated: true)
        case 2: navigationController?.pushViewController(LockScreenPwdViewController(), animated: true)
        default: break
        }
    }
}

// MARK: - 验证密码入口
class VertifyPwdViewController: UIViewController {
    private let pwdField = UITextField()
    private let submitButton = UIButton(type: .system)
    private var target: String
    private var boundAccount: String

    init(target: String, boundAccount: String) { self.target = target; self.boundAccount = boundAccount; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "验证密码"; view.backgroundColor = .themeBackground
        pwdField.placeholder = "请输入登录密码"; pwdField.borderStyle = .roundedRect; pwdField.isSecureTextEntry = true; pwdField.font = ScreenAdapter.font(16)
        submitButton.setTitle("验证", for: .normal); submitButton.titleLabel?.font = ScreenAdapter.font(17)
        submitButton.backgroundColor = .themePrimary; submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(10); submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [pwdField, submitButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        pwdField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        submitButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func submit() {
        guard let pwd = pwdField.text, !pwd.isEmpty else { AppUtility.showToast("请输入密码"); return }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.verifyLoginPwd(pwd: pwd))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 {
                        switch self.target {
                        case "phone": self.navigationController?.pushViewController(VertifyPhoneViewController(account: self.boundAccount), animated: true)
                        case "email": self.navigationController?.pushViewController(VertifyEmailViewController(account: self.boundAccount), animated: true)
                        default: self.navigationController?.pushViewController(AccountBindingViewController(bindType: .phone), animated: true)
                        }
                    } else { AppUtility.showToast(resp["msg"] as? String ?? "密码错误") }
                }
            } catch { DispatchQueue.main.async { AppUtility.showToast("验证失败") } }
        }
    }
}

// MARK: - 验证手机
class VertifyPhoneViewController: UIViewController {
    private var account: String
    private let codeField = UITextField()
    private let getCodeButton = UIButton(type: .system)
    private let bindButton = UIButton(type: .system)
    private var countdown = 0; private var timer: Timer?

    init(account: String) { self.account = account; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "验证手机"; view.backgroundColor = .themeBackground
        codeField.placeholder = "验证码"; codeField.borderStyle = .roundedRect; codeField.keyboardType = .numberPad; codeField.font = ScreenAdapter.font(16)
        getCodeButton.setTitle("获取验证码", for: .normal); getCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)
        bindButton.setTitle("绑定", for: .normal); bindButton.titleLabel?.font = ScreenAdapter.font(17)
        bindButton.backgroundColor = .themePrimary; bindButton.setTitleColor(.white, for: .normal)
        bindButton.layer.cornerRadius = ScreenAdapter.scaleW(10); bindButton.addTarget(self, action: #selector(bind), for: .touchUpInside)
        let codeRow = UIStackView(arrangedSubviews: [codeField, getCodeButton]); codeRow.axis = .horizontal; codeRow.spacing = 12
        let stack = UIStackView(arrangedSubviews: [codeRow, bindButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        codeField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        getCodeButton.snp.makeConstraints { make in make.width.equalTo(ScreenAdapter.scaleW(100)) }
        bindButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func getCode() {
        Task {
            do { _ = try await APIClient.shared.requestRaw(.sendBindPhoneCode(zone: "+86", phone: account)); DispatchQueue.main.async { self.startCountdown() } }
            catch { DispatchQueue.main.async { AppUtility.showToast("发送失败") } }
        }
    }
    private func startCountdown() {
        countdown = 60; getCodeButton.isEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 { t.invalidate(); self.getCodeButton.setTitle("获取验证码", for: .normal); self.getCodeButton.isEnabled = true }
            else { self.getCodeButton.setTitle("\(self.countdown)秒", for: .normal) }
        }
    }
    @objc private func bind() {
        guard let code = codeField.text, code.count == 6 else { AppUtility.showToast("请输入6位验证码"); return }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.bindPhone(zone: "+86", phone: account, code: code))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 { UserDefaults.standard.set(self.account, forKey: "bind_phone"); AppUtility.showToast("绑定成功"); self.navigationController?.popViewController(animated: true) }
                    else { AppUtility.showToast(resp["msg"] as? String ?? "绑定失败") }
                }
            } catch { DispatchQueue.main.async { AppUtility.showToast("操作失败") } }
        }
    }
}

// MARK: - 验证邮箱
class VertifyEmailViewController: UIViewController {
    private var account: String
    private let codeField = UITextField()
    private let getCodeButton = UIButton(type: .system)
    private let bindButton = UIButton(type: .system)
    private var countdown = 0; private var timer: Timer?

    init(account: String) { self.account = account; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "验证邮箱"; view.backgroundColor = .themeBackground
        codeField.placeholder = "验证码"; codeField.borderStyle = .roundedRect; codeField.keyboardType = .numberPad; codeField.font = ScreenAdapter.font(16)
        getCodeButton.setTitle("获取验证码", for: .normal); getCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)
        bindButton.setTitle("绑定", for: .normal); bindButton.titleLabel?.font = ScreenAdapter.font(17)
        bindButton.backgroundColor = .themePrimary; bindButton.setTitleColor(.white, for: .normal)
        bindButton.layer.cornerRadius = ScreenAdapter.scaleW(10); bindButton.addTarget(self, action: #selector(bind), for: .touchUpInside)
        let codeRow = UIStackView(arrangedSubviews: [codeField, getCodeButton]); codeRow.axis = .horizontal; codeRow.spacing = 12
        let stack = UIStackView(arrangedSubviews: [codeRow, bindButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        codeField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        getCodeButton.snp.makeConstraints { make in make.width.equalTo(ScreenAdapter.scaleW(100)) }
        bindButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func getCode() {
        Task {
            do { _ = try await APIClient.shared.requestRaw(.sendBindEmailCode(email: account)); DispatchQueue.main.async { self.startCountdown() } }
            catch { DispatchQueue.main.async { AppUtility.showToast("发送失败") } }
        }
    }
    private func startCountdown() {
        countdown = 60; getCodeButton.isEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 { t.invalidate(); self.getCodeButton.setTitle("获取验证码", for: .normal); self.getCodeButton.isEnabled = true }
            else { self.getCodeButton.setTitle("\(self.countdown)秒", for: .normal) }
        }
    }
    @objc private func bind() {
        guard let code = codeField.text, code.count == 6 else { AppUtility.showToast("请输入6位验证码"); return }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.bindEmail(email: account, code: code))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 { UserDefaults.standard.set(self.account, forKey: "bind_email"); AppUtility.showToast("绑定成功"); self.navigationController?.popViewController(animated: true) }
                    else { AppUtility.showToast(resp["msg"] as? String ?? "绑定失败") }
                }
            } catch { DispatchQueue.main.async { AppUtility.showToast("操作失败") } }
        }
    }
}

// MARK: - 个性签名
class PersonalSignatureViewController: UIViewController {
    private let textView = UITextView()
    private let saveButton = UIButton(type: .system)
    private let hintLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad(); title = "个性签名"; view.backgroundColor = .themeBackground
        hintLabel.text = "设置个性签名，让别人更了解你"; hintLabel.font = ScreenAdapter.font(14); hintLabel.textColor = .secondaryLabel
        textView.font = ScreenAdapter.font(16); textView.layer.cornerRadius = 8; textView.layer.borderWidth = 1; textView.layer.borderColor = UIColor.systemGray5.cgColor
        textView.text = UserDefaults.standard.string(forKey: "personal_signature") ?? ""
        saveButton.setTitle("保存", for: .normal); saveButton.titleLabel?.font = ScreenAdapter.font(17)
        saveButton.backgroundColor = .themePrimary; saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10); saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [hintLabel, textView, saveButton]); stack.axis = .vertical; stack.spacing = 12
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        textView.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(120)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func save() {
        UserDefaults.standard.set(textView.text, forKey: "personal_signature")
        AppUtility.showToast("已保存"); navigationController?.popViewController(animated: true)
    }
}

// MARK: - 设置备注
class SetUserRemarkViewController: UIViewController {
    private var uid: String
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)

    init(uid: String) { self.uid = uid; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "设置备注"; view.backgroundColor = .themeBackground
        textField.placeholder = "输入备注名"; textField.borderStyle = .roundedRect; textField.font = ScreenAdapter.font(16)
        textField.text = UserDefaults.standard.string(forKey: "remark_\(uid)")
        saveButton.setTitle("保存", for: .normal); saveButton.titleLabel?.font = ScreenAdapter.font(17)
        saveButton.backgroundColor = .themePrimary; saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10); saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [textField, saveButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        textField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func save() {
        UserDefaults.standard.set(textField.text, forKey: "remark_\(uid)")
        AppUtility.showToast("已保存"); navigationController?.popViewController(animated: true)
    }
}

// MARK: - 头像选择/裁剪
class MyHeadPortraitViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let avatarView = UIImageView()
    private let albumButton = UIButton(type: .system)
    private let cameraButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad(); title = "头像"; view.backgroundColor = .themeBackground
        avatarView.image = UIImage(systemName: "person.circle.fill"); avatarView.tintColor = .lightGray
        avatarView.contentMode = .scaleAspectFill; avatarView.layer.cornerRadius = ScreenAdapter.scaleW(60); avatarView.layer.masksToBounds = true
        albumButton.setTitle("从相册选择", for: .normal); albumButton.titleLabel?.font = ScreenAdapter.font(16)
        albumButton.addTarget(self, action: #selector(fromAlbum), for: .touchUpInside)
        cameraButton.setTitle("拍照", for: .normal); cameraButton.titleLabel?.font = ScreenAdapter.font(16)
        cameraButton.addTarget(self, action: #selector(fromCamera), for: .touchUpInside)
        saveButton.setTitle("保存", for: .normal); saveButton.titleLabel?.font = ScreenAdapter.font(17)
        saveButton.backgroundColor = .themePrimary; saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10); saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let avatarContainer = UIView(); avatarContainer.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in make.center.equalToSuperview(); make.width.height.equalTo(ScreenAdapter.scaleW(120)) }
        let stack = UIStackView(arrangedSubviews: [avatarContainer, albumButton, cameraButton, saveButton]); stack.axis = .vertical; stack.spacing = 16; stack.alignment = .center
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(48)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        avatarContainer.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(140)) }
        saveButton.snp.makeConstraints { make in make.width.equalToSuperview(); make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func fromAlbum() {
        let picker = UIImagePickerController(); picker.delegate = self; picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    @objc private func fromCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController(); picker.delegate = self; picker.sourceType = .camera
            present(picker, animated: true)
        } else { AppUtility.showToast("相机不可用") }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.originalImage] as? UIImage { avatarView.image = img }
        picker.dismiss(animated: true)
    }
    @objc private func save() { AppUtility.showToast("已保存"); navigationController?.popViewController(animated: true) }
}

// MARK: - 文件助手
class FileHelperViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var files: [(name: String, size: String, date: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad(); title = "文件助手"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FHCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        files = [("项目文档.pdf", "2.3MB", "2024-01-15"), ("设计稿.zip", "15.6MB", "2024-01-12")]
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(files.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FHCell", for: indexPath)
        if files.isEmpty { cell.textLabel?.text = "暂无文件"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let f = files[indexPath.row]; cell.textLabel?.text = f.name; cell.detailTextLabel?.text = "\(f.size)  \(f.date)"; cell.imageView?.image = UIImage(systemName: "doc.fill"); cell.imageView?.tintColor = .themePrimary }
        return cell
    }
}

// MARK: - 系统团队
class SystemTeamViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let teams: [(name: String, desc: String, icon: String)] = [
        ("闲雷虎虎官方", "官方团队", "shield.checkered"),
        ("技术支持", "问题反馈与解答", "wrench.adjustable"),
        ("安全中心", "安全相关事务", "lock.shield"),
        ("意见反馈", "产品建议收集", "envelope"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad(); title = "系统团队"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "STCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { teams.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "STCell", for: indexPath)
        let t = teams[indexPath.row]
        cell.textLabel?.text = t.name; cell.detailTextLabel?.text = t.desc
        cell.imageView?.image = UIImage(systemName: t.icon); cell.imageView?.tintColor = .themePrimary
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        AppUtility.showToast("功能开发中")
    }
}
