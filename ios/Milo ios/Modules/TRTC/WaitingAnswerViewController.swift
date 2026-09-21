import UIKit
import SnapKit
import TXLiteAVSDK_TRTC

class WaitingAnswerViewController: UIViewController {

    private let channelId: String
    private let callerName: String
    private var onAccept: (() -> Void)?
    private var onReject: (() -> Void)?

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let acceptButton = UIButton(type: .system)
    private let rejectButton = UIButton(type: .system)
    private var ringTimer: Timer?

    init(channelId: String, callerName: String, onAccept: @escaping () -> Void, onReject: @escaping () -> Void) {
        self.channelId = channelId
        self.callerName = callerName
        self.onAccept = onAccept
        self.onReject = onReject
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startRinging()
    }

    deinit {
        ringTimer?.invalidate()
    }

    private func setupUI() {
        // 毛玻璃 + 蓝色主题背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0).cgColor,
            UIColor(red: 0.05, green: 0.1, blue: 0.25, alpha: 1.0).cgColor
        ]
        gradientLayer.frame = view.bounds
        view.layer.addSublayer(gradientLayer)

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        view.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let avatarSize = ScreenAdapter.scaleW(100)
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray
        avatarView.backgroundColor = .systemGray5

        nameLabel.text = callerName
        nameLabel.font = ScreenAdapter.mediumFont(24)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center

        statusLabel.text = "邀请你语音通话..."
        statusLabel.font = ScreenAdapter.font(15)
        statusLabel.textColor = .systemGray4
        statusLabel.textAlignment = .center

        let btnSize = ScreenAdapter.scaleW(68)
        acceptButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        acceptButton.tintColor = .white
        acceptButton.backgroundColor = .systemGreen
        acceptButton.layer.cornerRadius = btnSize / 2
        acceptButton.addTarget(self, action: #selector(accept), for: .touchUpInside)

        rejectButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        rejectButton.tintColor = .white
        rejectButton.backgroundColor = .systemRed
        rejectButton.layer.cornerRadius = btnSize / 2
        rejectButton.addTarget(self, action: #selector(reject), for: .touchUpInside)

        let btnStack = UIStackView(arrangedSubviews: [rejectButton, acceptButton])
        btnStack.axis = .horizontal
        btnStack.spacing = ScreenAdapter.scaleW(80)
        btnStack.distribution = .fillEqually

        let rejectLabel = UILabel()
        rejectLabel.text = "拒绝"
        rejectLabel.font = ScreenAdapter.font(13)
        rejectLabel.textColor = .systemGray4
        rejectLabel.textAlignment = .center

        let acceptLabel = UILabel()
        acceptLabel.text = "接听"
        acceptLabel.font = ScreenAdapter.font(13)
        acceptLabel.textColor = .systemGray4
        acceptLabel.textAlignment = .center

        let labelStack = UIStackView(arrangedSubviews: [rejectLabel, acceptLabel])
        labelStack.axis = .horizontal
        labelStack.spacing = ScreenAdapter.scaleW(80)
        labelStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [avatarView, nameLabel, statusLabel, btnStack, labelStack])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = ScreenAdapter.scaleH(16)

        blurView.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(ScreenAdapter.scaleH(-40))
        }

        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(avatarSize)
        }

        rejectButton.snp.makeConstraints { make in
            make.width.height.equalTo(btnSize)
        }
    }

    private func startRinging() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        ringTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    @objc private func accept() {
        ringTimer?.invalidate()
        dismiss(animated: true) {
            self.onAccept?()
        }
    }

    @objc private func reject() {
        ringTimer?.invalidate()
        dismiss(animated: true) {
            self.onReject?()
        }
    }
}
