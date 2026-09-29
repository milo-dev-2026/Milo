//
//  GroupMuteViewController.swift
//  Milo
//
//  群组禁言管理模块
//  包含：禁言成员管理、群禁言关键词
//

import UIKit
import SnapKit

// MARK: - 禁言成员管理
class ForbiddenGroupMembersViewController: UIViewController {

    private let groupId: String
    private let tableView = UITableView()
    private var mutedMembers: [GroupMember] = []

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
        loadMutedMembers()
    }

    private func setupUI() {
        title = "禁言成员"
        view.backgroundColor = .themeBg

        // 导航栏右侧添加按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addMutedMember)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MutedMemberCell")
        tableView.rowHeight = 56
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 空状态
        let emptyLabel = UILabel()
        emptyLabel.text = "暂无禁言成员"
        emptyLabel.font = ThemeFont.bodySmall(14)
        emptyLabel.textColor = .themeTextHint
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        emptyLabel.tag = 999
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func loadMutedMembers() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.getMutedMembers(groupId: groupId))
                if let data = response["data"] as? [[String: Any]] {
                    mutedMembers = data.compactMap { dict in
                        guard let uid = dict["uid"] as? String,
                              let name = dict["name"] as? String else { return nil }
                        return GroupMember(uid: uid, name: name, avatar: dict["avatar"] as? String, role: 0)
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let emptyLabel = self.view.viewWithTag(999) as? UILabel
                    emptyLabel?.isHidden = !self.mutedMembers.isEmpty
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载失败")
                }
            }
        }
    }

    @objc private func addMutedMember() {
        let pickerVC = ChooseContactsViewController()
        pickerVC.title = "选择禁言成员"
        pickerVC.onSelected = { [weak self] users in
            guard let self = self, let user = users.first else { return }
            self.muteMember(uid: user.uid)
        }
        navigationController?.pushViewController(pickerVC, animated: true)
    }

    private func muteMember(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.muteGroupMember(groupId: groupId, uid: uid, muted: true))
                DispatchQueue.main.async {
                    AppUtility.showToast("已禁言")
                    self.loadMutedMembers()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }

    private func unmuteMember(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.muteGroupMember(groupId: groupId, uid: uid, muted: false))
                DispatchQueue.main.async {
                    AppUtility.showToast("已解除禁言")
                    self.loadMutedMembers()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ForbiddenGroupMembersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mutedMembers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MutedMemberCell", for: indexPath)
        let member = mutedMembers[indexPath.row]

        cell.textLabel?.text = member.name
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        cell.imageView?.tintColor = .systemGray5
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite

        // 解除禁言按钮
        let unmuteButton = UIButton(type: .system)
        unmuteButton.setTitle("解除", for: .normal)
        unmuteButton.titleLabel?.font = ThemeFont.bodySmall(14)
        unmuteButton.setTitleColor(.themeColorPrimary, for: .normal)
        unmuteButton.frame = CGRect(x: 0, y: 0, width: 50, height: 28)
        unmuteButton.tag = indexPath.row
        unmuteButton.addTarget(self, action: #selector(unmuteTapped(_:)), for: .touchUpInside)
        cell.accessoryView = unmuteButton

        return cell
    }

    @objc private func unmuteTapped(_ sender: UIButton) {
        let member = mutedMembers[sender.tag]
        let alert = AlertDialog(
            title: "解除禁言",
            message: "确定要解除 \(member.name) 的禁言吗？"
        )
        alert.onConfirm = { [weak self] in
            self?.unmuteMember(uid: member.uid)
        }
        present(alert, animated: false)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let unmuteAction = UIContextualAction(style: .normal, title: "解除") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            let member = self.mutedMembers[indexPath.row]
            self.unmuteMember(uid: member.uid)
            completion(true)
        }
        unmuteAction.backgroundColor = .themeColorPrimary
        return UISwipeActionsConfiguration(actions: [unmuteAction])
    }
}

// MARK: - 群禁言关键词
class GroupForbiddenWordViewController: UIViewController {

