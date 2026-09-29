//
//  RobotListViewController.swift
//  Milo
//
//  机器人模块 - 机器人列表页
//  功能：搜索、分段控件（全部/我的）、列表展示、添加按钮弹跳动画
//

import UIKit
import SnapKit

// MARK: - 机器人列表控制器
class RobotListViewController: UIViewController {

    // MARK: - UI 组件
    private let titleBarView = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .custom)

    private let searchContainer = UIView()
    private let searchIconImageView = UIImageView()
    private let searchTextField = UITextField()

    private let segmentControl = UISegmentedControl(items: [AppStrings.Common.all, AppStrings.Robot.myRobots])

    private let tableView = UITableView()

    // MARK: - 动画相关
    private var hasAnimatedEntrance = false

    // MARK: - 数据
    private var allRobots: [Robot] = []
    private var filteredRobots: [Robot] = []
    private var isSearching: Bool = false
    private var selectedSegment: Int = 0 {
        didSet {
            filterRobots()
            tableView.reloadData()
        }
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 列表入场动画
        if !hasAnimatedEntrance && !displayRobots.isEmpty
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
        titleLabel.text = AppStrings.Robot.robots
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
        searchTextField.placeholder = AppStrings.Robot.searchPlaceholder
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

        // MARK: 分段控件
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segmentControl)
        segmentControl.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }

        // MARK: 列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RobotListCell.self, forCellReuseIdentifier: "RobotListCell")
        tableView.rowHeight = 72
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .interactive

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - 加载数据
    private func loadData() {
        allRobots = RobotManager.shared.robots
        filteredRobots = allRobots
        filterRobots()
        tableView.reloadData()
    }

    // MARK: - 过滤机器人
    private func filterRobots() {
        var result: [Robot]

        // 先按分段过滤
        switch selectedSegment {
        case 1: // 我的
            result = RobotManager.shared.myRobots
        default: // 全部
            result = RobotManager.shared.robots
        }

        // 再按搜索关键词过滤
        if isSearching, let keyword = searchTextField.text, !keyword.isEmpty {
            result = result.filter { robot in
                robot.name.lowercased().contains(keyword.lowercased())
                || robot.description.lowercased().contains(keyword.lowercased())
                || robot.category.lowercased().contains(keyword.lowercased())
            }
        }

        filteredRobots = result
    }

    private var displayRobots: [Robot] {
        return filteredRobots
    }

    // MARK: - 按钮点击
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        selectedSegment = sender.selectedSegmentIndex

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }

        // 重新触发入场动画
        hasAnimatedEntrance = false
        if AnimationIntegration.shared.config.enableListEntranceAnimation {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                self.hasAnimatedEntrance = true
                self.tableView.animateCellsFadeInUp(delayPerItem: 0.03)
            }
        }
    }

    @objc private func searchTextDidChange(_ textField: UITextField) {
        let searchText = textField.text ?? ""
        isSearching = !searchText.isEmpty
        filterRobots()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension RobotListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayRobots.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RobotListCell", for: indexPath) as! RobotListCell
        let robot = displayRobots[indexPath.row]
        cell.configure(with: robot)
        cell.onAddButtonTapped = { [weak self] in
            self?.handleAddButtonTapped(at: indexPath)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let robot = displayRobots[indexPath.row]
        let chatVC = RobotChatViewController(robot: robot)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    // MARK: - 添加按钮处理
    private func handleAddButtonTapped(at indexPath: IndexPath) {
        guard indexPath.row < displayRobots.count else { return }
        let robot = displayRobots[indexPath.row]

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }

        if robot.isAdded {
            // 已添加 → 移除
            RobotManager.shared.removeRobot(robot.id)
            AppUtility.showToast("已移除 \(robot.name)")
        } else {
            // 未添加 → 添加
            RobotManager.shared.addRobot(robot.id)
            AppUtility.showToast("已添加 \(robot.name)")

            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.notificationSuccess()
            }
        }

        // 刷新数据
        filterRobots()

        // 如果是"我的"分段，移除后可能需要更新
        if selectedSegment == 1 {
            tableView.reloadData()
        } else {
            // 只刷新对应行
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

// MARK: - UITextFieldDelegate
extension RobotListViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 机器人列表 Cell
class RobotListCell: UITableViewCell {

    // MARK: - 回调
    var onAddButtonTapped: (() -> Void)?

    // MARK: - UI 组件
    private let cardView = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let categoryLabel = UILabel()
    private let addButton = UIButton(type: .custom)

    private var robot: Robot?

    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // 卡片背景（液态玻璃风格）
        cardView.backgroundColor = .themeBgWhite
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
        }

        // 头像（emoji）
        avatarLabel.font = UIFont.systemFont(ofSize: 28)
        avatarLabel.textAlignment = .center
        avatarLabel.backgroundColor = .themeBgGrayF5
        avatarLabel.layer.cornerRadius = 22
        avatarLabel.clipsToBounds = true
        cardView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        // 名称
        nameLabel.font = ScreenAdapter.font(16, weight: .semibold)
        nameLabel.textColor = .label
        cardView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
        }

        // 分类标签
        categoryLabel.font = ScreenAdapter.font(10)
        categoryLabel.textColor = .themeColorPrimary
        categoryLabel.backgroundColor = UIColor.themeColorPrimary.withAlphaComponent(0.1)
        categoryLabel.layer.cornerRadius = 4
        categoryLabel.clipsToBounds = true
        categoryLabel.textAlignment = .center
        cardView.addSubview(categoryLabel)
        categoryLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.centerY.equalTo(nameLabel)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(32)
        }

        // 描述
        descLabel.font = ScreenAdapter.font(12)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 1
        cardView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarLabel.snp.trailing).offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.equalTo(addButton.snp.leading).offset(-8)
        }

        // 添加按钮
        addButton.titleLabel?.font = ScreenAdapter.font(13, weight: .medium)
        addButton.layer.cornerRadius = 14
        addButton.clipsToBounds = true
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.addPressScaleEffect()
        cardView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(64)
            make.height.equalTo(28)
        }
    }

    // MARK: - 配置
    func configure(with robot: Robot) {
        self.robot = robot
        avatarLabel.text = robot.avatar
        nameLabel.text = robot.name
        descLabel.text = robot.description
        categoryLabel.text = robot.category

        // 分类标签内边距
        categoryLabel.text = robot.category
        categoryLabel.sizeToFit()

        updateAddButtonState(isAdded: robot.isAdded)
    }

    private func updateAddButtonState(isAdded: Bool) {
        if isAdded {
            addButton.setTitle(AppStrings.Robot.added, for: .normal)
            addButton.setTitleColor(.secondaryLabel, for: .normal)
            addButton.backgroundColor = .themeBgGrayF5
            addButton.layer.borderWidth = 0
        } else {
            addButton.setTitle(AppStrings.Robot.addRobot, for: .normal)
            addButton.setTitleColor(.white, for: .normal)
            addButton.backgroundColor = .themeColorPrimary
            addButton.layer.borderWidth = 0
        }
    }

    // MARK: - 按钮点击
    @objc private func addButtonTapped() {
        guard let robot = robot else { return }

        // 弹跳动画
        addBounceAnimation()

        onAddButtonTapped?()
    }

    private func addBounceAnimation() {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }

        let originalTransform = addButton.transform
        addButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.3,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseInOut) {
            self.addButton.transform = originalTransform
        }
    }
}
