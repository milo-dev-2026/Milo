import UIKit
import SnapKit
import Kingfisher

// MARK: - 通讯录
class ContactsViewController: UIViewController {

    // MARK: - 数据
    private let tableView = UITableView()
    private var contacts: [User] = []
    private var filteredContacts: [User] = []
    private var isSearching: Bool = false
    private var groupedContacts: [(title: String, users: [User])] = []

    // MARK: - 标题栏
    private let titleBarView = UIView()
    private let titleLabel = UILabel()

    // MARK: - 搜索栏
    private let searchContainer = UIView()
    private let searchIconImageView = UIImageView()
    private let searchTextField = UITextField()

    // MARK: - 入口项数据（与 Android 通讯录头部一致：新朋友/保存的群聊/我加入的群/文件传输助手/系统通知）
    private let headerEntries: [(icon: String, title: String, action: Selector)] = [
        ("person.badge.plus", "新朋友", #selector(showFriendApplyList)),
        ("seal.fill", "保存的群聊", #selector(showSavedGroups)),
        ("message.fill", "我加入的群", #selector(showJoinedGroups)),
        ("folder.fill", "文件传输助手", #selector(showFileHelper)),
        ("", "系统账号", #selector(showSystemNotice))
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleContactsSynced(_:)),
            name: NSNotification.Name("ContactsSynced"), object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc private func handleContactsSynced(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadData()
        }
    }

    private func setupUI() {
        view.backgroundColor = .themeBg
        navigationController?.setNavigationBarHidden(true, animated: false)

        // MARK: 标题栏（小字体 inline，位于安全区内不受灵动岛遮挡）
        titleBarView.backgroundColor = .themeBg
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        // 标题
        titleLabel.text = "通讯录"
        titleLabel.font = ScreenAdapter.boldFont(17)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // MARK: 搜索栏（胶囊）
        searchContainer.backgroundColor = .secondarySystemFill
        searchContainer.layer.cornerRadius = 19
        searchContainer.clipsToBounds = true
        view.addSubview(searchContainer)
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(titleBarView.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(38)
        }

        // 搜索图标
        searchIconImageView.image = UIImage(systemName: "magnifyingglass",
                                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))
        searchIconImageView.tintColor = .secondaryLabel
        searchIconImageView.contentMode = .scaleAspectFit
        searchContainer.addSubview(searchIconImageView)
        searchIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // 搜索输入框
        searchTextField.placeholder = "搜索"
        searchTextField.font = ScreenAdapter.font(15)
        searchTextField.textColor = .label
        searchTextField.tintColor = .themePrimary
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextDidChange(_:)), for: .editingChanged)
        searchContainer.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.leading.equalTo(searchIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }

        // MARK: 列表区域
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.rowHeight = 60
        tableView.backgroundColor = .themeBgWhite
        tableView.separatorColor = UIColor(white: 0, alpha: 0.06)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.sectionIndexColor = .themePrimary
        tableView.sectionIndexBackgroundColor = .clear
        tableView.keyboardDismissMode = .interactive

        // 入口项作为tableHeaderView
        updateTableHeader()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func updateTableHeader() {
        let headerHeight = CGFloat(headerEntries.count) * 56 + 8
        let headerView = ContactsHeaderView(entries: headerEntries, target: self, frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight))
        tableView.tableHeaderView = headerView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let header = tableView.tableHeaderView as? ContactsHeaderView {
            header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: header.bounds.height)
        }
    }

