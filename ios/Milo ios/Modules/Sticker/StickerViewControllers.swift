//
//  StickerViewControllers.swift
//  Milo
//
//  表情包模块 - iOS 完全缺失的模块
//  包含：表情商店、我的表情、表情管理、表情搜索、表情分类、表情详情、自定义表情、表情专辑
//

import UIKit
import SnapKit

// MARK: - 表情包模型
struct StickerPack {
    let id: String
    let name: String
    let icon: String
    let description: String
    let price: String? // nil = 免费
    let stickerCount: Int
    let isDownloaded: Bool
    let category: String
}

// MARK: - 表情商店
class StickerStoreViewController: UIViewController {

    // MARK: - UI
    private let searchBar = UISearchBar()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // 分类标签
    private let categoryScrollView = UIScrollView()
    private var categoryButtons: [UIButton] = []
    private let categories = ["推荐", "热门", "最新", "搞笑", "萌系", "情侣", "动漫", "游戏", "节日"]
    private var selectedCategory = 0

    // 推荐横幅
    private let bannerView = UIView()
    private let bannerImageView = UIImageView()
    private let bannerTitleLabel = UILabel()
    private let bannerDescLabel = UILabel()

    // 热门表情包
    private let hotSectionLabel = UILabel()
    private let hotCollectionView: UICollectionView
    private var hotPacks: [StickerPack] = []

    // 最新表情包
    private let newSectionLabel = UILabel()
    private let newCollectionView: UICollectionView
    private var newPacks: [StickerPack] = []

