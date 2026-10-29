import UIKit
import SnapKit
import Kingfisher

// MARK: - 我的页面
class MySettingViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - UI 元素
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // 顶部用户信息卡片
    private let userInfoCard = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let idLabel = UILabel()

    // 菜单项
    private let menuStackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserInfo()
        setupObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadUserInfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleUserInfoUpdated(_:)),
            name: NSNotification.Name("UserInfoUpdated"), object: nil
        )
    }

    @objc private func handleUserInfoUpdated(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadUserInfo()
        }
    }

    // MARK: - 布局
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)

        // ScrollView
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // MARK: - 顶部标题
        let titleLabel = UILabel()
        titleLabel.text = "我的"
        titleLabel.font = ScreenAdapter.boldFont(20)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }

        // MARK: - 用户信息卡片（液态玻璃，圆角 16）
        userInfoCard.backgroundColor = .clear
        userInfoCard.layer.cornerRadius = 16
        userInfoCard.applyLiquidGlassEffect(cornerRadius: 16)
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMyInfo))
        tap.delegate = self
        userInfoCard.addGestureRecognizer(tap)
        userInfoCard.isUserInteractionEnabled = true
        contentView.addSubview(userInfoCard)
        userInfoCard.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 头像（点击进入头像查看页）
        avatarImageView.layer.cornerRadius = 34
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemGray5
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(showHeadPortrait))
        avatarImageView.addGestureRecognizer(avatarTap)
        userInfoCard.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.height.equalTo(68)
        }

        // 名字
        nameLabel.font = ScreenAdapter.mediumFont(17)
        nameLabel.textColor = .label
        nameLabel.text = "未登录"
        userInfoCard.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(14)
            make.top.equalTo(avatarImageView.snp.top).offset(13)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        // Milo号
        idLabel.font = ScreenAdapter.font(13)
        idLabel.textColor = .secondaryLabel
        idLabel.text = nil
        userInfoCard.addSubview(idLabel)
        idLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        // MARK: - 菜单项
        menuStackView.axis = .vertical
        menuStackView.spacing = 0
        menuStackView.backgroundColor = .white
        menuStackView.layer.cornerRadius = 12
        menuStackView.clipsToBounds = true
        contentView.addSubview(menuStackView)
        menuStackView.snp.makeConstraints { make in
            make.top.equalTo(userInfoCard.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 我的笔记
        addMenuItem(icon: "note.text", title: "我的笔记", color: UIColor(red: 0.36, green: 0.55, blue: 0.94, alpha: 1.0), action: #selector(showNotes))

        // 我的收藏
        addMenuItem(icon: "star.fill", title: "我的收藏", color: UIColor(red: 1.0, green: 0.56, blue: 0.16, alpha: 1.0), action: #selector(showFavorites))

        // 设置
        addMenuItem(icon: "gearshape.fill", title: "设置", color: UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0), action: #selector(showSettings), isLast: true)

        // 底部留白
        contentView.snp.makeConstraints { make in
            make.bottom.equalTo(menuStackView.snp.bottom).offset(30)
        }
    }

    private func addMenuItem(icon: String, title: String, color: UIColor, action: Selector, isLast: Bool = false) {
        let cell = MenuItemCell()
        cell.configure(icon: icon, title: title, color: color, showSeparator: !isLast)
        let tap = UITapGestureRecognizer(target: self, action: action)
        cell.addGestureRecognizer(tap)
        cell.isUserInteractionEnabled = true
        menuStackView.addArrangedSubview(cell)
        cell.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }

    // MARK: - 加载用户信息
    private func loadUserInfo() {
        let defaults = UserDefaults.standard
        let uid = defaults.string(forKey: "uid") ?? ""
        let token = defaults.string(forKey: "token") ?? ""
        if !uid.isEmpty && !token.isEmpty {
            let name = defaults.string(forKey: "name") ?? ""
            nameLabel.text = name.isEmpty ? "Milo用户" : name
            let shortNo = defaults.string(forKey: "short_no") ?? ""
            idLabel.text = shortNo.isEmpty ? nil : "Milo号: \(shortNo)"
            idLabel.isHidden = shortNo.isEmpty
            // 与Android一致：通过 /v1/users/{uid}/avatar 加载自己的头像
            AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: name, into: avatarImageView)
        } else {
            nameLabel.text = "点击登录"
            idLabel.text = nil
            idLabel.isHidden = true
            avatarImageView.image = AppUtility.defaultAvatarImage(name: "", size: 96)
        }
    }

    // MARK: - 页面跳转
    @objc private func showMyInfo() {
        navigationController?.pushViewController(MyInfoViewController(), animated: true)
    }

    @objc private func showHeadPortrait() {
        navigationController?.pushViewController(MyHeadPortraitViewController(), animated: true)
    }

    // 头像区域点击交给头像自身的点击手势，其余区域进入个人信息页
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer.view == userInfoCard else { return true }
        let point = touch.location(in: userInfoCard)
        return !avatarImageView.frame.contains(point)
    }

    @objc private func showNotes() {
        let notesVC = NoteListViewController()
navigationController?.pushViewController(notesVC, animated: true)
    }

    @objc private func showFavorites() {
        let favVC = FavoriteViewController()
navigationController?.pushViewController(favVC, animated: true)
    }

    @objc private func showSettings() {
        let settingsVC = SettingMainViewController()
navigationController?.pushViewController(settingsVC, animated: true)
    }
}

// MARK: - 菜单项Cell
class MenuItemCell: UIView {

    private let iconBgView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let arrowView = UIImageView()
    private let separatorLine = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white

        let iconSize: CGFloat = 32
        let hPad: CGFloat = 16

        // 图标背景
        iconBgView.layer.cornerRadius = 8
        iconBgView.clipsToBounds = true
        addSubview(iconBgView)
        iconBgView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }

        // 图标
        iconImageView.tintColor = .white
        iconImageView.contentMode = .center
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconImageView.preferredSymbolConfiguration = config
        iconBgView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 标题
        titleLabel.font = ScreenAdapter.font(16)
        titleLabel.textColor = .label
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBgView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        // 箭头
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = UIColor(white: 0.8, alpha: 1.0)
        arrowView.contentMode = .scaleAspectFit
        addSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // 分割线
        separatorLine.backgroundColor = UIColor(white: 0, alpha: 0.06)
        addSubview(separatorLine)
        separatorLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad + iconSize + 12)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func configure(icon: String, title: String, color: UIColor, showSeparator: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)
        iconBgView.backgroundColor = color
        titleLabel.text = title
        separatorLine.isHidden = !showSeparator
    }
}
