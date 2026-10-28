import UIKit
import SnapKit
import Kingfisher

// MARK: - 选择联系人（发起群聊/添加成员/转发），对齐安卓 ChooseContacts 布局
class ChooseContactsViewController: UIViewController {

    // MARK: - 子视图
    private let searchBar = UIView()
    private let searchIcon = UIImageView()
    private let searchField = UITextField()
    private let searchClearBtn = UIButton(type: .custom)

    private var selectedHeaderHeight: NSLayoutConstraint!
    private var selectedHeader: UICollectionView!

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let indexBar = ContactIndexBar()

    /// 标题栏右侧「确定」按钮（对齐安卓：确定(N)）
    private let navConfirmButton = UIButton(type: .custom)

    // MARK: - 数据
    private var allContacts: [(uid: String, name: String, avatar: String?)] = []
    private var filteredContacts: [(uid: String, name: String, avatar: String?)] = []
    /// 分组后的数据：[首字母: [联系人]]，键已排序
    private var sections: [(letter: String, items: [(uid: String, name: String, avatar: String?)])] = []
    private var selectedOrder: [String] = []   // 保持选择顺序用于顶部头像流
    private var selectedSet: Set<String> = []

    private var maxSelection: Int
    var onSelected: (([(uid: String, name: String)]) -> Void)?
    var onContactsSelected: (([String]) -> Void)?

