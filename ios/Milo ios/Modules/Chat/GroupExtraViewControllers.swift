import UIKit
import SnapKit

// MARK: - 群管理（角色/权限）
class GroupManageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群管理"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GroupManageCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    func numberOfSections(in tableView: UITableView) -> Int { 3 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section { case 0: return 2; case 1: return 2; case 2: return 2; default: return 0 }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section { case 0: return "权限设置"; case 1: return "成员管理"; case 2: return "群信息"; default: return nil }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupManageCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = .themePrimary
        cell.selectionStyle = .none
        let sw = UISwitch()
        switch (indexPath.section, indexPath.row) {
        case (0, 0): cell.textLabel?.text = "仅群主/管理员可邀请"; cell.imageView?.image = UIImage(systemName: "person.badge.plus"); sw.isOn = UserDefaults.standard.bool(forKey: "group_invite_only_admin"); sw.tag = 0; sw.addTarget(self, action: #selector(toggleGroupSetting(_:)), for: .valueChanged); cell.accessoryView = sw; cell.accessoryType = .none
        case (0, 1): cell.textLabel?.text = "禁止群成员添加好友"; cell.imageView?.image = UIImage(systemName: "person.2.slash"); sw.isOn = UserDefaults.standard.bool(forKey: "group_forbid_add_friend"); sw.tag = 1; sw.addTarget(self, action: #selector(toggleGroupSetting(_:)), for: .valueChanged); cell.accessoryView = sw; cell.accessoryType = .none
        case (1, 0): cell.textLabel?.text = "全部成员"; cell.imageView?.image = UIImage(systemName: "person.3")
        case (1, 1): cell.textLabel?.text = "群黑名单"; cell.imageView?.image = UIImage(systemName: "person.badge.minus")
        case (2, 0): cell.textLabel?.text = "修改群名"; cell.imageView?.image = UIImage(systemName: "pencil")
        case (2, 1): cell.textLabel?.text = "群备注"; cell.imageView?.image = UIImage(systemName: "tag")
        default: break
        }
        return cell
    }
    @objc private func toggleGroupSetting(_ sw: UISwitch) {
        let key = sw.tag == 0 ? "group_invite_only_admin" : "group_forbid_add_friend"
        UserDefaults.standard.set(sw.isOn, forKey: key)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (1, 0): navigationController?.pushViewController(AllMembersViewController(groupId: groupId), animated: true)
        case (1, 1): navigationController?.pushViewController(GroupBlackListViewController(groupId: groupId), animated: true)
        case (2, 0): navigationController?.pushViewController(UpdateGroupNameViewController(groupId: groupId), animated: true)
        case (2, 1): navigationController?.pushViewController(SetGroupRemarkViewController(groupId: groupId), animated: true)
        default: break
        }
    }
}

// MARK: - 群黑名单
class GroupBlackListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [(uid: String, name: String)] = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群黑名单"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GBLCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(members.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GBLCell", for: indexPath)
        if members.isEmpty { cell.textLabel?.text = "暂无黑名单用户"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let m = members[indexPath.row]; cell.textLabel?.text = m.name; cell.imageView?.image = UIImage(systemName: "person.circle.fill"); cell.imageView?.tintColor = .lightGray }
        return cell
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !members.isEmpty else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "移出黑名单") { _, _, c in self.members.remove(at: indexPath.row); tableView.reloadData(); c(true) }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}

// MARK: - 已加入群列表
class JoinedGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groups: [(groupId: String, name: String, memberCount: Int)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "已加入的群"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "JGCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(groups.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JGCell", for: indexPath)
        if groups.isEmpty { cell.textLabel?.text = "暂未加入群组"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let g = groups[indexPath.row]; cell.textLabel?.text = g.name; cell.detailTextLabel?.text = "\(g.memberCount)人"; cell.imageView?.image = UIImage(systemName: "person.3.fill"); cell.imageView?.tintColor = .themePrimary }
        return cell
    }
}

// MARK: - 已保存群列表
class SavedGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groups: [(groupId: String, name: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "保存的群"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SGCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(groups.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SGCell", for: indexPath)
        if groups.isEmpty { cell.textLabel?.text = "暂无保存的群"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let g = groups[indexPath.row]; cell.textLabel?.text = g.name; cell.imageView?.image = UIImage(systemName: "bookmark.fill"); cell.imageView?.tintColor = .themePrimary }
        return cell
    }
}

// MARK: - 移出成员
class OutGroupMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [(uid: String, name: String)] = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "移出成员"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OGMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OGMCell", for: indexPath)
        let m = members[indexPath.row]
        cell.textLabel?.text = m.name
        cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        cell.imageView?.tintColor = .lightGray
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let out = UIContextualAction(style: .destructive, title: "移出") { _, _, c in
            self.members.remove(at: indexPath.row); tableView.reloadData(); c(true)
        }
        return UISwipeActionsConfiguration(actions: [out])
    }
}

