//
//  MyStickersViewController.swift
//  Milo
//
//  我的贴纸页面
//  包含：已添加贴纸包列表、编辑模式（删除/排序）、液态玻璃风格
//

import UIKit
import SnapKit

// MARK: - 我的贴纸控制器
class MyStickersViewController: UIViewController {

    // MARK: - UI 组件

    /// 表格视图
    private let tableView = UITableView(frame: .zero, style: .plain)

    /// 管理按钮
    private var manageButton: UIBarButtonItem!

    /// 编辑模式标识
    private var isEditingMode = false {
        didSet {
            tableView.setEditing(isEditingMode, animated: true)
            updateManageButtonTitle()
        }
    }

    /// 入场动画是否已执行
    private var hasAnimatedEntrance = false

    // MARK: - 数据

    /// 我的贴纸包列表
    private var myPacks: [StickerPack] = []

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMyStickers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次出现刷新数据（可能从商店添加了新贴纸）
        loadMyStickers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAnimatedEntrance {
            hasAnimatedEntrance = true
            animateTableEntrance()
        }
    }

    // MARK: - UI 设置

    private func setupUI() {
        title = AppStrings.Sticker.myStickers
        view.backgroundColor = .themeBg

        // 管理按钮
        manageButton = UIBarButtonItem(
            title: AppStrings.Sticker.manage,
            style: .plain,
            target: self,
            action: #selector(toggleEditingMode)
        )
        navigationItem.rightBarButtonItem = manageButton

        // 表格视图
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MyStickerCell.self, forCellReuseIdentifier: "MyStickerCell")
        tableView.rowHeight = 72
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.showsVerticalScrollIndicator = false

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 数据加载

    private func loadMyStickers() {
        // 从贴纸管理器加载已添加的贴纸包
        myPacks = StickerManager.shared.addedPacks
        tableView.reloadData()
    }

    // MARK: - 编辑模式

    private func updateManageButtonTitle() {
        manageButton.title = isEditingMode ? AppStrings.Common.done : AppStrings.Sticker.manage
    }

    @objc private func toggleEditingMode() {
        isEditingMode.toggle()

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }
    }

    // MARK: - 动画

    private func animateTableEntrance() {
        guard AnimationIntegration.shared.config.enableListEntranceAnimation else { return }

        let visibleCells = tableView.visibleCells
        for (index, cell) in visibleCells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: -20, y: 0)

            UIView.animate(
                withDuration: AnimationDuration.slow,
                delay: Double(index) * AnimationIntegration.shared.config.listItemDelay,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut
            ) {
                cell.alpha = 1
                cell.transform = .identity
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension MyStickersViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myPacks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyStickerCell", for: indexPath) as! MyStickerCell
        let pack = myPacks[indexPath.row]
        cell.configure(with: pack)
        cell.showsReorderControl = isEditingMode
        return cell
    }

    // 允许编辑（删除）
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // 允许移动（排序）
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return isEditingMode
    }

    // 移动行
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedPack = myPacks.remove(at: sourceIndexPath.row)
        myPacks.insert(movedPack, at: destinationIndexPath.row)

        // 同步到管理器
        StickerManager.shared.movePack(from: sourceIndexPath.row, to: destinationIndexPath.row)

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
    }

    // 提交编辑（删除）
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let pack = myPacks[indexPath.row]

            // 显示确认弹窗
            let alert = UIAlertController(
                title: AppStrings.Common.tip,
                message: "确定移除「\(pack.name)」吗？",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))
            alert.addAction(UIAlertAction(title: AppStrings.Common.delete, style: .destructive) { [weak self] _ in
                guard let self = self else { return }

                // 删除数据
                let packId = self.myPacks[indexPath.row].id
                self.myPacks.remove(at: indexPath.row)
                StickerManager.shared.removePack(withId: packId)

                // 删除动画
                tableView.deleteRows(at: [indexPath], with: .fade)

                // 触觉反馈
                if AnimationIntegration.shared.config.enableHapticFeedback {
                    HapticManager.shared.playDescend()
                }

                // 如果删完了，退出编辑模式
                if self.myPacks.isEmpty {
                    self.isEditingMode = false
                }
            })
            present(alert, animated: true)
        }
    }

    // 删除按钮文字
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return AppStrings.Sticker.remove
    }
}

// MARK: - UITableViewDelegate
extension MyStickersViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if isEditingMode {
            // 编辑模式下点击不进入详情
            return
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }

        // 进入贴纸包详情
        let pack = myPacks[indexPath.row]
        // TODO: 跳转到贴纸包详情页
        AppUtility.showToast("查看 \(pack.name)")
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    // 编辑模式下调整缩进
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // 编辑样式
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return isEditingMode ? .delete : .none
    }
}

// MARK: - 我的贴纸 Cell
class MyStickerCell: UITableViewCell {

    // MARK: - UI 组件

    /// 封面容器
    private let coverContainer = UIView()
    /// 封面 emoji
    private let coverEmojiLabel = UILabel()

    /// 贴纸包名称
    private let nameLabel = UILabel()

    /// 贴纸数量
    private let countLabel = UILabel()

    /// 排序图标（三条杠）
    private let reorderImageView = UIImageView()

    // MARK: - 初始化

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite

        // 选中背景
        let selectedBg = UIView()
        selectedBg.backgroundColor = .themeColorPrimaryLight
        selectedBackgroundView = selectedBg

        // 封面容器
        coverContainer.backgroundColor = .themeColorPrimaryLight
        coverContainer.layer.cornerRadius = 10
        coverContainer.clipsToBounds = true
        contentView.addSubview(coverContainer)
        coverContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        // 封面 emoji
        coverEmojiLabel.font = UIFont.systemFont(ofSize: 28)
        coverEmojiLabel.textAlignment = .center
        coverContainer.addSubview(coverEmojiLabel)
        coverEmojiLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 名称
        nameLabel.font = ThemeFont.bodyMedium(16)
        nameLabel.textColor = .themeTextPrimary
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(coverContainer.snp.right).offset(12)
            make.top.equalTo(coverContainer).offset(4)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }

        // 数量
        countLabel.font = ThemeFont.caption(13)
        countLabel.textColor = .themeTextSecondary
        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.bottom.equalTo(coverContainer).offset(-4)
        }

        // 排序图标（三条杠）
        reorderImageView.image = UIImage(systemName: "line.horizontal.3")
        reorderImageView.tintColor = .themeTextTertiary
        reorderImageView.isHidden = true
        contentView.addSubview(reorderImageView)
        reorderImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(16)
        }
    }

    // MARK: - 配置

    func configure(with pack: StickerPack) {
        coverEmojiLabel.text = pack.coverImage
        nameLabel.text = pack.name
        countLabel.text = "\(pack.stickerCount)\(AppStrings.Sticker.stickerCount)"
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        // 编辑模式下显示排序图标
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.reorderImageView.isHidden = !editing
            if editing {
                self.reorderImageView.alpha = 1
            } else {
                self.reorderImageView.alpha = 0
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reorderImageView.isHidden = true
    }
}
