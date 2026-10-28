import UIKit
import SnapKit

// MARK: - 账号绑定（对照 Android 账号绑定页）
class AccountBindingViewController: UIViewController {

    private enum BindType { case phone, email }

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let phoneBadge = PaddingLabel()
    private let phoneAccountLabel = UILabel()
    private let phoneActionButton = UIButton(type: .system)

    private let emailBadge = PaddingLabel()
    private let emailAccountLabel = UILabel()
    private let emailActionButton = UIButton(type: .system)

    private var bindPhone: String {
        let p = UserDefaults.standard.string(forKey: "bind_phone") ?? ""
        return p.isEmpty ? (UserDefaults.standard.string(forKey: "phone") ?? "") : p
    }
    private var bindEmail: String { UserDefaults.standard.string(forKey: "bind_email") ?? "" }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "账号绑定"
        view.backgroundColor = .themeBackground
        setupUI()
        refreshUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
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
            icon: "shield.lefthalf.filled",
            title: "完善账号验证方式",
            desc: "绑定手机号和邮箱，提升登录与账号找回的安全性"
        )
        contentView.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        let phoneCard = makeBindCard(
            title: "手机号码",
            desc: "用于登录、身份验证和账号安全通知",
            badge: phoneBadge,
            accountLabel: phoneAccountLabel,
            actionButton: phoneActionButton
        ) { [weak self] in
            self?.showBindDialog(type: .phone)
        }
        contentView.addSubview(phoneCard)
        phoneCard.snp.makeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(16)
            make.leading.trailing.equalTo(banner)
        }

        let emailCard = makeBindCard(
            title: "电子邮箱",
            desc: "可作为备用身份验证与账号找回方式",
            badge: emailBadge,
            accountLabel: emailAccountLabel,
            actionButton: emailActionButton
        ) { [weak self] in
            self?.showBindDialog(type: .email)
        }
        contentView.addSubview(emailCard)
        emailCard.snp.makeConstraints { make in
            make.top.equalTo(phoneCard.snp.bottom).offset(12)
            make.leading.trailing.equalTo(banner)
        }

        let tipLabel = UILabel()
        tipLabel.text = "绑定或更换账号信息前，需要先完成安全验证。"
        tipLabel.font = ScreenAdapter.font(12)
        tipLabel.textColor = .secondaryLabel
        tipLabel.textAlignment = .center
        contentView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(emailCard.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-30)
        }
    }

    private func refreshUI() {
        let phone = bindPhone
        let phoneBound = !phone.isEmpty
        updateBadge(phoneBadge, bound: phoneBound)
        phoneAccountLabel.text = phoneBound ? maskPhone(phone) : "未绑定"
        phoneAccountLabel.textColor = phoneBound ? .label : .secondaryLabel
        styleActionButton(phoneActionButton, bound: phoneBound)

        let email = bindEmail
        let emailBound = !email.isEmpty
        updateBadge(emailBadge, bound: emailBound)
        emailAccountLabel.text = emailBound ? email : "未绑定"
        emailAccountLabel.textColor = emailBound ? .label : .secondaryLabel
        styleActionButton(emailActionButton, bound: emailBound)
    }

    private func maskPhone(_ phone: String) -> String {
        phone.count >= 7 ? "\(phone.prefix(3))****\(phone.suffix(4))" : phone
    }

    // MARK: - UI 构建
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

    private func makeBindCard(title: String,
                              desc: String,
                              badge: PaddingLabel,
                              accountLabel: UILabel,
                              actionButton: UIButton,
                              onTap: @escaping () -> Void) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ScreenAdapter.boldFont(16)
        titleLabel.textColor = .label
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
        }

        badge.font = ScreenAdapter.font(11)
        badge.layer.cornerRadius = 9
        badge.clipsToBounds = true
        card.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
        }

        accountLabel.font = ScreenAdapter.font(17)
        card.addSubview(accountLabel)
        accountLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-16)
        }

        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = ScreenAdapter.font(13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(accountLabel.snp.bottom).offset(6)
            make.trailing.equalToSuperview().offset(-16)
        }

        actionButton.titleLabel?.font = ScreenAdapter.font(14)
        actionButton.layer.cornerRadius = 16
        actionButton.clipsToBounds = true
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        card.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(descLabel.snp.bottom).offset(14)
            make.height.equalTo(32)
            make.bottom.equalToSuperview().offset(-16)
        }

        let tapAction = UIAction { _ in onTap() }
        actionButton.addAction(tapAction, for: .touchUpInside)

        return card
    }

    private func updateBadge(_ badge: PaddingLabel, bound: Bool) {
        badge.text = bound ? "已绑定" : "未绑定"
        if bound {
            badge.textColor = .themePrimary
            badge.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.12)
        } else {
            badge.textColor = .secondaryLabel
            badge.backgroundColor = UIColor(white: 0.93, alpha: 1.0)
        }
    }

    private func styleActionButton(_ button: UIButton, bound: Bool) {
        if bound {
            button.setTitle("更换", for: .normal)
            button.backgroundColor = .themePrimary
            button.setTitleColor(.white, for: .normal)
            button.layer.borderWidth = 0
        } else {
            button.setTitle("绑定", for: .normal)
            button.backgroundColor = .white
            button.setTitleColor(.themePrimary, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.themePrimary.cgColor
        }
    }

    // MARK: - 绑定 / 更换
    private func showBindDialog(type: BindType, prefilledAccount: String = "") {
        let isPhone = type == .phone
        let current = isPhone ? bindPhone : bindEmail
        let isBound = !current.isEmpty

        let alert = UIAlertController(
            title: isPhone ? (isBound ? "更换手机号" : "绑定手机号") : (isBound ? "更换邮箱" : "绑定邮箱"),
            message: isBound ? "当前已绑定，修改将替换原绑定" : nil,
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.placeholder = isPhone ? "请输入手机号" : "请输入邮箱"
            tf.keyboardType = isPhone ? .numberPad : .emailAddress
            tf.text = !prefilledAccount.isEmpty ? prefilledAccount : (isBound ? current : nil)
        }
        alert.addTextField { tf in
            tf.placeholder = "验证码"
            tf.keyboardType = .numberPad
        }

        let getCodeAction = UIAlertAction(title: "获取验证码", style: .default) { [weak self] _ in
            guard let self = self,
                  let account = alert.textFields?[0].text, !account.isEmpty else { return }
            self.sendCode(type: type, account: account)
            self.showBindDialog(type: type, prefilledAccount: account)
        }

        let confirmAction = UIAlertAction(title: "确认绑定", style: .default) { [weak self] _ in
            guard let self = self,
                  let account = alert.textFields?[0].text, !account.isEmpty,
                  let code = alert.textFields?[1].text, code.count == 6 else {
                AppUtility.showToast("请填写完整信息")
                return
            }
            self.bindAccount(type: type, account: account, code: code)
        }

        alert.addAction(getCodeAction)
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func sendCode(type: BindType, account: String) {
        Task {
            do {
                switch type {
                case .phone:
                    _ = try await APIClient.shared.requestRaw(.sendBindPhoneCode(zone: "+86", phone: account))
                case .email:
                    _ = try await APIClient.shared.requestRaw(.sendBindEmailCode(email: account))
                }
                DispatchQueue.main.async { AppUtility.showToast("验证码已发送") }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("发送失败") }
            }
        }
    }

    private func bindAccount(type: BindType, account: String, code: String) {
        Task {
            do {
                var resp: [String: Any]
                switch type {
                case .phone:
                    resp = try await APIClient.shared.requestRaw(.bindPhone(zone: "+86", phone: account, code: code))
                case .email:
                    resp = try await APIClient.shared.requestRaw(.bindEmail(email: account, code: code))
                }
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 {
                        switch type {
                        case .phone:
                            UserDefaults.standard.set(account, forKey: "bind_phone")
                        case .email:
                            UserDefaults.standard.set(account, forKey: "bind_email")
                        }
                        self.refreshUI()
                        AppUtility.showToast("绑定成功")
                    } else {
                        AppUtility.showToast(resp["msg"] as? String ?? "绑定失败")
                    }
                }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("操作失败") }
            }
        }
    }
}

// MARK: - 带内边距的徽章 Label
private final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}
