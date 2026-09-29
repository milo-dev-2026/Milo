//
//  LoginExtraViewControllers.swift
//  Milo
//
//  登录模块补充页面
//  包含：第三方登录、PC端扫码登录
//

import UIKit
import SnapKit
import CoreImage

// MARK: - 第三方登录
class ThirdLoginViewController: UIViewController {

    // MARK: - UI
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let wechatButton = UIButton(type: .system)
    private let qqButton = UIButton(type: .system)
    private let weiboButton = UIButton(type: .system)

    private let separatorView = UIView()
    private let separatorLabel = UILabel()
    private let phoneLoginButton = UIButton(type: .system)

    private let agreementLabel = UILabel()

    // MARK: - 回调
    var onLoginSuccess: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .themeBgWhite

        // Logo
        logoImageView.image = UIImage(named: "LoginLogo") ?? UIImage(systemName: "message.circle.fill")
        logoImageView.tintColor = .themeColorPrimary
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }

        titleLabel.text = "欢迎使用 Milo"
        titleLabel.font = ThemeFont.title1(24)
        titleLabel.textColor = .themeTextPrimary
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        subtitleLabel.text = "选择以下方式快速登录"
        subtitleLabel.font = ThemeFont.bodySmall(14)
        subtitleLabel.textColor = .themeTextSecondary
        subtitleLabel.textAlignment = .center
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        // 第三方登录按钮容器
        let loginStack = UIStackView()
        loginStack.axis = .horizontal
        loginStack.spacing = 40
        loginStack.distribution = .fillEqually
        loginStack.alignment = .center
        view.addSubview(loginStack)
        loginStack.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
        }

        // 微信登录
        configureThirdPartyButton(wechatButton, icon: "message.circle.fill", title: "微信", color: UIColor(red: 0.08, green: 0.78, blue: 0.36, alpha: 1.0))
        wechatButton.addTarget(self, action: #selector(wechatLoginTapped), for: .touchUpInside)
        loginStack.addArrangedSubview(wechatButton)

        // QQ 登录
        configureThirdPartyButton(qqButton, icon: "message.bubble.fill", title: "QQ", color: UIColor(red: 0.08, green: 0.56, blue: 0.94, alpha: 1.0))
        qqButton.addTarget(self, action: #selector(qqLoginTapped), for: .touchUpInside)
        loginStack.addArrangedSubview(qqButton)

        // 微博登录
        configureThirdPartyButton(weiboButton, icon: "eye.circle.fill", title: "微博", color: UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1.0))
        weiboButton.addTarget(self, action: #selector(weiboLoginTapped), for: .touchUpInside)
        loginStack.addArrangedSubview(weiboButton)

        // 分隔线
        view.addSubview(separatorView)
        separatorView.backgroundColor = .themeSeparatorLight
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(loginStack.snp.bottom).offset(50)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.height.equalTo(0.5)
        }

        separatorLabel.text = "或"
        separatorLabel.font = ThemeFont.caption(13)
        separatorLabel.textColor = .themeTextTertiary
        separatorLabel.textAlignment = .center
        separatorLabel.backgroundColor = .themeBgWhite
        view.addSubview(separatorLabel)
        separatorLabel.snp.makeConstraints { make in
            make.center.equalTo(separatorView)
            make.width.equalTo(40)
        }

        // 手机号登录
        phoneLoginButton.setTitle("手机号登录", for: .normal)
        phoneLoginButton.titleLabel?.font = ThemeFont.buttonLarge(16)
        phoneLoginButton.setTitleColor(.themeColorPrimary, for: .normal)
        phoneLoginButton.backgroundColor = .themeColorPrimary.withAlphaComponent(0.1)
        phoneLoginButton.layer.cornerRadius = 10
        phoneLoginButton.addTarget(self, action: #selector(phoneLoginTapped), for: .touchUpInside)
        view.addSubview(phoneLoginButton)
        phoneLoginButton.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(48)
        }

        // 用户协议
        agreementLabel.text = "登录即表示您同意《用户协议》和《隐私政策》"
        agreementLabel.font = ThemeFont.tiny(12)
        agreementLabel.textColor = .themeTextHint
        agreementLabel.textAlignment = .center
        agreementLabel.numberOfLines = 0
        view.addSubview(agreementLabel)
        agreementLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
        }
    }

    private func configureThirdPartyButton(_ button: UIButton, icon: String, title: String, color: UIColor) {
        let containerView = UIView()
        button.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let iconImageView = UIImageView(image: UIImage(systemName: icon))
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(48)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ThemeFont.caption(12)
        titleLabel.textColor = .themeTextSecondary
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - 登录动作
    @objc private func wechatLoginTapped() {
        AppUtility.showToast("微信登录")
        // TODO: 调用微信 SDK 登录
    }

    @objc private func qqLoginTapped() {
        AppUtility.showToast("QQ 登录")
        // TODO: 调用 QQ SDK 登录
    }

    @objc private func weiboLoginTapped() {
        AppUtility.showToast("微博登录")
        // TODO: 调用微博 SDK 登录
    }

    @objc private func phoneLoginTapped() {
        let loginVC = LoginViewController(account: "", isEmail: false)
        navigationController?.pushViewController(loginVC, animated: true)
    }
}

// MARK: - PC 端扫码登录
class PCLoginViewController: UIViewController {

    // MARK: - 状态
    enum LoginStatus {
        case waiting        // 等待扫码
        case scanned        // 已扫码，等待确认
        case confirmed      // 已确认登录
        case expired        // 二维码已过期
    }

    private var status: LoginStatus = .waiting

    // MARK: - UI
    private let qrImageView = UIImageView()
    private let statusLabel = UILabel()
    private let descLabel = UILabel()
    private let refreshButton = UIButton(type: .system)

