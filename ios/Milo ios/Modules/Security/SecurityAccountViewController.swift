import UIKit
import SnapKit

// MARK: - 账号安全（对照 Android SecurityAccountActivity）
class SecurityAccountViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    /// 账号绑定的右侧状态（手机号脱敏 / 未绑定）
    private let bindStatusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "账号安全"
        view.backgroundColor = .themeBackground
        setupUI()
        refreshBindStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshBindStatus()
    }

    // MARK: - 账号绑定状态
    private func refreshBindStatus() {
        let defaults = UserDefaults.standard
        var phone = defaults.string(forKey: "bind_phone") ?? ""
        if phone.isEmpty {
            phone = defaults.string(forKey: "phone") ?? ""
        }

        if phone.count >= 7 {
            bindStatusLabel.text = "\(phone.prefix(3))****\(phone.suffix(4))"
            bindStatusLabel.textColor = .label
        } else {
            bindStatusLabel.text = "未绑定"
            bindStatusLabel.textColor = .secondaryLabel
        }
    }

    // MARK: - 布局
    private func setupUI() {
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

        // 安全提示横幅
        let banner = makeBanner(
            icon: "shield.lefthalf.filled",
            title: "保护你的账号安全",
            desc: "管理账号凭证、登录设备与安全设置"
        )
        contentView.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 账号凭证
        let credentialsLabel = makeSectionLabel("账号凭证")
        contentView.addSubview(credentialsLabel)
        credentialsLabel.snp.makeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        bindStatusLabel.font = ScreenAdapter.font(14)

        let bindRow = SecurityAccountRowView(
            title: "账号绑定",
            subtitle: "管理已绑定的手机号与电子邮箱",
            showRightText: bindStatusLabel
        ) { [weak self] in
            self?.navigationController?.pushViewController(AccountBindingViewController(), animated: true)
        }

        let changePwdRow = SecurityAccountRowView(
            title: "修改密码",
            subtitle: "修改登录密码、聊天密码与锁屏密码"
        ) { [weak self] in
            self?.navigationController?.pushViewController(PwdManagerViewController(), animated: true)
        }

        let credentialsCard = makeGlassCard(rows: [bindRow, changePwdRow])
        contentView.addSubview(credentialsCard)
        credentialsCard.snp.makeConstraints { make in
            make.top.equalTo(credentialsLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 安全管理
        let securityLabel = makeSectionLabel("安全管理")
        contentView.addSubview(securityLabel)
        securityLabel.snp.makeConstraints { make in
            make.top.equalTo(credentialsCard.snp.bottom).offset(20)
            make.leading.equalTo(credentialsLabel)
        }

        let blacklistRow = SecurityAccountRowView(
            title: "黑名单管理",
            subtitle: "查看和管理已屏蔽的用户"
        ) { [weak self] in
            self?.navigationController?.pushViewController(BlacklistViewController(), animated: true)
        }

        let securityCard = makeGlassCard(rows: [blacklistRow])
        contentView.addSubview(securityCard)
        securityCard.snp.makeConstraints { make in
            make.top.equalTo(securityLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(credentialsCard)
        }

        // 账号操作
        let operationLabel = makeSectionLabel("账号操作")
        contentView.addSubview(operationLabel)
        operationLabel.snp.makeConstraints { make in
            make.top.equalTo(securityCard.snp.bottom).offset(20)
            make.leading.equalTo(credentialsLabel)
        }

        let destroyRow = SecurityAccountRowView(
            title: "注销账号",
            subtitle: "注销当前账号及相关数据",
            isDestructive: true
        ) { [weak self] in
            self?.navigationController?.pushViewController(DestroyAccountViewController(), animated: true)
        }

        let operationCard = makeGlassCard(rows: [destroyRow])
        contentView.addSubview(operationCard)
        operationCard.snp.makeConstraints { make in
            make.top.equalTo(operationLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(credentialsCard)
            make.bottom.equalToSuperview().offset(-30)
        }
    }

    // MARK: - UI 构建
    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = ScreenAdapter.font(13)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeBanner(icon: String, title: String, desc: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .clear
        card.layer.cornerRadius = 16
        card.applyLiquidGlassEffect(cornerRadius: 16)

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 24
        iconBg.clipsToBounds = true
        card.addSubview(iconBg)
        iconBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .themePrimary
        iconView.contentMode = .scaleAspectFit
        iconBg.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ScreenAdapter.boldFont(16)
        titleLabel.textColor = .label
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBg.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-20)
        }

        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = ScreenAdapter.font(13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-26)
        }

        return card
    }

    /// 液态玻璃卡片，内部按顺序纵向排列行
    private func makeGlassCard(rows: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = .clear
        card.layer.cornerRadius = 16
        card.applyLiquidGlassEffect(cornerRadius: 16)

        var previous: UIView?
        for row in rows {
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                if let previous = previous {
                    make.top.equalTo(previous.snp.bottom).offset(0.5)
                } else {
                    make.top.equalToSuperview()
                }
            }
            if previous != nil {
                let separator = UIView()
                separator.backgroundColor = .themeSeparatorLight
                card.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.trailing.equalToSuperview()
                    make.height.equalTo(0.5)
                    make.bottom.equalTo(row.snp.top)
                }
            }
            previous = row
        }
        previous?.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
        return card
    }
}

// MARK: - 账号安全行
private final class SecurityAccountRowView: UIView {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let arrowView = UIImageView()
    private var onTap: (() -> Void)?

    init(title: String,
         subtitle: String,
         showRightText: UILabel? = nil,
         isDestructive: Bool = false,
         onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        super.init(frame: .zero)
        setupUI(title: title, subtitle: subtitle, rightText: showRightText, isDestructive: isDestructive)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(title: String, subtitle: String, rightText: UILabel?, isDestructive: Bool) {
        backgroundColor = .clear

        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = UIColor(white: 0.8, alpha: 1.0)
        arrowView.contentMode = .scaleAspectFit
        addSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }

        titleLabel.text = title
        titleLabel.font = ScreenAdapter.font(16)
        titleLabel.textColor = isDestructive ? .systemRed : .label
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
        }

        if let rightText = rightText {
            addSubview(rightText)
            rightText.snp.makeConstraints { make in
                make.trailing.equalTo(arrowView.snp.leading).offset(-8)
                make.centerY.equalTo(titleLabel)
            }
            titleLabel.snp.makeConstraints { make in
                make.trailing.lessThanOrEqualTo(rightText.snp.leading).offset(-8)
            }
        } else {
            titleLabel.snp.makeConstraints { make in
                make.trailing.lessThanOrEqualTo(arrowView.snp.leading).offset(-8)
            }
        }

        subtitleLabel.text = subtitle
        subtitleLabel.font = ScreenAdapter.font(13)
        subtitleLabel.textColor = .secondaryLabel
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-14)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }
}
