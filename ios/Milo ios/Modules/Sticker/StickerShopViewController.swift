//
//  StickerShopViewController.swift
//  Milo
//
//  贴纸商店页面
//  包含：分段控件（热门/最新）、搜索栏、2列网格贴纸包列表、液态玻璃添加按钮
//  特点：液态玻璃风格卡片、弹跳动画、触觉反馈
//

import UIKit
import SnapKit

// MARK: - 贴纸模型
/// 单张贴纸
struct Sticker {
    let id: String
    let imageUrl: String
}

/// 贴纸包
struct StickerPack {
    let id: String
    let name: String
    let coverImage: String
    let stickerCount: Int
    var isAdded: Bool
    let stickers: [Sticker]
}

// MARK: - 贴纸商店控制器
class StickerShopViewController: UIViewController {

    // MARK: - UI 组件

    /// 分段控件：热门 / 最新
    private let segmentControl = UISegmentedControl(items: [AppStrings.Sticker.hot, AppStrings.Sticker.new])

    /// 搜索栏
    private let searchBar = UISearchBar()

    /// 集合视图
    private var collectionView: UICollectionView!

    // MARK: - 数据

    /// 热门贴纸包
    private var hotPacks: [StickerPack] = []

    /// 最新贴纸包
    private var newPacks: [StickerPack] = []

    /// 当前展示的贴纸包（根据分段控件切换）
    private var currentPacks: [StickerPack] {
        return segmentControl.selectedSegmentIndex == 0 ? hotPacks : newPacks
    }