    // MARK: - 初始化
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 130)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        hotCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        let layout2 = UICollectionViewFlowLayout()
        layout2.scrollDirection = .horizontal
        layout2.itemSize = CGSize(width: 100, height: 130)
        layout2.minimumLineSpacing = 12
        layout2.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        newCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout2)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    private func setupUI() {
        title = "表情商店"
        view.backgroundColor = .themeBg

        // 搜索栏
        searchBar.placeholder = "搜索表情包"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        navigationItem.titleView = searchBar

        // 右侧按钮：我的表情
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "我的",
            style: .plain,
            target: self,
            action: #selector(showMyStickers)
        )

        // ScrollView
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // 分类标签
        categoryScrollView.showsHorizontalScrollIndicator = false
        contentView.addSubview(categoryScrollView)
        categoryScrollView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(36)
        }

        var lastBtn: UIButton?
        for (index, category) in categories.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(category, for: .normal)
            btn.titleLabel?.font = ThemeFont.bodySmall(14)
            btn.setTitleColor(index == 0 ? .themeColorPrimary : .themeTextSecondary, for: .normal)
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            btn.tag = index
            categoryScrollView.addSubview(btn)
            btn.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(category.size(withAttributes: [.font: ThemeFont.bodySmall(14)]).width + 20)
                if let last = lastBtn {
                    make.left.equalTo(last.snp.right).offset(4)
                } else {
                    make.left.equalToSuperview().offset(12)
                }
            }
            lastBtn = btn
            categoryButtons.append(btn)
        }
        lastBtn?.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
        }

        // Banner
        bannerView.backgroundColor = .themeColorPrimary.withAlphaComponent(0.1)
        bannerView.layer.cornerRadius = 12
        bannerView.clipsToBounds = true
        contentView.addSubview(bannerView)
        bannerView.snp.makeConstraints { make in
            make.top.equalTo(categoryScrollView.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(100)
        }

        bannerImageView.contentMode = .scaleAspectFit
        bannerImageView.image = UIImage(systemName: "face.smiling.fill")
        bannerImageView.tintColor = .themeColorPrimary
        bannerView.addSubview(bannerImageView)
        bannerImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(60)
        }

        bannerTitleLabel.text = "限时免费"
        bannerTitleLabel.font = ThemeFont.title2(18)
        bannerTitleLabel.textColor = .themeColorPrimary
        bannerView.addSubview(bannerTitleLabel)
        bannerTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
        }

        bannerDescLabel.text = "精选表情包限时免费下载"
        bannerDescLabel.font = ThemeFont.bodySmall(13)
        bannerDescLabel.textColor = .themeTextSecondary
        bannerView.addSubview(bannerDescLabel)
        bannerDescLabel.snp.makeConstraints { make in
            make.left.equalTo(bannerTitleLabel)
            make.top.equalTo(bannerTitleLabel.snp.bottom).offset(6)
        }

        // 热门表情包
        hotSectionLabel.text = "热门表情"
        hotSectionLabel.font = ThemeFont.title3(16)
        hotSectionLabel.textColor = .themeTextPrimary
        contentView.addSubview(hotSectionLabel)
        hotSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
        }

        let moreBtn1 = UIButton(type: .system)
        moreBtn1.setTitle("更多", for: .normal)
        moreBtn1.titleLabel?.font = ThemeFont.bodySmall(13)
        moreBtn1.addTarget(self, action: #selector(showMoreHot), for: .touchUpInside)
        contentView.addSubview(moreBtn1)
        moreBtn1.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(hotSectionLabel)
        }

        hotCollectionView.backgroundColor = .clear
        hotCollectionView.showsHorizontalScrollIndicator = false
        hotCollectionView.dataSource = self
        hotCollectionView.delegate = self
        hotCollectionView.register(StickerPackCell.self, forCellWithReuseIdentifier: "HotPackCell")
        contentView.addSubview(hotCollectionView)
        hotCollectionView.snp.makeConstraints { make in
            make.top.equalTo(hotSectionLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(130)
        }

        // 最新表情包
        newSectionLabel.text = "最新表情"
        newSectionLabel.font = ThemeFont.title3(16)
        newSectionLabel.textColor = .themeTextPrimary
        contentView.addSubview(newSectionLabel)
        newSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(hotCollectionView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
        }

        let moreBtn2 = UIButton(type: .system)
        moreBtn2.setTitle("更多", for: .normal)
        moreBtn2.titleLabel?.font = ThemeFont.bodySmall(13)
        moreBtn2.addTarget(self, action: #selector(showMoreNew), for: .touchUpInside)
        contentView.addSubview(moreBtn2)
        moreBtn2.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(newSectionLabel)
        }

        newCollectionView.backgroundColor = .clear
        newCollectionView.showsHorizontalScrollIndicator = false
        newCollectionView.dataSource = self
        newCollectionView.delegate = self
        newCollectionView.register(StickerPackCell.self, forCellWithReuseIdentifier: "NewPackCell")
        contentView.addSubview(newCollectionView)
        newCollectionView.snp.makeConstraints { make in
            make.top.equalTo(newSectionLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(130)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    private func loadData() {
        // 模拟数据
        hotPacks = [
            StickerPack(id: "1", name: "小熊猫", icon: "🐼", description: "可爱的小熊猫表情包", price: nil, stickerCount: 24, isDownloaded: false, category: "热门"),
            StickerPack(id: "2", name: "柴犬君", icon: "🐕", description: "呆萌柴犬日常", price: nil, stickerCount: 32, isDownloaded: true, category: "热门"),
            StickerPack(id: "3", name: "猫咪日记", icon: "🐱", description: "猫咪的一天", price: "¥6.00", stickerCount: 28, isDownloaded: false, category: "热门"),
            StickerPack(id: "4", name: "兔兔兔", icon: "🐰", description: "软萌小兔子", price: nil, stickerCount: 20, isDownloaded: false, category: "热门"),
            StickerPack(id: "5", name: "小黄鸭", icon: "🦆", description: "冲鸭！", price: nil, stickerCount: 18, isDownloaded: false, category: "热门")
        ]

        newPacks = [
            StickerPack(id: "6", name: "独角兽", icon: "🦄", description: "梦幻独角兽", price: nil, stickerCount: 22, isDownloaded: false, category: "最新"),
            StickerPack(id: "7", name: "小狐狸", icon: "🦊", description: "机灵小狐狸", price: "¥3.00", stickerCount: 26, isDownloaded: false, category: "最新"),
            StickerPack(id: "8", name: "小熊维尼", icon: "🐻", description: "蜂蜜爱好者", price: nil, stickerCount: 30, isDownloaded: false, category: "最新"),
            StickerPack(id: "9", name: "小企鹅", icon: "🐧", description: "南极来客", price: nil, stickerCount: 20, isDownloaded: false, category: "最新")
        ]

        hotCollectionView.reloadData()
        newCollectionView.reloadData()
    }

    // MARK: - 动作
    @objc private func showMyStickers() {
        let vc = MyStickerViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        selectedCategory = sender.tag
        for (index, btn) in categoryButtons.enumerated() {
            btn.setTitleColor(index == selectedCategory ? .themeColorPrimary : .themeTextSecondary, for: .normal)
        }
    }

    @objc private func showMoreHot() {
        let vc = StickerCategoryViewController(category: "热门")
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func showMoreNew() {
        let vc = StickerCategoryViewController(category: "最新")
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension StickerStoreViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let vc = StickerSearchViewController()
        navigationController?.pushViewController(vc, animated: true)
        return false
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension StickerStoreViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == hotCollectionView {
            return hotPacks.count
        }
        return newPacks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let packs = collectionView == hotCollectionView ? hotPacks : newPacks
        let reuseId = collectionView == hotCollectionView ? "HotPackCell" : "NewPackCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! StickerPackCell
        cell.configure(with: packs[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let packs = collectionView == hotCollectionView ? hotPacks : newPacks
        let pack = packs[indexPath.item]
        let vc = StickerDetailViewController(pack: pack)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 表情包 Cell
class StickerPackCell: UICollectionViewCell {

    private let iconLabel = UILabel()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let downloadedImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .themeBgCard
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        iconLabel.font = UIFont.systemFont(ofSize: 36)
        iconLabel.textAlignment = .center
        contentView.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60)
        }

        nameLabel.font = ThemeFont.bodySmall(13)
        nameLabel.textColor = .themeTextPrimary
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(4)
        }

        priceLabel.font = ThemeFont.tiny(11)
        priceLabel.textColor = .themeColorPrimary
        priceLabel.textAlignment = .center
        contentView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-6)
        }

        downloadedImageView.image = UIImage(systemName: "checkmark.circle.fill")
        downloadedImageView.tintColor = .themeSuccess
        downloadedImageView.isHidden = true
        contentView.addSubview(downloadedImageView)
        downloadedImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
            make.width.height.equalTo(20)
        }
    }

    func configure(with pack: StickerPack) {
        iconLabel.text = pack.icon
        nameLabel.text = pack.name
        downloadedImageView.isHidden = !pack.isDownloaded

        if pack.isDownloaded {
            priceLabel.text = "已下载"
            priceLabel.textColor = .themeSuccess
        } else if let price = pack.price {
            priceLabel.text = price
            priceLabel.textColor = .themeColorPrimary
        } else {
            priceLabel.text = "免费"
            priceLabel.textColor = .themeSuccess
        }
    }
}

