import UIKit
import SnapKit
import Kingfisher
import UniformTypeIdentifiers

// MARK: - 我的页面
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

        // 头部视图
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: ScreenAdapter.scaleH(100))
        headerView.onTap = { [weak self] in
            self?.navigationController?.pushViewController(SettingProfileEditViewController(), animated: true)
        }
        headerView.onTapQR = { [weak self] in
            let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
            let name = UserDefaults.standard.string(forKey: "name") ?? "用户"
            self?.navigationController?.pushViewController(UserQRCodeViewController(uid: uid, name: name), animated: true)
        }
        tableView.tableHeaderView = headerView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadUserInfo() {
        guard let uid = UserDefaults.standard.string(forKey: "uid") else { return }
        Task {
            do {
                let channelInfo: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: uid, channelType: 1)
                )
                let user = channelInfo.toUser()
                UserDefaults.standard.set(user.name, forKey: "name")
                if let avatar = user.avatar {
                    UserDefaults.standard.set(avatar, forKey: "avatar")
                }
                let shortNo = UserDefaults.standard.string(forKey: "short_no") ?? ""
                var fullUser = user
                fullUser.uid = shortNo.isEmpty ? uid : shortNo
                DispatchQueue.main.async {
                    self.headerView.configure(with: fullUser)
                }
            } catch {
                let name = UserDefaults.standard.string(forKey: "name") ?? "用户"
                let avatar = UserDefaults.standard.string(forKey: "avatar")
                let shortNo = UserDefaults.standard.string(forKey: "short_no") ?? uid
                let user = User(uid: shortNo, name: name, avatar: avatar)
                DispatchQueue.main.async {
                    self.headerView.configure(with: user)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension MySettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = .themePrimary
        cell.textLabel?.font = ScreenAdapter.font(16)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "我的笔记"
            cell.imageView?.image = UIImage(systemName: "note.text")
        case 1:
            cell.textLabel?.text = "我的收藏"
            cell.imageView?.image = UIImage(systemName: "star")
        case 2:
            cell.textLabel?.text = "设置"
            cell.imageView?.image = UIImage(systemName: "gear")
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            // 我的笔记
            let noteVC = NoteViewController()
            navigationController?.pushViewController(noteVC, animated: true)
        case 1:
            // 我的收藏
            let favVC = FavoriteViewController()
            navigationController?.pushViewController(favVC, animated: true)
        case 2:
            // 设置
            navigationController?.pushViewController(SettingMainViewController(), animated: true)
        default:
            break
        }
    }
}

// MARK: - 个人资料头部视图
class MyProfileHeaderView: UIView {

    var onTap: (() -> Void)?
    var onTapQR: (() -> Void)?

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let uidLabel = UILabel()
    private let qrButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        let avatarSize = ScreenAdapter.scaleW(60)
        let hPad = ScreenAdapter.scaleW(16)
        let avatarRadius = ScreenAdapter.scaleW(30)

        avatarView.layer.cornerRadius = avatarRadius
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5
        avatarView.isUserInteractionEnabled = true

        nameLabel.font = ScreenAdapter.mediumFont(18)
        nameLabel.textColor = .label
        nameLabel.text = "用户"

        uidLabel.font = ScreenAdapter.font(13)
        uidLabel.textColor = .secondaryLabel
        uidLabel.text = "Milo号: --"

        let textStack = UIStackView(arrangedSubviews: [nameLabel, uidLabel])
        textStack.axis = .vertical
        textStack.spacing = ScreenAdapter.scaleH(4)
        textStack.alignment = .leading

        qrButton.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        qrButton.tintColor = .themePrimary
        qrButton.addTarget(self, action: #selector(qrTapped), for: .touchUpInside)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .systemGray3

        addSubviews(avatarView, textStack, qrButton, chevron)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(hPad)
            make.centerY.equalToSuperview()
        }

        qrButton.snp.makeConstraints { make in
            make.trailing.equalTo(chevron.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }

        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-hPad)
            make.centerY.equalToSuperview()
        }

        // 整体点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        addGestureRecognizer(tapGesture)
    }

    @objc private func headerTapped() {
        onTap?()
    }

    @objc private func qrTapped() {
        onTapQR?()
    }

    func configure(with user: User) {
        nameLabel.text = user.name
        uidLabel.text = "Milo号: \(user.uid)"
        AppUtility.loadAvatar(user.avatarURL, into: avatarView)
    }
}

// MARK: - 个人资料编辑页
class SettingProfileEditViewController: UIViewController {

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
                let channelInfo: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: uid, channelType: 1)
                )
                user = channelInfo.toUser()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                AppUtility.showToast("加载失败")
            }
        }
    }

    @objc private func changeAvatar() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.image.identifier]
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

extension SettingProfileEditViewController: UITableViewDataSource, UITableViewDelegate {

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

extension SettingProfileEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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
