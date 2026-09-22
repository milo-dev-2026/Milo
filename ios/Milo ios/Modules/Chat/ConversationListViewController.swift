import UIKit
import SnapKit
import Kingfisher
import MJRefresh

// MARK: - 会话列表
class ConversationListViewController: UIViewController {

    private let tableView = UITableView()
    private var conversations: [Conversation] = []

    // MARK: - 自定义顶部视图
    private let titleBarView = UIView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)

    // MARK: - 液态玻璃搜索栏
    private let searchBarContainer = UIView()
    private let searchBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let searchIconView = UIImageView()
    private let searchPlaceholderLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        setupIMObserver()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleSyncCompleted(_:)),
            name: NSNotification.Name("ConversationsSynced"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleNewMessage(_:)),
            name: IMManager.messageReceivedNotification, object: nil
        )
    }

    @objc private func handleSyncCompleted(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadData()
        }
    }

    @objc private func handleNewMessage(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        view.backgroundColor = .white

        // MARK: - 顶部标题栏（48pt，白色背景）
        titleBarView.backgroundColor = .white
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        // 居中标题 "消息"
        titleLabel.text = "消息"
        titleLabel.font = ScreenAdapter.boldFont(20)
        titleLabel.textColor = .label
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 右侧加号按钮（40x40pt，右边距 15pt）
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .label
        addButton.addTarget(self, action: #selector(showAddMenu), for: .touchUpInside)
        titleBarView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // MARK: - 液态玻璃搜索栏（36pt高，胶囊形）
        searchBarContainer.layer.cornerRadius = 18
        searchBarContainer.clipsToBounds = true
        view.addSubview(searchBarContainer)
        searchBarContainer.snp.makeConstraints { make in
            make.top.equalTo(titleBarView.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(36)
        }

        // 毛玻璃背景（液态玻璃核心）
        searchBarContainer.addSubview(searchBlurView)
        searchBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 柔光边框效果
        searchBarContainer.layer.borderWidth = 0.5
        searchBarContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor

        // 搜索图标（16x16pt）
        searchIconView.image = UIImage(systemName: "magnifyingglass")
        searchIconView.tintColor = .secondaryLabel
        searchIconView.contentMode = .scaleAspectFit
        searchBarContainer.addSubview(searchIconView)
        searchIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // 搜索提示文字（14pt）
        searchPlaceholderLabel.text = "搜索"
        searchPlaceholderLabel.font = ScreenAdapter.font(14)
        searchPlaceholderLabel.textColor = .secondaryLabel
        searchBarContainer.addSubview(searchPlaceholderLabel)
        searchPlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalTo(searchIconView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }

        // MARK: - 列表区域（白色背景，MJRefresh 下拉刷新）
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: "ConversationCell")
        tableView.rowHeight = 56
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 64, bottom: 0, right: 0)
        tableView.separatorColor = UIColor(white: 0, alpha: 0.1)
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .white

        let header = MJRefreshNormalHeader { [weak self] in
            self?.loadData()
        }
        tableView.mj_header = header

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBarContainer.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
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
                let syncResp: WKSyncChat = try await APIClient.shared.requestFlexible(.syncConversations)
                let wkConversations = syncResp.conversations ?? []
                conversations = wkConversations.map { Conversation(from: $0) }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.mj_header?.endRefreshing()
                }
                self.fetchChannelInfoForConversations()
            } catch {
                print("[ConvList] 加载失败: \(error)")
                DispatchQueue.main.async {
                    AppUtility.showToast("加载失败: \(error.localizedDescription)")
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
        let avatarSize: CGFloat = 40
        let hPad: CGFloat = 12
        let vPad: CGFloat = 2

        avatarView.layer.cornerRadius = 8
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
        unreadBadge.layer.cornerRadius = 9
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
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
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
            make.width.greaterThanOrEqualTo(18)
            make.height.equalTo(18)
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
