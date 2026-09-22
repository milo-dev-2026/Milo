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
    private let titleGradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .custom)

    // MARK: - 搜索栏（液态玻璃风格）
    private let searchContainer = UIView()
    private let searchBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialLight))
    private let searchIconImageView = UIImageView()
    private let searchTextField = UITextField()

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
        view.backgroundColor = .themeBackground
        navigationController?.setNavigationBarHidden(true, animated: false)

        // MARK: 标题栏（48pt 高，渐变背景）
        titleBarView.backgroundColor = .clear
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }

        // 渐变背景
        titleGradientLayer.colors = [
            UIColor.themePrimary.withAlphaComponent(0.08).cgColor,
            UIColor.themeBackground.cgColor
        ]
        titleGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        titleGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        titleBarView.layer.insertSublayer(titleGradientLayer, at: 0)

        // 标题
        titleLabel.text = "通讯录"
        titleLabel.font = ScreenAdapter.boldFont(18)
        titleLabel.textColor = .themeTextPrimary
        titleLabel.textAlignment = .center
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 加号按钮（24x24pt，15pt 右边距）
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

        // 搜索图标（16x16pt）
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
        searchTextField.textColor = .themeTextPrimary
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

        // MARK: 列表区域（白色背景 + 下拉刷新 + 字母索引）
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.rowHeight = ScreenAdapter.scaleH(56)
        tableView.backgroundColor = .themeCardBackground
        tableView.separatorColor = .themeSeparator
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(64), bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.sectionIndexColor = .themePrimary
        tableView.sectionIndexBackgroundColor = .clear

        // 下拉刷新
        refreshControl.tintColor = .themePrimary
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        titleGradientLayer.frame = titleBarView.bounds
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

    @objc private func showFriendApplyList() {
        navigationController?.pushViewController(FriendApplyListViewController(), animated: true)
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

    // MARK: - A-Z 分组数据
    /// 按姓名首字母分组的标题数组
    private var sectionTitles: [String] {
        let names = displayContacts.map { String($0.name.first ?? "#") }
        let letters = Set(names.map { $0.uppercased() })
        return letters.sorted { (lhs, rhs) -> Bool in
            // # 排在最后
            if lhs == "#" { return false }
            if rhs == "#" { return true }
            return lhs < rhs
        }
    }

    /// 按首字母分组的二维数组
    private var sectionedContacts: [[User]] {
        return sectionTitles.map { title in
            displayContacts.filter { user in
                let first = String(user.name.first ?? "#").uppercased()
                return first == title
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
        header.textLabel?.textColor = .themeTextSecondary
        header.backgroundView?.backgroundColor = .themeCardBackground
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

        backgroundColor = .themeCardBackground
        contentView.backgroundColor = .themeCardBackground

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
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