    init(maxSelection: Int = 9, onSelected: (([(uid: String, name: String)]) -> Void)? = nil) {
        self.maxSelection = maxSelection
        self.onSelected = onSelected
        super.init(nibName: nil, bundle: nil)
        // 进入本页隐藏底部 Tab 栏（对齐安卓全屏选择页）
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择联系人"
        view.backgroundColor = .themeBg
        setupNav()
        setupSearchBar()
        setupSelectedHeader()
        setupTableView()
        loadData()
    }

    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        // 确定按钮放在「选择联系人」标题右侧（对齐安卓标题栏右按钮）
        navConfirmButton.setTitle("确定", for: .normal)
        navConfirmButton.setTitleColor(.white, for: .normal)
        navConfirmButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .disabled)
        navConfirmButton.titleLabel?.font = ScreenAdapter.mediumFont(14)
        navConfirmButton.backgroundColor = .themeColorPrimary
        navConfirmButton.layer.cornerRadius = 15
        navConfirmButton.clipsToBounds = true
        navConfirmButton.isEnabled = false
        navConfirmButton.alpha = 0.4
        navConfirmButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        navConfirmButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        let container = UIView()
        container.addSubview(navConfirmButton)
        navConfirmButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(30)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: container)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - 搜索栏（对齐安卓：圆角浅灰底 + 放大镜 + 清除按钮）
    private func setupSearchBar() {
        searchBar.backgroundColor = .themeBgSearchBar
        searchBar.layer.cornerRadius = 18
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(36)
        }

        searchIcon.image = UIImage(systemName: "magnifyingglass")
        searchIcon.tintColor = .secondaryLabel
        searchIcon.contentMode = .scaleAspectFit
        searchBar.addSubview(searchIcon)
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        searchField.placeholder = "搜索"
        searchField.font = ScreenAdapter.font(14)
        searchField.textColor = .label
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .never
        searchField.addTarget(self, action: #selector(filterContacts), for: .editingChanged)
        searchBar.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-36)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }

        searchClearBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        searchClearBtn.tintColor = UIColor(white: 0.7, alpha: 1)
        searchClearBtn.isHidden = true
        searchClearBtn.addTarget(self, action: #selector(clearSearch), for: .touchUpInside)
        searchBar.addSubview(searchClearBtn)
        searchClearBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    @objc private func clearSearch() {
        searchField.text = ""
        filterContacts()
    }

    // MARK: - 顶部已选联系人横向头像流（对齐安卓 selectUserRecyclerView）
    private func setupSelectedHeader() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 52, height: 72)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        selectedHeader = UICollectionView(frame: .zero, collectionViewLayout: layout)
        selectedHeader.backgroundColor = .clear
        selectedHeader.showsHorizontalScrollIndicator = false
        selectedHeader.dataSource = self
        selectedHeader.delegate = self
        selectedHeader.register(SelectedAvatarCell.self, forCellWithReuseIdentifier: "SelectedAvatarCell")
        view.addSubview(selectedHeader)
        selectedHeader.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        selectedHeaderHeight = selectedHeader.heightAnchor.constraint(equalToConstant: 0)
        selectedHeaderHeight.isActive = true
    }

    // MARK: - 联系人列表（plain样式 + section头 + 右侧字母索引）
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChooseContactCell.self, forCellReuseIdentifier: "ChooseContactCell")
        tableView.rowHeight = 56
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 0, right: 0)
        tableView.separatorColor = .themeSeparator
        tableView.backgroundColor = .themeBg
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(selectedHeader.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        indexBar.onSelect = { [weak self] letter in
            guard let self = self else { return }
            if let idx = self.sections.firstIndex(where: { $0.letter == letter }) {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: false)
            }
        }
        view.addSubview(indexBar)
        indexBar.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-2)
            make.centerY.equalTo(tableView.snp.centerY)
            make.width.equalTo(18)
            make.height.lessThanOrEqualTo(tableView.snp.height).offset(-20)
        }
    }

    private func updateSelectionUI() {
        let has = !selectedOrder.isEmpty
        selectedHeaderHeight.constant = has ? 72 : 0
        // 标题栏确定按钮：带数量，未选时置灰
        navConfirmButton.setTitle(has ? "确定(\(selectedOrder.count))" : "确定", for: .normal)
        navConfirmButton.isEnabled = has
        navConfirmButton.alpha = has ? 1 : 0.4
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        selectedHeader.reloadData()
        if has {
            selectedHeader.scrollToItem(at: IndexPath(item: selectedOrder.count - 1, section: 0), at: .right, animated: true)
        }
    }

    // MARK: - 数据加载与分组
    private static let cacheKey = "choose_contacts_cache_v1"

    private func loadData() {
        // 先渲染本地缓存，避免每次都等网络（提速）
        if let data = UserDefaults.standard.data(forKey: ChooseContactsViewController.cacheKey),
           let cached = try? JSONDecoder().decode([CachedContact].self, from: data),
           !cached.isEmpty {
            allContacts = cached.map { ($0.uid, $0.name, $0.avatar) }
            applyFilter()
        }

        Task {
            do {
                let friends: [FriendSyncInfo] = try await APIClient.shared.requestFlexible(.syncFriends)
                let list = friends.map { ($0.uid, $0.displayName, $0.avatar) }
                // 写入缓存供下次秒开
                let cached = list.map { CachedContact(uid: $0.0, name: $0.1, avatar: $0.2) }
                if let data = try? JSONEncoder().encode(cached) {
                    UserDefaults.standard.set(data, forKey: ChooseContactsViewController.cacheKey)
                }
                DispatchQueue.main.async {
                    self.allContacts = list
                    self.applyFilter()
                }
            } catch {
                DispatchQueue.main.async {
                    if self.allContacts.isEmpty { AppUtility.showToast("加载联系人失败") }
                }
            }
        }
    }

    private struct CachedContact: Codable {
        let uid: String
        let name: String
        let avatar: String?
    }

    @objc private func filterContacts() {
        searchClearBtn.isHidden = (searchField.text ?? "").isEmpty
        applyFilter()
    }

    private func applyFilter() {
        let keyword = (searchField.text ?? "").lowercased()
        filteredContacts = keyword.isEmpty ? allContacts : allContacts.filter { $0.name.lowercased().contains(keyword) }
        rebuildSections()
    }

    /// 按拼音首字母分组排序（对齐安卓 QuickSideBar）
    private func rebuildSections() {
        sections = PinyinHelper.sections(filteredContacts, name: { $0.name })
            .map { (letter: $0.letter, items: $0.items) }
        indexBar.letters = sections.map { $0.letter }
        tableView.reloadData()
    }

    static func firstLetter(of name: String) -> String {
        PinyinHelper.firstLetter(of: name)
    }

    // MARK: - 选择逻辑
    private func toggleSelection(_ uid: String) {
        if selectedSet.contains(uid) {
            selectedSet.remove(uid)
            selectedOrder.removeAll { $0 == uid }
        } else {
            guard selectedSet.count < maxSelection else {
                AppUtility.showToast("最多选择\(maxSelection)位")
                return
            }
            selectedSet.insert(uid)
            selectedOrder.append(uid)
        }
        updateSelectionUI()
        tableView.reloadData()
    }

    @objc private func done() {
        let selected = allContacts.filter { selectedSet.contains($0.uid) }.map { (uid: $0.uid, name: $0.name) }
        onSelected?(selected)
        onContactsSelected?(selected.map { $0.uid })
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableView
extension ChooseContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return max(sections.count, 1)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.isEmpty ? 1 : sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections.isEmpty ? nil : sections[section].letter
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !sections.isEmpty else { return nil }
        let v = UIView()
        v.backgroundColor = .themeBgGrayF5
        let label = UILabel()
        label.text = sections[section].letter
        label.font = ScreenAdapter.mediumFont(13)
        label.textColor = .secondaryLabel
        v.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        return v
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections.isEmpty ? 0 : 24
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseContactCell", for: indexPath) as! ChooseContactCell
        if sections.isEmpty {
            cell.showEmpty("暂无联系人")
            return cell
        }
        let c = sections[indexPath.section].items[indexPath.row]
        cell.configure(uid: c.uid, name: c.name, selected: selectedSet.contains(c.uid))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !sections.isEmpty else { return }
        let c = sections[indexPath.section].items[indexPath.row]
        toggleSelection(c.uid)
    }
}

