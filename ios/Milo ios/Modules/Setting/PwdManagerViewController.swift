import UIKit
import SnapKit

// MARK: - 密码管理（对照 Android 密码管理页）
class PwdManagerViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let chatPwdStatusLabel = UILabel()
    private let lockPwdStatusLabel = UILabel()

    private var uid: String { UserDefaults.standard.string(forKey: "uid") ?? "" }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "密码管理"
        view.backgroundColor = .themeBackground
        setupUI()
        refreshStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshStatus()
    }

    private func refreshStatus() {
        let chatSet = UserDefaults.standard.bool(forKey: "chat_pwd_set_\(uid)")
        chatPwdStatusLabel.text = chatSet ? "已设置" : "未设置"

        let lockSet = LocalStore.shared.isAppLockEnabled
        lockPwdStatusLabel.text = lockSet ? "已设置" : "未设置"
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

        let banner = makeBanner(
            icon: "lock.fill",
            title: "管理你的账号密码",
            desc: "定期更新密码，降低账号和本机数据泄露风险"
        )
        contentView.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 账号密码
        let accountLabel = makeSectionLabel("账号密码")
        contentView.addSubview(accountLabel)
        accountLabel.snp.makeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        let loginPwdRow = PwdManagerRowView(
            title: "登录密码",
            subtitle: "用于登录当前账号，可随时重置"
        ) { [weak self] in
            self?.navigationController?.pushViewController(LoginPasswordViewController(), animated: true)
        }

        let chatPwdRow = PwdManagerRowView(
            title: "聊天密码",
            subtitle: "使用独立的6位密码保护聊天内容",
            showRightText: chatPwdStatusLabel
        ) { [weak self] in
            self?.navigationController?.pushViewController(ChatPasswordViewController(), animated: true)
        }

        let accountCard = makeCard(rows: [loginPwdRow, chatPwdRow])
        contentView.addSubview(accountCard)
        accountCard.snp.makeConstraints { make in
            make.top.equalTo(accountLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 设备保护
        let deviceLabel = makeSectionLabel("设备保护")
        contentView.addSubview(deviceLabel)
        deviceLabel.snp.makeConstraints { make in
            make.top.equalTo(accountCard.snp.bottom).offset(20)
            make.leading.equalTo(accountLabel)
        }

        let lockRow = PwdManagerRowView(
            title: "锁屏密码",
            subtitle: "离开应用后限制他人访问本机内容",
            showRightText: lockPwdStatusLabel
        ) { [weak self] in
            self?.navigationController?.pushViewController(LockScreenPwdViewController(), animated: true)
        }

        let deviceCard = makeCard(rows: [lockRow])
        contentView.addSubview(deviceCard)
        deviceCard.snp.makeConstraints { make in
            make.top.equalTo(deviceLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(accountCard)
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
        card.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 1.0, alpha: 1.0)
        card.layer.cornerRadius = 16

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

    private func makeCard(rows: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16

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

// MARK: - 密码管理行
private final class PwdManagerRowView: UIView {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let arrowView = UIImageView()
    private var onTap: (() -> Void)?

    init(title: String,
         subtitle: String,
         showRightText: UILabel? = nil,
         onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        super.init(frame: .zero)
        setupUI(title: title, subtitle: subtitle, rightText: showRightText)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(title: String, subtitle: String, rightText: UILabel?) {
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
        titleLabel.textColor = .label
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
        }

        if let rightText = rightText {
            rightText.font = ScreenAdapter.font(14)
            rightText.textColor = .secondaryLabel
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
