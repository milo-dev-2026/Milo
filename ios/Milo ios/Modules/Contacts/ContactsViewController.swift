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

    // MARK: - 标题栏
    private let titleBarView = UIView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .custom)

    // MARK: - 搜索栏（液态玻璃风格）
    private let searchContainer = UIView()
    private let searchBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialLight))
    private let searchIconImageView = UIImageView()
    private let searchTextField = UITextField()

    // MARK: - 入口项数据
    private let headerEntries: [(icon: String, title: String, color: UIColor, action: Selector)] = [
        ("person.crop.circle.badge.plus", "新的朋友", UIColor(red: 1.0, green: 0.42, blue: 0.48, alpha: 1.0), #selector(showFriendApplyList)),
        ("person.2.square.stack.fill", "保存的群聊", UIColor(red: 0.36, green: 0.56, blue: 0.94, alpha: 1.0), #selector(showSavedGroups)),
        ("person.3.sequence", "加入的群聊", UIColor(red: 0.15, green: 0.65, blue: 0.58, alpha: 1.0), #selector(showJoinedGroups)),
        ("doc.text.fill", "文件传输助手", UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0), #selector(showFileHelper)),
        ("bell.fill", "系统通知", UIColor(red: 1.0, green: 0.66, blue: 0.25, alpha: 1.0), #selector(showSystemNotice))
    ]

    // MARK: - 下拉刷新
    private let refreshControl = UIRefreshControl()

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

        // MARK: 标题栏（48pt 高，白色背景）
        titleBarView.backgroundColor = .white
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }

        // 标题
        titleLabel.text = "通讯录"
        titleLabel.font = ScreenAdapter.boldFont(18)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 加号按钮
        addButton.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        addButton.tintColor = .themePrimary
        addButton.addTarget(self, action: #selector(showAddMenu), for: .touchUpInside)
        titleBarView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(15))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(24))
        }

        // MARK: 搜索栏（36pt 高，液态玻璃风格）
        searchContainer.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        searchContainer.layer.cornerRadius = ScreenAdapter.scaleH(18)
        searchContainer.layer.masksToBounds = false
        searchContainer.layer.shadowColor = UIColor.black.cgColor
        searchContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        searchContainer.layer.shadowRadius = 12
        searchContainer.layer.shadowOpacity = 0.06
        view.addSubview(searchContainer)
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(titleBarView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(36))
        }

        // 毛玻璃效果
        searchBlurView.layer.cornerRadius = ScreenAdapter.scaleH(18)
        searchBlurView.layer.masksToBounds = true
        searchContainer.insertSubview(searchBlurView, at: 0)
        searchBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 搜索图标
        searchIconImageView.image = UIImage(systemName: "magnifyingglass")
        searchIconImageView.tintColor = .themeTextTertiary
        searchIconImageView.contentMode = .scaleAspectFit
        searchContainer.addSubview(searchIconImageView)
        searchIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(16))
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
            make.leading.equalTo(searchIconImageView.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }

        // MARK: 列表区域
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.rowHeight = ScreenAdapter.scaleH(56)
        tableView.backgroundColor = .white
        tableView.separatorColor = UIColor(white: 0, alpha: 0.1)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(64), bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.sectionIndexColor = .themePrimary
        tableView.sectionIndexBackgroundColor = .clear
        tableView.keyboardDismissMode = .interactive

        // 下拉刷新
        refreshControl.tintColor = .themePrimary
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // 入口项作为tableHeaderView
        updateTableHeader()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func updateTableHeader() {
        let headerView = ContactsHeaderView(entries: headerEntries, target: self)
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 56 * CGFloat(headerEntries.count) + 8)
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
        navigationController?.pushViewController(FriendApplyListViewController(), animated: true)
    }

    @objc private func showSavedGroups() {
        AppUtility.showToast("保存的群聊")
    }

    @objc private func showJoinedGroups() {
        AppUtility.showToast("加入的群聊")
    }

    @objc private func showFileHelper() {
        AppUtility.showToast("文件传输助手")
    }

    @objc private func showSystemNotice() {
        AppUtility.showToast("系统通知")
    }

    @objc private func startScan() {
        let scanVC = ScanViewController()
        scanVC.onScanResult = { [weak self] result in
            self?.handleScanResult(result)
        }
        navigationController?.pushViewController(scanVC, animated: true)
    }

    @objc private func showAddMenu() {
        let alert = UIAlertController(title: "添加好友", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "搜索用户ID", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(AddFriendViewController(), animated: true)
        })
        alert.addAction(UIAlertAction(title: "扫一扫", style: .default) { [weak self] _ in
            self?.startScan()
        })
        alert.addAction(UIAlertAction(title: "好友申请", style: .default) { [weak self] _ in
            self?.showFriendApplyList()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func handleScanResult(_ result: String) {
        if result.hasPrefix("uid:") {
            let uid = String(result.dropFirst(4))
            applyFriend(uid: uid)
        } else if result.count > 0 {
            applyFriend(uid: result)
        }
    }

    private func applyFriend(uid: String) {
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

    private func loadData() {
        Task {
            do {
                let friends: [FriendSyncInfo] = try await APIClient.shared.requestFlexible(.syncFriends)
                contacts = friends.map { $0.toUser() }.sorted { $0.name < $1.name }
                filteredContacts = contacts
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载通讯录失败")
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }

    // MARK: - 搜索处理
    @objc private func searchTextDidChange(_ textField: UITextField) {
        let searchText = textField.text ?? ""
        isSearching = !searchText.isEmpty
        filteredContacts = contacts.filter { $0.name.contains(searchText) }
        tableView.reloadData()
    }

    // MARK: - 下拉刷新
    @objc private func handleRefresh() {
        loadData()
    }

    private var displayContacts: [User] {
        return isSearching ? filteredContacts : contacts
    }

    // MARK: - 拼音首字母
    private func pinyinFirstLetter(of name: String) -> String {
        guard let firstChar = name.first else { return "#" }
        // 如果是字母，直接返回大写
        if firstChar.isASCII && firstChar.isLetter {
            return String(firstChar).uppercased()
        }
        // 中文名转拼音首字母
        let mutableStr = NSMutableString(string: String(firstChar))
        CFStringTransform(mutableStr, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableStr, nil, kCFStringTransformStripDiacritics, false)
        let pinyin = mutableStr as String
        if let first = pinyin.first, first.isLetter {
            return String(first).uppercased()
        }
        return "#"
    }

    // MARK: - A-Z 分组数据
    private var sectionTitles: [String] {
        let names = displayContacts.map { pinyinFirstLetter(of: $0.name) }
        let letters = Set(names.map { $0.uppercased() })
        return letters.sorted { (lhs, rhs) -> Bool in
            if lhs == "#" { return false }
            if rhs == "#" { return true }
            return lhs < rhs
        }
    }

    private var sectionedContacts: [[User]] {
        return sectionTitles.map { title in
            displayContacts.filter { user in
                pinyinFirstLetter(of: user.name) == title
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionTitles
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ScreenAdapter.scaleH(28)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = ScreenAdapter.font(12, weight: .medium)
        header.textLabel?.textColor = .secondaryLabel
        header.backgroundView?.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionedContacts[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        cell.configure(with: sectionedContacts[indexPath.section][indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = sectionedContacts[indexPath.section][indexPath.row]
        let detailVC = ContactDetailViewController(uid: user.uid)
        navigationController?.pushViewController(detailVC, animated: true)
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
    init(entries: [(icon: String, title: String, color: UIColor, action: Selector)], target: Any?) {
        super.init(frame: .zero)
        setupUI(entries: entries, target: target)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(entries: [(icon: String, title: String, color: UIColor, action: Selector)], target: Any?) {
        backgroundColor = .white

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        for entry in entries {
            let cell = ContactsHeaderCell()
            cell.configure(icon: entry.icon, title: entry.title, color: entry.color)
            let tap = UITapGestureRecognizer(target: target, action: entry.action)
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
            stackView.addArrangedSubview(cell)
            cell.snp.makeConstraints { make in
                make.height.equalTo(56)
            }
        }

        // 底部间距
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

        let iconSize: CGFloat = 36
        let hPad: CGFloat = 12

        // 图标背景（圆角方形）
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
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
        line.backgroundColor = UIColor(white: 0, alpha: 0.1)
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad + iconSize + 12)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func configure(icon: String, title: String, color: UIColor) {
        iconView.image = UIImage(systemName: icon)
        iconView.backgroundColor = color
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
        let avatarSize = ScreenAdapter.scaleW(40)
        let hPad = ScreenAdapter.scaleW(12)

        backgroundColor = .white
        contentView.backgroundColor = .white

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        nameLabel.font = ScreenAdapter.font(15)

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
        AppUtility.loadAvatar(user.avatarURL, into: avatarView)
    }
}