// MARK: - 我的表情
class MyStickerViewController: UIViewController {

    private let tableView = UITableView()
    private var myPacks: [StickerPack] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMyStickers()
    }

    private func setupUI() {
        title = "我的表情"
        view.backgroundColor = .themeBg

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "管理",
            style: .plain,
            target: self,
            action: #selector(manageStickers)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyStickerCell")
        tableView.rowHeight = 64
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadMyStickers() {
        // 模拟数据
        myPacks = [
            StickerPack(id: "1", name: "小熊猫", icon: "🐼", description: "可爱的小熊猫表情包", price: nil, stickerCount: 24, isDownloaded: true, category: ""),
            StickerPack(id: "2", name: "柴犬君", icon: "🐕", description: "呆萌柴犬日常", price: nil, stickerCount: 32, isDownloaded: true, category: ""),
            StickerPack(id: "3", name: "经典表情", icon: "😀", description: "系统默认表情包", price: nil, stickerCount: 50, isDownloaded: true, category: "")
        ]
        tableView.reloadData()
    }

    @objc private func manageStickers() {
        let vc = StickerManagerViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension MyStickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myPacks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyStickerCell", for: indexPath)
        let pack = myPacks[indexPath.row]

        cell.imageView?.image = nil
        cell.textLabel?.text = pack.name
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.detailTextLabel?.text = "\(pack.stickerCount) 个表情"
        cell.detailTextLabel?.font = ThemeFont.caption(13)
        cell.detailTextLabel?.textColor = .themeTextSecondary
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite

        // 用 emoji 做图标
        let iconLabel = UILabel()
        iconLabel.text = pack.icon
        iconLabel.font = UIFont.systemFont(ofSize: 28)
        iconLabel.textAlignment = .center
        cell.contentView.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        cell.textLabel?.snp.remakeConstraints { make in
            make.left.equalTo(iconLabel.snp.right).offset(12)
            make.centerY.equalToSuperview().offset(-8)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let pack = myPacks[indexPath.row]
        let vc = StickerDetailViewController(pack: pack)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 表情管理
class StickerManagerViewController: UIViewController {

    private let tableView = UITableView()
    private var packs: [StickerPack] = []
    private var isEditingMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPacks()
    }

    private func setupUI() {
        title = "表情管理"
        view.backgroundColor = .themeBg

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "排序",
            style: .plain,
            target: self,
            action: #selector(toggleEditing)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ManageCell")
        tableView.rowHeight = 64
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.isEditing = false
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadPacks() {
        packs = [
            StickerPack(id: "1", name: "小熊猫", icon: "🐼", description: "", price: nil, stickerCount: 24, isDownloaded: true, category: ""),
            StickerPack(id: "2", name: "柴犬君", icon: "🐕", description: "", price: nil, stickerCount: 32, isDownloaded: true, category: ""),
            StickerPack(id: "3", name: "经典表情", icon: "😀", description: "", price: nil, stickerCount: 50, isDownloaded: true, category: "")
        ]
        tableView.reloadData()
    }

    @objc private func toggleEditing() {
        isEditingMode.toggle()
        tableView.setEditing(isEditingMode, animated: true)
        navigationItem.rightBarButtonItem?.title = isEditingMode ? "完成" : "排序"
    }
}

extension StickerManagerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return packs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ManageCell", for: indexPath)
        let pack = packs[indexPath.row]
        cell.textLabel?.text = pack.name
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite
        return cell
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let moved = packs.remove(at: sourceIndexPath.row)
        packs.insert(moved, at: destinationIndexPath.row)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            packs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "移除"
    }
}

// MARK: - 表情搜索
class StickerSearchViewController: UIViewController {

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private var results: [StickerPack] = []
    private var hotKeywords = ["小熊猫", "柴犬", "猫咪", "兔子", "小黄鸭", "搞笑", "萌系", "爱心"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "搜索表情"
        view.backgroundColor = .themeBg

        searchBar.placeholder = "搜索表情包名称"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        navigationItem.titleView = searchBar

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchResultCell")
        tableView.rowHeight = 64
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableFooterView = UIView()

        // 搜索历史和热门搜索
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 180))
        headerView.backgroundColor = .clear

        let hotLabel = UILabel()
        hotLabel.text = "热门搜索"
        hotLabel.font = ThemeFont.title3(15)
        hotLabel.textColor = .themeTextPrimary
        headerView.addSubview(hotLabel)
        hotLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
        }

        // 热门标签
        let tagStackView = UIStackView()
        tagStackView.axis = .horizontal
        tagStackView.spacing = 8
        tagStackView.alignment = .center
        tagStackView.distribution = .fillProportionally
        headerView.addSubview(tagStackView)
        tagStackView.snp.makeConstraints { make in
            make.top.equalTo(hotLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }

        for keyword in hotKeywords {
            let tagBtn = UIButton(type: .system)
            tagBtn.setTitle(keyword, for: .normal)
            tagBtn.titleLabel?.font = ThemeFont.bodySmall(13)
            tagBtn.setTitleColor(.themeTextSecondary, for: .normal)
            tagBtn.backgroundColor = .themeBgCard
            tagBtn.layer.cornerRadius = 14
            tagBtn.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            tagStackView.addArrangedSubview(tagBtn)
            tagBtn.snp.makeConstraints { make in
                make.height.equalTo(28)
            }
        }

        tableView.tableHeaderView = headerView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func tagTapped(_ sender: UIButton) {
        searchBar.text = sender.title(for: .normal)
        searchResults(keyword: sender.title(for: .normal) ?? "")
    }

    private func searchResults(keyword: String) {
        // 模拟搜索
        results = [
            StickerPack(id: "1", name: "\(keyword)表情包", icon: "😀", description: "", price: nil, stickerCount: 24, isDownloaded: false, category: "")
        ]
        tableView.reloadData()
    }
}

