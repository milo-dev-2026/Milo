//
//  TagDetailViewController.swift
//  Milo
//
//  标签模块 - 标签详情页
//  功能：编辑标签名、选择颜色、管理成员、删除标签
//

import UIKit
import SnapKit

// MARK: - 标签详情模式
enum TagDetailMode {
    case create                 // 新建标签
    case edit(tag: Tag)         // 编辑标签
}

// MARK: - 标签详情控制器
class TagDetailViewController: UIViewController {

    // MARK: - 模式
    private let mode: TagDetailMode

    // MARK: - 回调
    var onTagCreated: ((Tag) -> Void)?
    var onTagUpdated: ((Tag) -> Void)?
    var onTagDeleted: ((String) -> Void)?

    // MARK: - UI 组件
    private let titleBarView = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .custom)
    private let saveButton = UIButton(type: .system)

    private let tableView = UITableView()

    // MARK: - 数据
    private var tagName: String = ""
    private var selectedColor: TagColor = .blue
    private var selectedMembers: [TagMember] = []
    private var tagId: String = ""

    // MARK: - 初始化
    init(mode: TagDetailMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)

        switch mode {
        case .create:
            tagId = UUID().uuidString
            tagName = ""
            selectedColor = .blue
            selectedMembers = []
        case .edit(let tag):
            tagId = tag.id
            tagName = tag.name
            selectedColor = tag.tagColor
            selectedMembers = tag.members
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
        switch mode {
        case .create:
            titleLabel.text = AppStrings.Tag.addTag
        case .edit:
            titleLabel.text = AppStrings.Tag.editTag
        }
        titleLabel.font = ScreenAdapter.boldFont(18)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 保存按钮
        saveButton.setTitle(AppStrings.Tag.save, for: .normal)
        saveButton.titleLabel?.font = ScreenAdapter.font(15, weight: .medium)
        saveButton.tintColor = .themeColorPrimary
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.addPressScaleEffect()
        titleBarView.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        // MARK: 列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BasicCell")
        tableView.register(TagNameCell.self, forCellReuseIdentifier: "TagNameCell")
        tableView.register(TagColorCell.self, forCellReuseIdentifier: "TagColorCell")
        tableView.register(TagMemberPreviewCell.self, forCellReuseIdentifier: "TagMemberPreviewCell")
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .interactive

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleBarView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - 按钮点击
    @objc private func backButtonTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func saveButtonTapped() {
        view.endEditing(true)

        let name = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            AppUtility.showToast("请输入标签名称")
            return
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }

        switch mode {
        case .create:
            let newTag = TagManager.shared.addTag(
                name: name,
                color: selectedColor,
                members: selectedMembers
            )
            onTagCreated?(newTag)
            AppUtility.showToast("标签创建成功")

        case .edit:
            TagManager.shared.updateTag(
                tagId,
                name: name,
                color: selectedColor,
                members: selectedMembers
            )
            if let updatedTag = TagManager.shared.getTag(by: tagId) {
                onTagUpdated?(updatedTag)
            }
            AppUtility.showToast("保存成功")
        }

        navigationController?.popViewController(animated: true)
    }

    // MARK: - 删除标签
    private func deleteTag() {
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

            TagManager.shared.deleteTag(self.tagId)
            self.onTagDeleted?(self.tagId)
            AppUtility.showToast("已删除标签")
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension TagDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        switch mode {
        case .create:
            return 3 // 名称、颜色、成员
        case .edit:
            return 4 // 名称、颜色、成员、删除
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // 标签名称
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagNameCell", for: indexPath) as! TagNameCell
            cell.configure(name: tagName, placeholder: AppStrings.Tag.tagNamePlaceholder)
            cell.onNameChanged = { [weak self] name in
                self?.tagName = name
            }
            return cell

        case 1:
            // 标签颜色
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagColorCell", for: indexPath) as! TagColorCell
            cell.configure(selectedColor: selectedColor)
            cell.onColorSelected = { [weak self] color in
                self?.selectedColor = color
                if AnimationIntegration.shared.config.enableHapticFeedback {
                    HapticManager.shared.selectionChanged()
                }
            }
            return cell

        case 2:
            // 标签成员
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagMemberPreviewCell", for: indexPath) as! TagMemberPreviewCell
            cell.configure(members: selectedMembers)
            return cell

        case 3:
            // 删除标签
            let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
            cell.textLabel?.text = AppStrings.Tag.deleteTag
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.backgroundColor = .themeBgWhite
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 56
        case 1:
            return 72
        case 2:
            return 72
        case 3:
            return 56
        default:
            return 56
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return AppStrings.Tag.tagName
        case 1:
            return "标签颜色"
        case 2:
            return AppStrings.Tag.tagMembers
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 28
        case 1, 2:
            return 32
        default:
            return 20
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = ScreenAdapter.font(12, weight: .medium)
        header.textLabel?.textColor = .secondaryLabel
        header.backgroundView?.backgroundColor = .clear
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        view.endEditing(true)

        switch indexPath.section {
        case 2:
            // 选择成员
            let selectVC = TagMemberSelectViewController(selectedMembers: selectedMembers)
            selectVC.onMembersSelected = { [weak self] members in
                guard let self = self else { return }
                self.selectedMembers = members
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
            }
            navigationController?.pushViewController(selectVC, animated: true)

        case 3:
            // 删除标签
            deleteTag()

        default:
            break
        }
    }
}

