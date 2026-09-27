import UIKit
import SnapKit
import Kingfisher

// MARK: - 我的页面
class MySettingViewController: UIViewController {

    // MARK: - UI 元素
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // 顶部用户信息卡片
    private let userInfoCard = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let idLabel = UILabel()
    private let qrButton = UIButton(type: .custom)
    private let arrowImageView = UIImageView()

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

        // MARK: - 用户信息卡片
        userInfoCard.backgroundColor = .white
        userInfoCard.layer.cornerRadius = 12
        userInfoCard.clipsToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMyInfo))
        userInfoCard.addGestureRecognizer(tap)
        userInfoCard.isUserInteractionEnabled = true
        contentView.addSubview(userInfoCard)
        userInfoCard.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 头像
        avatarImageView.layer.cornerRadius = 45
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemGray5
        userInfoCard.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.height.equalTo(90)
        }

        // 名字
        nameLabel.font = ScreenAdapter.boldFont(20)
        nameLabel.textColor = .label
        nameLabel.text = "未登录"
        userInfoCard.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.top.equalTo(avatarImageView.snp.top).offset(12)
            make.trailing.equalTo(qrButton.snp.leading).offset(-8)
        }

        // Milo号
        idLabel.font = ScreenAdapter.font(13)
        idLabel.textColor = .secondaryLabel
        idLabel.text = ""
        userInfoCard.addSubview(idLabel)
        idLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.trailing.equalTo(qrButton.snp.leading).offset(-8)
        }

        // 二维码按钮
        let qrConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        qrButton.setImage(UIImage(systemName: "qrcode", withConfiguration: qrConfig), for: .normal)
        qrButton.tintColor = .secondaryLabel
        qrButton.addTarget(self, action: #selector(showMyQRCode), for: .touchUpInside)
        userInfoCard.addSubview(qrButton)
        qrButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // 箭头
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = UIColor(white: 0.8, alpha: 1.0)
        arrowImageView.contentMode = .scaleAspectFit
        userInfoCard.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-20)
            make.width.height.equalTo(14)
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
        if let userInfo = UserDefaults.standard.dictionary(forKey: "userInfo"),
           let name = userInfo["name"] as? String {
            nameLabel.text = name
            if let uid = userInfo["uid"] as? String {
                idLabel.text = "Milo号：\(uid)"
                if let avatarUrl = userInfo["avatar"] as? String, let url = URL(string: avatarUrl) {
                    AppUtility.loadAvatar(url, into: avatarImageView)
                }
            }
        } else {
            nameLabel.text = "点击登录"
            idLabel.text = ""
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }

    // MARK: - 页面跳转
    @objc private func showMyInfo() {
        let profileVC = ProfileEditViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }

    @objc private func showMyQRCode() {
        let qrVC = UserQRCodeViewController()
        navigationController?.pushViewController(qrVC, animated: true)
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
