import UIKit
import SnapKit

class ChatBackgroundViewController: UIViewController {

    /// Android ChatBgListActivity 的 12 个内置颜色（统一存 #RRGGBB）
    static let backgroundColors: [(name: String, hex: String)] = [
        ("白色", "#FFFFFF"),
        ("浅灰", "#F5F5F5"),
        ("淡绿", "#E8F5E9"),
        ("淡蓝", "#E3F2FD"),
        ("淡粉", "#FCE4EC"),
        ("淡橙", "#FFF3E0"),
        ("淡紫", "#F3E5F5"),
        ("淡青", "#E0F7FA"),
        ("浅棕", "#EFEBE9"),
        ("冷灰", "#ECEFF1"),
        ("淡黄", "#FFFDE7"),
        ("青柠", "#F1F8E9")
    ]

    /// 兼容旧接口：设置页展示用
    static var backgroundList: [(name: String, color: UIColor)] {
        return backgroundColors.map { ($0.name, UIColor.hex($0.hex)) }
    }

    /// 兼容旧接口：兼容 chat_bg_index（0-11）
    static var currentColor: UIColor {
        let list = backgroundColors
        let index = UserDefaults.standard.integer(forKey: "chat_bg_index")
        guard list.indices.contains(index) else { return .themeChatBackground }
        return UIColor.hex(list[index].hex)
    }

    private let channelId: String
    private let channelType: Int

    private let applyCard = UIView()
    private let applyAllSwitch = UISwitch()
    private var collectionView: UICollectionView!
    /// 当前选中的颜色下标；nil 表示尚未设置
    private var selectedIndex: Int?

    init(channelId: String, channelType: Int = 1) {
        self.channelId = channelId
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentSelection()
    }

    private func setupUI() {
        title = "聊天背景"
        view.backgroundColor = .themeBackground

        // 应用到全部聊天
        applyCard.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        applyCard.layer.cornerRadius = 12
        applyCard.layer.borderWidth = 0.5
        applyCard.layer.borderColor = UIColor(white: 0, alpha: 0.06).cgColor

        let applyTitleLabel = UILabel()
        applyTitleLabel.text = "应用到全部聊天"
        applyTitleLabel.font = ScreenAdapter.mediumFont(16)
        applyTitleLabel.textColor = .label

        let applyDetailLabel = UILabel()
        applyDetailLabel.text = "开启后所选颜色将作为所有聊天的默认背景"
        applyDetailLabel.font = ScreenAdapter.font(12)
        applyDetailLabel.textColor = .secondaryLabel
        applyDetailLabel.numberOfLines = 1

        applyAllSwitch.onTintColor = .themePrimary
        applyAllSwitch.addTarget(self, action: #selector(applyAllChanged(_:)), for: .valueChanged)

        view.addSubview(applyCard)
        applyCard.addSubviews(applyTitleLabel, applyDetailLabel, applyAllSwitch)

        applyCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(64)
        }

        applyTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(13)
        }

