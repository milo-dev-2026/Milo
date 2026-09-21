import UIKit
import SnapKit
import Kingfisher

// MARK: - 群管理（角色/权限）
class GroupManageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let groupId: String
    private var group: Group?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable {
        case groupSettings = 0  // 群设置：入群审核、全员禁言、禁止加好友、禁止临时会话、禁止新成员看历史
        case adminManage = 1    // 管理员管理
        case memberManage = 2   // 成员管理：群黑名单、已退群成员
        case ownerTransfer = 3  // 群主转让
    }

    init(groupId: String) {
        self.groupId = groupId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadGroupInfo()
    }

    private func setupUI() {
        title = "群管理"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupManageSwitchCell.self, forCellReuseIdentifier: "ManageSwitchCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ManageCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private func loadGroupInfo() {
        Task {
            do {
                let response: APIResponse<Group> = try await APIClient.shared.request(.getGroupInfo(groupId: groupId))
                if let data = response.data {
                    group = data
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } catch {
                AppUtility.showToast("加载失败")
            }
        }
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        // 只有群主才能看到群主转让
        if group?.isOwner ?? false {
            return Section.allCases.count
        }
        return Section.allCases.count - 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .groupSettings: return 5
        case .adminManage: return 1
        case .memberManage: return 2
        case .ownerTransfer: return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sec = Section(rawValue: section) else { return nil }
        switch sec {
        case .groupSettings: return "群设置"
        case .adminManage: return "管理员管理"
        case .memberManage: return "成员管理"
        case .ownerTransfer: return "群主权限"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sec = Section(rawValue: indexPath.section) else { return UITableViewCell() }

        switch sec {
        case .groupSettings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ManageSwitchCell", for: indexPath) as! GroupManageSwitchCell
            cell.imageView?.tintColor = .themePrimary
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.selectionStyle = .none

            switch indexPath.row {
            case 0:
                cell.configure(title: "入群审核", icon: "checkmark.shield", isOn: group?.joinApproval ?? false)
                cell.switchControl.tag = 100
                cell.switchControl.addTarget(self, action: #selector(toggleGroupSetting(_:)), for: .valueChanged)
            case 1:
                cell.configure(title: "全员禁言", icon: "speaker.slash.fill", isOn: group?.muteAll ?? false)
                cell.switchControl.tag = 101
                cell.switchControl.addTarget(self, action: #selector(toggleGroupSetting(_:)), for: .valueChanged)
            case 2:
                cell.configure(title: "禁止添加好友", icon: "person.2.slash", isOn: group?.forbidAddFriend ?? false)
                cell.switchControl.tag = 102
                cell.switchControl.addTarget(self, action: #selector(toggleGroupSetting(_:)), for: .valueChanged)
            case 3:
                cell.configure(title: "禁止临时会话", icon: "message.slash", isOn: group?.forbidTempChat ?? false)
                cell.switchControl.tag = 103
                cell.switchControl.addTarget(self, action: #selector(toggleGroupSetting(_:)), for: .valueChanged)
            case 4:
                cell.configure(title: "禁止新成员查看历史消息", icon: "clock.badge.xmark", isOn: group?.forbidNewViewHistory ?? false)
                cell.switchControl.tag = 104
                cell.switchControl.addTarget(self, action: #selector(toggleGroupSetting(_:)), for: .valueChanged)
            default: break
            }
            return cell

        case .adminManage:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ManageCell", for: indexPath)
            cell.textLabel?.text = "管理员列表"
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.imageView?.image = UIImage(systemName: "person.badge.shield.checkmark")
            cell.imageView?.tintColor = .themePrimary
            cell.accessoryType = .disclosureIndicator
            return cell

        case .memberManage:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ManageCell", for: indexPath)
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.imageView?.tintColor = .themePrimary
            cell.accessoryType = .disclosureIndicator

            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "群黑名单"
                cell.imageView?.image = UIImage(systemName: "person.badge.minus")
            case 1:
                cell.textLabel?.text = "已退群成员"
                cell.imageView?.image = UIImage(systemName: "person.2.slash.fill")
            default: break
            }
            return cell

        case .ownerTransfer:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ManageCell", for: indexPath)
            cell.textLabel?.text = "群主转让"
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.textLabel?.textColor = .label
            cell.imageView?.image = UIImage(systemName: "arrowshape.turn.up.right.circle")
            cell.imageView?.tintColor = .themePrimary
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sec = Section(rawValue: indexPath.section) else { return }

        switch sec {
        case .groupSettings:
            break // 开关操作

        case .adminManage:
            let vc = GroupAdminsViewController(groupId: groupId)
            navigationController?.pushViewController(vc, animated: true)

        case .memberManage:
            switch indexPath.row {
            case 0:
                let vc = GroupBlackListViewController(groupId: groupId)
                navigationController?.pushViewController(vc, animated: true)
            case 1:
                let vc = LeftGroupMembersViewController(groupId: groupId)
                navigationController?.pushViewController(vc, animated: true)
            default: break
            }

        case .ownerTransfer:
            let vc = TransferOwnerViewController(groupId: groupId)
            vc.onTransferSuccess = { [weak self] in
                self?.loadGroupInfo()
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - 开关操作
    @objc private func toggleGroupSetting(_ sender: UISwitch) {
        let tag = sender.tag
        let isOn = sender.isOn

        Task {
            do {
                var success = false
                switch tag {
                case 100: // 入群审核
                    _ = try await APIClient.shared.requestRaw(.setJoinApproval(groupId: groupId, enabled: isOn))
                    success = true
                    group?.joinApproval = isOn
                case 101: // 全员禁言
                    _ = try await APIClient.shared.requestRaw(.setGroupMuteAll(groupId: groupId, muted: isOn))
                    success = true
                    group?.muteAll = isOn
                case 102: // 禁止添加好友
                    _ = try await APIClient.shared.requestRaw(.setForbidAddFriend(groupId: groupId, forbidden: isOn))
                    success = true
                    group?.forbidAddFriend = isOn
                case 103: // 禁止临时会话
                    _ = try await APIClient.shared.requestRaw(.setForbidTempChat(groupId: groupId, forbidden: isOn))
                    success = true
                    group?.forbidTempChat = isOn
                case 104: // 禁止新成员查看历史消息
                    _ = try await APIClient.shared.requestRaw(.setForbidNewMemberViewHistory(groupId: groupId, forbidden: isOn))
                    success = true
                    group?.forbidNewViewHistory = isOn
                default: break
                }

                DispatchQueue.main.async {
                    if success {
                        AppUtility.showToast(isOn ? "已开启" : "已关闭")
                    } else {
                        sender.isOn = !isOn
                        AppUtility.showToast("设置失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    sender.isOn = !isOn
                    AppUtility.showToast("设置失败")
                }
            }
        }
    }
}

// MARK: - 群管理开关 Cell
class GroupManageSwitchCell: UITableViewCell {

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

// MARK: - 群主转让
class TransferOwnerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let groupId: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private var members: [GroupMember] = []
    private var filteredMembers: [GroupMember] = []
    private var selectedUid: String?

    var onTransferSuccess: (() -> Void)?

    init(groupId: String) {
        self.groupId = groupId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMembers()
    }

    private func setupUI() {
        title = "群主转让"
        view.backgroundColor = .themeBackground

        searchBar.placeholder = "搜索成员"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "TransferCell")
        tableView.backgroundColor = .themeBackground
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(64), bottom: 0, right: 0)

        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("确定转让", for: .normal)
        confirmBtn.titleLabel?.font = ScreenAdapter.font(17)
        confirmBtn.backgroundColor = .themePrimary
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.layer.cornerRadius = ScreenAdapter.scaleW(10)
        confirmBtn.addTarget(self, action: #selector(confirmTransfer), for: .touchUpInside)

        view.addSubviews(searchBar, tableView, confirmBtn)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(confirmBtn.snp.top).offset(-ScreenAdapter.scaleH(12))
        }

        confirmBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-ScreenAdapter.scaleH(16))
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
    }

    private func loadMembers() {
        Task {
            do {
                let response: APIResponse<GroupMembersResponse> = try await APIClient.shared.request(
                    .getGroupMembers(groupId: groupId, page: 1, size: 100, keyword: nil)
                )
                if let data = response.data {
                    let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
                    let list = data.list.filter { $0.uid != myUid }
                    DispatchQueue.main.async {
                        self.members = list
                        self.filteredMembers = list
                        self.tableView.reloadData()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载成员失败")
                }
            }
        }
    }

    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredMembers = members
        } else {
            filteredMembers = members.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(filteredMembers.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransferCell", for: indexPath) as! GroupMemberCell

        if filteredMembers.isEmpty {
            cell.textLabel?.text = "暂无成员"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            let member = filteredMembers[indexPath.row]
            cell.configure(with: member)
            cell.accessoryType = (selectedUid == member.uid) ? .checkmark : .none
            cell.tintColor = .themePrimary
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !filteredMembers.isEmpty else { return }
        let member = filteredMembers[indexPath.row]
        selectedUid = member.uid
        tableView.reloadData()
    }

    @objc private func confirmTransfer() {
        guard let uid = selectedUid else {
            AppUtility.showToast("请选择新群主")
            return
        }

        let member = members.first { $0.uid == uid }
        let name = member?.name ?? ""

        let alert = UIAlertController(
            title: "转让群主",
            message: "确定将群主转让给 \(name)？转让后你将成为普通成员。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.doTransfer(uid: uid)
        })
        present(alert, animated: true)
    }

    private func doTransfer(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.transferGroupOwner(groupId: groupId, uid: uid))
                DispatchQueue.main.async {
                    AppUtility.showToast("转让成功")
                    self.onTransferSuccess?()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("转让失败")
                }
            }
        }
    }
}

// MARK: - 已退群成员
class LeftGroupMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let groupId: String
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var members: [GroupMember] = []

    init(groupId: String) {
        self.groupId = groupId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadLeftMembers()
    }

    private func setupUI() {
        title = "已退群成员"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "LeftCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private func loadLeftMembers() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.getLeftGroupMembers(groupId: groupId))
                if let data = response["data"] as? [[String: Any]] {
                    let list = data.compactMap { dict -> GroupMember? in
                        let uid = dict["uid"] as? String ?? ""
                        let name = dict["name"] as? String ?? ""
                        let avatar = dict["avatar"] as? String
                        return GroupMember(uid: uid, name: name, avatar: avatar, role: 0, nickname: nil, joinTime: nil, isMuted: nil)
                    }
                    DispatchQueue.main.async {
                        self.members = list
                        self.tableView.reloadData()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载失败")
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(members.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeftCell", for: indexPath) as! GroupMemberCell

        if members.isEmpty {
            cell.textLabel?.text = "暂无已退群成员"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.selectionStyle = .none
        } else {
            let member = members[indexPath.row]
            cell.configure(with: member)
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !members.isEmpty else { return }
        let member = members[indexPath.row]
        navigationController?.pushViewController(ContactDetailViewController(uid: member.uid), animated: true)
    }
}
