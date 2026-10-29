import UIKit
import SnapKit

// MARK: - 注销账号（对照 Android 注销账号页）
class DestroyAccountViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var bindPhone: String { UserDefaults.standard.string(forKey: "bind_phone") ?? "" }
    private var bindEmail: String { UserDefaults.standard.string(forKey: "bind_email") ?? "" }
    private var verifyType: String { bindPhone.isEmpty ? "email" : "phone" }
    private var boundAccount: String { verifyType == "phone" ? bindPhone : bindEmail }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "注销账号"
        view.backgroundColor = .themeBackground
        setupUI()
    }

    // MARK: - 布局
    private func setupUI() {
        // 底部固定按钮
        let continueButton = UIButton(type: .system)
        continueButton.setTitle("继续注销", for: .normal)
        continueButton.titleLabel?.font = ScreenAdapter.font(16)
        continueButton.setTitleColor(.systemRed, for: .normal)
        continueButton.backgroundColor = .white
        continueButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        continueButton.layer.borderWidth = 1
        continueButton.layer.borderColor = UIColor.systemRed.cgColor
        continueButton.addTarget(self, action: #selector(continueDestroy), for: .touchUpInside)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("再想想", for: .normal)
        cancelButton.titleLabel?.font = ScreenAdapter.font(16)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = .themePrimary
        cancelButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        cancelButton.addTarget(self, action: #selector(cancelDestroy), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [continueButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        view.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.height.equalTo(ScreenAdapter.scaleH(46))
        }

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(buttonStack.snp.top).offset(-12)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // 顶部红色警示横幅
        let banner = makeWarningBanner()
        contentView.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        let readLabel = UILabel()
        readLabel.text = "请在继续前仔细阅读"
        readLabel.font = ScreenAdapter.font(13)
        readLabel.textColor = .secondaryLabel
        contentView.addSubview(readLabel)
        readLabel.snp.makeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        let introLabel = UILabel()
        introLabel.text = "账号注销是不可恢复的操作，请您仔细考虑，谨慎操作，操作前务必审慎阅读、充分理解以下内容。"
        introLabel.font = ScreenAdapter.font(13)
        introLabel.textColor = .secondaryLabel
        introLabel.numberOfLines = 0
        contentView.addSubview(introLabel)
        introLabel.snp.makeConstraints { make in
            make.top.equalTo(readLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(readLabel)
        }

        // 注销须知
        let noticeCard = makeInfoCard(
            title: "注销须知",
            items: [
                ("账号处于安全状态", "您的账号未被他人盗取，账号不存在被封禁等风险"),
                ("全部财产均已结清", "账号内不存在已充值的相关财产"),
                ("绑定目前可用的手机号或安全邮箱", "用于确认当前账号的身份归属情况")
            ],
            numberColor: .systemRed
        )
        contentView.addSubview(noticeCard)
        noticeCard.snp.makeConstraints { make in
            make.top.equalTo(introLabel.snp.bottom).offset(12)
            make.leading.trailing.equalTo(banner)
        }

        // 特别说明
        let specialCard = makeInfoCard(
            title: "特别说明",
            items: [
                ("账号注销申请时即放弃该账号在Milo软件所有涉及相关数据，包括但不限于该账号的资产、权益、记录等一切内容，将视为您自愿放弃", nil),
                ("账号成功注销后，您将无法登录", nil),
                ("已成功注销的账号无法进行找回", nil)
            ],
            numberColor: UIColor(white: 0.6, alpha: 1.0)
        )
        contentView.addSubview(specialCard)
        specialCard.snp.makeConstraints { make in
            make.top.equalTo(noticeCard.snp.bottom).offset(12)
            make.leading.trailing.equalTo(banner)
        }

        // 协议提示
        let agreementLabel = UILabel()
        agreementLabel.numberOfLines = 0
        let attr = NSMutableAttributedString(
            string: "轻按下方'注销账号'按钮，即表示您已阅读并同意 ",
            attributes: [
                .font: ScreenAdapter.font(12),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        attr.append(NSAttributedString(
            string: "用户协议",
            attributes: [
                .font: ScreenAdapter.font(12),
                .foregroundColor: UIColor.themePrimary
            ]
        ))
        agreementLabel.attributedText = attr
        contentView.addSubview(agreementLabel)
        agreementLabel.snp.makeConstraints { make in
            make.top.equalTo(specialCard.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    // MARK: - UI 构建
    private func makeWarningBanner() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0)
        card.layer.cornerRadius = 16

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 24
        iconBg.clipsToBounds = true
        card.addSubview(iconBg)
        iconBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        let iconView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        iconView.tintColor = .systemRed
        iconView.contentMode = .scaleAspectFit
        iconBg.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }

        let titleLabel = UILabel()
        titleLabel.text = "此操作不可恢复"
        titleLabel.font = ScreenAdapter.boldFont(16)
        titleLabel.textColor = .systemRed
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBg.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-20)
        }

        let accountText: String
        if verifyType == "phone" {
            let p = boundAccount
            accountText = p.count >= 7 ? "手机：\(p.prefix(3))****\(p.suffix(4))" : "手机：\(p)"
        } else {
            accountText = "邮箱：\(boundAccount)"
        }
        let accountLabel = UILabel()
        accountLabel.text = accountText
        accountLabel.font = ScreenAdapter.font(13)
        accountLabel.textColor = .systemRed
        card.addSubview(accountLabel)
        accountLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-26)
        }

        return card
    }

    private func makeInfoCard(title: String, items: [(String, String?)], numberColor: UIColor) -> UIView {
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
            make.trailing.equalToSuperview().offset(-16)
        }

        var previous: UIView = titleLabel
        for (index, item) in items.enumerated() {
            let row = makeNumberedRow(number: index + 1, title: item.0, desc: item.1, numberColor: numberColor)
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.top.equalTo(previous.snp.bottom).offset(previous == titleLabel ? 12 : 14)
                make.leading.trailing.equalToSuperview()
            }
            previous = row
        }
        previous.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
        }

        return card
    }

    private func makeNumberedRow(number: Int, title: String, desc: String?, numberColor: UIColor) -> UIView {
        let row = UIView()

        let circle = UILabel()
        circle.text = "\(number)"
        circle.font = ScreenAdapter.boldFont(12)
        circle.textColor = .white
        circle.textAlignment = .center
        circle.backgroundColor = numberColor
        circle.layer.cornerRadius = 10
        circle.clipsToBounds = true
        row.addSubview(circle)
        circle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(1)
            make.width.height.equalTo(20)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ScreenAdapter.font(15)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(circle.snp.trailing).offset(10)
            make.top.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }

        if let desc = desc {
            let descLabel = UILabel()
            descLabel.text = desc
            descLabel.font = ScreenAdapter.font(13)
            descLabel.textColor = .secondaryLabel
            descLabel.numberOfLines = 0
            row.addSubview(descLabel)
            descLabel.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel)
                make.top.equalTo(titleLabel.snp.bottom).offset(3)
                make.trailing.equalTo(titleLabel)
                make.bottom.equalToSuperview()
            }
        } else {
            titleLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }

        return row
    }

    // MARK: - 操作
    @objc private func continueDestroy() {
        navigationController?.pushViewController(InputDestroyCodeViewController(
            account: boundAccount,
            verifyType: verifyType
        ), animated: true)
    }

    @objc private func cancelDestroy() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - 注销验证码（最后一步身份验证）
