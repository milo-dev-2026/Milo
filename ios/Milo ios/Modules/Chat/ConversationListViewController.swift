import UIKit
import SnapKit
import Kingfisher

// MARK: - 会话列表
class ConversationListViewController: UIViewController {

    private let tableView = UITableView()
    private var conversations: [Conversation] = []

    // MARK: - 顶部标题栏
    private let titleBarView = UIView()
    private let titleLabel = UILabel()
    private let deviceButton = UIButton(type: .custom)
    private let searchButton = UIButton(type: .custom)
    private let addButton = UIButton(type: .custom)

    // MARK: - 搜索栏
    private let searchBarContainer = UIView()
    private let searchIconView = UIImageView()
    private let searchTextField = UITextField()

    // MARK: - 弹窗菜单
    private var popupMenuView: PopupMenuView?

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

        // MARK: - 顶部标题栏
        titleBarView.backgroundColor = .white
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        // 左侧设备按钮
        let deviceConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        deviceButton.setImage(UIImage(systemName: "desktopcomputer", withConfiguration: deviceConfig), for: .normal)
        deviceButton.tintColor = .label
        deviceButton.addTarget(self, action: #selector(deviceButtonTapped), for: .touchUpInside)
        titleBarView.addSubview(deviceButton)
        deviceButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // 中间标题 "Milo"
        titleLabel.text = "Milo"
        titleLabel.font = ScreenAdapter.boldFont(20)
        titleLabel.textColor = .label
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 右侧搜索按钮
        let searchConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        searchButton.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: searchConfig), for: .normal)
        searchButton.tintColor = .label
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        titleBarView.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.trailing.equalTo(addButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // 右侧加号按钮
        let addConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        addButton.setImage(UIImage(systemName: "plus.circle", withConfiguration: addConfig), for: .normal)
        addButton.tintColor = .label
        addButton.addTarget(self, action: #selector(showAddMenu), for: .touchUpInside)
        titleBarView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // MARK: - 搜索栏
        searchBarContainer.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        searchBarContainer.layer.cornerRadius = 18
        searchBarContainer.clipsToBounds = true
        view.addSubview(searchBarContainer)
        searchBarContainer.snp.makeConstraints { make in
            make.top.equalTo(titleBarView.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(36)
        }

        // 搜索图标
        searchIconView.image = UIImage(systemName: "magnifyingglass")
        searchIconView.tintColor = .secondaryLabel
        searchIconView.contentMode = .scaleAspectFit
        searchBarContainer.addSubview(searchIconView)
        searchIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // 搜索输入框
        searchTextField.placeholder = "搜索"
        searchTextField.font = ScreenAdapter.font(14)
        searchTextField.textColor = .label
        searchTextField.tintColor = .themePrimary
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
        searchBarContainer.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.leading.equalTo(searchIconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }

        // MARK: - 列表区域
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: "ConversationCell")
        tableView.rowHeight = 64
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.separatorColor = UIColor(white: 0, alpha: 0.08)
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .white
        tableView.keyboardDismissMode = .interactive

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBarContainer.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - 按钮点击
    @objc private func deviceButtonTapped() {
        AppUtility.showToast("PC端登录")
    }

    @objc private func searchButtonTapped() {
        let searchVC = SearchAllViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }

    // MARK: - 加号弹窗菜单
    @objc private func showAddMenu() {
        if popupMenuView != nil {
            closePopupMenu()
            return
        }

        let menu = PopupMenuView(items: [
            ("person.2.fill", "发起群聊"),
            ("qrcode.viewfinder", "扫一扫"),
            ("person.badge.plus", "添加好友")
        ])
        menu.onSelect = { [weak self] index in
            self?.closePopupMenu()
            switch index {
            case 0: self?.startGroupChat()
            case 1: self?.startScan()
            case 2: self?.showAddFriend()
            default: break
            }
        }
        menu.onDismiss = { [weak self] in
            self?.popupMenuView = nil
        }

        view.addSubview(menu)
        let buttonFrame = addButton.convert(addButton.bounds, to: view)
        menu.snp.makeConstraints { make in
            make.top.equalTo(buttonFrame.maxY + 6)
            make.trailing.equalToSuperview().offset(-12)
            make.width.equalTo(160)
        }
        menu.alpha = 0
        UIView.animate(withDuration: 0.2) {
            menu.alpha = 1
        }
        popupMenuView = menu
    }

    private func closePopupMenu() {
        guard let menu = popupMenuView else { return }
        UIView.animate(withDuration: 0.2, animations: {
            menu.alpha = 0
        }) { _ in
            menu.removeFromSuperview()
            self.popupMenuView = nil
        }
    }

    private func startGroupChat() {
        let chooseVC = ChooseContactsViewController(maxSelection: 99)
        chooseVC.title = "选择联系人"
        chooseVC.onContactsSelected = { [weak self] selectedUids in
            self?.createGroup(with: selectedUids)
        }
        navigationController?.pushViewController(chooseVC, animated: true)
    }

    private func createGroup(with uids: [String]) {
        guard !uids.isEmpty else { return }
        AppUtility.showToast("正在创建群聊...")
        Task {
            do {
                let groupId = "group_\(Int(Date().timeIntervalSince1970))"
                let response = try await APIClient.shared.requestRaw(.addGroupMembers(groupId: groupId, uids: uids))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        AppUtility.showToast("群聊创建成功")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("创建群聊失败")
                }
            }
        }
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
        navigationController?.pushViewController(AddFriendViewController(), animated: true)
    }

    private func loadData() {
        Task {
            do {
                let syncResp: WKSyncChat = try await APIClient.shared.requestFlexible(.syncConversations)
                let wkConversations = syncResp.conversations ?? []
                conversations = wkConversations.map { Conversation(from: $0) }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.fetchChannelInfoForConversations()
            } catch {
                print("[ConvList] 加载失败: \(error)")
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

    // MARK: - 搜索
    @objc private func searchTextChanged(_ textField: UITextField) {
        // 实时搜索过滤
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
        let muteAction = UIContextualAction(style: .normal, title: "免打扰") { _, _, completion in
            AppUtility.showToast("已设为免打扰")
            completion(true)
        }
        muteAction.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [deleteAction, muteAction])
    }
}

// MARK: - UITextFieldDelegate
extension ConversationListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 弹窗菜单视图
class PopupMenuView: UIView {

    private let backgroundView = UIView()
    private let stackView = UIStackView()
    var onSelect: ((Int) -> Void)?
    var onDismiss: (() -> Void)?

    init(items: [(icon: String, title: String)]) {
        super.init(frame: .zero)
        setupUI(items: items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(items: [(icon: String, title: String)]) {
        backgroundColor = .clear
        layer.cornerRadius = 12
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.15

        // 背景
        backgroundView.backgroundColor = UIColor.systemBackground
        backgroundView.layer.cornerRadius = 12
        backgroundView.clipsToBounds = true
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        for (index, item) in items.enumerated() {
            let btn = UIButton(type: .system)
            btn.tag = index
            let iconImg = UIImage(systemName: item.icon)
            btn.setImage(iconImg, for: .normal)
            btn.setTitle("  \(item.title)", for: .normal)
            btn.titleLabel?.font = ScreenAdapter.font(15)
            btn.tintColor = .label
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            btn.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(btn)
            btn.snp.makeConstraints { make in
                make.height.equalTo(48)
            }

            // 分割线
            if index < items.count - 1 {
                let line = UIView()
                line.backgroundColor = UIColor(white: 0, alpha: 0.08)
                btn.addSubview(line)
                line.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.trailing.bottom.equalToSuperview()
                    make.height.equalTo(0.5)
                }
            }
        }

        snp.makeConstraints { make in
            make.height.equalTo(CGFloat(items.count) * 48)
        }
    }

    @objc private func itemTapped(_ sender: UIButton) {
        onSelect?(sender.tag)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(handleDismissTap(_:)))
        dismissTap.cancelsTouchesInView = false
        self.superview?.addGestureRecognizer(dismissTap)
    }

    @objc private func handleDismissTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if !self.bounds.contains(location) {
            onDismiss?()
        }
    }
}

// MARK: - 会话Cell
class ConversationCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadBadge = UIView()
    private let unreadLabel = UILabel()
    private let muteIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let avatarSize: CGFloat = 48
        let hPad: CGFloat = 12

        backgroundColor = .white
        contentView.backgroundColor = .white

        // 头像
        avatarView.layer.cornerRadius = 8
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        // 名字
        nameLabel.font = ScreenAdapter.mediumFont(16)
        nameLabel.textColor = .label

        // 最后一条消息
        lastMessageLabel.font = ScreenAdapter.font(13)
        lastMessageLabel.textColor = .secondaryLabel
        lastMessageLabel.numberOfLines = 1

        // 时间
        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.textAlignment = .right

        // 未读红点
        unreadBadge.backgroundColor = .systemRed
        unreadBadge.layer.cornerRadius = 9
        unreadBadge.clipsToBounds = true
        unreadBadge.isHidden = true

        unreadLabel.font = ScreenAdapter.font(10)
        unreadLabel.textColor = .white
        unreadLabel.textAlignment = .center

        // 免打扰图标
        muteIcon.image = UIImage(systemName: "bell.slash.fill")
        muteIcon.tintColor = .systemGray3
        muteIcon.contentMode = .scaleAspectFit
        muteIcon.isHidden = true

        contentView.addSubviews(avatarView, nameLabel, lastMessageLabel, timeLabel, unreadBadge, muteIcon)
        unreadBadge.addSubview(unreadLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(hPad)
            make.top.equalTo(avatarView.snp.top).offset(2)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
        }

        lastMessageLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.bottom.equalTo(avatarView.snp.bottom).offset(-2)
            make.trailing.lessThanOrEqualTo(unreadBadge.snp.leading).offset(-8)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.top).offset(4)
            make.trailing.equalToSuperview().offset(-hPad)
        }

        unreadBadge.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView.snp.bottom).offset(-2)
            make.trailing.equalToSuperview().offset(-hPad)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(18)
        }

        unreadLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(6)
            make.trailing.equalToSuperview().offset(-6)
        }

        muteIcon.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView.snp.bottom).offset(-2)
            make.trailing.equalToSuperview().offset(-hPad)
            make.width.height.equalTo(14)
        }
    }

    func configure(with conversation: Conversation) {
        nameLabel.text = conversation.name
        lastMessageLabel.text = conversation.lastMessage ?? ""
        timeLabel.text = conversation.timeString

        AppUtility.loadAvatar(conversation.avatarURL, into: avatarView)

        if conversation.unreadCount > 0 {
            unreadBadge.isHidden = false
            muteIcon.isHidden = true
            unreadLabel.text = conversation.unreadCount > 99 ? "99+" : "\(conversation.unreadCount)"
        } else {
            unreadBadge.isHidden = true
            // TODO: 根据免打扰状态显示
            muteIcon.isHidden = true
        }
    }
}
