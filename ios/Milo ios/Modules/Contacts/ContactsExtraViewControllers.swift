//
//  ContactsExtraViewControllers.swift
//  Milo
//
//  通讯录模块补充页面
//  包含：新朋友、黑名单
//

import UIKit
import SnapKit
import Kingfisher

// MARK: - 新的朋友
class NewFriendsViewController: UIViewController {

    // MARK: - 数据模型
    struct FriendRequest {
        let uid: String
        let name: String
        let avatar: String?
        let remark: String
        let status: RequestStatus // 0: 待处理, 1: 已接受, 2: 已拒绝
    }

    enum RequestStatus: Int {
        case pending = 0
        case accepted = 1
        case rejected = 2
    }

    // MARK: - UI
    private let tableView = UITableView()
    private var requests: [FriendRequest] = []

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFriendRequests()
    }

    private func setupUI() {
        title = "新的朋友"
        view.backgroundColor = .themeBg

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FriendRequestCell.self, forCellReuseIdentifier: "FriendRequestCell")
        tableView.rowHeight = 64
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 加载数据
    private func loadFriendRequests() {
        // 模拟数据，实际应从 API 加载
        requests = [
            FriendRequest(uid: "user001", name: "张三", avatar: nil, remark: "我是张三，加个好友", status: .pending),
            FriendRequest(uid: "user002", name: "李四", avatar: nil, remark: "来自群聊：产品讨论组", status: .pending),
            FriendRequest(uid: "user003", name: "王五", avatar: nil, remark: "你好，我是王五", status: .accepted)
        ]
        tableView.reloadData()
    }

    // MARK: - 接受好友
    private func acceptFriendRequest(at indexPath: IndexPath) {
        let request = requests[indexPath.row]
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.acceptFriendApply(uid: request.uid))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        AppUtility.showToast("已添加好友")
                        self.loadFriendRequests()
                    }
                } else {
                    DispatchQueue.main.async {
                        AppUtility.showToast("添加失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("添加失败")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NewFriendsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendRequestCell", for: indexPath) as! FriendRequestCell
        cell.configure(with: requests[indexPath.row])
        cell.onAccept = { [weak self] in
            self?.acceptFriendRequest(at: indexPath)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - 好友申请 Cell
class FriendRequestCell: UITableViewCell {

    // MARK: - UI
    private let avatarView = AvatarView()
    private let nameLabel = UILabel()
    private let remarkLabel = UILabel()
    private let statusButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    var onAccept: (() -> Void)?

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

        contentView.addSubviews(avatarView, nameLabel, remarkLabel, statusButton, statusLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        nameLabel.font = ThemeFont.title3(16)
        nameLabel.textColor = .themeTextPrimary
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalTo(avatarView).offset(2)
        }

        remarkLabel.font = ThemeFont.caption(13)
        remarkLabel.textColor = .themeTextSecondary
        remarkLabel.numberOfLines = 1
        remarkLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.trailing.lessThanOrEqualTo(statusButton.snp.leading).offset(-8)
        }

        statusButton.setTitle("接受", for: .normal)
        statusButton.titleLabel?.font = ThemeFont.bodySmall(14)
        statusButton.setTitleColor(.white, for: .normal)
        statusButton.backgroundColor = .themeColorPrimary
        statusButton.layer.cornerRadius = 4
        statusButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        statusButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(28)
        }

        statusLabel.font = ThemeFont.caption(13)
        statusLabel.textColor = .themeTextTertiary
        statusLabel.textAlignment = .right
        statusLabel.isHidden = true
        statusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with request: NewFriendsViewController.FriendRequest) {
        nameLabel.text = request.name
        remarkLabel.text = request.remark

        if let avatar = request.avatar, let url = URL(string: avatar) {
            avatarView.setAvatar(url: url)
        }

        switch request.status {
        case .pending:
            statusButton.isHidden = false
            statusLabel.isHidden = true
        case .accepted:
            statusButton.isHidden = true
            statusLabel.isHidden = false
            statusLabel.text = "已添加"
            statusLabel.textColor = .themeSuccess
        case .rejected:
            statusButton.isHidden = true
            statusLabel.isHidden = false
            statusLabel.text = "已拒绝"
            statusLabel.textColor = .themeTextTertiary
        }
    }

    @objc private func acceptTapped() {
        onAccept?()
    }
}

// MARK: - 黑名单
class BlacklistViewController: UIViewController {

    // MARK: - 数据
    private let tableView = UITableView()
    private var blacklist: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadBlacklist()
    }

    private func setupUI() {
        title = "黑名单"
        view.backgroundColor = .themeBg

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BlacklistCell")
        tableView.rowHeight = 56
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 空状态提示
        let emptyLabel = UILabel()
        emptyLabel.text = "暂无黑名单用户"
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

    private func loadBlacklist() {
        // 模拟数据，实际应从 API 加载
        blacklist = []
        tableView.reloadData()

        let emptyLabel = view.viewWithTag(999) as? UILabel
        emptyLabel?.isHidden = !blacklist.isEmpty
    }

    private func removeFromBlacklist(at indexPath: IndexPath) {
        let user = blacklist[indexPath.row]
        let alert = AlertDialog(
            title: "移除黑名单",
            message: "确定要将 \(user.name) 从黑名单中移除吗？"
        )
        alert.onConfirm = { [weak self] in
            self?.blacklist.remove(at: indexPath.row)
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            AppUtility.showToast("已移除")
        }
        present(alert, animated: false)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension BlacklistViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blacklist.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlacklistCell", for: indexPath)
        let user = blacklist[indexPath.row]

        cell.textLabel?.text = user.name
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        cell.imageView?.tintColor = .systemGray5
        cell.accessoryType = .none
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let removeAction = UIContextualAction(style: .destructive, title: "移除") { [weak self] (_, _, completion) in
            self?.removeFromBlacklist(at: indexPath)
            completion(true)
        }
        removeAction.backgroundColor = .themeError
        return UISwipeActionsConfiguration(actions: [removeAction])
    }
}