// MARK: - 标签名称 Cell
class TagNameCell: UITableViewCell, UITextFieldDelegate {

    var onNameChanged: ((String) -> Void)?

    private let nameTextField = UITextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        selectionStyle = .none

        nameTextField.font = ScreenAdapter.font(16)
        nameTextField.textColor = .label
        nameTextField.tintColor = .themeColorPrimary
        nameTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        contentView.addSubview(nameTextField)
        nameTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    func configure(name: String, placeholder: String) {
        nameTextField.text = name
        nameTextField.placeholder = placeholder
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        onNameChanged?(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 标签颜色 Cell
class TagColorCell: UITableViewCell {

    var onColorSelected: ((TagColor) -> Void)?

    private let colorStackView = UIStackView()
    private var colorButtons: [UIButton] = []
    private var selectedColor: TagColor = .blue

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        selectionStyle = .none

        colorStackView.axis = .horizontal
        colorStackView.spacing = 16
        colorStackView.alignment = .center
        colorStackView.distribution = .fillEqually
        contentView.addSubview(colorStackView)
        colorStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }

        for (index, color) in TagColor.allCases.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.backgroundColor = color.uiColor
            button.layer.cornerRadius = 18
            button.clipsToBounds = true
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.clear.cgColor
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            button.addPressScaleEffect()
            colorStackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.width.height.equalTo(36)
            }
            colorButtons.append(button)
        }
    }

    func configure(selectedColor: TagColor) {
        self.selectedColor = selectedColor
        updateSelectionUI()
    }

    private func updateSelectionUI() {
        for (index, button) in colorButtons.enumerated() {
            if index == selectedColor.rawValue {
                button.layer.borderColor = UIColor.white.cgColor
                button.layer.shadowColor = UIColor.black.cgColor
                button.layer.shadowOpacity = 0.3
                button.layer.shadowOffset = CGSize(width: 0, height: 2)
                button.layer.shadowRadius = 4
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.layer.shadowOpacity = 0
            }
        }
    }

    @objc private func colorButtonTapped(_ sender: UIButton) {
        guard let color = TagColor(rawValue: sender.tag) else { return }
        selectedColor = color
        updateSelectionUI()
        onColorSelected?(color)
    }
}

// MARK: - 标签成员预览 Cell
class TagMemberPreviewCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let arrowView = UIImageView()
    private let membersContainer = UIView()
    private var avatarViews: [UILabel] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        accessoryType = .disclosureIndicator

        // 标题
        titleLabel.text = AppStrings.Tag.tagMembers
        titleLabel.font = ScreenAdapter.font(15)
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
        }

        // 数量
        countLabel.font = ScreenAdapter.font(13)
        countLabel.textColor = .secondaryLabel
        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }

        // 成员头像容器
        contentView.addSubview(membersContainer)
        membersContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-10)
            make.height.equalTo(24)
        }
    }

    func configure(members: [TagMember]) {
        countLabel.text = "\(members.count)\(AppStrings.Tag.memberCount)"

        // 清除旧的头像
        avatarViews.forEach { $0.removeFromSuperview() }
        avatarViews.removeAll()

        // 最多显示 5 个头像
        let maxVisible = 5
        let displayMembers = Array(members.prefix(maxVisible))

        var lastView: UIView = membersContainer
        for (index, member) in displayMembers.enumerated() {
            let avatarLabel = UILabel()
            avatarLabel.font = UIFont.systemFont(ofSize: 10)
            avatarLabel.textAlignment = .center
            avatarLabel.backgroundColor = .systemGray5
            avatarLabel.layer.cornerRadius = 12
            avatarLabel.clipsToBounds = true
            avatarLabel.text = String(member.name.prefix(1))
            avatarLabel.textColor = .white
            membersContainer.addSubview(avatarLabel)
            avatarLabel.snp.makeConstraints { make in
                make.width.height.equalTo(24)
                make.centerY.equalToSuperview()
                if index == 0 {
                    make.leading.equalToSuperview()
                } else {
                    make.leading.equalTo(lastView.snp.trailing).offset(-6)
                }
            }
            // 后面的头像层级更高
            membersContainer.bringSubviewToFront(avatarLabel)
            avatarViews.append(avatarLabel)
            lastView = avatarLabel
        }

        // 如果有更多成员，显示 +N
        if members.count > maxVisible {
            let moreLabel = UILabel()
            moreLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            moreLabel.textAlignment = .center
            moreLabel.backgroundColor = .systemGray4
            moreLabel.textColor = .white
            moreLabel.layer.cornerRadius = 12
            moreLabel.clipsToBounds = true
            moreLabel.text = "+\(members.count - maxVisible)"
            membersContainer.addSubview(moreLabel)
            moreLabel.snp.makeConstraints { make in
                make.width.height.equalTo(24)
                make.centerY.equalToSuperview()
                make.leading.equalTo(lastView.snp.trailing).offset(-6)
            }
            membersContainer.bringSubviewToFront(moreLabel)
        }
    }
}
