import UIKit
import SnapKit
import Kingfisher

// MARK: - @提及选择面板代理
protocol MentionPickerViewDelegate: AnyObject {
    func mentionPicker(_ picker: MentionPickerView, didSelectMember member: GroupMember)
    func mentionPickerDidSelectAll(_ picker: MentionPickerView)
}

// MARK: - @提及选择面板
class MentionPickerView: UIView {

    weak var delegate: MentionPickerViewDelegate?

    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private var members: [GroupMember] = []
    private var showsAllOption = true

    // MARK: - 液态玻璃背景
    @available(iOS 15.0, *)
    private lazy var glassBackgroundView: LiquidGlassView? = {
        let glass = LiquidGlassView()
        glass.cornerRadius = 0
        glass.glassOpacity = 0.6
        glass.borderWidth = 0
        glass.highlightOpacity = 0.1
        return glass
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = true

        // 液态玻璃背景（iOS 15+）
        if #available(iOS 15.0, *) {
            setupLiquidGlassBackground()
        } else {
            backgroundColor = .systemBackground
        }

        // 顶部分割线
        let topBorder = UIView()
        topBorder.backgroundColor = .themeSeparator
        addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // 标题
        titleLabel.text = "选择要@的成员"
        titleLabel.font = ScreenAdapter.font(13)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .left
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(8))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(20))
        }

        // 列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MentionMemberCell.self, forCellReuseIdentifier: "MentionMemberCell")
        tableView.register(MentionAllCell.self, forCellReuseIdentifier: "MentionAllCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(56), bottom: 0, right: 0)
        tableView.separatorColor = .themeSeparator
        tableView.rowHeight = ScreenAdapter.scaleH(44)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - 液态玻璃背景设置
    @available(iOS 15.0, *)
    private func setupLiquidGlassBackground() {
        guard let glass = glassBackgroundView else { return }
        glass.blurStyle = traitCollection.userInterfaceStyle == .dark ? .systemMaterialDark : .systemMaterial
        glass.borderColor = UIColor.white.withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.15 : 0.2)
        insertSubview(glass, at: 0)
        glass.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 15.0, *),
           traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            let isDark = traitCollection.userInterfaceStyle == .dark
            glassBackgroundView?.blurStyle = isDark ? .systemMaterialDark : .systemMaterial
            glassBackgroundView?.borderColor = UIColor.white.withAlphaComponent(isDark ? 0.15 : 0.2)
        }
    }

    // MARK: - 公共方法

    /// 更新成员列表
    func updateMembers(_ members: [GroupMember], showsAllOption: Bool = true) {
        self.members = members
        self.showsAllOption = showsAllOption
        tableView.reloadData()
    }

    /// 入场动画（从下方滑入 + 淡入）
    func animateEntrance() {
        let offset = ScreenAdapter.scaleH(200)
        transform = CGAffineTransform(translationX: 0, y: offset)
        alpha = 0

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            self.transform = .identity
            self.alpha = 1
        }
    }

    /// 退场动画（向下滑出 + 淡出）
    func animateExit(completion: (() -> Void)? = nil) {
        let offset = ScreenAdapter.scaleH(200)

        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
            self.transform = CGAffineTransform(translationX: 0, y: offset)
            self.alpha = 0
        }) { _ in
            completion?()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MentionPickerView: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return showsAllOption ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsAllOption && section == 0 {
            return 1
        }
        return members.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsAllOption && indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MentionAllCell", for: indexPath) as! MentionAllCell
            cell.configure()
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "MentionMemberCell", for: indexPath) as! MentionMemberCell
        let member = members[indexPath.row]
        cell.configure(with: member)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // 触觉反馈
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
            HapticManager.shared.impactSoft()
        }

        if showsAllOption && indexPath.section == 0 {
            delegate?.mentionPickerDidSelectAll(self)
        } else {
            let member = members[indexPath.row]
            delegate?.mentionPicker(self, didSelectMember: member)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if showsAllOption && section == 0 {
            return 0
        }
        return 0
    }
}

// MARK: - 所有人选项 Cell
class MentionAllCell: UITableViewCell {

    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()

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

        let avatarSize = ScreenAdapter.scaleW(32)

        iconImageView.image = UIImage(systemName: "person.3.fill")
        iconImageView.tintColor = .white
        iconImageView.backgroundColor = .systemOrange
        iconImageView.contentMode = .center
        iconImageView.layer.cornerRadius = avatarSize / 2
        iconImageView.clipsToBounds = true
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.text = "@所有人"
        nameLabel.font = ScreenAdapter.font(15)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(12))
        }
    }

    func configure() {
        // 无需额外配置
    }
}

// MARK: - 成员 Cell
class MentionMemberCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

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

        let avatarSize = ScreenAdapter.scaleW(32)

        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.font = ScreenAdapter.font(15)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(12))
        }
    }

    func configure(with member: GroupMember) {
        nameLabel.text = member.nickname ?? member.name

        if let avatar = member.avatar, let url = URL(string: avatar) {
            avatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
        } else {
            avatarView.image = UIImage(systemName: "person.circle.fill")
            avatarView.tintColor = .systemGray5
        }
    }
}
