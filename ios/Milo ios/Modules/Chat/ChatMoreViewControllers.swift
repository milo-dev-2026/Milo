//
//  ChatMoreViewControllers.swift
//  Milo
//
//  聊天模块补充页面
//  包含：群成员消息搜索、指定用户聊天记录、聊天背景完善
//

import UIKit
import SnapKit

// MARK: - 群成员消息搜索
class SearchWithMemberViewController: UIViewController {

    private let groupId: String
    private let searchBar = UISearchBar()
    private let memberCollectionView: UICollectionView
    private let resultTableView = UITableView()

    private var members: [GroupMember] = []
    private var selectedMember: GroupMember?
    private var results: [Message] = []

    init(groupId: String) {
        self.groupId = groupId
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 56, height: 68)
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        memberCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMembers()
    }

    private func setupUI() {
        title = "搜索群成员消息"
        view.backgroundColor = .themeBg

        // 搜索栏
        searchBar.placeholder = "搜索消息内容"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        navigationItem.titleView = searchBar

        // 成员横向滚动选择
        memberCollectionView.backgroundColor = .clear
        memberCollectionView.showsHorizontalScrollIndicator = false
        memberCollectionView.dataSource = self
        memberCollectionView.delegate = self
        memberCollectionView.register(MemberSearchCell.self, forCellWithReuseIdentifier: "MemberSearchCell")
        view.addSubview(memberCollectionView)
        memberCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(76)
        }

        // 结果表格
        resultTableView.dataSource = self
        resultTableView.delegate = self
        resultTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchResultCell")
        resultTableView.rowHeight = 60
        resultTableView.backgroundColor = .clear
        resultTableView.separatorColor = .themeSeparatorLight
        resultTableView.tableFooterView = UIView()
        view.addSubview(resultTableView)
        resultTableView.snp.makeConstraints { make in
            make.top.equalTo(memberCollectionView.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func loadMembers() {
        // 模拟群成员数据
        members = [
            GroupMember(uid: "all", name: "全部", avatar: nil, role: 0),
            GroupMember(uid: "u1", name: "张三", avatar: nil, role: 0),
            GroupMember(uid: "u2", name: "李四", avatar: nil, role: 0),
            GroupMember(uid: "u3", name: "王五", avatar: nil, role: 1),
            GroupMember(uid: "u4", name: "赵六", avatar: nil, role: 0),
            GroupMember(uid: "u5", name: "孙七", avatar: nil, role: 0),
            GroupMember(uid: "u6", name: "周八", avatar: nil, role: 0),
            GroupMember(uid: "u7", name: "吴九", avatar: nil, role: 0),
        ]
        selectedMember = members.first
        memberCollectionView.reloadData()
    }

    private func searchMessages() {
        guard let keyword = searchBar.text, !keyword.isEmpty else {
            results = []
            resultTableView.reloadData()
            return
        }

        // 模拟搜索结果
        results = [
            Message(messageID: "1", fromUID: "u1", channelID: groupId, content: keyword + "相关内容1", timestamp: Date().addingTimeInterval(-3600), status: 0),
            Message(messageID: "2", fromUID: "u2", channelID: groupId, content: keyword + "相关内容2", timestamp: Date().addingTimeInterval(-7200), status: 0),
            Message(messageID: "3", fromUID: "u1", channelID: groupId, content: "另一条" + keyword, timestamp: Date().addingTimeInterval(-86400), status: 0),
        ]
        resultTableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate
extension SearchWithMemberViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchMessages()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchMessages()
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension SearchWithMemberViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return members.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemberSearchCell", for: indexPath) as! MemberSearchCell
        let member = members[indexPath.item]
        let isSelected = selectedMember?.uid == member.uid
        cell.configure(with: member, isSelected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedMember = members[indexPath.item]
        memberCollectionView.reloadData()
        searchMessages()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SearchWithMemberViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)
        let msg = results[indexPath.row]
        cell.textLabel?.text = msg.content
        cell.textLabel?.font = ThemeFont.body(15)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.text = AppUtility.formatTimestamp(Int64(msg.timestamp.timeIntervalSince1970 * 1000))
        cell.detailTextLabel?.font = ThemeFont.tiny(12)
        cell.detailTextLabel?.textColor = .themeTextTertiary
        cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        cell.imageView?.tintColor = .systemGray5
        cell.backgroundColor = .themeBgWhite
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 跳转到对应消息位置
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - 成员搜索 Cell
class MemberSearchCell: UICollectionViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.clear.cgColor
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(36)
        }

        nameLabel.font = ThemeFont.tiny(11)
        nameLabel.textColor = .themeTextSecondary
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(4)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    func configure(with member: GroupMember, isSelected: Bool) {
        nameLabel.text = member.name
        nameLabel.textColor = isSelected ? .themeColorPrimary : .themeTextSecondary
        avatarView.layer.borderColor = isSelected ? UIColor.themeColorPrimary.cgColor : UIColor.clear.cgColor
    }
}

// MARK: - 指定用户聊天记录
class ChatWithFromUIDViewController: UIViewController {

    private let channelId: String
    private let targetUID: String
    private let targetName: String
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private var messages: [Message] = []

    init(channelId: String, targetUID: String, targetName: String) {
        self.channelId = channelId
        self.targetUID = targetUID
        self.targetName = targetName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMessages()
    }

    private func setupUI() {
        title = "\(targetName) 的消息"
        view.backgroundColor = .themeBg

        searchBar.placeholder = "搜索 \(targetName) 的消息"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserMsgCell")
        tableView.rowHeight = 60
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableHeaderView = searchBar
        searchBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadMessages() {
        // 模拟数据
        messages = [
            Message(messageID: "1", fromUID: targetUID, channelID: channelId, content: "你好，在吗？", timestamp: Date().addingTimeInterval(-3600), status: 0),
            Message(messageID: "2", fromUID: targetUID, channelID: channelId, content: "关于项目的事情想跟你聊一下", timestamp: Date().addingTimeInterval(-3500), status: 0),
            Message(messageID: "3", fromUID: targetUID, channelID: channelId, content: "方便的时候回复我一下", timestamp: Date().addingTimeInterval(-3400), status: 0),
            Message(messageID: "4", fromUID: targetUID, channelID: channelId, content: "明天有空吗？", timestamp: Date().addingTimeInterval(-7200), status: 0),
            Message(messageID: "5", fromUID: targetUID, channelID: channelId, content: "收到请回复", timestamp: Date().addingTimeInterval(-86400), status: 0),
        ]
        tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate
extension ChatWithFromUIDViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 过滤消息
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatWithFromUIDViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserMsgCell", for: indexPath)
        let msg = messages[indexPath.row]
        cell.textLabel?.text = msg.content
        cell.textLabel?.font = ThemeFont.body(15)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.text = AppUtility.formatTimestamp(Int64(msg.timestamp.timeIntervalSince1970 * 1000))
        cell.detailTextLabel?.font = ThemeFont.tiny(12)
        cell.detailTextLabel?.textColor = .themeTextTertiary
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .themeBgWhite
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - 聊天背景列表（完善版）
class ChatBackgroundListViewController: UIViewController {

    enum BackgroundSection: Int {
        case preset = 0
        case custom = 1
        case solidColor = 2
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let presetBackgrounds = [
        "bg_white", "bg_blue", "bg_green", "bg_pink", "bg_purple", "bg_orange"
    ]
    private let customBackgrounds: [String] = []
    private let solidColors: [UIColor] = [
        .white, .themeBg, .themeColorPrimary.withAlphaComponent(0.1),
        UIColor(red: 0.95, green: 0.9, blue: 0.85, alpha: 1.0),
        UIColor(red: 0.85, green: 0.95, blue: 0.85, alpha: 1.0),
        UIColor(red: 0.85, green: 0.9, blue: 0.95, alpha: 1.0),
    ]

    var onSelected: ((String?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "聊天背景"
        view.backgroundColor = .themeBg

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatBackgroundCell.self, forCellWithReuseIdentifier: "BGCenterCell")
        tableView.register(ChatBackgroundSolidCell.self, forCellWithReuseIdentifier: "BGSolidCell")

        // 底部重置按钮
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 80))
        footerView.backgroundColor = .clear

        let resetBtn = UIButton(type: .system)
        resetBtn.setTitle("恢复默认背景", for: .normal)
        resetBtn.titleLabel?.font = ThemeFont.body(15)
        resetBtn.setTitleColor(.themeTextSecondary, for: .normal)
        resetBtn.addTarget(self, action: #selector(resetBackground), for: .touchUpInside)
        footerView.addSubview(resetBtn)
        resetBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }

        tableView.tableFooterView = footerView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func resetBackground() {
        onSelected?(nil)
        AppUtility.showToast("已恢复默认")
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatBackgroundListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch BackgroundSection(rawValue: section) {
        case .preset: return "推荐背景"
        case .custom: return "我的背景"
        case .solidColor: return "纯色背景"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch BackgroundSection(rawValue: indexPath.section) {
        case .custom:
            return customBackgrounds.isEmpty ? 80 : 120
        default:
            return 120
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch BackgroundSection(rawValue: indexPath.section) {
        case .preset:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BGCenterCell", for: indexPath) as! ChatBackgroundCell
            cell.configure(with: presetBackgrounds, isCustom: false)
            cell.onSelected = { [weak self] index in
                guard let self = self else { return }
                self.onSelected?(self.presetBackgrounds[index])
                self.navigationController?.popViewController(animated: true)
            }
            return cell

        case .custom:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BGCenterCell", for: indexPath) as! ChatBackgroundCell
            cell.configure(with: customBackgrounds, isCustom: true)
            cell.onAddCustom = { [weak self] in
                AppUtility.showToast("从相册选择")
            }
            return cell

        case .solidColor:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BGSolidCell", for: indexPath) as! ChatBackgroundSolidCell
            cell.configure(with: solidColors)
            cell.onSelected = { [weak self] index in
                AppUtility.showToast("已选择纯色背景")
                self?.navigationController?.popViewController(animated: true)
            }
            return cell

        default:
            return UITableViewCell()
        }
    }
}

// MARK: - 聊天背景 Cell（横向滚动）
class ChatBackgroundCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {

    private let collectionView: UICollectionView
    private var backgrounds: [String] = []
    private var isCustom = false

    var onSelected: ((Int) -> Void)?
    var onAddCustom: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 70, height: 100)
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ChatBGItemCell.self, forCellWithReuseIdentifier: "BGItemCell")
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with backgrounds: [String], isCustom: Bool) {
        self.backgrounds = backgrounds
        self.isCustom = isCustom
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isCustom {
            return backgrounds.count + 1 // +1 for add button
        }
        return backgrounds.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BGItemCell", for: indexPath) as! ChatBGItemCell

        if isCustom && indexPath.item == backgrounds.count {
            cell.configureAsAddButton()
        } else {
            let index = isCustom ? indexPath.item - 1 : indexPath.item
            cell.configure(with: backgrounds[index])
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isCustom && indexPath.item == backgrounds.count {
            onAddCustom?()
        } else {
            let index = isCustom ? indexPath.item - 1 : indexPath.item
            onSelected?(index)
        }
    }
}

// MARK: - 纯色背景 Cell
class ChatBackgroundSolidCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {

    private let collectionView: UICollectionView
    private var colors: [UIColor] = []
    var onSelected: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 20, left: 12, bottom: 20, right: 12)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ChatBGSolidItemCell.self, forCellWithReuseIdentifier: "BGSolidItemCell")
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with colors: [UIColor]) {
        self.colors = colors
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BGSolidItemCell", for: indexPath) as! ChatBGSolidItemCell
        cell.configure(with: colors[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelected?(indexPath.item)
    }
}

// MARK: - 背景图 Cell
class ChatBGItemCell: UICollectionViewCell {

    private let bgImageView = UIImageView()
    private let addImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.layer.cornerRadius = 6
        bgImageView.clipsToBounds = true
        bgImageView.layer.borderWidth = 1
        bgImageView.layer.borderColor = UIColor.themeSeparator.cgColor
        contentView.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addImageView.image = UIImage(systemName: "plus")
        addImageView.tintColor = .themeTextTertiary
        addImageView.contentMode = .scaleAspectFit
        addImageView.isHidden = true
        contentView.addSubview(addImageView)
        addImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    func configure(with bgName: String) {
        bgImageView.image = UIImage(named: bgName)
        if bgImageView.image == nil {
            // 用渐变色代替
            bgImageView.backgroundColor = .themeBgCard
        }
        addImageView.isHidden = true
        bgImageView.isHidden = false
    }

    func configureAsAddButton() {
        bgImageView.isHidden = true
        addImageView.isHidden = false
        contentView.backgroundColor = .themeBgInput
        contentView.layer.cornerRadius = 6
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.themeSeparator.cgColor
    }
}

// MARK: - 纯色背景 Item Cell
class ChatBGSolidItemCell: UICollectionViewCell {

    private let colorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        colorView.layer.cornerRadius = 30
        colorView.layer.borderWidth = 1
        colorView.layer.borderColor = UIColor.themeSeparator.cgColor
        colorView.clipsToBounds = true
        contentView.addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with color: UIColor) {
        colorView.backgroundColor = color
    }
}