    private var qrTimer: Timer?
    private var qrExpireTime: TimeInterval = 60 // 60秒过期

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateQRCode()
        startQRTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        qrTimer?.invalidate()
        qrTimer = nil
    }

    private func setupUI() {
        title = "PC 端扫码登录"
        view.backgroundColor = .themeBg

        let cardView = UIView()
        cardView.backgroundColor = .themeBgCard
        cardView.layer.cornerRadius = 16
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(280)
            make.height.equalTo(380)
        }

        // 二维码
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.backgroundColor = .white
        qrImageView.layer.cornerRadius = 8
        qrImageView.clipsToBounds = true
        cardView.addSubview(qrImageView)
        qrImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(200)
        }

        // 状态标签
        statusLabel.font = ThemeFont.title3(16)
        statusLabel.textColor = .themeTextPrimary
        statusLabel.textAlignment = .center
        cardView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(qrImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        // 描述标签
        descLabel.font = ThemeFont.bodySmall(13)
        descLabel.textColor = .themeTextSecondary
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        cardView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        // 刷新按钮
        refreshButton.setTitle("刷新二维码", for: .normal)
        refreshButton.titleLabel?.font = ThemeFont.bodySmall(14)
        refreshButton.setTitleColor(.themeColorPrimary, for: .normal)
        refreshButton.isHidden = true
        refreshButton.addTarget(self, action: #selector(refreshQRCode), for: .touchUpInside)
        cardView.addSubview(refreshButton)
        refreshButton.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        updateStatus(.waiting)
    }

    // MARK: - 生成二维码
    private func generateQRCode() {
        // 生成随机 token
        let token = UUID().uuidString
        let qrString = "milo_pc_login:\(token)"

        guard let data = qrString.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return }

        qrImageView.image = UIImage(cgImage: cgImage)
    }

    // MARK: - 状态更新
    private func updateStatus(_ newStatus: LoginStatus) {
        status = newStatus

        switch newStatus {
        case .waiting:
            statusLabel.text = "请使用 Milo 手机端扫码登录"
            descLabel.text = "打开 Milo APP → 扫一扫 → 扫描二维码"
            refreshButton.isHidden = true
            qrImageView.alpha = 1.0

        case .scanned:
            statusLabel.text = "扫码成功"
            descLabel.text = "请在手机上确认登录"
            refreshButton.isHidden = true
            qrImageView.alpha = 1.0

        case .confirmed:
            statusLabel.text = "登录成功"
            descLabel.text = "您已成功登录 PC 端"
            refreshButton.isHidden = true
            qrImageView.alpha = 1.0

        case .expired:
            statusLabel.text = "二维码已过期"
            descLabel.text = "二维码已失效，请点击下方按钮刷新"
            refreshButton.isHidden = false
            qrImageView.alpha = 0.3
        }
    }

    // MARK: - 二维码过期计时器
    private func startQRTimer() {
        qrTimer?.invalidate()
        qrTimer = Timer.scheduledTimer(withTimeInterval: qrExpireTime, repeats: false) { [weak self] _ in
            self?.updateStatus(.expired)
        }
    }

    @objc private func refreshQRCode() {
        generateQRCode()
        updateStatus(.waiting)
        startQRTimer()
    }

    // MARK: - 模拟扫码（测试用）
    func simulateScan() {
        updateStatus(.scanned)

        // 2秒后模拟确认
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.updateStatus(.confirmed)
        }
    }
}

// MARK: - 扫码登录结果页（手机端）
class ScanLoginConfirmViewController: UIViewController {

    private let avatarView = AvatarView()
    private let nameLabel = UILabel()
    private let deviceLabel = UILabel()
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "PC 端登录确认"
        view.backgroundColor = .themeBg

        // 卡片
        let cardView = UIView()
        cardView.backgroundColor = .themeBgCard
        cardView.layer.cornerRadius = 16
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }

        // 提示
        let tipLabel = UILabel()
        tipLabel.text = "检测到 PC 端登录请求"
        tipLabel.font = ThemeFont.title2(18)
        tipLabel.textColor = .themeTextPrimary
        tipLabel.textAlignment = .center
        cardView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }

        // 头像
        cardView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.equalTo(tipLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(64)
        }

        if let avatarPath = LocalStore.shared.avatar, let url = URL(string: avatarPath) {
            avatarView.setAvatar(url: url)
        }

        // 用户名
        nameLabel.text = LocalStore.shared.name ?? "用户"
        nameLabel.font = ThemeFont.title2(18)
        nameLabel.textColor = .themeTextPrimary
        nameLabel.textAlignment = .center
        cardView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        // 设备信息
        deviceLabel.text = "设备：Windows PC\n位置：北京市"
        deviceLabel.font = ThemeFont.bodySmall(14)
        deviceLabel.textColor = .themeTextSecondary
        deviceLabel.textAlignment = .center
        deviceLabel.numberOfLines = 0
        cardView.addSubview(deviceLabel)
        deviceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        // 确认按钮
        confirmButton.setTitle("确认登录", for: .normal)
        confirmButton.titleLabel?.font = ThemeFont.buttonLarge(16)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.backgroundColor = .themeColorPrimary
        confirmButton.layer.cornerRadius = 10
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        cardView.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(deviceLabel.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(48)
        }

        // 取消按钮
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = ThemeFont.button(15)
        cancelButton.setTitleColor(.themeTextSecondary, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cardView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(confirmButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    @objc private func confirmTapped() {
        onConfirm?()
        AppUtility.showToast("已确认登录")
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        onCancel?()
        dismiss(animated: true)
    }
}