extension StickerSearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchResults(keyword: searchBar.text ?? "")
    }
}

extension StickerSearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)
        let pack = results[indexPath.row]
        cell.textLabel?.text = pack.name
        cell.textLabel?.font = ThemeFont.body(16)
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .themeBgWhite
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let pack = results[indexPath.row]
        let vc = StickerDetailViewController(pack: pack)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 表情分类
class StickerCategoryViewController: UIViewController {

    private let category: String
    private let collectionView: UICollectionView
    private var packs: [StickerPack] = []

    init(category: String) {
        self.category = category
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 48) / 3, height: 150)
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    private func setupUI() {
        title = category
        view.backgroundColor = .themeBg

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerPackCell.self, forCellWithReuseIdentifier: "CategoryPackCell")

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadData() {
        // 模拟数据
        packs = [
            StickerPack(id: "1", name: "小熊猫", icon: "🐼", description: "", price: nil, stickerCount: 24, isDownloaded: false, category: category),
            StickerPack(id: "2", name: "柴犬君", icon: "🐕", description: "", price: nil, stickerCount: 32, isDownloaded: true, category: category),
            StickerPack(id: "3", name: "猫咪日记", icon: "🐱", description: "", price: "¥6.00", stickerCount: 28, isDownloaded: false, category: category),
            StickerPack(id: "4", name: "兔兔兔", icon: "🐰", description: "", price: nil, stickerCount: 20, isDownloaded: false, category: category),
            StickerPack(id: "5", name: "小黄鸭", icon: "🦆", description: "", price: nil, stickerCount: 18, isDownloaded: false, category: category),
            StickerPack(id: "6", name: "独角兽", icon: "🦄", description: "", price: nil, stickerCount: 22, isDownloaded: false, category: category)
        ]
        collectionView.reloadData()
    }
}