class InputDestroyCodeViewController: UIViewController {

    private let account: String
    private let verifyType: String
    private let codeField = UITextField()
    private let getCodeButton = UIButton(type: .system)
    private let submitButton = UIButton(type: .system)
    private var countdown = 0
    private var countdownTimer: Timer?

    init(account: String, verifyType: String) {
        self.account = account
        self.verifyType = verifyType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "验证账号身份"
        view.backgroundColor = .themeBackground
        setupUI()
        sendCode()
    }

    private func setupUI() {
        // 红色浅底横幅
        let banner = UIView()
        banner.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0)
        banner.layer.cornerRadius = 16
        view.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        let bannerTitle = UILabel()
        bannerTitle.text = "最后一步身份验证"
        bannerTitle.font = ScreenAdapter.boldFont(16)
        bannerTitle.textColor = .systemRed
        banner.addSubview(bannerTitle)
        bannerTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        let bannerDesc1 = UILabel()
        bannerDesc1.text = "验证码将发送至当前绑定的手机号或邮箱"
        bannerDesc1.font = ScreenAdapter.font(13)
        bannerDesc1.textColor = .systemRed
        banner.addSubview(bannerDesc1)
        bannerDesc1.snp.makeConstraints { make in
            make.leading.trailing.equalTo(bannerTitle)
            make.top.equalTo(bannerTitle.snp.bottom).offset(4)
        }