    /// 入场动画是否已执行
    private var hasAnimatedEntrance = false

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMockData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次出现时刷新添加状态（可能从"我的贴纸"返回后有变化）
        collectionView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAnimatedEntrance {
            hasAnimatedEntrance = true
            animateCollectionEntrance()
        }
    }

    // MARK: - UI 设置

    private func setupUI() {
        title = AppStrings.Sticker.stickerShop
        view.backgroundColor = .themeBg

        // 导航栏右侧：我的贴纸
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: AppStrings.Sticker.myStickers,
            style: .plain,
            target: self,
            action: #selector(showMyStickers)
        )

        // 分段控件
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        navigationItem.titleView = nil // 先不设置为 titleView，放在顶部

        // 搜索栏
        searchBar.placeholder = AppStrings.Sticker.searchPlaceholder
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self

        // CollectionView 布局
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 12
        let itemWidth = (view.bounds.width - 16 * 2 - spacing) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.3)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 20, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerShopCell.self, forCellWithReuseIdentifier: "StickerShopCell")

        // 添加子视图
        view.addSubview(segmentControl)
        view.addSubview(searchBar)
        view.addSubview(collectionView)

        // 约束
        segmentControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(180)
        }

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(8)
            make.height.equalTo(44)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(4)
            make.left.right.bottom.equalToSuperview()
        }
    }

    // MARK: - 模拟数据

    private func loadMockData() {
        // 生成模拟贴纸
        func makeStickers(count: Int, emoji: String) -> [Sticker] {
            return (0..<count).map { index in
                Sticker(id: "sticker_\(index)", imageUrl: emoji)
            }
        }

        // 热门贴纸包
        hotPacks = [
            StickerPack(
                id: "hot_1",
                name: "小熊猫",
                coverImage: "🐼",
                stickerCount: 24,
                isAdded: false,
                stickers: makeStickers(count: 24, emoji: "🐼")
            ),
            StickerPack(
                id: "hot_2",
                name: "柴犬君",
                coverImage: "🐕",
                stickerCount: 32,
                isAdded: true,
                stickers: makeStickers(count: 32, emoji: "🐕")
            ),
            StickerPack(
                id: "hot_3",
                name: "猫咪日记",
                coverImage: "🐱",
                stickerCount: 28,
                isAdded: false,
                stickers: makeStickers(count: 28, emoji: "🐱")
            ),
            StickerPack(
                id: "hot_4",
                name: "兔兔兔",
                coverImage: "🐰",
                stickerCount: 20,
                isAdded: false,
                stickers: makeStickers(count: 20, emoji: "🐰")
            ),
            StickerPack(
                id: "hot_5",
                name: "小黄鸭",
                coverImage: "🦆",
                stickerCount: 18,
                isAdded: true,
                stickers: makeStickers(count: 18, emoji: "🦆")
            ),
            StickerPack(
                id: "hot_6",
                name: "搞怪表情",
                coverImage: "🤪",
                stickerCount: 36,
                isAdded: false,
                stickers: makeStickers(count: 36, emoji: "🤪")
            )
        ]

        // 最新贴纸包
        newPacks = [
            StickerPack(
                id: "new_1",
                name: "独角兽",
                coverImage: "🦄",
                stickerCount: 22,
                isAdded: false,
                stickers: makeStickers(count: 22, emoji: "🦄")
            ),
            StickerPack(
                id: "new_2",
                name: "小狐狸",
                coverImage: "🦊",
                stickerCount: 26,
                isAdded: false,
                stickers: makeStickers(count: 26, emoji: "🦊")
            ),
            StickerPack(
                id: "new_3",
                name: "小熊维尼",
                coverImage: "🐻",
                stickerCount: 30,
                isAdded: false,
                stickers: makeStickers(count: 30, emoji: "🐻")
            ),
            StickerPack(
                id: "new_4",
                name: "小企鹅",
                coverImage: "🐧",
                stickerCount: 20,
                isAdded: false,
                stickers: makeStickers(count: 20, emoji: "🐧")
            ),
            StickerPack(
                id: "new_5",
                name: "爱心小熊",
                coverImage: "💝",
                stickerCount: 24,
                isAdded: false,
                stickers: makeStickers(count: 24, emoji: "💝")
            ),
            StickerPack(
                id: "new_6",
                name: "太空漫游",
                coverImage: "🚀",
                stickerCount: 16,
                isAdded: false,
                stickers: makeStickers(count: 16, emoji: "🚀")
            )
        ]

        collectionView.reloadData()
    }

    // MARK: - 动画

    private func animateCollectionEntrance() {
        guard AnimationIntegration.shared.config.enableListEntranceAnimation else { return }

        let visibleCells = collectionView.visibleCells
        for (index, cell) in visibleCells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 20)

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

    // MARK: - 动作

    @objc private func segmentChanged() {
        hasAnimatedEntrance = false // 重置入场动画
        collectionView.reloadData()

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }

        // 切换后重新播放入场动画
        DispatchQueue.main.async { [weak self] in
            self?.animateCollectionEntrance()
            self?.hasAnimatedEntrance = true
        }
    }

    @objc private func showMyStickers() {
        let vc = MyStickersViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 添加贴纸包
    private func addStickerPack(at indexPath: IndexPath) {
        let pack = currentPacks[indexPath.item]
        guard !pack.isAdded else { return }

        // 更新数据
        if segmentControl.selectedSegmentIndex == 0 {
            hotPacks[indexPath.item].isAdded = true
        } else {
            newPacks[indexPath.item].isAdded = true
        }

        // 刷新 cell + 弹跳动画
        if let cell = collectionView.cellForItem(at: indexPath) as? StickerShopCell {
            cell.configure(with: currentPacks[indexPath.item])
            cell.playAddAnimation()
        }

        // 触觉反馈 - 成功上升节奏
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.playAscend()
        }

        // 添加到我的贴纸（同步到本地存储）
        StickerManager.shared.addPack(currentPacks[indexPath.item])
    }
}

// MARK: - UISearchBarDelegate
extension StickerShopViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        // 跳转到搜索页
        searchBar.resignFirstResponder()
        // TODO: 实现贴纸搜索页
        AppUtility.showToast("搜索功能开发中")
        return false
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension StickerShopViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentPacks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerShopCell", for: indexPath) as! StickerShopCell
        let pack = currentPacks[indexPath.item]
        cell.configure(with: pack)
        cell.onAddTapped = { [weak self] in
            self?.addStickerPack(at: indexPath)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }

        // 进入贴纸包详情页
        let pack = currentPacks[indexPath.item]
        // TODO: StickerDetailViewController 已在 StickerViewControllers.swift 中
        AppUtility.showToast("查看 \(pack.name) 详情")
    }
}

