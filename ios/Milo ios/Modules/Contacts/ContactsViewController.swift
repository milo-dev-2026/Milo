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

    // MARK: - 入口项数据（与 Android 图标对应：新的朋友/保存的群聊/加入的群/文件传输助手/系统通知）
    private let headerEntries: [(icon: String, title: String, action: Selector)] = [
        ("person.badge.plus", "新的朋友", #selector(showFriendApplyList)),
        ("square.grid.2x2.fill", "保存的群聊", #selector(showSavedGroups)),
        ("person.3.fill", "加入的群聊", #selector(showJoinedGroups)),
        ("folder.fill", "文件传输助手", #selector(showFileHelper)),
        ("bell.badge.fill", "系统通知", #selector(showSystemNotice))
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
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        // MARK: 标题栏
        titleBarView.backgroundColor = .white
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        // 标题
        titleLabel.text = "通讯录"
        titleLabel.font = ScreenAdapter.boldFont(20)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // MARK: 搜索栏
        searchContainer.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        searchContainer.layer.cornerRadius = 18
        searchContainer.clipsToBounds = true
        view.addSubview(searchContainer)
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(titleBarView.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(36)
        }

        // 搜索图标
        searchIconImageView.image = UIImage(systemName: "magnifyingglass")
        searchIconImageView.tintColor = .secondaryLabel
        searchIconImageView.contentMode = .scaleAspectFit
        searchContainer.addSubview(searchIconImageView)
        searchIconImageView.snp.makeConstraints { make in
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
        tableView.rowHeight = 56
        tableView.backgroundColor = .white
        tableView.separatorColor = UIColor(white: 0, alpha: 0.08)
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

    private func loadData() {
        Task {
            do {
                let friends: [FriendSyncInfo] = try await APIClient.shared.requestFlexible(.syncFriends)
                contacts = friends.map { $0.toUser() }.sorted { $0.name < $1.name }
                filteredContacts = contacts
                DispatchQueue.main.async {
                    self.rebuildSections()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载通讯录失败")
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
        guard let firstChar = name.first else { return "#" }
        if firstChar.isASCII && firstChar.isLetter {
            return String(firstChar).uppercased()
        }
        let mutableStr = NSMutableString(string: String(firstChar))
        CFStringTransform(mutableStr, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableStr, nil, kCFStringTransformStripDiacritics, false)
        let pinyin = mutableStr as String
        if let first = pinyin.first, first.isLetter, first.isASCII {
            return String(first).uppercased()
        }
        return "#"
    }

    /// 一次性构建分组快照，保证 sections 与 sectionIndexTitles 严格一一对应
    private func rebuildSections() {
        var buckets: [String: [User]] = [:]
        for user in displayContacts {
            let key = pinyinFirstLetter(of: user.name)
            buckets[key, default: []].append(user)
        }
        let titles = buckets.keys.sorted { lhs, rhs -> Bool in
            if lhs == "#" { return false }
            if rhs == "#" { return true }
            return lhs < rhs
        }
        groupedContacts = titles.map { title in
            (title: title, users: buckets[title]?.sorted { $0.name < $1.name } ?? [])
        }
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
        return groupedContacts[section].users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        cell.configure(with: groupedContacts[indexPath.section].users[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = groupedContacts[indexPath.section].users[indexPath.row]
        let detailVC = ContactDetailViewController(uid: user.uid)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
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
    private let arrowView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white

        let iconSize: CGFloat = 40
        let hPad: CGFloat = 12

        // 图标背景：浅色模式淡蓝 #E3F2FD
        let iconBgColor = UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.11, green: 0.16, blue: 0.24, alpha: 1.0)
            }
            return UIColor(red: 227.0 / 255.0, green: 242.0 / 255.0, blue: 253.0 / 255.0, alpha: 1.0)
        }

        iconView.layer.cornerRadius = 10
        iconView.clipsToBounds = true
        iconView.contentMode = .center
        iconView.backgroundColor = iconBgColor
        iconView.tintColor = .themeColorPrimary
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
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        iconView.image = UIImage(systemName: icon, withConfiguration: config)
        titleLabel.text = title
    }
}

// MARK: - 联系人Cell
class ContactCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

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

        backgroundColor = .white
        contentView.backgroundColor = .white

        avatarView.layer.cornerRadius = 6
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        nameLabel.font = ScreenAdapter.font(15)
        nameLabel.textColor = .label

        contentView.addSubviews(avatarView, nameLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(hPad)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-hPad)
        }
    }

    func configure(with user: User) {
        nameLabel.text = user.name
        AppUtility.loadChannelAvatar(channelId: user.uid, channelType: 1, name: user.name, into: avatarView)
    }
}
