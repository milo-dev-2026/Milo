import UIKit
import SnapKit
import Kingfisher

// MARK: - 我的设置页
class MySettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let headerView = MyProfileHeaderView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserInfo()
    }

    private func setupUI() {
        title = "我的"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.tableHeaderView = headerView
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: ScreenAdapter.scaleH(120))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadUserInfo() {
        guard let uid = UserDefaults.standard.string(forKey: "uid") else { return }
        Task {
            do {
                let response: APIResponse<User> = try await APIClient.shared.request(.getUserInfo(uid: uid))
                if let user = response.data {
                    DispatchQueue.main.async {
                        self.headerView.configure(with: user)
                    }
                }
            } catch {}
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension MySettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 4
        case 2: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "设置"
        case 2: return "其他"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = .themePrimary
        cell.textLabel?.font = ScreenAdapter.font(16)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "个人资料"
            cell.imageView?.image = UIImage(systemName: "person.circle")
        case (1, 0):
            cell.textLabel?.text = "通用设置"
            cell.imageView?.image = UIImage(systemName: "gear")
        case (1, 1):
            cell.textLabel?.text = "消息通知"
            cell.imageView?.image = UIImage(systemName: "bell")
        case (1, 2):
            cell.textLabel?.text = "安全中心"
            cell.imageView?.image = UIImage(systemName: "lock.shield")
        case (1, 3):
            cell.textLabel?.text = "我的二维码"
            cell.imageView?.image = UIImage(systemName: "qrcode")
        case (2, 0):
            cell.textLabel?.text = "关于"
            cell.imageView?.image = UIImage(systemName: "info.circle")
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            navigationController?.pushViewController(ProfileEditViewController(), animated: true)
        case (1, 0):
            navigationController?.pushViewController(GeneralSettingViewController(), animated: true)
        case (1, 1):
            navigationController?.pushViewController(MessageNotificationSettingViewController(), animated: true)
        case (1, 2):
            navigationController?.pushViewController(SecuritySettingViewController(), animated: true)
        case (1, 3):
            let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
            let name = UserDefaults.standard.string(forKey: "name") ?? "用户"
            navigationController?.pushViewController(UserQRCodeViewController(uid: uid, name: name), animated: true)
        case (2, 0):
            navigationController?.pushViewController(AboutViewController(), animated: true)
        default:
            break
        }
    }
}

// MARK: - 个人资料头部视图
class MyProfileHeaderView: UIView {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let uidLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        let avatarSize = ScreenAdapter.scaleW(60)
        let hPad = ScreenAdapter.scaleW(16)
        let avatarRadius = ScreenAdapter.scaleW(30)

        avatarView.layer.cornerRadius = avatarRadius
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        nameLabel.font = ScreenAdapter.mediumFont(17)
        uidLabel.font = ScreenAdapter.font(12)
        uidLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [nameLabel, uidLabel])
        textStack.axis = .vertical
        textStack.spacing = ScreenAdapter.scaleH(2)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .systemGray3

        addSubviews(avatarView, textStack, chevron)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(hPad)
            make.centerY.equalToSuperview()
        }

        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-hPad)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with user: User) {
        nameLabel.text = user.name
        uidLabel.text = "ID: \(user.uid)"
        AppUtility.loadAvatar(user.avatarURL, into: avatarView)
    }
}

// MARK: - 个人资料编辑页
class ProfileEditViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var user: User?
    private let avatarView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserInfo()
    }

    private func setupUI() {
        title = "个人资料"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let changeAvatarBtn = UIButton(type: .system)
        changeAvatarBtn.setTitle("修改头像", for: .normal)
        changeAvatarBtn.titleLabel?.font = ScreenAdapter.font(14)
        changeAvatarBtn.addTarget(self, action: #selector(changeAvatar), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: changeAvatarBtn)
    }

    private func loadUserInfo() {
        guard let uid = UserDefaults.standard.string(forKey: "uid") else { return }
        Task {
            do {
                let response: APIResponse<User> = try await APIClient.shared.request(.getUserInfo(uid: uid))
                if let data = response.data {
                    user = data
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } catch {
                AppUtility.showToast("加载失败")
            }
        }
    }

    @objc private func changeAvatar() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [.image]
        picker.delegate = self
        present(picker, animated: true)
    }

    private func showEditNameAlert() {
        let alert = UIAlertController(title: "修改昵称", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "昵称"
            tf.text = self.user?.name ?? ""
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            self?.updateName(name)
        })
        present(alert, animated: true)
    }

    private func updateName(_ name: String) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.updateUserInfo(name: name, avatar: nil))
                if response["status"] as? Int == 200 {
                    UserDefaults.standard.set(name, forKey: "name")
                    user?.name = name
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        AppUtility.showToast("已更新昵称")
                    }
                }
            } catch {
                AppUtility.showToast("更新失败")
            }
        }
    }

    private func uploadAvatar(data: Data) {
        Task {
            do {
                let fileName = "avatar_\(Int(Date().timeIntervalSince1970)).jpg"
                let path = try await APIClient.shared.upload(data: data, fileName: fileName)
                let response = try await APIClient.shared.requestRaw(.updateUserInfo(name: nil, avatar: path))
                if response["status"] as? Int == 200 {
                    UserDefaults.standard.set(path, forKey: "avatar")
                    user?.avatar = path
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        AppUtility.showToast("头像已更新")
                    }
                }
            } catch {
                AppUtility.showToast("上传失败")
            }
        }
    }
}