// MARK: - 贴纸商店 Cell
class StickerShopCell: UICollectionViewCell {

    // MARK: - 回调
    var onAddTapped: (() -> Void)?

    // MARK: - UI 组件

    /// 液态玻璃卡片背景
    private var glassCard: UIView?

    /// 封面图
    private let coverImageView = UIImageView()
    /// 封面 emoji label（模拟图片）
    private let coverEmojiLabel = UILabel()

    /// 贴纸包名称
    private let nameLabel = UILabel()

    /// 贴纸数量
    private let countLabel = UILabel()

    /// 添加按钮（液态玻璃风格）
    private var addButton: UIButton!

    /// 已添加勾选图标
    private let addedCheckImageView = UIImageView()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        // 卡片背景（液态玻璃效果，iOS 15+）
        if #available(iOS 15.0, *) {
            let card = LiquidGlassCard(cornerRadius: 16)
            card.enableTapAnimation = false
            contentView.addSubview(card)
            card.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            glassCard = card
        } else {
            // Fallback 到普通卡片
            let card = UIView()
            card.backgroundColor = .themeBgCard
            card.layer.cornerRadius = 16
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.08
            card.layer.shadowOffset = CGSize(width: 0, height: 4)
            card.layer.shadowRadius = 12
            contentView.addSubview(card)
            card.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            glassCard = card
        }

        // 封面图容器
        let coverContainer = UIView()
        coverContainer.backgroundColor = .themeColorPrimaryLight
        coverContainer.layer.cornerRadius = 12
        coverContainer.clipsToBounds = true
        contentView.addSubview(coverContainer)
        coverContainer.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(10)
            make.height.equalTo(coverContainer.snp.width) // 正方形
        }

        // 封面 emoji
        coverEmojiLabel.font = UIFont.systemFont(ofSize: 48)
        coverEmojiLabel.textAlignment = .center
        coverContainer.addSubview(coverEmojiLabel)
        coverEmojiLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 贴纸包名称
        nameLabel.font = ThemeFont.title3(14)
        nameLabel.textColor = .themeTextPrimary
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(coverContainer.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(8)
        }

        // 贴纸数量
        countLabel.font = ThemeFont.caption(12)
        countLabel.textColor = .themeTextSecondary
        countLabel.textAlignment = .center
        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.left.right.equalToSuperview().inset(8)
        }

        // 添加按钮
        addButton = UIButton(type: .system)
        addButton.layer.cornerRadius = 14
        addButton.titleLabel?.font = ThemeFont.captionMedium(12)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        contentView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(72)
            make.height.equalTo(28)
        }

        // 液态玻璃效果（iOS 15+）
        if #available(iOS 15.0, *) {
            addButton.applyLiquidGlassEffect(cornerRadius: 14, blurStyle: .systemUltraThinMaterialLight)
            addButton.setTitleColor(.themeColorPrimary, for: .normal)
        } else {
            addButton.backgroundColor = .themeColorPrimary
            addButton.setTitleColor(.white, for: .normal)
        }

        // 已添加勾选图标（默认隐藏）
        addedCheckImageView.image = UIImage(systemName: "checkmark.circle.fill")
        addedCheckImageView.tintColor = .themeSuccess
        addedCheckImageView.isHidden = true
        contentView.addSubview(addedCheckImageView)
        addedCheckImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-6)
            make.width.height.equalTo(24)
        }
    }

    // MARK: - 配置

    func configure(with pack: StickerPack) {
        coverEmojiLabel.text = pack.coverImage
        nameLabel.text = pack.name
        countLabel.text = "\(pack.stickerCount)\(AppStrings.Sticker.stickerCount)"

        if pack.isAdded {
            // 已添加状态
            addButton.setTitle(AppStrings.Sticker.added, for: .normal)
            if #available(iOS 15.0, *) {
                addButton.setTitleColor(.themeSuccess, for: .normal)
            } else {
                addButton.backgroundColor = .themeSuccess
                addButton.setTitleColor(.white, for: .normal)
            }
            addButton.isUserInteractionEnabled = false
            addedCheckImageView.isHidden = false
        } else {
            // 未添加状态
            addButton.setTitle(AppStrings.Sticker.add, for: .normal)
            if #available(iOS 15.0, *) {
                addButton.setTitleColor(.themeColorPrimary, for: .normal)
            } else {
                addButton.backgroundColor = .themeColorPrimary
                addButton.setTitleColor(.white, for: .normal)
            }
            addButton.isUserInteractionEnabled = true
            addedCheckImageView.isHidden = true
        }
    }

    // MARK: - 添加动画

    func playAddAnimation() {
        // 弹跳动画
        let originalTransform = addButton.transform

        UIView.animateKeyframes(withDuration: 0.6, delay: 0, options: []) {
            // 放大
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2) {
                self.addButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }
            // 缩小弹回
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2) {
                self.addButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
            // 恢复
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.2) {
                self.addButton.transform = originalTransform
            }
        }

        // 勾选图标淡入 + 缩放
        addedCheckImageView.alpha = 0
        addedCheckImageView.transform = CGAffineTransform(scaleX: 0, y: 0)
        addedCheckImageView.isHidden = false

        UIView.animate(
            withDuration: 0.4,
            delay: 0.1,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: .curveEaseOut
        ) {
            self.addedCheckImageView.alpha = 1
            self.addedCheckImageView.transform = .identity
        }
    }

    // MARK: - 动作

    @objc private func addButtonTapped() {
        onAddTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        addedCheckImageView.isHidden = true
        addedCheckImageView.alpha = 1
        addedCheckImageView.transform = .identity
        addButton.transform = .identity
    }
}

