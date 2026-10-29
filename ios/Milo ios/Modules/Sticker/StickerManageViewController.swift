//
//  StickerManageViewController.swift
//  Milo
//
//  贴纸管理（对齐 Android StickerManagerActivity + CustomStickerActivity）
//  功能：网格展示我的贴纸包、长按编辑（删除/排序）、添加跳转贴纸商店、自定义贴纸入口
//

import UIKit
import SnapKit
import Kingfisher

// MARK: - 本地贴纸包记录（可持久化）
struct ManagedStickerPack: Codable {
    let id: String
    var name: String
    var coverImage: String      // emoji 或 URL 字符串
    var stickerCount: Int
}

// MARK: - 自定义贴纸记录
struct CustomSticker: Codable {
    let id: String
    var localFileName: String   // Documents/CustomStickers 下的文件名
}

// MARK: - 贴纸管理控制器
class StickerManageViewController: UIViewController {

    // MARK: - 常量
    private let packsStorageKey = "sticker_manage_packs"

    // MARK: - UI 组件
    private var collectionView: UICollectionView!
    private let bottomEntryView = UIView()
    private let entryIcon = UIImageView()
    private let entryLabel = UILabel()
    private let entryArrow = UIImageView()

    // MARK: - 数据
    private var myPacks: [ManagedStickerPack] = []
    private var isEditingMode = false
    /// 是否正在交互式拖拽排序
    private var isInteractiveMoving = false

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // 如果从商店返回，同步新添加的贴纸包
        syncFromStickerManager()
    }

    // MARK: - UI 设置
    private func setupUI() {
        title = "贴纸管理"
        view.backgroundColor = .themeBackground

        // 返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        // 右上角"添加"→贴纸商店
        let addBtn = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addTapped)
        )
        addBtn.tintColor = .label
        navigationItem.rightBarButtonItem = addBtn

        // 网格布局
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = ScreenAdapter.scaleW(12)
        let itemWidth = (view.bounds.width - ScreenAdapter.scaleW(16) * 2 - spacing) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.25)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: ScreenAdapter.scaleH(12),
                                           left: ScreenAdapter.scaleW(16),
                                           bottom: ScreenAdapter.scaleH(20),
                                           right: ScreenAdapter.scaleW(16))

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerManageCell.self, forCellWithReuseIdentifier: "StickerManageCell")

        // 长按手势（进入编辑模式 / 拖拽排序）
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        // 底部"自定义贴纸"入口
        bottomEntryView.backgroundColor = .themeBgWhite
        let tap = UITapGestureRecognizer(target: self, action: #selector(customStickerTapped))
        bottomEntryView.addGestureRecognizer(tap)
        bottomEntryView.isUserInteractionEnabled = true

        entryIcon.image = UIImage(systemName: "face.smiling")
        entryIcon.tintColor = .themePrimary
        entryIcon.contentMode = .scaleAspectFit

        entryLabel.text = "自定义贴纸"
        entryLabel.font = ScreenAdapter.font(15)
        entryLabel.textColor = .label

        entryArrow.image = UIImage(systemName: "chevron.right")
        entryArrow.tintColor = .themeTextTertiary
        entryArrow.contentMode = .scaleAspectFit

        bottomEntryView.addSubviews(entryIcon, entryLabel, entryArrow)
        view.addSubview(bottomEntryView)

        bottomEntryView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(ScreenAdapter.scaleH(56))
        }

        entryIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(24))
        }
        entryLabel.snp.makeConstraints { make in
            make.leading.equalTo(entryIcon.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
        }
        entryArrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }
    }

    // MARK: - 数据加载 / 持久化
    private func loadPacks() {
        if let data = UserDefaults.standard.data(forKey: packsStorageKey),
           let list = try? JSONDecoder().decode([ManagedStickerPack].self, from: data) {
            myPacks = list
        } else {
            // 首次加载：从 StickerManager 同步
            syncFromStickerManager()
        }
        collectionView.reloadData()
    }

    private func savePacks() {
        if let data = try? JSONEncoder().encode(myPacks) {
            UserDefaults.standard.set(data, forKey: packsStorageKey)
        }
    }

    /// 从 StickerManager 同步已添加的贴纸包
    private func syncFromStickerManager() {
        let managerPacks = StickerManager.shared.addedPacks
        var newPacks: [ManagedStickerPack] = []
        for pack in managerPacks {
            newPacks.append(ManagedStickerPack(
                id: pack.id,
                name: pack.name,
                coverImage: pack.coverImage,
                stickerCount: pack.stickerCount
            ))
        }
        // 保留本地排序，追加新包
        let existingIds = Set(myPacks.map { $0.id })
        for pack in newPacks {
            if !existingIds.contains(pack.id) {
                myPacks.append(pack)
            }
        }
        savePacks()
        collectionView.reloadData()
    }

    // MARK: - 编辑模式 & 手势
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location) else { return }

        switch gesture.state {
        case .began:
            if isEditingMode {
                // 编辑模式下开始拖拽排序
                if collectionView.beginInteractiveMovementForItem(at: indexPath) {
                    isInteractiveMoving = true
                    if AnimationIntegration.shared.config.enableHapticFeedback {
                        HapticManager.shared.impactMedium()
                    }
                }
            } else {
                // 非编辑模式：进入编辑模式
                enterEditingMode()
            }
        case .changed:
            if isInteractiveMoving {
                collectionView.updateInteractiveMovementTargetPosition(location)
            }
        case .ended:
            if isInteractiveMoving {
                collectionView.endInteractiveMovement()
                isInteractiveMoving = false
            }
        default:
            if isInteractiveMoving {
                collectionView.cancelInteractiveMovement()
                isInteractiveMoving = false
            }
        }
    }

    private func enterEditingMode() {
        isEditingMode = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: AppStrings.Common.done,
            style: .plain,
            target: self,
            action: #selector(exitEditingMode)
        )
        collectionView.reloadData()
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }
    }

    @objc private func exitEditingMode() {
        isEditingMode = false
        let addBtn = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addTapped)
        )
        addBtn.tintColor = .label
        navigationItem.rightBarButtonItem = addBtn
        collectionView.reloadData()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func addTapped() {
        let shopVC = StickerShopViewController()
        navigationController?.pushViewController(shopVC, animated: true)
    }

    @objc private func customStickerTapped() {
        let vc = CustomStickerViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 删除贴纸包
    private func deletePack(at indexPath: IndexPath) {
        let pack = myPacks[indexPath.item]
        let alert = UIAlertController(
            title: AppStrings.Common.tip,
            message: "确定删除「\(pack.name)」吗？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: AppStrings.Common.delete, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.myPacks.remove(at: indexPath.item)
            StickerManager.shared.removePack(withId: pack.id)
            self.savePacks()
            self.collectionView.deleteItems(at: [indexPath])
            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.playDescend()
            }
            if self.myPacks.isEmpty {
                self.exitEditingMode()
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension StickerManageViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myPacks.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "StickerManageCell", for: indexPath
        ) as! StickerManageCell
        let pack = myPacks[indexPath.item]
        cell.configure(with: pack, isEditing: isEditingMode)
        cell.onDeleteTapped = { [weak self] in
            self?.deletePack(at: indexPath)
        }
        return cell
    }

    // 允许移动
    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        let pack = myPacks.remove(at: sourceIndexPath.item)
        myPacks.insert(pack, at: destinationIndexPath.item)
        savePacks()
        // 同步到 StickerManager
        StickerManager.shared.movePack(from: sourceIndexPath.item, to: destinationIndexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if isEditingMode { return }
        let pack = myPacks[indexPath.item]
        AppUtility.showToast("查看 \(pack.name)")
    }
}

