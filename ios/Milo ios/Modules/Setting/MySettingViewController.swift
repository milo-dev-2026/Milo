import UIKit
import SnapKit
import Kingfisher
import UniformTypeIdentifiers

// MARK: - 我的页面
class MySettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let headerView = MyProfileHeaderView()
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadUserInfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.themeSeparator.withAlphaComponent(0.6)
        tableView.showsVerticalScrollIndicator = false

        // 下拉刷新
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // 头部视图高度：顶部间距 80pt + 玻璃卡片内容 + 底部间距 40pt
        let headerHeight = ScreenAdapter.scaleH(80) + MyProfileHeaderView.cardHeight + ScreenAdapter.scaleH(40)
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight)
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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc private func handleRefresh() {
        loadUserInfo()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.refreshControl.endRefreshing()
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

        // 玻璃卡片效果：半透明白色背景
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        cell.tintColor = .themePrimary

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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return ScreenAdapter.scaleH(20)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
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

    // MARK: - 玻璃卡片高度（供外部计算总高度使用）
    static var cardHeight: CGFloat {
        let topPad = ScreenAdapter.scaleH(32)
        let avatarSize = ScreenAdapter.scaleW(88)
        let avatarToName = ScreenAdapter.scaleH(16)
        let nameHeight = ScreenAdapter.scaleH(24)
        let nameToUid = ScreenAdapter.scaleH(8)
        let uidHeight = ScreenAdapter.scaleH(20)
        let bottomPad = ScreenAdapter.scaleH(32)
        return topPad + avatarSize + avatarToName + nameHeight + nameToUid + uidHeight + bottomPad
    }

    var onTap: (() -> Void)?
    var onTapQR: (() -> Void)?

    private let glassCard = GlassCardView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let uidLabel = UILabel()
    private let copyButton = UIButton(type: .system)
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

        // MARK: 玻璃卡片
        addSubview(glassCard)
        glassCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(80))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.height.equalTo(MyProfileHeaderView.cardHeight)
        }

        // MARK: 头像
        let avatarSize = ScreenAdapter.scaleW(88)
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5
        avatarView.isUserInteractionEnabled = true
        // 头像柔光边框
        avatarView.layer.borderWidth = 3
        avatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor

        glassCard.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(32))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        // MARK: 用户名
        nameLabel.font = ScreenAdapter.mediumFont(18)
        nameLabel.textColor = .label
        nameLabel.text = "用户"
        nameLabel.textAlignment = .center

        glassCard.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(20))
        }

        // MARK: Milo号 + 复制按钮
        uidLabel.font = ScreenAdapter.font(12)
        uidLabel.textColor = .secondaryLabel
        uidLabel.text = "Milo号: --"

        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.tintColor = .secondaryLabel
        copyButton.addTarget(self, action: #selector(copyUidTapped), for: .touchUpInside)

        let uidStack = UIStackView(arrangedSubviews: [uidLabel, copyButton])
        uidStack.axis = .horizontal
        uidStack.spacing = ScreenAdapter.scaleW(6)
        uidStack.alignment = .center

        glassCard.addSubview(uidStack)
        uidStack.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.centerX.equalToSuperview()
        }

        // MARK: 二维码按钮（右上角）
        qrButton.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        qrButton.tintColor = .themePrimary
        qrButton.addTarget(self, action: #selector(qrTapped), for: .touchUpInside)

        glassCard.addSubview(qrButton)
        qrButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }

        // 整体点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        glassCard.addGestureRecognizer(tapGesture)
    }

    @objc private func headerTapped() {
        onTap?()
    }

    @objc private func qrTapped() {
        onTapQR?()
    }

    @objc private func copyUidTapped() {
        let uidText = uidLabel.text?.replacingOccurrences(of: "Milo号: ", with: "") ?? ""
        UIPasteboard.general.string = uidText
        AppUtility.showToast("已复制Milo号")
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
