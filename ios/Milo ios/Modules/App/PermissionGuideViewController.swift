import UIKit
import SnapKit

class PermissionGuideViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let continueButton = UIButton(type: .system)

    private let permissions: [(icon: String, title: String, desc: String)] = [
        ("camera.fill", "相机权限", "用于拍照、扫描二维码"),
        ("mic.fill", "麦克风权限", "用于语音消息、语音通话"),
        ("photo.onrectangle", "相册权限", "用于发送图片、视频、文件"),
        ("location.fill", "位置权限", "用于发送位置信息"),
        ("bell.fill", "通知权限", "用于接收消息推送通知"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "权限说明"
        view.backgroundColor = .themeBackground
        setupUI()
    }

    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PermCell")
        tableView.isScrollEnabled = false

        continueButton.setTitle("同意并继续", for: .normal)
        continueButton.titleLabel?.font = ScreenAdapter.font(17)
        continueButton.backgroundColor = .themePrimary
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)

        view.addSubview(tableView)
        view.addSubview(continueButton)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(16))
            make.leading.trailing.equalToSuperview()
        }
        continueButton.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.height.equalTo(ScreenAdapter.scaleH(48))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(24))
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return permissions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PermCell", for: indexPath)
        let perm = permissions[indexPath.row]
        cell.imageView?.image = UIImage(systemName: perm.icon)
        cell.imageView?.tintColor = .themePrimary
        cell.textLabel?.text = perm.title
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.detailTextLabel?.text = perm.desc
        cell.detailTextLabel?.font = ScreenAdapter.font(12)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.selectionStyle = .none
        return cell
    }

    @objc private func continueAction() {
        UserDefaults.standard.set(true, forKey: "privacy_agreed")
        let mainVC = MainTabBarController()
        view.window?.rootViewController = mainVC
    }
}

class PrivacyAgreementDialogView: UIView {

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let agreeButton = UIButton(type: .system)
    private let disagreeButton = UIButton(type: .system)
    private var onAgree: (() -> Void)?
    private var onDisagree: (() -> Void)?

    init(onAgree: @escaping () -> Void, onDisagree: @escaping () -> Void) {
        self.onAgree = onAgree
        self.onDisagree = onDisagree
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)

        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = ScreenAdapter.scaleW(16)

        titleLabel.text = "用户协议与隐私政策"
        titleLabel.font = ScreenAdapter.boldFont(18)
        titleLabel.textAlignment = .center

        contentLabel.text = "欢迎使用闲雷虎虎！我们重视您的隐私。\n\n在您使用我们的服务前，请仔细阅读《用户协议》和《隐私政策》。\n\n我们将严格保护您的个人信息，仅在必要范围内使用。点击\"同意\"即表示您已阅读并同意上述协议。"
        contentLabel.font = ScreenAdapter.font(14)
        contentLabel.numberOfLines = 0
        contentLabel.textColor = .secondaryLabel

        agreeButton.setTitle("同意", for: .normal)
        agreeButton.titleLabel?.font = ScreenAdapter.font(16)
        agreeButton.backgroundColor = .themePrimary
        agreeButton.setTitleColor(.white, for: .normal)
        agreeButton.layer.cornerRadius = ScreenAdapter.scaleW(8)
        agreeButton.addTarget(self, action: #selector(agree), for: .touchUpInside)

        disagreeButton.setTitle("不同意", for: .normal)
        disagreeButton.titleLabel?.font = ScreenAdapter.font(16)
        disagreeButton.setTitleColor(.secondaryLabel, for: .normal)
        disagreeButton.addTarget(self, action: #selector(disagree), for: .touchUpInside)

        containerView.addSubview(titleLabel)
        containerView.addSubview(contentLabel)
        containerView.addSubview(agreeButton)
        containerView.addSubview(disagreeButton)

        addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(40))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(40))
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.leading.trailing.equalToSuperview().inset(ScreenAdapter.scaleW(16))
        }
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.leading.trailing.equalToSuperview().inset(ScreenAdapter.scaleW(16))
        }
        agreeButton.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.width.equalTo(ScreenAdapter.scaleW(120))
            make.height.equalTo(ScreenAdapter.scaleH(40))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(24))
        }
        disagreeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalTo(agreeButton)
            make.width.equalTo(ScreenAdapter.scaleW(120))
            make.height.equalTo(ScreenAdapter.scaleH(40))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(24))
        }
    }

    @objc private func agree() {
        removeFromSuperview()
        onAgree?()
    }

    @objc private func disagree() {
        removeFromSuperview()
        onDisagree?()
    }

    func show(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}
