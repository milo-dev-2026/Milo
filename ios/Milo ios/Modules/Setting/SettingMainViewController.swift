import UIKit
import SnapKit

// MARK: - 设置主页面（对照 Android SettingActivity，仅保留 4 个入口）
class SettingMainViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "设置"
        view.backgroundColor = .themeBackground

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

        // 分组标题：隐私设置
        let sectionLabel = makeSectionLabel("隐私设置")
        contentView.addSubview(sectionLabel)
        sectionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        // 账号安全 + 消息通知
        let accountRow = SettingEntryRow(title: "账号安全") { [weak self] in
            self?.navigationController?.pushViewController(SecurityAccountViewController(), animated: true)
        }
        let noticeRow = SettingEntryRow(title: "消息通知") { [weak self] in
            self?.navigationController?.pushViewController(MsgNoticesSettingViewController(), animated: true)
        }
        let mainCard = makeGlassCard(rows: [accountRow, noticeRow])
        contentView.addSubview(mainCard)
        mainCard.snp.makeConstraints { make in
            make.top.equalTo(sectionLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 关于我们
        let aboutRow = SettingEntryRow(title: "关于我们") { [weak self] in
            self?.navigationController?.pushViewController(AboutViewController(), animated: true)
        }
        let aboutCard = makeGlassCard(rows: [aboutRow])
        contentView.addSubview(aboutCard)
        aboutCard.snp.makeConstraints { make in
            make.top.equalTo(mainCard.snp.bottom).offset(10)
            make.leading.trailing.equalTo(mainCard)
        }

        // 退出登录
        let logoutCard = makeLogoutCard()
        contentView.addSubview(logoutCard)
        logoutCard.snp.makeConstraints { make in
            make.top.equalTo(aboutCard.snp.bottom).offset(30)
            make.leading.trailing.equalTo(mainCard)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-30)
        }
    }

    // MARK: - 退出登录
    private func showLogoutConfirm() {
        let alert = UIAlertController(
            title: "退出登录",
            message: "退出后不会删除任何历史数据，下次登录依然可以使用本账号。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出登录", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        present(alert, animated: true)
    }

    private func logout() {
        // 断开 IM 连接并清除本地登录状态（token、uid 等）
        IMManager.shared.disconnect()
        LocalStore.shared.clearAll()
        // 一并清除其余用户信息，避免切换账号后展示残留数据
        let defaults = UserDefaults.standard
        ["short_no", "sex", "sign", "bind_phone", "bind_email", "email"].forEach {
            defaults.removeObject(forKey: $0)
        }

        let loginVC = LoginViewController(account: "", isEmail: false)
        let nav = BaseNavigationController(rootViewController: loginVC)
        view.window?.rootViewController = nav
    }

    // MARK: - UI 构建
    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = ScreenAdapter.font(13)
        label.textColor = .secondaryLabel
        return label
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
            if let previous = previous {
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

    private func makeLogoutCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .clear
        card.layer.cornerRadius = 16
        card.applyLiquidGlassEffect(cornerRadius: 16)

        let label = UILabel()
        label.text = "退出登录"
        label.font = ScreenAdapter.font(16)
        label.textColor = .systemRed
        label.textAlignment = .center
        card.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(logoutTapped))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        return card
    }

    @objc private func logoutTapped() {
        showLogoutConfirm()
    }
}

// MARK: - 设置项行
private final class SettingEntryRow: UIView {

    private let titleLabel = UILabel()
    private let arrowView = UIImageView()
    private var onTap: (() -> Void)?

    init(title: String, onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        super.init(frame: .zero)
        setupUI(title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(title: String) {
        backgroundColor = .clear

        titleLabel.text = title
        titleLabel.font = ScreenAdapter.font(16)
        titleLabel.textColor = .label
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-40)
        }

        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = UIColor(white: 0.8, alpha: 1.0)
        arrowView.contentMode = .scaleAspectFit
        addSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }

        snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }
}