// MARK: - 贴纸管理 Cell
class StickerManageCell: UICollectionViewCell {

    var onDeleteTapped: (() -> Void)?

    private let cardView = UIView()
    private let coverImageView = UIImageView()
    private let coverEmojiLabel = UILabel()
    private let nameLabel = UILabel()
    private let countLabel = UILabel()
    private let deleteButton = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        // 卡片
        cardView.backgroundColor = .themeBgWhite
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset = CGSize(width: 0, height: ScreenAdapter.scaleH(2))
        cardView.layer.shadowRadius = 6
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 封面
        coverImageView.contentMode = .scaleAspectFit
        coverImageView.backgroundColor = .themeColorPrimaryLight
        coverImageView.layer.cornerRadius = ScreenAdapter.scaleW(10)
        coverImageView.clipsToBounds = true
        cardView.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(ScreenAdapter.scaleW(10))
            make.height.equalTo(coverImageView.snp.width)
        }

        // emoji（URL 加载时隐藏）
        coverEmojiLabel.font = UIFont.systemFont(ofSize: ScreenAdapter.scaleW(40))
        coverEmojiLabel.textAlignment = .center
        coverImageView.addSubview(coverEmojiLabel)
        coverEmojiLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 名称
        nameLabel.font = ScreenAdapter.mediumFont(14)
        nameLabel.textColor = .themeTextPrimary
        nameLabel.textAlignment = .center
        cardView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(coverImageView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview().inset(ScreenAdapter.scaleW(8))
        }

        // 数量
        countLabel.font = ScreenAdapter.font(11)
        countLabel.textColor = .themeTextSecondary
        countLabel.textAlignment = .center
        cardView.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(2))
            make.leading.trailing.equalToSuperview().inset(ScreenAdapter.scaleW(8))
        }

        // 删除按钮（编辑模式显示）
        deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.isHidden = true
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        cardView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(4))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
            make.width.height.equalTo(ScreenAdapter.scaleW(24))
        }
    }

    func configure(with pack: ManagedStickerPack, isEditing: Bool) {
        nameLabel.text = pack.name
        countLabel.text = "\(pack.stickerCount)\(AppStrings.Sticker.stickerCount)"
        deleteButton.isHidden = !isEditing

        // 封面：URL 用 Kingfisher，否则 emoji
        if pack.coverImage.hasPrefix("http") {
            coverImageView.backgroundColor = .themeBgGrayF5
            coverEmojiLabel.isHidden = true
            if let url = URL(string: pack.coverImage) {
                coverImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "face.smiling"))
            }
        } else {
            coverImageView.backgroundColor = .themeColorPrimaryLight
            coverImageView.image = nil
            coverEmojiLabel.isHidden = false
            coverEmojiLabel.text = pack.coverImage
        }
    }

    @objc private func deleteTapped() {
        onDeleteTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
        coverImageView.kf.cancelDownloadTask()
    }
}