// MARK: - 删除成员
class DeleteGroupMemberViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [(uid: String, name: String)] = []
    private var selectedUids: Set<String> = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "删除成员"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DGMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "删除", style: .destructive, target: self, action: #selector(deleteMembers))
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DGMCell", for: indexPath)
        let m = members[indexPath.row]
        cell.textLabel?.text = m.name
        cell.imageView?.image = UIImage(systemName: "person.circle.fill"); cell.imageView?.tintColor = .lightGray
        cell.accessoryType = selectedUids.contains(m.uid) ? .checkmark : .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let m = members[indexPath.row]
        if selectedUids.contains(m.uid) { selectedUids.remove(m.uid) } else { selectedUids.insert(m.uid) }
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    @objc private func deleteMembers() {
        guard !selectedUids.isEmpty else { AppUtility.showToast("请选择成员"); return }
        let alert = UIAlertController(title: "删除成员", message: "确定删除选中的\(selectedUids.count)名成员？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in AppUtility.showToast("已删除"); self.navigationController?.popViewController(animated: true) })
        present(alert, animated: true)
    }
}

// MARK: - 已读成员列表
class ReadMsgMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var readMembers: [(uid: String, name: String, time: String)] = []
    private var unreadMembers: [(uid: String, name: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "已读/未读成员"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) { section == 0 ? max(readMembers.count, 1) : max(unreadMembers.count, 1) }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { section == 0 ? "已读\(readMembers.count)人" : "未读\(unreadMembers.count)人" }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RMCell", for: indexPath)
        if indexPath.section == 0 && !readMembers.isEmpty { let m = readMembers[indexPath.row]; cell.textLabel?.text = m.name; cell.detailTextLabel?.text = m.time; cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill"); cell.imageView?.tintColor = .systemGreen }
        else if indexPath.section == 1 && !unreadMembers.isEmpty { let m = unreadMembers[indexPath.row]; cell.textLabel?.text = m.name; cell.imageView?.image = UIImage(systemName: "circle"); cell.imageView?.tintColor = .secondaryLabel }
        else { cell.textLabel?.text = "暂无"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        return cell
    }
}

// MARK: - 全部成员列表
class AllMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [(uid: String, name: String, role: Int)] = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全部成员"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AMCell", for: indexPath)
        let m = members[indexPath.row]
        cell.textLabel?.text = m.name
        cell.imageView?.image = UIImage(systemName: "person.circle.fill"); cell.imageView?.tintColor = .lightGray
        switch m.role {
        case 1: cell.detailTextLabel?.text = "群主"; cell.detailTextLabel?.textColor = .themePrimary
        case 2: cell.detailTextLabel?.text = "管理员"; cell.detailTextLabel?.textColor = .systemOrange
        default: cell.detailTextLabel?.text = ""
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let m = members[indexPath.row]
        navigationController?.pushViewController(ContactDetailViewController(uid: m.uid), animated: true)
    }
}

// MARK: - 设置群备注
class SetGroupRemarkViewController: UIViewController {
    private var groupId: String
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群备注"
        view.backgroundColor = .themeBackground
        textField.placeholder = "请输入群备注"
        textField.borderStyle = .roundedRect; textField.font = ScreenAdapter.font(16)
        textField.text = UserDefaults.standard.string(forKey: "group_remark_\(groupId)")
        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = ScreenAdapter.font(17); saveButton.backgroundColor = .themePrimary
        saveButton.setTitleColor(.white, for: .normal); saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [textField, saveButton]); stack.axis = .vertical; stack.spacing = ScreenAdapter.scaleH(16)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24)); make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        textField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func save() {
        UserDefaults.standard.set(textField.text, forKey: "group_remark_\(groupId)")
        AppUtility.showToast("已保存"); navigationController?.popViewController(animated: true)
    }
}

// MARK: - 修改群名
class UpdateGroupNameViewController: UIViewController {
    private var groupId: String
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "修改群名"
        view.backgroundColor = .themeBackground
        textField.placeholder = "请输入群名称"
        textField.borderStyle = .roundedRect; textField.font = ScreenAdapter.font(16)
        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = ScreenAdapter.font(17); saveButton.backgroundColor = .themePrimary
        saveButton.setTitleColor(.white, for: .normal); saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [textField, saveButton]); stack.axis = .vertical; stack.spacing = ScreenAdapter.scaleH(16)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24)); make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        textField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func save() {
        guard let name = textField.text, !name.isEmpty else { AppUtility.showToast("请输入群名"); return }
        AppUtility.showToast("已修改"); navigationController?.popViewController(animated: true)
    }
}