// MARK: - UICollectionView（顶部已选头像流）
extension ChooseContactsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedOrder.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedAvatarCell", for: indexPath) as! SelectedAvatarCell
        let uid = selectedOrder[indexPath.item]
        let name = allContacts.first { $0.uid == uid }?.name ?? uid
        cell.configure(uid: uid, name: name)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        toggleSelection(selectedOrder[indexPath.item])
    }
}

// MARK: - 联系人Cell：圆形勾选框 + 圆角头像 + 名字
private class ChooseContactCell: UITableViewCell {

    private let checkCircle = UIImageView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .themeBgWhite

        checkCircle.image = UIImage(systemName: "circle")
        checkCircle.tintColor = UIColor(white: 0.75, alpha: 1)
        checkCircle.contentMode = .scaleAspectFit
        contentView.addSubview(checkCircle)
        checkCircle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }

        avatarView.layer.cornerRadius = 6
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.backgroundColor = .themeBgTertiary
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalTo(checkCircle.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(uid: String, name: String, selected: Bool) {
        nameLabel.text = name
        nameLabel.textAlignment = .left
        avatarView.isHidden = false
        checkCircle.isHidden = false
        AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: name, into: avatarView)
        checkCircle.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        checkCircle.tintColor = selected ? .themeColorPrimary : UIColor(white: 0.75, alpha: 1)
    }

    func showEmpty(_ text: String) {
        nameLabel.text = text
        nameLabel.textAlignment = .center
        avatarView.isHidden = true
        checkCircle.isHidden = true
        avatarView.image = nil
    }
}

// MARK: - 顶部已选头像Cell
private class SelectedAvatarCell: UICollectionViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        avatarView.layer.cornerRadius = 6
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.backgroundColor = .themeBgTertiary
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(44)
        }
        nameLabel.font = ScreenAdapter.font(10)
        nameLabel.textColor = .secondaryLabel
        nameLabel.textAlignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(uid: String, name: String) {
        nameLabel.text = name
        AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: name, into: avatarView)
    }
}

// MARK: - 右侧字母索引条
private class ContactIndexBar: UIView {

    var letters: [String] = [] {
        didSet { setNeedsDisplay() }
    }
    var onSelect: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard !letters.isEmpty, let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)
        let itemH = rect.height / CGFloat(letters.count)
        for (i, letter) in letters.enumerated() {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor(white: 0.45, alpha: 1)
            ]
            let str = NSAttributedString(string: letter, attributes: attrs)
            let size = str.size()
            str.draw(at: CGPoint(x: (rect.width - size.width) / 2, y: itemH * CGFloat(i) + (itemH - size.height) / 2))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }

    private func handleTouch(_ touches: Set<UITouch>) {
        guard let point = touches.first?.location(in: self), !letters.isEmpty else { return }
        let itemH = bounds.height / CGFloat(letters.count)
        let idx = Int(point.y / itemH)
        if idx >= 0 && idx < letters.count {
            onSelect?(letters[idx])
        }
    }
}
