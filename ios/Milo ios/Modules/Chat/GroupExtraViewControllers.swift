import UIKit
import SnapKit

// MARK: - 群二维码
class GroupQRCodeViewController: UIViewController {
    private let groupId: String
    private let groupName: String
    private let qrImageView = UIImageView()
    private let nameLabel = UILabel()
    private let tipLabel = UILabel()

    init(groupId: String, groupName: String) {
        self.groupId = groupId
        self.groupName = groupName
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群二维码"
        view.backgroundColor = .themeBackground

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.backgroundColor = .white
        qrImageView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        qrImageView.clipsToBounds = true

        nameLabel.text = groupName
        nameLabel.font = ScreenAdapter.mediumFont(18)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center

        tipLabel.text = "扫一扫二维码，加入群聊"
        tipLabel.font = ScreenAdapter.font(14)
        tipLabel.textColor = .secondaryLabel
        tipLabel.textAlignment = .center

        view.addSubviews(qrImageView, nameLabel, tipLabel)

        qrImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(40))
            make.width.height.equalTo(ScreenAdapter.scaleW(240))
        }

        nameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(qrImageView.snp.bottom).offset(ScreenAdapter.scaleH(20))
        }

        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
        }

        generateQRCode()
    }

    private func generateQRCode() {
        let qrString = "milo://group?\(groupId)"
        guard let data = qrString.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else { return }
        let scaleX = qrImageView.bounds.width / outputImage.extent.width
        let scaleY = qrImageView.bounds.height / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: max(scaleX, scaleY), y: max(scaleX, scaleY)))
        qrImageView.image = UIImage(ciImage: scaledImage)
    }
}

// MARK: - 群黑名单
class GroupBlackListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [GroupMember] = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群黑名单"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "GBLCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "添加",
            style: .plain,
            target: self,
            action: #selector(addToBlackList)
        )
        navigationItem.rightBarButtonItem?.tintColor = .themePrimary

        loadBlackList()
    }

    private func loadBlackList() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.getGroupBlackList(groupId: groupId))
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

    @objc private func addToBlackList() {
        let vc = ChooseContactsViewController()
        vc.onContactsSelected = { [weak self] (uids: [String]) in
            guard let self = self, let uid = uids.first else { return }
            self.addMemberToBlackList(uid: uid)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func addMemberToBlackList(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.addToBlackList(groupId: groupId, uid: uid))
                DispatchQueue.main.async {
                    AppUtility.showToast("已加入黑名单")
                    self.loadBlackList()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("添加失败")
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(members.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GBLCell", for: indexPath) as! GroupMemberCell
        if members.isEmpty {
            cell.textLabel?.text = "暂无黑名单用户"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.selectionStyle = .none
        } else {
            let m = members[indexPath.row]
            cell.configure(with: m)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !members.isEmpty else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "移出") { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            let m = self.members[indexPath.row]
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.removeFromBlackList(groupId: self.groupId, uid: m.uid))
                    DispatchQueue.main.async {
                        self.members.remove(at: indexPath.row)
                        tableView.reloadData()
                        AppUtility.showToast("已移出黑名单")
                        completionHandler(true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("操作失败")
                        completionHandler(false)
                    }
                }
            }
        }
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteMembers))
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? max(readMembers.count, 1) : max(unreadMembers.count, 1) }
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