        let sentText: String
        if verifyType == "phone", account.count >= 7 {
            sentText = "验证码已发送至 \(account.prefix(3))****\(account.suffix(4))"
        } else {
            sentText = "验证码已发送至 \(account)"
        }
        let bannerDesc2 = UILabel()
        bannerDesc2.text = sentText
        bannerDesc2.font = ScreenAdapter.font(13)
        bannerDesc2.textColor = .systemRed
        banner.addSubview(bannerDesc2)
        bannerDesc2.snp.makeConstraints { make in
            make.leading.trailing.equalTo(bannerTitle)
            make.top.equalTo(bannerDesc1.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-16)
        }

        // 输入验证码
        let codeTitle = UILabel()
        codeTitle.text = "输入验证码"
        codeTitle.font = ScreenAdapter.boldFont(16)
        codeTitle.textColor = .label
        view.addSubview(codeTitle)
        codeTitle.snp.makeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
        }

        codeField.placeholder = "请输入6位验证码"
        codeField.keyboardType = .numberPad
        codeField.font = ScreenAdapter.font(16)
        codeField.backgroundColor = .white
        codeField.layer.cornerRadius = 10
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        codeField.leftView = padding
        codeField.leftViewMode = .always
        view.addSubview(codeField)

        getCodeButton.setTitle("59s后重新获取", for: .normal)
        getCodeButton.titleLabel?.font = ScreenAdapter.font(13)
        getCodeButton.setTitleColor(.secondaryLabel, for: .normal)
        getCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)
        view.addSubview(getCodeButton)

        codeField.snp.makeConstraints { make in
            make.top.equalTo(codeTitle.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(getCodeButton.snp.leading).offset(-12)
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
        getCodeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(codeField)
            make.width.equalTo(ScreenAdapter.scaleW(100))
        }

        let tipLabel = UILabel()
        tipLabel.text = "验证通过后账号将被注销，此操作无法撤销"
        tipLabel.font = ScreenAdapter.font(13)
        tipLabel.textColor = .secondaryLabel
        tipLabel.numberOfLines = 0
        view.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(codeField.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        submitButton.setTitle("确认注销账号", for: .normal)
        submitButton.titleLabel?.font = ScreenAdapter.boldFont(17)
        submitButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.6)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        view.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
    }

    private func sendCode() {
        Task {
            do {
                var resp: [String: Any]
                if verifyType == "phone" {
                    resp = try await APIClient.shared.requestRaw(.sendDestroyPhoneCode(zone: "0086", phone: account))
                } else {
                    resp = try await APIClient.shared.requestRaw(.sendDestroyEmailCode(email: account))
                }
                DispatchQueue.main.async {
                    if AppUtility.handleSMSCodeEcho(resp, onCode: { [weak self] c in self?.codeField.text = c }) { return }
                    self.startCountdown()
                }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("发送失败，请稍后重试") }
            }
        }
    }

    @objc private func getCode() { sendCode() }

    private func startCountdown() {
        countdown = 60
        getCodeButton.isEnabled = false
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 {
                t.invalidate()
                self.getCodeButton.setTitle("重新获取", for: .normal)
                self.getCodeButton.isEnabled = true
            } else {
                self.getCodeButton.setTitle("\(self.countdown)s后重新获取", for: .normal)
            }
        }
    }

    @objc private func submit() {
        guard let code = codeField.text, code.count == 6 else {
            AppUtility.showToast("请输入6位验证码"); return
        }

        submitButton.isEnabled = false
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.destroyAccount(
                    account: self.account,
                    code: code,
                    type: self.verifyType,
                    zone: self.verifyType == "phone" ? "0086" : ""
                ))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    if status == 200 {
                        AppUtility.showToast("账号已注销")
                        IMManager.shared.disconnect()
                        LocalStore.shared.clearAll()
                        let loginVC = EntryLoginViewController()
                        self.view.window?.rootViewController = BaseNavigationController(rootViewController: loginVC)
                    } else {
                        AppUtility.showToast(resp["msg"] as? String ?? "注销失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }
}