extension ProfileEditViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)

        switch indexPath.row {
        case 0:
            let avatarSize = ScreenAdapter.scaleW(40)
            avatarView.layer.cornerRadius = avatarSize / 2
            avatarView.clipsToBounds = true
            avatarView.contentMode = .scaleAspectFill
            avatarView.image = UIImage(systemName: "person.circle.fill")
            avatarView.tintColor = .systemGray5
            if let url = user?.avatarURL {
                avatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
            }
            cell.imageView?.image = UIImage(systemName: "person.crop.circle")
            cell.textLabel?.text = "头像"
            cell.accessoryView = avatarView
            cell.imageView?.tintColor = .themePrimary
        case 1:
            cell.textLabel?.text = "昵称"
            cell.detailTextLabel?.text = user?.name ?? ""
            cell.imageView?.image = UIImage(systemName: "pencil")
            cell.imageView?.tintColor = .themePrimary
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 1:
            showEditNameAlert()
        default:
            break
        }
    }
}

extension ProfileEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage,
           let data = image.jpegData(compressionQuality: 0.6) {
            uploadAvatar(data: data)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - 通用设置页
class GeneralSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let fontSizeLabel = UILabel()
    private let fontSizeSlider = UISlider()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "通用设置"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GeneralCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension GeneralSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "字体大小"
        case 1: return "外观"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let sizeView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenAdapter.scaleW(120), height: ScreenAdapter.scaleH(30)))
            fontSizeSlider.minimumValue = 13
            fontSizeSlider.maximumValue = 20
            fontSizeSlider.value = Float(LocalStore.shared.fontSize)
            fontSizeSlider.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
            fontSizeSlider.translatesAutoresizingMaskIntoConstraints = false
            sizeView.addSubview(fontSizeSlider)
            fontSizeSlider.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            cell.textLabel?.text = "字号"
            cell.accessoryView = sizeView
            cell.accessoryType = .none
            cell.imageView?.image = UIImage(systemName: "textformat")
        case (1, 0):
            cell.textLabel?.text = "深色模式"
            cell.imageView?.image = UIImage(systemName: "moon")
            let mode = UserDefaults.standard.integer(forKey: "appearance_mode")
            cell.detailTextLabel?.text = mode == 1 ? "开启" : "跟随系统"
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            showAppearanceAlert()
        default:
            break
        }
    }

    @objc private func fontSizeChanged() {
        let size = Int(fontSizeSlider.value.rounded())
        LocalStore.shared.fontSize = size
        fontSizeLabel.text = "\(size)"
    }

    private func showAppearanceAlert() {
        let alert = UIAlertController(title: "深色模式", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "跟随系统", style: .default) { _ in
            UserDefaults.standard.set(0, forKey: "appearance_mode")
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "开启", style: .default) { _ in
            UserDefaults.standard.set(1, forKey: "appearance_mode")
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "关闭", style: .default) { _ in
            UserDefaults.standard.set(2, forKey: "appearance_mode")
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - 消息通知设置页
class MessageNotificationSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "消息通知"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotifCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension MessageNotificationSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "通知设置"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath)
        cell.accessoryType = .none
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.selectionStyle = .none
        cell.imageView?.tintColor = .themePrimary

        let switchControl = UISwitch()

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "消息通知"
            cell.imageView?.image = UIImage(systemName: "bell")
            switchControl.isOn = LocalStore.shared.isMessageNotificationEnabled
            switchControl.addTarget(self, action: #selector(toggleNotification(_:)), for: .valueChanged)
        case 1:
            cell.textLabel?.text = "声音"
            cell.imageView?.image = UIImage(systemName: "speaker.wave.2")
            switchControl.isOn = LocalStore.shared.isSoundEnabled
            switchControl.addTarget(self, action: #selector(toggleSound(_:)), for: .valueChanged)
        case 2:
            cell.textLabel?.text = "振动"
            cell.imageView?.image = UIImage(systemName: "iphone.radiowaves.left.and.right")
            switchControl.isOn = LocalStore.shared.isVibrationEnabled
            switchControl.addTarget(self, action: #selector(toggleVibration(_:)), for: .valueChanged)
        default:
            break
        }
        cell.accessoryView = switchControl
        return cell
    }

    @objc private func toggleNotification(_ sender: UISwitch) {
        LocalStore.shared.isMessageNotificationEnabled = sender.isOn
    }

    @objc private func toggleSound(_ sender: UISwitch) {
        LocalStore.shared.isSoundEnabled = sender.isOn
    }

    @objc private func toggleVibration(_ sender: UISwitch) {
        LocalStore.shared.isVibrationEnabled = sender.isOn
    }
}

// MARK: - 安全设置页（安全中心）
class SecuritySettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupUI() {
        title = "安全中心"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SecurityCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension SecuritySettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 4
        case 2: return 2
        case 3: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "账号安全"
        case 1: return "隐私安全"
        case 2: return "密码管理"
        case 3: return "账号操作"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SecurityCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.textLabel?.textColor = .label
        cell.imageView?.tintColor = .themePrimary

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "安全账号"
            cell.imageView?.image = UIImage(systemName: "shield.lefthalf.filled")
            let phone = UserDefaults.standard.string(forKey: "bind_phone") ?? ""
            let email = UserDefaults.standard.string(forKey: "bind_email") ?? ""
            cell.detailTextLabel?.text = !phone.isEmpty || !email.isEmpty ? "已绑定" : "未绑定"
        case (1, 0):
            cell.textLabel?.text = "设备管理"
            cell.imageView?.image = UIImage(systemName: "laptopcomputer")
        case (1, 1):
            cell.textLabel?.text = "消息隐私"
            cell.imageView?.image = UIImage(systemName: "eye.slash")
        case (1, 2):
            cell.textLabel?.text = "聊天密码"
            cell.imageView?.image = UIImage(systemName: "key")
            let enabled = UserDefaults.standard.bool(forKey: "chat_password_enabled")
            cell.detailTextLabel?.text = enabled ? "已设置" : "未设置"
        case (1, 3):
            cell.textLabel?.text = "黑名单"
            cell.imageView?.image = UIImage(systemName: "person.badge.minus")
        case (2, 0):
            cell.textLabel?.text = "锁屏密码"
            cell.imageView?.image = UIImage(systemName: "lock")
            let enabled = LocalStore.shared.isAppLockEnabled
            cell.detailTextLabel?.text = enabled ? "已设置" : "未设置"
        case (2, 1):
            cell.textLabel?.text = "登录密码"
            cell.imageView?.image = UIImage(systemName: "key.viewfinder")
            cell.detailTextLabel?.text = "已设置"
        case (3, 0):
            cell.textLabel?.text = "注销账号"
            cell.imageView?.image = UIImage(systemName: "person.crop.circle.badge.xmark")
            cell.textLabel?.textColor = .systemRed
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            navigationController?.pushViewController(SecurityAccountViewController(), animated: true)
        case (1, 0):
            navigationController?.pushViewController(DeviceManageViewController(), animated: true)
        case (1, 1):
            navigationController?.pushViewController(MessagePrivacyViewController(), animated: true)
        case (1, 2):
            navigationController?.pushViewController(ChatPasswordViewController(), animated: true)
        case (1, 3):
            navigationController?.pushViewController(BlacklistViewController(), animated: true)
        case (2, 0):
            navigationController?.pushViewController(LockScreenPwdViewController(), animated: true)
        case (2, 1):
            navigationController?.pushViewController(LoginPasswordViewController(), animated: true)
        case (3, 0):
            navigationController?.pushViewController(DestroyAccountViewController(), animated: true)
        default:
            break
        }
    }
}

// MARK: - 黑名单
class BlacklistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var blacklist: [[String: String]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "黑名单"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BlackCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        loadData()
    }

    private func loadData() {
        if let saved = UserDefaults.standard.array(forKey: "blacklist") as? [[String: String]] {
            blacklist = saved
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(blacklist.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlackCell", for: indexPath)
        if blacklist.isEmpty {
            cell.textLabel?.text = "暂无黑名单用户"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
        } else {
            let item = blacklist[indexPath.row]
            cell.textLabel?.text = item["name"] ?? ""
        }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !blacklist.isEmpty else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "移除") { _, _, completion in
            self.blacklist.remove(at: indexPath.row)
            UserDefaults.standard.set(self.blacklist, forKey: "blacklist")
            tableView.reloadData()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}

class AboutViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "关于"
        view.backgroundColor = .themeBackground

        let label = UILabel()
        label.text = "闲雷虎虎 v\(APIConfig.appVersion)"
        label.font = ScreenAdapter.font(16)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