        applyDetailLabel.snp.makeConstraints { make in
            make.leading.equalTo(applyTitleLabel)
            make.top.equalTo(applyTitleLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(applyAllSwitch.snp.leading).offset(-12)
        }

        applyAllSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        // 2 列颜色网格
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ChatBackgroundColorCell.self, forCellWithReuseIdentifier: "ChatBackgroundColorCell")

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(applyCard.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - 读取已保存的背景（会话级 > 全局 > 兼容 chat_bg_index）
    private func loadCurrentSelection() {
        let defaults = UserDefaults.standard
        let colors = ChatBackgroundViewController.backgroundColors

        if let hex = defaults.string(forKey: "chat_bg_\(channelId)"), !hex.isEmpty {
            selectedIndex = colors.firstIndex { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }
        }
        if selectedIndex == nil, let hex = defaults.string(forKey: "chat_bg_global"), !hex.isEmpty {
            selectedIndex = colors.firstIndex { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }
        }
        if selectedIndex == nil, defaults.object(forKey: "chat_bg_index") != nil {
            let index = defaults.integer(forKey: "chat_bg_index")
            if colors.indices.contains(index) {
                selectedIndex = index
            }
        }

        let hasGlobal = (defaults.string(forKey: "chat_bg_global")?.isEmpty == false)
            || defaults.object(forKey: "chat_bg_index") != nil
        applyAllSwitch.isOn = hasGlobal

        collectionView.reloadData()
    }

    // MARK: - 选择颜色
    private func selectColor(at index: Int) {
        guard ChatBackgroundViewController.backgroundColors.indices.contains(index) else { return }
        let defaults = UserDefaults.standard
        let hex = ChatBackgroundViewController.backgroundColors[index].hex

        selectedIndex = index
        // 会话级背景：chat_bg_<channelId>
        defaults.set(hex, forKey: "chat_bg_\(channelId)")

        if applyAllSwitch.isOn {
            defaults.set(hex, forKey: "chat_bg_global")
            // 兼容旧版 chat_bg_index（仅前 8 色有索引映射）
            if index < 8 {
                defaults.set(index, forKey: "chat_bg_index")
            } else {
                defaults.removeObject(forKey: "chat_bg_index")
            }
        }

        collectionView.reloadData()
        AppUtility.showToast("已设置聊天背景")
    }

    @objc private func applyAllChanged(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        let colors = ChatBackgroundViewController.backgroundColors

        if sender.isOn {
            let index = selectedIndex ?? 0
            defaults.set(colors[index].hex, forKey: "chat_bg_global")
            // 兼容旧版索引读取
            if index < 8 {
                defaults.set(index, forKey: "chat_bg_index")
            } else {
                defaults.removeObject(forKey: "chat_bg_index")
            }
            AppUtility.showToast("已应用到全部聊天")
        } else {
            defaults.removeObject(forKey: "chat_bg_global")
            defaults.removeObject(forKey: "chat_bg_index")
            AppUtility.showToast("已取消全局聊天背景")
        }
    }
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout
extension ChatBackgroundViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ChatBackgroundViewController.backgroundColors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ChatBackgroundColorCell", for: indexPath
        ) as! ChatBackgroundColorCell
        let item = ChatBackgroundViewController.backgroundColors[indexPath.item]
        cell.configure(name: item.name, hex: item.hex, isSelected: selectedIndex == indexPath.item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectColor(at: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        guard width > 0 else { return CGSize(width: 160, height: 96) }
        let itemWidth = (width - 16 * 2 - 12) / 2
        return CGSize(width: floor(itemWidth), height: 96)
    }
}

// MARK: - 颜色卡片 Cell
final class ChatBackgroundColorCell: UICollectionViewCell {

    private let colorView = UIView()
    private let nameLabel = UILabel()
    private let checkView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        colorView.layer.cornerRadius = 8
        colorView.clipsToBounds = true
        colorView.layer.borderWidth = 0.5
        colorView.layer.borderColor = UIColor.systemGray4.cgColor

        nameLabel.font = ScreenAdapter.font(13)
        nameLabel.textColor = .secondaryLabel
        nameLabel.textAlignment = .center

        checkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkView.tintColor = .themePrimary
        checkView.backgroundColor = .white
        checkView.layer.cornerRadius = 10
        checkView.clipsToBounds = true
        checkView.contentMode = .scaleAspectFit
        checkView.isHidden = true

        contentView.addSubviews(colorView, nameLabel)
        colorView.addSubview(checkView)

        colorView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalTo(56)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(colorView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }

        checkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    func configure(name: String, hex: String, isSelected: Bool) {
        nameLabel.text = name
        colorView.backgroundColor = UIColor.hex(hex)
        checkView.isHidden = !isSelected
        contentView.layer.borderWidth = isSelected ? 2 : 0
        contentView.layer.borderColor = UIColor.themePrimary.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.layer.borderWidth = 0
    }
}