// MARK: - 贴纸管理器（本地存储已添加的贴纸包）
/// 贴纸管理器：管理已添加的贴纸包，提供增删查改
final class StickerManager {

    static let shared = StickerManager()
    private init() {}

    // MARK: - 属性

    /// 已添加的贴纸包
    private(set) var addedPacks: [StickerPack] = []

    // MARK: - 公开方法

    /// 添加贴纸包
    func addPack(_ pack: StickerPack) {
        guard !addedPacks.contains(where: { $0.id == pack.id }) else { return }
        var newPack = pack
        newPack.isAdded = true
        addedPacks.append(newPack)
        saveToLocal()
    }

    /// 移除贴纸包
    func removePack(withId id: String) {
        addedPacks.removeAll { $0.id == id }
        saveToLocal()
    }

    /// 检查是否已添加
    func isAdded(packId: String) -> Bool {
        return addedPacks.contains { $0.id == packId }
    }

    /// 移动贴纸包顺序
    func movePack(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < addedPacks.count,
              destinationIndex >= 0, destinationIndex < addedPacks.count else { return }
        let pack = addedPacks.remove(at: sourceIndex)
        addedPacks.insert(pack, at: destinationIndex)
        saveToLocal()
    }

    // MARK: - 本地存储

    private func saveToLocal() {
        // TODO: 实现本地持久化存储
        // 目前仅内存存储
    }

    /// 加载本地存储的贴纸包（启动时调用）
    func loadFromLocal() {
        // TODO: 从本地加载
        // 先加载一些默认数据
        addedPacks = [
            StickerPack(
                id: "hot_2",
                name: "柴犬君",
                coverImage: "🐕",
                stickerCount: 32,
                isAdded: true,
                stickers: (0..<32).map { Sticker(id: "sticker_\($0)", imageUrl: "🐕") }
            ),
            StickerPack(
                id: "hot_5",
                name: "小黄鸭",
                coverImage: "🦆",
                stickerCount: 18,
                isAdded: true,
                stickers: (0..<18).map { Sticker(id: "sticker_\($0)", imageUrl: "🦆") }
            ),
            StickerPack(
                id: "default_emoji",
                name: "经典表情",
                coverImage: "😀",
                stickerCount: 50,
                isAdded: true,
                stickers: (0..<50).map { Sticker(id: "sticker_\($0)", imageUrl: "😀") }
            )
        ]
    }
}