    // MARK: - 入口项点击
    @objc private func showFriendApplyList() {
        let vc = NewFriendsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func showSavedGroups() {
        let vc = SavedGroupsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func showJoinedGroups() {
        let vc = JoinedGroupsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func showFileHelper() {
        let vc = FileHelperViewController(mode: .fileHelper)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func showSystemNotice() {
        let vc = FileHelperViewController(mode: .systemNotice)
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 通讯录本地缓存（先渲染缓存再拉网络，对齐安卓本地优先）
    private static let contactsCacheKey = "contacts_cache_v1"

    private func loadData() {
        // 系统账号/文件传输助手保留在 header 入口里，过滤掉后端同步到好友列表的重复条目
        let isSystemUid: (String) -> Bool = { uid in
            let lower = uid.lowercased()
            return ["system_file_helper", "filehelper", "system_notice", "u_10000", "system_team"].contains(lower)
        }
        let isSystemName: (String) -> Bool = { name in
            name.contains("系统账号") || name.contains("系统通知") || name.contains("文件传输助手")
        }

        // 先渲染本地缓存好友列表，避免空白等待
        if let data = UserDefaults.standard.data(forKey: ContactsViewController.contactsCacheKey),
           let cached = try? JSONDecoder().decode([User].self, from: data) {
            let filtered = cached.filter { !isSystemUid($0.uid) && !isSystemName($0.name) }
            contacts = filtered
            filteredContacts = filtered
            rebuildSections()
        }

        Task {
            do {
                let friends: [FriendSyncInfo] = try await APIClient.shared.requestFlexible(.syncFriends)
                let list = friends.map { $0.toUser() }
                    .filter { !isSystemUid($0.uid) && !isSystemName($0.name) }
                    .sorted { $0.name < $1.name }
                // 写入本地缓存供下次秒开
                if let data = try? JSONEncoder().encode(list) {
                    UserDefaults.standard.set(data, forKey: ContactsViewController.contactsCacheKey)
                }
                contacts = list
                filteredContacts = list
                DispatchQueue.main.async {
                    self.rebuildSections()
                }
            } catch {
                DispatchQueue.main.async {
                    if self.contacts.isEmpty {
                        AppUtility.showToast("加载通讯录失败")
                    }
                }
            }
        }
    }

    // MARK: - 搜索处理
    @objc private func searchTextDidChange(_ textField: UITextField) {
        let searchText = textField.text ?? ""
        isSearching = !searchText.isEmpty
        filteredContacts = contacts.filter { $0.name.contains(searchText) }
        rebuildSections()
    }

    private var displayContacts: [User] {
        return isSearching ? filteredContacts : contacts
    }

    // MARK: - 拼音首字母
    private func pinyinFirstLetter(of name: String) -> String {
        PinyinHelper.firstLetter(of: name)
    }

    /// 一次性构建分组快照，保证 sections 与 sectionIndexTitles 严格一一对应
    private func rebuildSections() {
        groupedContacts = PinyinHelper.sections(displayContacts, name: { $0.name })
            .map { (title: $0.letter, users: $0.items) }
        tableView.reloadData()
    }

    // MARK: - 获取联系人数量
    private var contactsCount: Int {
        return contacts.count
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedContacts.count
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return groupedContacts.map { $0.title }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // 数据刷新与布局存在时序差，越界时返回 nil 而不是崩溃
        guard section < groupedContacts.count else { return nil }
        return groupedContacts[section].title
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = ScreenAdapter.font(12, weight: .medium)
        header.textLabel?.textColor = .secondaryLabel
        header.backgroundView?.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < groupedContacts.count else { return 0 }
        return groupedContacts[section].users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        guard indexPath.section < groupedContacts.count,
              indexPath.row < groupedContacts[indexPath.section].users.count else { return cell }
        cell.configure(with: groupedContacts[indexPath.section].users[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < groupedContacts.count,
              indexPath.row < groupedContacts[indexPath.section].users.count else { return }
        let user = groupedContacts[indexPath.section].users[indexPath.row]
        let detailVC = ContactDetailViewController(uid: user.uid)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < groupedContacts.count else { return UIView() }
        // 最后一个 section 的 footer 显示联系人总数
        if section == groupedContacts.count - 1 {
            let footerView = UIView()
            footerView.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
            let countLabel = UILabel()
            countLabel.text = "\(contactsCount) 位联系人"
            countLabel.font = ScreenAdapter.font(12)
            countLabel.textColor = .secondaryLabel
            countLabel.textAlignment = .center
            footerView.addSubview(countLabel)
            countLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            return footerView
        }
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == groupedContacts.count - 1 {
            return 40
        }
        return 0.01
    }
}

// MARK: - UITextFieldDelegate
extension ContactsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 入口项容器视图
class ContactsHeaderView: UIView {
    private let stackView = UIStackView()

    init(entries: [(icon: String, title: String, action: Selector)], target: Any?, frame: CGRect) {
        super.init(frame: frame)
        setupUI(entries: entries, target: target)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(entries: [(icon: String, title: String, action: Selector)], target: Any?) {
        backgroundColor = .white

        stackView.axis = .vertical
        stackView.spacing = 0
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        for entry in entries {
            let cell = ContactsHeaderCell()
            cell.configure(icon: entry.icon, title: entry.title)
            let tap = UITapGestureRecognizer(target: target, action: entry.action)
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
            stackView.addArrangedSubview(cell)
            cell.snp.makeConstraints { make in
                make.height.equalTo(56)
            }
        }

        // 底部分隔区域
        let spacer = UIView()
        spacer.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        stackView.addArrangedSubview(spacer)
        spacer.snp.makeConstraints { make in
            make.height.equalTo(8)
        }
    }
}

// MARK: - 入口项Cell
class ContactsHeaderCell: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let officialBadge = UIImageView()
    private let robotBadge = UIImageView()
    private let arrowView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite

        let iconSize: CGFloat = 40
        let hPad: CGFloat = 16

        iconView.layer.cornerRadius = 11
        iconView.clipsToBounds = true
        iconView.contentMode = .center
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }

        titleLabel.font = ScreenAdapter.font(16)
        titleLabel.textColor = .label
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        // 「官方」红框徽章（文件传输助手/系统通知）
        officialBadge.contentMode = .scaleAspectFit
        officialBadge.isHidden = true
        addSubview(officialBadge)
        officialBadge.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
        }

        // 「机器人」蓝框徽章（仅系统通知）
        robotBadge.contentMode = .scaleAspectFit
        robotBadge.isHidden = true
        addSubview(robotBadge)
        robotBadge.snp.makeConstraints { make in
            make.leading.equalTo(officialBadge.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
        }

        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = UIColor(white: 0.8, alpha: 1.0)
        arrowView.contentMode = .scaleAspectFit
        addSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // 底部分割线
        let line = UIView()
        line.backgroundColor = UIColor(white: 0, alpha: 0.06)
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad + iconSize + 12)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func configure(icon: String, title: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        titleLabel.text = title
        iconView.image = icon.isEmpty ? nil : UIImage(systemName: icon, withConfiguration: config)
        iconView.contentMode = .center
        officialBadge.isHidden = true
        robotBadge.isHidden = true

        // 图标样式对齐安卓通讯录头部
        switch title {
        case "新朋友":
            iconView.backgroundColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 217.0/255.0, alpha: 1.0)
            iconView.tintColor = .white
        case "保存的群聊":
            iconView.backgroundColor = UIColor(red: 245.0/255.0, green: 108.0/255.0, blue: 108.0/255.0, alpha: 1.0)
            iconView.tintColor = .white
        case "我加入的群":
            iconView.backgroundColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 217.0/255.0, alpha: 1.0)
            iconView.tintColor = .white
        case "文件传输助手":
            iconView.backgroundColor = UIColor(red: 76.0/255.0, green: 175.0/255.0, blue: 80.0/255.0, alpha: 1.0)
            iconView.tintColor = .white
            officialBadge.image = ConversationCell.makeTextBadge("官方", colorHex: "F53F3F")
            officialBadge.isHidden = false
        case "系统账号":
            // 对齐安卓：系统账号使用 Milo Logo 头像
            iconView.image = UIImage(named: "LoginLogo")
            iconView.contentMode = .scaleAspectFill
            iconView.backgroundColor = .clear
            officialBadge.image = ConversationCell.makeTextBadge("官方", colorHex: "F53F3F")
            officialBadge.isHidden = false
            robotBadge.image = ConversationCell.makeTextBadge("机器人", colorHex: "165DFF")
            robotBadge.isHidden = false
        default:
            iconView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
            iconView.tintColor = .themeColorPrimary
        }
    }
}

// MARK: - 联系人Cell
class ContactCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    /// 当前 cell 绑定的 uid，防止异步回调串数据
    private var currentUid = ""

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let avatarSize: CGFloat = 44
        let hPad: CGFloat = 16

        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite

        avatarView.layer.cornerRadius = 11
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label

        statusLabel.font = ScreenAdapter.font(12)
        statusLabel.textColor = .secondaryLabel
        statusLabel.isHidden = true

        contentView.addSubviews(avatarView, nameLabel, statusLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(hPad)
            make.trailing.equalToSuperview().offset(-hPad)
            make.centerY.equalToSuperview().offset(-9)
        }

        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-hPad)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentUid = ""
        statusLabel.isHidden = true
        statusLabel.text = nil
        nameLabel.attributedText = nil
        nameLabel.text = nil
        nameLabel.textColor = .label
    }

