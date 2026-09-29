//
//  TagListViewController.swift
//  Milo
//
//  标签模块 - 标签列表页
//  功能：搜索、新建标签、列表展示、左滑删除
//

import UIKit
import SnapKit

// MARK: - 标签列表控制器
class TagListViewController: UIViewController {

    // MARK: - UI 组件
    private let titleBarView = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .custom)
    private let addButton = UIButton(type: .custom)

    private let searchContainer = UIView()
    private let searchIconImageView = UIImageView()
    private let searchTextField = UITextField()

    private let tableView = UITableView()

    // MARK: - 动画相关
    private var hasAnimatedEntrance = false

    // MARK: - 数据
    private var allTags: [Tag] = []
    private var filteredTags: [Tag] = []
    private var isSearching: Bool = false

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // 每次出现刷新数据
        loadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 列表入场动画
        if !hasAnimatedEntrance && !displayTags.isEmpty
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
        titleLabel.text = AppStrings.Tag.tags
        titleLabel.font = ScreenAdapter.boldFont(18)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 新建按钮
        let addConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: addConfig), for: .normal)
        addButton.tintColor = .label
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.addPressScaleEffect()
        titleBarView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
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
        searchTextField.placeholder = "搜索标签"
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
        tableView.register(TagListCell.self, forCellReuseIdentifier: "TagListCell")
        tableView.rowHeight = 56
        tableView.backgroundColor = .themeBgWhite
        tableView.separatorColor = .themeSeparatorLight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .interactive
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    // MARK: - 加载数据
    private func loadData() {
        allTags = TagManager.shared.allTags
        filteredTags = allTags
        tableView.reloadData()

        // 重置入场动画
        hasAnimatedEntrance = false
    }

    // MARK: - 过滤标签
    private func filterTags(with keyword: String) {
        if keyword.isEmpty {
            filteredTags = allTags
        } else {
            filteredTags = allTags.filter { tag in
                tag.name.lowercased().contains(keyword.lowercased())
            }
        }
        tableView.reloadData()
    }

    private var displayTags: [Tag] {
        return filteredTags
    }

    // MARK: - 按钮点击
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func addButtonTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }

        let detailVC = TagDetailViewController(mode: .create)
        detailVC.onTagCreated = { [weak self] _ in
            self?.loadData()
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc private func searchTextDidChange(_ textField: UITextField) {
        let searchText = textField.text ?? ""
        isSearching = !searchText.isEmpty
        filterTags(with: searchText)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension TagListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayTags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagListCell", for: indexPath) as! TagListCell
        let tag = displayTags[indexPath.row]
        cell.configure(with: tag)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tag = displayTags[indexPath.row]
        let detailVC = TagDetailViewController(mode: .edit(tag: tag))
        detailVC.onTagUpdated = { [weak self] _ in
            self?.loadData()
        }
        detailVC.onTagDeleted = { [weak self] _ in
            self?.loadData()
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - 左滑删除
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return AppStrings.Common.delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tag = displayTags[indexPath.row]
            showDeleteConfirm(for: tag, at: indexPath)
        }
    }

    private func showDeleteConfirm(for tag: Tag, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "删除标签",
            message: AppStrings.Tag.deleteHint,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: AppStrings.Common.delete, style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.impactHeavy()
            }

            TagManager.shared.deleteTag(tag.id)
            self.loadData()
            AppUtility.showToast("已删除标签")
        })
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension TagListViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 标签列表 Cell
class TagListCell: UITableViewCell {

    // MARK: - UI 组件
    private let colorDotView = UIView()
    private let nameLabel = UILabel()
    private let countLabel = UILabel()
    private let arrowView = UIImageView()

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
        accessoryType = .none

        // 颜色圆点
        colorDotView.layer.cornerRadius = 6
        colorDotView.clipsToBounds = true
        contentView.addSubview(colorDotView)
        colorDotView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }

        // 标签名称
        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(colorDotView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        // 成员数量
        countLabel.font = ScreenAdapter.font(14)
        countLabel.textColor = .secondaryLabel
        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }

        // 箭头
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = UIColor(white: 0.8, alpha: 1.0)
        arrowView.contentMode = .scaleAspectFit
        contentView.addSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
    }

    func configure(with tag: Tag) {
        colorDotView.backgroundColor = tag.color
        nameLabel.text = tag.name
        countLabel.text = "\(tag.memberCount)\(AppStrings.Tag.memberCount)"
    }
}
