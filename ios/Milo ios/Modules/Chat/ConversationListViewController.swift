import UIKit
import SnapKit
import Kingfisher
import MJRefresh

// MARK: - 会话列表
class ConversationListViewController: UIViewController {

    private let tableView = UITableView()
    private var conversations: [Conversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        setupIMObserver()
    }

    private func setupUI() {
        title = "Milo"
        view.backgroundColor = .themeBackground

        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(showAddMenu)
        )
        navigationItem.rightBarButtonItem = addButton
        navigationItem.rightBarButtonItem?.tintColor = .themePrimary

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: "ConversationCell")
        tableView.rowHeight = ScreenAdapter.scaleH(72)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(68), bottom: 0, right: 0)
        tableView.tableFooterView = UIView()

        let header = MJRefreshNormalHeader { [weak self] in
            self?.loadData()
        }
        tableView.mj_header = header

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func showAddMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "扫一扫", style: .default) { [weak self] _ in
            self?.startScan()
        })
        alert.addAction(UIAlertAction(title: "添加好友", style: .default) { [weak self] _ in
            self?.showAddFriend()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func startScan() {
        let scanVC = ScanViewController()
        scanVC.onScanResult = { [weak self] result in
            self?.handleScanResult(result)
        }
        navigationController?.pushViewController(scanVC, animated: true)
    }

    private func handleScanResult(_ result: String) {
        let uid: String
        if result.hasPrefix("uid:") {
            uid = String(result.dropFirst(4))
        } else {
            uid = result
        }
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.applyFriend(uid: uid, remark: ""))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        AppUtility.showToast("好友申请已发送")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("发送申请失败")
                }
            }
        }
    }

    private func showAddFriend() {
        let alert = UIAlertController(title: "添加好友", message: "请输入对方ID", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "用户ID"
            tf.keyboardType = .asciiCapable
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "发送申请", style: .default) { [weak self] _ in
            guard let uid = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !uid.isEmpty else { return }
            Task {
                do {
                    let response = try await APIClient.shared.requestRaw(.applyFriend(uid: uid, remark: ""))
                    if response["status"] as? Int == 200 {
                        DispatchQueue.main.async {
                            AppUtility.showToast("好友申请已发送")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("发送申请失败")
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func loadData() {
        Task {
            do {
                let wkConversations: [WKConversation] = try await APIClient.shared.requestFlexible(.syncConversations)
                conversations = wkConversations.map { Conversation(from: $0) }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.mj_header?.endRefreshing()
                }
                self.fetchChannelInfoForConversations()
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载失败")
                    self.tableView.mj_header?.endRefreshing()
                }
            }
        }
    }

    private func fetchChannelInfoForConversations() {
        for (index, conv) in conversations.enumerated() {
            Task {
                do {
                    let channelInfo: ChannelInfo = try await APIClient.shared.requestFlexible(
                        .getChannelInfo(channelId: conv.channelID, channelType: conv.channelType)
                    )
                    DispatchQueue.main.async {
                        if index < self.conversations.count {
                            self.conversations[index].name = channelInfo.displayName
                            self.conversations[index].avatar = channelInfo.logo ?? channelInfo.avatar
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }
                    }
                } catch { }
            }
        }
    }

    private func setupIMObserver() {
        IMManager.shared.onMessageReceived = { [weak self] message in
            self?.loadData()
        }
    }
}

// MARK: - UITableViewDataSource
extension ConversationListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        cell.configure(with: conversations[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ConversationListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        let chatVC = ChatViewController(channelId: conversation.channelID, title: conversation.name, channelType: conversation.channelType)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { _, _, completion in
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - 会话Cell
class ConversationCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadBadge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let avatarSize = ScreenAdapter.scaleW(48)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(2)

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        nameLabel.font = ScreenAdapter.mediumFont(16)
        nameLabel.textColor = .label

        lastMessageLabel.font = ScreenAdapter.font(13)
        lastMessageLabel.textColor = .secondaryLabel
        lastMessageLabel.numberOfLines = 1

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel

        unreadBadge.font = ScreenAdapter.font(11)
        unreadBadge.textColor = .white
        unreadBadge.backgroundColor = .systemRed
        unreadBadge.textAlignment = .center
        unreadBadge.layer.cornerRadius = ScreenAdapter.scaleW(9)
        unreadBadge.clipsToBounds = true
        unreadBadge.isHidden = true

        contentView.addSubviews(avatarView, nameLabel, lastMessageLabel, timeLabel, unreadBadge)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(hPad)
            make.top.equalTo(avatarView.snp.top).offset(vPad)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }

        lastMessageLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.bottom.equalTo(avatarView.snp.bottom).offset(-vPad)
            make.trailing.lessThanOrEqualToSuperview().offset(-hPad)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.top).offset(vPad)
            make.trailing.equalToSuperview().offset(-hPad)
        }

        unreadBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-hPad)
            make.bottom.equalTo(avatarView.snp.bottom).offset(-vPad)
            make.width.greaterThanOrEqualTo(ScreenAdapter.scaleW(18))
            make.height.equalTo(ScreenAdapter.scaleW(18))
        }
    }

    func configure(with conversation: Conversation) {
        nameLabel.text = conversation.name
        lastMessageLabel.text = conversation.lastMessage ?? ""
        timeLabel.text = conversation.timeString

        AppUtility.loadAvatar(conversation.avatarURL, into: avatarView)

        if conversation.unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadBadge.text = conversation.unreadCount > 99 ? "99+" : "\(conversation.unreadCount)"
        } else {
            unreadBadge.isHidden = true
        }
    }
}