// MARK: - 自定义贴纸控制器
class CustomStickerViewController: UIViewController {

    private let customStickersStorageKey = "custom_stickers"
    private var customStickers: [CustomSticker] = []
    private var collectionView: UICollectionView!
    private var imagePicker: UIImagePickerController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStickers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        title = AppStrings.Sticker.custom
        view.backgroundColor = .themeBackground

        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        // 4 列网格
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = ScreenAdapter.scaleW(8)
        let itemWidth = (view.bounds.width - ScreenAdapter.scaleW(16) * 2 - spacing * 3) / 4
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: ScreenAdapter.scaleH(16),
                                           left: ScreenAdapter.scaleW(16),
                                           bottom: ScreenAdapter.scaleH(16),
                                           right: ScreenAdapter.scaleW(16))

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CustomStickerCell.self, forCellWithReuseIdentifier: "CustomStickerCell")
        collectionView.register(AddStickerCell.self, forCellWithReuseIdentifier: "AddStickerCell")
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadStickers() {
        if let data = UserDefaults.standard.data(forKey: customStickersStorageKey),
           let list = try? JSONDecoder().decode([CustomSticker].self, from: data) {
            customStickers = list
        }
        collectionView.reloadData()
    }

    private func saveStickers() {
        if let data = try? JSONEncoder().encode(customStickers) {
            UserDefaults.standard.set(data, forKey: customStickersStorageKey)
        }
    }

    /// 自定义贴纸目录
    private func customStickersDirectory() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = documents.appendingPathComponent("CustomStickers")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func imagePath(for sticker: CustomSticker) -> String {
        return customStickersDirectory().appendingPathComponent(sticker.localFileName).path
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 添加自定义贴纸（从相册）
    private func addCustomSticker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.delegate = self
        imagePicker = picker
        present(picker, animated: true)
    }

    /// 保存图片到本地并插入记录
    private func saveCustomSticker(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            AppUtility.showToast("图片保存失败")
            return
        }
        let fileName = "custom_\(Int(Date().timeIntervalSince1970)).jpg"
        let fileURL = customStickersDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            let sticker = CustomSticker(id: UUID().uuidString, localFileName: fileName)
            customStickers.append(sticker)
            saveStickers()
            collectionView.reloadData()
        } catch {
            AppUtility.showToast("保存失败")
        }
    }

    /// 删除自定义贴纸
    private func deleteCustomSticker(at indexPath: IndexPath) {
        let sticker = customStickers[indexPath.item]
        let path = imagePath(for: sticker)
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        customStickers.remove(at: indexPath.item)
        saveStickers()
        collectionView.deleteItems(at: [indexPath])
    }
}

// MARK: - UICollectionViewDataSource & Delegate（自定义贴纸页）
extension CustomStickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return customStickers.count + 1 // +1 为添加按钮
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == customStickers.count {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "AddStickerCell", for: indexPath
            ) as! AddStickerCell
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "CustomStickerCell", for: indexPath
        ) as! CustomStickerCell
        let sticker = customStickers[indexPath.item]
        let path = imagePath(for: sticker)
        cell.configure(imagePath: path)
        cell.onLongPress = { [weak self] in
            self?.deleteCustomSticker(at: indexPath)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == customStickers.count {
            addCustomSticker()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CustomStickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        saveCustomSticker(image: image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - 自定义贴纸 Cell
class CustomStickerCell: UICollectionViewCell {

    var onLongPress: (() -> Void)?
    private let imageView = UIImageView()
    private var longPressGesture: UILongPressGestureRecognizer?

    /// 贴纸图内存缓存：避免滑动时每个 cell 重复从磁盘解码，造成掉帧
    private static let imageCache = NSCache<NSString, UIImage>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .themeBgWhite
        contentView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        contentView.layer.masksToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        contentView.addGestureRecognizer(lp)
        longPressGesture = lp
    }

    func configure(imagePath: String) {
        let key = imagePath as NSString
        if let cached = Self.imageCache.object(forKey: key) {
            imageView.image = cached
            return
        }
        if let image = UIImage(contentsOfFile: imagePath) {
            Self.imageCache.setObject(image, forKey: key)
            imageView.image = image
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray4
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.impactMedium()
            }
            onLongPress?()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}

// MARK: - 添加自定义贴纸 Cell
class AddStickerCell: UICollectionViewCell {

    private let iconImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .themeBgWhite
        contentView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        contentView.layer.masksToBounds = true

        iconImageView.image = UIImage(systemName: "plus")
        iconImageView.tintColor = .themeTextSecondary
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }
    }
}