    private let groupId: String
    private let tableView = UITableView()
    private var forbiddenWords: [String] = []

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
        loadForbiddenWords()
    }

    private func setupUI() {
        title = "禁言关键词"
        view.backgroundColor = .themeBg

        // 添加按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addForbiddenWord)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ForbiddenWordCell")
        tableView.rowHeight = 50
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 空状态提示
        let emptyLabel = UILabel()
        emptyLabel.text = "暂无禁言关键词\n添加关键词后，发送包含关键词的消息将被自动禁言"
        emptyLabel.font = ThemeFont.bodySmall(14)
        emptyLabel.textColor = .themeTextHint
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        emptyLabel.tag = 999
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
        }
    }

    private func loadForbiddenWords() {
        // 模拟数据，实际应从 API 加载
        forbiddenWords = ["广告", "诈骗", "违规"]
        tableView.reloadData()

        let emptyLabel = view.viewWithTag(999) as? UILabel
        emptyLabel?.isHidden = !forbiddenWords.isEmpty
    }

    @objc private func addForbiddenWord() {
        let alert = UIAlertController(title: "添加禁言关键词", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "请输入关键词"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "添加", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  !text.isEmpty else { return }
            self.forbiddenWords.append(text)
            self.tableView.reloadData()
            let emptyLabel = self.view.viewWithTag(999) as? UILabel
            emptyLabel?.isHidden = !self.forbiddenWords.isEmpty
            AppUtility.showToast("已添加")
        })
        present(alert, animated: true)
    }

    private func deleteForbiddenWord(at indexPath: IndexPath) {
        forbiddenWords.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)

        let emptyLabel = view.viewWithTag(999) as? UILabel
        emptyLabel?.isHidden = !forbiddenWords.isEmpty
    }
}

// MARK: - UITableViewDataSource & Delegate
extension GroupForbiddenWordViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forbiddenWords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForbiddenWordCell", for: indexPath)
        cell.textLabel?.text = forbiddenWords[indexPath.row]
        cell.textLabel?.font = ThemeFont.body(15)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completion) in
            self?.deleteForbiddenWord(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = .themeError
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - 群待办/提醒
class GroupReminderViewController: UIViewController {

    private let groupId: String
    private let tableView = UITableView()
    private var reminders: [GroupReminder] = []

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
        loadReminders()
    }

    private func setupUI() {
        title = "群待办"
        view.backgroundColor = .themeBg

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addReminder)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupReminderCell.self, forCellReuseIdentifier: "ReminderCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadReminders() {
        // 模拟数据
        reminders = [
            GroupReminder(id: "1", title: "本周项目进度汇报", content: "请各位成员在周五前提交本周工作进度", creator: "张三", createTime: Date().addingTimeInterval(-3600), isDone: false),
            GroupReminder(id: "2", title: "团队会议", content: "明天下午3点线上会议", creator: "李四", createTime: Date().addingTimeInterval(-86400), isDone: true)
        ]
        tableView.reloadData()
    }

    @objc private func addReminder() {
        AppUtility.showToast("添加群待办")
    }
}

struct GroupReminder {
    let id: String
    let title: String
    let content: String
    let creator: String
    let createTime: Date
    var isDone: Bool
}

// MARK: - UITableViewDataSource & Delegate
extension GroupReminderViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath) as! GroupReminderCell
        cell.configure(with: reminders[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - 群待办 Cell
class GroupReminderCell: UITableViewCell {

    private let checkButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let creatorLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        selectionStyle = .none

        checkButton.setImage(UIImage(systemName: "circle"), for: .normal)
        checkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        checkButton.tintColor = .themeColorPrimary
        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)
        contentView.addSubview(checkButton)
        checkButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.width.height.equalTo(22)
        }

        titleLabel.font = ThemeFont.title3(16)
        titleLabel.textColor = .themeTextPrimary
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
        }

        contentLabel.font = ThemeFont.bodySmall(14)
        contentLabel.textColor = .themeTextSecondary
        contentLabel.numberOfLines = 2
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }

        creatorLabel.font = ThemeFont.tiny(12)
        creatorLabel.textColor = .themeTextTertiary
        contentView.addSubview(creatorLabel)
        creatorLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(contentLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    func configure(with reminder: GroupReminder) {
        titleLabel.text = reminder.title
        contentLabel.text = reminder.content
        creatorLabel.text = "\(reminder.creator) · \(AppUtility.formatTimestamp(Int64(reminder.createTime.timeIntervalSince1970 * 1000)))"
        checkButton.isSelected = reminder.isDone

        titleLabel.textColor = reminder.isDone ? .themeTextTertiary : .themeTextPrimary
        contentLabel.textColor = reminder.isDone ? .themeTextHint : .themeTextSecondary
    }

    @objc private func checkTapped() {
        checkButton.isSelected.toggle()
    }
}
