//
//  TagMemberSelectViewController.swift
//  Milo
//
//  标签模块 - 选择标签成员
//  功能：通讯录成员多选、A-Z索引、搜索、底部确定按钮
//

import UIKit
import SnapKit

// MARK: - 标签成员选择控制器
class TagMemberSelectViewController: UIViewController {

    // MARK: - 回调
    var onMembersSelected: (([TagMember]) -> Void)?

    // MARK: - UI 组件
    private let titleBarView = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .custom)

    private let searchContainer = UIView()
    private let searchIconImageView = UIImageView()
    private let searchTextField = UITextField()

    private let tableView = UITableView()

    // 底部确定栏
    private let bottomBar = UIView()
    private let confirmButton = UIButton(type: .system)
    private var bottomBarBottomConstraint: Constraint?

    // 右侧索引条
    private let indexSidebar = UIView()
    private var indexButtons: [UIButton] = []

    // MARK: - 动画相关
    private var hasAnimatedEntrance = false

    // MARK: - 数据
    private var allContacts: [TagMember] = []
    private var filteredContacts: [TagMember] = []
    private var isSearching: Bool = false
    private var selectedMemberIDs: Set<String> = []

    // MARK: - 初始化
    init(selectedMembers: [TagMember]) {
        self.selectedMemberIDs = Set(selectedMembers.map { $0.uid })
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMockContacts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !hasAnimatedEntrance && !displayContacts.isEmpty
            && AnimationIntegration.shared.config.enableListEntranceAnimation {
            hasAnimatedEntrance = true
            tableView.animateCellsFadeInUp(delayPerItem: 0.03)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - 设置 UI
    private func setupUI() {
        view.backgroundColor = .themeBg

        // MARK: 标题栏
        titleBarView.backgroundColor = .themeBgWhite
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        // 返回按钮
        let backConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: backConfig), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.addPressScaleEffect()
        titleBarView.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // 标题
        titleLabel.text = "选择成员"
        titleLabel.font = ScreenAdapter.boldFont(18)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // MARK: 搜索栏
        searchContainer.backgroundColor = .themeBgInput
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
        searchTextField.placeholder = AppStrings.Search.searchPlaceholder
        searchTextField.font = ScreenAdapter.font(14)
        searchTextField.textColor = .label
        searchTextField.tintColor = .themeColorPrimary
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

        // MARK: 列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TagMemberSelectCell.self, forCellReuseIdentifier: "TagMemberSelectCell")
        tableView.rowHeight = 56
        tableView.backgroundColor = .themeBgWhite
        tableView.separatorColor = .themeSeparatorLight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .interactive
        tableView.allowsMultipleSelection = true
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-68)
        }

        // MARK: 右侧字母索引条
        setupIndexSidebar()

        // MARK: 底部确定栏
        bottomBar.backgroundColor = .themeBgWhite
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
            bottomBarBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).constraint
        }

        // 顶部分割线
        let topLine = UIView()
        topLine.backgroundColor = .themeSeparatorLight
        bottomBar.addSubview(topLine)
        topLine.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // 确定按钮
        confirmButton.setTitle("确定 (\(selectedMemberIDs.count))", for: .normal)
        confirmButton.titleLabel?.font = ScreenAdapter.font(16, weight: .semibold)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.backgroundColor = .themeColorPrimary
        confirmButton.layer.cornerRadius = 22
        confirmButton.clipsToBounds = true
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        confirmButton.addPressScaleEffect()
        bottomBar.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
            make.height.equalTo(44)
        }

        updateConfirmButton()
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
            btn.setTitleColor(.themeColorPrimary, for: .normal)
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

    // MARK: - 加载模拟联系人数据
    private func loadMockContacts() {
        // 生成模拟联系人
        let names = [
            "艾丽丝", "白晓峰", "陈思远", "丁小雨", "董明辉",
            "范思琪", "冯志刚", "高海燕", "郭建华", "韩雪梅",
            "何俊杰", "侯文博", "黄丽华", "贾晓东", "蒋美玲",
            "金鑫宇", "康晓燕", "孔德明", "雷建军", "李春燕",
            "李明辉", "林晓彤", "刘建国", "卢晓峰", "陆诗涵",
            "罗志强", "吕梦琪", "马晓东", "毛振华", "孟繁伟",
            "倪雅琴", "聂宇航", "潘志伟", "彭晓芳", "钱多多",
            "秦天宇", "邱淑芬", "任盈盈", "尚志强", "邵佳怡",
            "沈晓明", "石晓峰", "史文博", "宋佳慧", "苏晓燕",
            "孙伟强", "谭丽华", "汤明辉", "唐晓宇", "田晓光"
        ]

        allContacts = names.enumerated().map { index, name in
            TagMember(
                uid: "mock_member_\(index + 1)",
                name: name,
                avatar: ""
            )
        }
        filteredContacts = allContacts
        tableView.reloadData()
    }

    // MARK: - 显示数据
    private var displayContacts: [TagMember] {
        return isSearching ? filteredContacts : allContacts
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

    private var sectionedContacts: [[TagMember]] {
        return sectionTitles.map { title in
            displayContacts.filter { member in
                pinyinFirstLetter(of: member.name) == title
            }
        }
    }

    // MARK: - 更新确定按钮
    private func updateConfirmButton() {
        let count = selectedMemberIDs.count
        confirmButton.setTitle("确定 (\(count))", for: .normal)
        confirmButton.isEnabled = count > 0
        confirmButton.alpha = count > 0 ? 1.0 : 0.5
    }

    // MARK: - 按钮点击
    @objc private func backButtonTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func confirmButtonTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }

        let selectedMembers = allContacts.filter { selectedMemberIDs.contains($0.uid) }
        onMembersSelected?(selectedMembers)
        navigationController?.popViewController(animated: true)
    }

    @objc private func indexButtonTapped(_ sender: UIButton) {
        guard let letter = sender.titleLabel?.text else { return }
        let sectionIndex = sectionTitles.firstIndex(of: letter) ?? 0
        if sectionIndex < sectionTitles.count {
            tableView.scrollToRow(at: IndexPath(row: 0, section: sectionIndex), at: .top, animated: true)
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
    }

    @objc private func searchTextDidChange(_ textField: UITextField) {
        let searchText = textField.text ?? ""
        isSearching = !searchText.isEmpty
        if isSearching {
            filteredContacts = allContacts.filter { $0.name.contains(searchText) }
        } else {
            filteredContacts = allContacts
        }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension TagMemberSelectViewController: UITableViewDataSource, UITableViewDelegate {

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagMemberSelectCell", for: indexPath) as! TagMemberSelectCell
        let member = sectionedContacts[indexPath.section][indexPath.row]
        let isSelected = selectedMemberIDs.contains(member.uid)
        cell.configure(with: member, isSelected: isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let member = sectionedContacts[indexPath.section][indexPath.row]

        if selectedMemberIDs.contains(member.uid) {
            selectedMemberIDs.remove(member.uid)
        } else {
            selectedMemberIDs.insert(member.uid)
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }

        tableView.reloadRows(at: [indexPath], with: .none)
        updateConfirmButton()
    }
}

// MARK: - UITextFieldDelegate
extension TagMemberSelectViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 成员选择 Cell
class TagMemberSelectCell: UITableViewCell {

    // MARK: - UI 组件
    private let checkBoxView = UIView()
    private let checkImageView = UIImageView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()

    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        contentView.backgroundColor = .white
        selectionStyle = .none

        // 复选框
        checkBoxView.layer.cornerRadius = 11
        checkBoxView.layer.borderWidth = 1.5
        checkBoxView.layer.borderColor = UIColor.systemGray4.cgColor
        checkBoxView.backgroundColor = .clear
        contentView.addSubview(checkBoxView)
        checkBoxView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }

        // 勾选图标
        let checkConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        checkImageView.image = UIImage(systemName: "checkmark", withConfiguration: checkConfig)
        checkImageView.tintColor = .white
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.isHidden = true
        checkBoxView.addSubview(checkImageView)
        checkImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // 头像
        avatarLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        avatarLabel.textAlignment = .center
        avatarLabel.backgroundColor = .systemGray5
        avatarLabel.textColor = .white
        avatarLabel.layer.cornerRadius = 20
        avatarLabel.clipsToBounds = true
        contentView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkBoxView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // 名称
        nameLabel.font = ScreenAdapter.font(15)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarLabel.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
    }

    func configure(with member: TagMember, isSelected: Bool) {
        nameLabel.text = member.name
        avatarLabel.text = String(member.name.prefix(1))

        // 随机头像背景色（基于名称哈希）
        let hash = abs(member.name.hashValue) % 6
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.42, blue: 0.48, alpha: 1.0),
            UIColor(red: 1.0, green: 0.66, blue: 0.25, alpha: 1.0),
            UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0),
            UIColor(red: 0.36, green: 0.55, blue: 0.94, alpha: 1.0),
            UIColor(red: 0.65, green: 0.45, blue: 0.94, alpha: 1.0),
            UIColor(red: 0.15, green: 0.65, blue: 0.60, alpha: 1.0)
        ]
        avatarLabel.backgroundColor = colors[hash]

        if isSelected {
            checkBoxView.backgroundColor = .themeColorPrimary
            checkBoxView.layer.borderColor = UIColor.themeColorPrimary.cgColor
            checkImageView.isHidden = false
        } else {
            checkBoxView.backgroundColor = .clear
            checkBoxView.layer.borderColor = UIColor.systemGray4.cgColor
            checkImageView.isHidden = true
        }
    }
}