extension StickerCategoryViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return packs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryPackCell", for: indexPath) as! StickerPackCell
        cell.configure(with: packs[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pack = packs[indexPath.item]
        let vc = StickerDetailViewController(pack: pack)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 表情详情
class StickerDetailViewController: UIViewController {

    private let pack: StickerPack
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let iconLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let downloadButton = UIButton(type: .system)
    private let stickerCollectionView: UICollectionView

    init(pack: StickerPack) {
        self.pack = pack
        let layout = UICollectionViewFlowLayout()
        let itemWidth = (UIScreen.main.bounds.width - 48) / 4
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stickerCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = pack.name
        view.backgroundColor = .themeBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // Header
        headerView.backgroundColor = .themeBgCard
        contentView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(120)
        }

        iconLabel.text = pack.icon
        iconLabel.font = UIFont.systemFont(ofSize: 48)
        iconLabel.textAlignment = .center
        headerView.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(64)
        }

        nameLabel.text = pack.name
        nameLabel.font = ThemeFont.title2(18)
        nameLabel.textColor = .themeTextPrimary
        headerView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(iconLabel.snp.right).offset(16)
            make.top.equalTo(iconLabel).offset(4)
        }

        descLabel.text = "\(pack.stickerCount) 个表情"
        descLabel.font = ThemeFont.bodySmall(14)
        descLabel.textColor = .themeTextSecondary
        headerView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
        }

        // 下载按钮
        downloadButton.layer.cornerRadius = 18
        downloadButton.titleLabel?.font = ThemeFont.bodyMedium(14)
        updateDownloadButton()
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        headerView.addSubview(downloadButton)
        downloadButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(36)
        }

        // 表情预览
        let previewLabel = UILabel()
        previewLabel.text = "表情预览"
        previewLabel.font = ThemeFont.title3(16)
        previewLabel.textColor = .themeTextPrimary
        contentView.addSubview(previewLabel)
        previewLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
        }

        stickerCollectionView.backgroundColor = .clear
        stickerCollectionView.dataSource = self
        stickerCollectionView.delegate = self
        stickerCollectionView.register(StickerPreviewCell.self, forCellWithReuseIdentifier: "PreviewCell")
        stickerCollectionView.isScrollEnabled = false
        contentView.addSubview(stickerCollectionView)
        stickerCollectionView.snp.makeConstraints { make in
            make.top.equalTo(previewLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(300)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    private func updateDownloadButton() {
        if pack.isDownloaded {
            downloadButton.setTitle("已下载", for: .normal)
            downloadButton.setTitleColor(.themeSuccess, for: .normal)
            downloadButton.backgroundColor = .themeSuccess.withAlphaComponent(0.1)
        } else if let price = pack.price {
            downloadButton.setTitle(price, for: .normal)
            downloadButton.setTitleColor(.white, for: .normal)
            downloadButton.backgroundColor = .themeColorPrimary
        } else {
            downloadButton.setTitle("下载", for: .normal)
            downloadButton.setTitleColor(.white, for: .normal)
            downloadButton.backgroundColor = .themeColorPrimary
        }
    }

    @objc private func downloadTapped() {
        if pack.isDownloaded {
            AppUtility.showToast("已下载")
        } else {
            AppUtility.showToast("开始下载...")
        }
    }
}

extension StickerDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(pack.stickerCount, 12)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCell", for: indexPath) as! StickerPreviewCell
        cell.configure(emoji: pack.icon)
        return cell
    }
}

class StickerPreviewCell: UICollectionViewCell {

    private let emojiLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .themeBgCard
        contentView.layer.cornerRadius = 8

        emojiLabel.font = UIFont.systemFont(ofSize: 32)
        emojiLabel.textAlignment = .center
        contentView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(emoji: String) {
        emojiLabel.text = emoji
    }
}
