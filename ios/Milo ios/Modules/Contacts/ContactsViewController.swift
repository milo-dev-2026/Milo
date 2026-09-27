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
    private let searchButton = UIButton(type: .custom)
    private let addButton = UIButton(type: .custom)

    // MARK: - 搜索栏
    private let searchContainer = UIView()
    private let searchIconImageView = UIImageView()
    private let searchTextField = UITextField()

    // MARK: - 右侧字母索引条
    private let indexSidebar = UIView()
    private var indexButtons: [UIButton] = []

    // MARK: - 入口项数据
    private let headerEntries: [(icon: String, title: String, color: UIColor, action: Selector)] = [
        ("person.fill.badge.plus", "新的朋友", UIColor(red: 1.0, green: 0.42, blue: 0.48, alpha: 1.0), #selector(showFriendApplyList)),
        ("person.2.fill", "保存的群聊", UIColor(red: 0.36, green: 0.55, blue: 0.94, alpha: 1.0), #selector(showSavedGroups)),
        ("person.3.fill", "加入的群聊", UIColor(red: 0.15, green: 0.65, blue: 0.60, alpha: 1.0), #selector(showJoinedGroups)),
        ("doc.fill", "文件传输助手", UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0), #selector(showFileHelper)),
        ("bell.badge.fill", "系统通知", UIColor(red: 1.0, green: 0.66, blue: 0.25, alpha: 1.0), #selector(showSystemNotice))
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

        // 搜索按钮
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

        // 加号按钮
        let addConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        addButton.setImage(UIImage(systemName: "person.badge.plus", withConfiguration: addConfig), for: .normal)
        addButton.tintColor = .label
        addButton.addTarget(self, action: #selector(showAddMenu), for: .touchUpInside)
        titleBarView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
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

        // MARK: 右侧字母索引条
        setupIndexSidebar()
    }

    private func setupIndexSidebar() {
        indexSidebar.backgroundColor = .clear
        view.addSubview(indexSidebar)
        indexSidebar.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-4)
            make.centerY.equalTo(tableView)
            make.width.equalTo(20)
        }

        let letters = ["#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        var lastBtn: UIButton?
        for letter in letters {
            let btn = UIButton(type: .system)
            btn.setTitle(letter, for: .normal)
            btn.titleLabel?.font = ScreenAdapter.font(10, weight: .medium)
            btn.setTitleColor(.themePrimary, for: .normal)
            btn.addTarget(self, action: #selector(indexButtonTapped(_:)), for: .touchUpInside)
            indexSidebar.addSubview(btn)
            btn.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(20)
                make.height.equalTo(14)
                if let last = lastBtn {
                    make.top.equalTo(last.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }
            lastBtn = btn
            indexButtons.append(btn)
        }
        lastBtn?.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    @objc private func indexButtonTapped(_ sender: UIButton) {
        guard let letter = sender.titleLabel?.text else { return }
        let sectionIndex = sectionTitles.firstIndex(of: letter) ?? 0
        if sectionIndex < sectionTitles.count {
            tableView.scrollToRow(at: IndexPath(row: 0, section: sectionIndex), at: .top, animated: true)
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

    // MARK: - 按钮点击
    @objc private func searchButtonTapped() {
        let searchVC = GlobalSearchViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }

    // MARK: - 入口项点击
    @objc private func showFriendApplyList() {
        AppUtility.showToast("新的朋友")
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
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "添加好友", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(AddFriendViewController(), animated: true)
        })
        alert.addAction(UIAlertAction(title: "扫一扫", style: .default) { [weak self] _ in
            self?.startScan()
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
        tableView.reloadData()
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

    // MARK: - 获取联系人数量
    private var contactsCount: Int {
        return contacts.count
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
        return 28
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // 最后一个 section 的 footer 显示联系人总数
        if section == sectionTitles.count - 1 {
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
        if section == sectionTitles.count - 1 {
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

    init(entries: [(icon: String, title: String, color: UIColor, action: Selector)], target: Any?, frame: CGRect) {
        super.init(frame: frame)
        setupUI(entries: entries, target: target)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(entries: [(icon: String, title: String, color: UIColor, action: Selector)], target: Any?) {
        backgroundColor = .white

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

        // 图标背景
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.contentMode = .center
        iconView.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconView.preferredSymbolConfiguration = config
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

    func configure(icon: String, title: String, color: UIColor) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconView.image = UIImage(systemName: icon, withConfiguration: config)
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
        AppUtility.loadAvatar(user.avatarURL, into: avatarView)
    }
}