    func configure(with user: User) {
        currentUid = user.uid
        AppUtility.loadChannelAvatar(channelId: user.uid, channelType: 1, name: user.name, into: avatarView)

        // 特殊好友（西安雷虎虎）：红色昵称 + 西安/押金商家徽章 + 在线状态副标题
        if SpecialUserUtils.isSpecialUser(uid: user.uid, shortNo: "", name: user.name) {
            nameLabel.attributedText = SpecialUserUtils.attributedName(
                user.name, font: nameLabel.font, color: SpecialUserUtils.specialUserNameColor)
            nameLabel.snp.updateConstraints { make in
                make.centerY.equalToSuperview().offset(-9)
            }
            loadOnlineStatus(uid: user.uid)
        } else {
            nameLabel.text = user.name
            nameLabel.snp.updateConstraints { make in
                make.centerY.equalToSuperview().offset(0)
            }
        }
    }

    /// 拉取频道信息，展示「在线 / 上次在线时间 xx」（对齐安卓）
    private func loadOnlineStatus(uid: String) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: uid, channelType: 1))
                DispatchQueue.main.async {
                    guard self.currentUid == uid else { return }
                    if (info.online ?? 0) == 1 {
                        self.statusLabel.text = "在线"
                    } else if let last = info.last_offline, last > 0 {
                        self.statusLabel.text = "上次在线时间 \(ContactCell.lastOfflineText(seconds: last))"
                    }
                    self.statusLabel.isHidden = self.statusLabel.text == nil
                }
            } catch { }
        }
    }

    private static func lastOfflineText(seconds: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let cal = Calendar.current
        let fmt = DateFormatter()
        if cal.isDateInToday(date) {
            fmt.dateFormat = "HH:mm"
        } else if cal.isDateInYesterday(date) {
            fmt.dateFormat = "昨天 HH:mm"
        } else {
            fmt.dateFormat = "MM-dd HH:mm"
        }
        return fmt.string(from: date)
    }
}
