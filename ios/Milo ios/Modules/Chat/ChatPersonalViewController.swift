import UIKit
import SnapKit
import Kingfisher

class ChatPersonalViewController: UIViewController {

    private let channelId: String
    private var chatTitle: String
    private let channelType: Int
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // 开关状态
    private var flameOn = false
    private var muteOn = false
    private var topOn = false

    // Section 索引
    private enum Section: Int, CaseIterable {
        case settings = 0   // 阅后即焚、消息免打扰、置顶聊天
        case actions = 1    // 查找聊天内容、清空聊天记录
        case bottom = 2     // 添加群成员
    }

    init(channelId: String, title: String, channelType: Int = 1) {
        self.channelId = channelId
        self.chatTitle = title
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadChannelInfo()
    }

    private func setupUI() {
        title = "聊天信息"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatPersonalSwitchCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
        tableView.tableHeaderView = createHeaderView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(56), bottom: 0, right: 0)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Header View（对方头像 + 昵称，点击跳转用户详情）
    private func createHeaderView() -> UIView {
        let header = UIView()
        header.backgroundColor = .clear

        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapHeader))
        cardView.addGestureRecognizer(tap)

        // 对方头像（圆形）
        let avatarSize: CGFloat = 56
        let avatarImageView = UIImageView()
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .systemGray6

        // 昵称（左对齐）
        let nameLabel = UILabel()
        nameLabel.font = ScreenAdapter.boldFont(18)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 2
        nameLabel.text = chatTitle

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(white: 0.75, alpha: 1.0)
        arrow.contentMode = .scaleAspectFit

        cardView.addSubviews(avatarImageView, nameLabel, arrow)
        header.addSubview(cardView)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }

        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(avatarSize)
            make.bottom.equalToSuperview().offset(-16)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalTo(arrow.snp.leading).offset(-8)
            make.centerY.equalTo(avatarImageView)
        }

        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(avatarImageView)
            make.width.height.equalTo(14)
        }

        headerCache = HeaderCache(avatar: avatarImageView, nameLabel: nameLabel)

        AppUtility.loadChannelAvatar(channelId: channelId, channelType: 1, name: chatTitle, into: avatarImageView)

        let headerWidth = view.bounds.width > 0 ? view.bounds.width : ScreenAdapter.screenWidth
        let headerHeight: CGFloat = 12 + 16 + avatarSize + 16 + 8
        header.frame = CGRect(x: 0, y: 0, width: headerWidth, height: headerHeight)

        return header
    }

    private struct HeaderCache {
        weak var avatar: UIImageView?
        weak var nameLabel: UILabel?
    }

    private var headerCache: HeaderCache?

    // MARK: - Load Data
    private func loadChannelInfo() {
        Task {
            do {
                let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: channelId, channelType: 1)
                )
                DispatchQueue.main.async {
                    if !info.displayName.isEmpty {
                        self.chatTitle = info.displayName
                        self.headerCache?.nameLabel?.text = info.displayName
                    }
                    if let avatarView = self.headerCache?.avatar {
                        AppUtility.loadChannelAvatar(channelId: self.channelId, channelType: 1, name: self.chatTitle, into: avatarView)
                    }
                }
            } catch {
                // 静默失败，保留传入的标题
            }
        }
    }

    // MARK: - Header Action（跳转用户详情）
    @objc private func didTapHeader() {
        let vc = ContactDetailViewController(uid: channelId)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Switch Actions
    private func updateSetting(key: String, value: Bool, sender: UISwitch, successMessage: String, applyLocal: ((Bool) -> Void)? = nil) {
        applyLocal?(value)
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.updateUserSetting(key: key, value: value ? 1 : 0))
                DispatchQueue.main.async {
                    AppUtility.showToast(successMessage)
                }
            } catch {
                DispatchQueue.main.async {
                    sender.isOn = !value
                    applyLocal?(!value)
                    AppUtility.showToast("设置失败")
                }
            }
        }
    }

    @objc private func toggleFlame(_ sender: UISwitch) {
        updateSetting(key: "flame", value: sender.isOn, sender: sender,
                      successMessage: sender.isOn ? "已开启阅后即焚" : "已关闭阅后即焚") { [weak self] v in
            self?.flameOn = v
        }
    }

    @objc private func toggleMute(_ sender: UISwitch) {
        updateSetting(key: "mute", value: sender.isOn, sender: sender,
                      successMessage: sender.isOn ? "已开启消息免打扰" : "已关闭消息免打扰") { [weak self] v in
            guard let self = self else { return }
            self.muteOn = v
            IMManager.shared.setChannelMute(channelId: self.channelId, channelType: self.channelType, mute: v)
        }
    }

    @objc private func toggleTop(_ sender: UISwitch) {
        updateSetting(key: "top", value: sender.isOn, sender: sender,
                      successMessage: sender.isOn ? "已置顶" : "已取消置顶") { [weak self] v in
            guard let self = self else { return }
            self.topOn = v
            IMManager.shared.setChannelStick(channelId: self.channelId, channelType: self.channelType, stick: v)
        }
    }

    // MARK: - 清空聊天记录
    private func confirmClearHistory() {
        let alert = UIAlertController(title: "清空聊天记录",
                                      message: "确定清空与 \(chatTitle) 的聊天记录？",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            self?.clearChatHistory()
        })
        present(alert, animated: true)
    }

    private func clearChatHistory() {
        IMManager.shared.clearMessages(channelId: channelId, channelType: channelType)
        AppUtility.showToast("聊天记录已清空")
    }

    // MARK: - 添加群成员（单聊转群聊）
    private func addGroupMembers() {
        let vc = ChooseContactsViewController(maxSelection: 99)
        vc.title = "选择联系人"
        vc.onContactsSelected = { [weak self] uids in
            self?.createGroup(with: uids)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func createGroup(with uids: [String]) {
        guard !uids.isEmpty else { return }
        // 把当前单聊对象一起加入群聊
        var memberUids = uids
        if !memberUids.contains(channelId) {
            memberUids.append(channelId)
        }
        AppUtility.showToast("正在创建群聊...")
        Task {
            do {
                let groupId = "group_\(Int(Date().timeIntervalSince1970))"
                let response = try await APIClient.shared.requestRaw(.addGroupMembers(groupId: groupId, uids: memberUids))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        AppUtility.showToast("群聊创建成功")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("创建群聊失败")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatPersonalViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .settings: return 3
        case .actions: return 2
        case .bottom: return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sec = Section(rawValue: section) else { return nil }
        switch sec {
        case .settings, .actions:
            // 空字符串显示间距，nil 不显示
            return ""
        case .bottom:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .settings: return ScreenAdapter.scaleH(8)
        case .actions: return ScreenAdapter.scaleH(8)
        case .bottom: return ScreenAdapter.scaleH(24)
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sec = Section(rawValue: section) else { return nil }
        switch sec {
        case .settings:
            return "对方阅读消息后，根据设置的时间自动销毁"
        case .actions, .bottom:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sec = Section(rawValue: indexPath.section) else { return UITableViewCell() }

        switch sec {
        case .settings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! ChatPersonalSwitchCell
            cell.imageView?.tintColor = .themePrimary
            cell.textLabel?.font = ScreenAdapter.font(16)

            switch indexPath.row {
            case 0:
                cell.configure(title: "阅后即焚", icon: "flame", isOn: flameOn)
                cell.switchControl.addTarget(self, action: #selector(toggleFlame(_:)), for: .valueChanged)
            case 1:
                cell.configure(title: "消息免打扰", icon: "bell.slash", isOn: muteOn)
                cell.switchControl.addTarget(self, action: #selector(toggleMute(_:)), for: .valueChanged)
            case 2:
                cell.configure(title: "置顶聊天", icon: "pin.fill", isOn: topOn)
                cell.switchControl.addTarget(self, action: #selector(toggleTop(_:)), for: .valueChanged)
            default: break
            }
            return cell

        case .actions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.tintColor = .themePrimary
            cell.textLabel?.font = ScreenAdapter.font(16)

            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "查找聊天内容"
                cell.imageView?.image = UIImage(systemName: "magnifyingglass")
            case 1:
                cell.textLabel?.text = "清空聊天记录"
                cell.imageView?.image = UIImage(systemName: "trash")
            default: break
            }
            return cell

        case .bottom:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            cell.accessoryType = .none
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.imageView?.image = nil
            cell.textLabel?.text = "添加群成员"
            cell.textLabel?.textColor = .systemRed
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sec = Section(rawValue: indexPath.section) else { return }

        switch sec {
        case .settings:
            break // 开关操作已处理

        case .actions:
            switch indexPath.row {
            case 0:
                // 查找聊天内容
                let vc = SearchAllViewController()
                navigationController?.pushViewController(vc, animated: true)
            case 1:
                // 清空聊天记录
                confirmClearHistory()
            default: break
            }

        case .bottom:
            addGroupMembers()
        }
    }
}

// MARK: - 带开关的 Cell
class ChatPersonalSwitchCell: UITableViewCell {

    let switchControl = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        switchControl.onTintColor = .themePrimary
        accessoryView = switchControl
    }

    func configure(title: String, icon: String, isOn: Bool) {
        textLabel?.text = title
        imageView?.image = UIImage(systemName: icon)
        switchControl.isOn = isOn
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        switchControl.removeTarget(nil, action: nil, for: .allEvents)
    }
}
