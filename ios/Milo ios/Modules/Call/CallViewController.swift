//
//  CallViewController.swift
//  Milo
//
//  音视频通话页面
//  精美的液态玻璃风格通话界面，支持语音/视频通话
//

import UIKit
import SnapKit
import Kingfisher

// MARK: - 通话类型
enum CallType {
    case voice
    case video
}

// MARK: - 通话状态
enum CallStatus {
    case calling      // 正在呼叫
    case ringing      // 对方响铃
    case connected    // 通话中
    case ended        // 已结束
    case rejected     // 被拒绝
}

// MARK: - 音视频通话页面
@available(iOS 15.0, *)
class CallViewController: UIViewController {

    // MARK: - 配置属性
    private let callType: CallType
    private var callStatus: CallStatus = .calling
    private let remoteUid: String
    private let remoteName: String
    private let remoteAvatar: String?

    // MARK: - 通话时长
    private var callDuration: Int = 0
    private var durationTimer: Timer?

    // MARK: - 状态标记
    private var isMuted = false
    private var isSpeakerOn = true
    private var isCameraOn = true
    private var isFrontCamera = true

    // MARK: - 背景相关（语音通话）
    private let backgroundImageView = UIImageView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    private let gradientOverlay = UIView()

    // MARK: - 顶部信息区
    private let topContainer = UIView()
    private let backButton = UIButton(type: .custom)
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let durationLabel = UILabel()

    // MARK: - 大头像（语音通话）
    private let avatarContainer = UIView()
    private let largeAvatarView = UIImageView()
    private let avatarPulseLayer = CAShapeLayer()

    // MARK: - 视频通话相关
    private let remoteVideoView = UIView()
    private let localVideoView = UIView()
    private var localVideoOriginalCenter = CGPoint.zero
    private var isDraggingLocalVideo = false

    // MARK: - 底部操作栏
    private let bottomContainer = UIView()
    private let bottomGlassView = LiquidGlassView()
    private var actionButtons: [LiquidGlassButton] = []
    private let hangupButton = UIButton(type: .custom)

    // MARK: - 切换通话类型按钮
    private let switchCallTypeButton = UIButton(type: .custom)

    // MARK: - 初始化
    init(callType: CallType, remoteUid: String, remoteName: String, remoteAvatar: String? = nil) {
        self.callType = callType
        self.remoteUid = remoteUid
        self.remoteName = remoteName
        self.remoteAvatar = remoteAvatar
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
        self.modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopDurationTimer()
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCallTypeUI()
        simulateCallProgress()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - UI 设置
    private func setupUI() {
        view.backgroundColor = .black

        // 背景（语音通话用头像大图+毛玻璃，视频通话用渐变）
        setupBackground()

        // 顶部信息区
        setupTopBar()

        // 底部操作栏
        setupBottomBar()
    }

    private func setupBackground() {
        // 背景图片
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = UIImage(systemName: "person.circle.fill")
        backgroundImageView.tintColor = .systemGray5
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 加载头像作为背景
        if let avatar = remoteAvatar, let url = URL(string: avatar) {
            backgroundImageView.kf.setImage(with: url)
        }

        // 渐变叠加层
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.6).cgColor,
            UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 0.9).cgColor
        ]
        gradientLayer.frame = view.bounds
        gradientOverlay.layer.addSublayer(gradientLayer)
        view.addSubview(gradientOverlay)
        gradientOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 毛玻璃效果
        view.addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupTopBar() {
        view.addSubview(topContainer)
        topContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        // 返回按钮（视频通话显示）
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.isHidden = true
        topContainer.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }

        // 对方名称
        nameLabel.text = remoteName
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        topContainer.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(60)
            make.trailing.lessThanOrEqualToSuperview().offset(-60)
        }

        // 状态文字
        statusLabel.text = AppStrings.Call.calling
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        statusLabel.textAlignment = .center
        topContainer.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }

        // 通话时长
        durationLabel.text = "00:00"
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        durationLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        durationLabel.textAlignment = .center
        durationLabel.isHidden = true
        topContainer.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(statusLabel.snp.bottom).offset(2)
        }
    }

    private func setupBottomBar() {
        view.addSubview(bottomContainer)
        bottomContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.height.equalTo(80)
        }

        // 液态玻璃背景
        bottomGlassView.blurStyle = .systemUltraThinMaterialDark
        bottomGlassView.cornerRadius = 24
        bottomGlassView.glassOpacity = 0.4
        bottomContainer.addSubview(bottomGlassView)
        bottomGlassView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().inset(20)
            make.height.equalToSuperview()
        }
    }

    // MARK: - 根据通话类型设置 UI
    private func setupCallTypeUI() {
        switch callType {
        case .voice:
            setupVoiceCallUI()
        case .video:
            setupVideoCallUI()
        }
    }

    // MARK: - 语音通话界面
    private func setupVoiceCallUI() {
        // 大头像 + 脉冲效果
        setupLargeAvatar()

        // 底部按钮：静音、键盘、免提、添加通话、挂断
        let buttonConfig: [(icon: String, activeIcon: String?, action: Selector, isToggle: Bool)] = [
            ("mic.fill", "mic.slash.fill", #selector(toggleMute), true),
            ("keypad.fill", nil, #selector(showKeypad), false),
            ("speaker.wave.2.fill", "speaker.slash.fill", #selector(toggleSpeaker), true),
            ("person.badge.plus.fill", nil, #selector(addCall), false)
        ]

        let buttonSize: CGFloat = 56
        let spacing: CGFloat = 12

        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        buttonStack.distribution = .equalSpacing
        bottomGlassView.addContent(buttonStack)

        for (index, config) in buttonConfig.enumerated() {
            let btn = LiquidGlassButton(icon: UIImage(systemName: config.icon)!, tintColor: .white)
            btn.cornerRadius = buttonSize / 2
            btn.blurStyle = .systemUltraThinMaterialDark
            btn.tag = index
            btn.addTarget(self, action: config.action, for: .touchUpInside)
            btn.snp.makeConstraints { make in
                make.width.height.equalTo(buttonSize)
            }
            actionButtons.append(btn)
            buttonStack.addArrangedSubview(btn)
        }

        buttonStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        // 挂断按钮（独立的红色大按钮）
        hangupButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        hangupButton.tintColor = .white
        hangupButton.backgroundColor = .systemRed
        hangupButton.layer.cornerRadius = 32
        hangupButton.addTarget(self, action: #selector(hangup), for: .touchUpInside)
        hangupButton.layer.shadowColor = UIColor.systemRed.cgColor
        hangupButton.layer.shadowOpacity = 0.5
        hangupButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        hangupButton.layer.shadowRadius = 12
        view.addSubview(hangupButton)

        hangupButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-32)
            make.centerY.equalTo(bottomContainer)
            make.width.height.equalTo(64)
        }

        // 切换到视频通话按钮
        switchCallTypeButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        switchCallTypeButton.tintColor = .white
        switchCallTypeButton.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        switchCallTypeButton.layer.cornerRadius = 28
        switchCallTypeButton.addTarget(self, action: #selector(switchToVideoCall), for: .touchUpInside)
        switchCallTypeButton.setTitle("视频", for: .normal)
        switchCallTypeButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        switchCallTypeButton.titleEdgeInsets = UIEdgeInsets(top: 24, left: -28, bottom: 0, right: 0)
        switchCallTypeButton.imageEdgeInsets = UIEdgeInsets(top: -8, left: 8, bottom: 12, right: -8)
        view.addSubview(switchCallTypeButton)

        switchCallTypeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(32)
            make.centerY.equalTo(bottomContainer)
            make.width.height.equalTo(56)
        }
    }

    private func setupLargeAvatar() {
        view.addSubview(avatarContainer)
        avatarContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.width.height.equalTo(120)
        }

        // 脉冲光晕
        let pulsePath = UIBezierPath(arcCenter: CGPoint(x: 60, y: 60), radius: 60, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        avatarPulseLayer.path = pulsePath.cgPath
        avatarPulseLayer.fillColor = UIColor.clear.cgColor
        avatarPulseLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
        avatarPulseLayer.lineWidth = 2
        avatarContainer.layer.insertSublayer(avatarPulseLayer, at: 0)

        // 大头像
        largeAvatarView.contentMode = .scaleAspectFill
        largeAvatarView.clipsToBounds = true
        largeAvatarView.layer.cornerRadius = 50
        largeAvatarView.layer.borderWidth = 3
        largeAvatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        largeAvatarView.image = UIImage(systemName: "person.circle.fill")
        largeAvatarView.tintColor = .systemGray4
        largeAvatarView.backgroundColor = UIColor.white.withAlphaComponent(0.1)

        if let avatar = remoteAvatar, let url = URL(string: avatar) {
            largeAvatarView.kf.setImage(with: url)
        }

        avatarContainer.addSubview(largeAvatarView)
        largeAvatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(100)
        }

        // 启动脉冲动画
        startPulseAnimation()
    }

    private func startPulseAnimation() {
        // 脉冲扩散动画
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.3
        pulseAnimation.duration = 1.5
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.6
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 1.5
        opacityAnimation.repeatCount = .infinity
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        avatarPulseLayer.add(pulseAnimation, forKey: "pulseScale")
        avatarPulseLayer.add(opacityAnimation, forKey: "pulseOpacity")
    }

    private func stopPulseAnimation() {
        avatarPulseLayer.removeAllAnimations()
    }

    // MARK: - 视频通话界面
    private func setupVideoCallUI() {
        // 显示返回按钮
        backButton.isHidden = false

        // 调整顶部区域高度（视频通话顶部更紧凑）
        topContainer.snp.remakeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }

        // 远程视频画面（用渐变模拟）
        setupRemoteVideoView()

        // 本地视频小窗口
        setupLocalVideoView()

        // 视频通话底部按钮：静音、翻转摄像头、挂断、切换语音、更多
        let buttonSize: CGFloat = 52

        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        buttonStack.distribution = .equalSpacing
        bottomGlassView.addContent(buttonStack)

        let videoButtons: [(icon: String, action: Selector)] = [
            ("mic.fill", #selector(toggleMute)),
            ("arrow.triangle.2.circlepath.camera.fill", #selector(switchCamera)),
            ("video.slash.fill", #selector(toggleCamera)),
            ("phone.fill.arrow.down.left", #selector(switchToVoiceCall)),
            ("ellipsis", #selector(showMoreOptions))
        ]

        for (index, (icon, action)) in videoButtons.enumerated() {
            let btn = LiquidGlassButton(icon: UIImage(systemName: icon)!, tintColor: .white)
            btn.cornerRadius = buttonSize / 2
            btn.blurStyle = .systemUltraThinMaterialDark
            btn.tag = index
            btn.addTarget(self, action: action, for: .touchUpInside)
            btn.snp.makeConstraints { make in
                make.width.height.equalTo(buttonSize)
            }
            actionButtons.append(btn)
            buttonStack.addArrangedSubview(btn)
        }

        buttonStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        // 挂断按钮（红色大按钮）
        hangupButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        hangupButton.tintColor = .white
        hangupButton.backgroundColor = .systemRed
        hangupButton.layer.cornerRadius = 32
        hangupButton.addTarget(self, action: #selector(hangup), for: .touchUpInside)
        hangupButton.layer.shadowColor = UIColor.systemRed.cgColor
        hangupButton.layer.shadowOpacity = 0.5
        hangupButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        hangupButton.layer.shadowRadius = 12
        bottomGlassView.addContent(hangupButton)

        hangupButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(64)
        }

        // 背景隐藏（视频通话背景是远程画面）
        backgroundImageView.isHidden = true
        blurEffectView.isHidden = true
        gradientOverlay.isHidden = true
    }

    private func setupRemoteVideoView() {
        // 用渐变色模拟远程视频画面
        remoteVideoView.backgroundColor = .clear
        view.insertSubview(remoteVideoView, at: 0)
        remoteVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 添加渐变背景模拟视频
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.12, blue: 0.2, alpha: 1.0).cgColor,
            UIColor(red: 0.2, green: 0.15, blue: 0.3, alpha: 1.0).cgColor
        ]
        gradientLayer.frame = view.bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        remoteVideoView.layer.addSublayer(gradientLayer)

        // 添加一些"噪点"效果模拟视频
        let noiseView = UIView()
        noiseView.backgroundColor = UIColor.white.withAlphaComponent(0.02)
        remoteVideoView.addSubview(noiseView)
        noiseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupLocalVideoView() {
        localVideoView.backgroundColor = UIColor(red: 0.3, green: 0.35, blue: 0.45, alpha: 1.0)
        localVideoView.layer.cornerRadius = 12
        localVideoView.clipsToBounds = true
        localVideoView.layer.borderWidth = 1
        localVideoView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        localVideoView.isUserInteractionEnabled = true

        // 添加摄像头图标占位
        let camIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        camIcon.tintColor = UIColor.white.withAlphaComponent(0.5)
        camIcon.contentMode = .scaleAspectFit
        localVideoView.addSubview(camIcon)
        camIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(30)
        }

        view.addSubview(localVideoView)
        localVideoView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(70)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(100)
            make.height.equalTo(140)
        }

        // 添加拖动手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleLocalVideoPan(_:)))
        localVideoView.addGestureRecognizer(panGesture)

        // 添加点击手势（双击切换摄像头）
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLocalVideoTap(_:)))
        tapGesture.numberOfTapsRequired = 2
        localVideoView.addGestureRecognizer(tapGesture)
    }

    // MARK: - 模拟通话进度
    private func simulateCallProgress() {
        // 2 秒后变为响铃状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.updateCallStatus(.ringing)
        }

        // 5 秒后接通
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            self.updateCallStatus(.connected)
        }
    }

    private func updateCallStatus(_ status: CallStatus) {
        callStatus = status

        switch status {
        case .calling:
            statusLabel.text = AppStrings.Call.calling
            durationLabel.isHidden = true
        case .ringing:
            statusLabel.text = AppStrings.Call.waitingAnswer
            durationLabel.isHidden = true
        case .connected:
            statusLabel.text = AppStrings.Call.inCall
            durationLabel.isHidden = false
            stopPulseAnimation()
            startDurationTimer()

            // 接通动画
            animateConnected()
        case .ended:
            statusLabel.text = AppStrings.Call.callEnded
            stopDurationTimer()
        case .rejected:
            statusLabel.text = AppStrings.Call.rejected
            stopDurationTimer()
        }
    }

    // MARK: - 通话计时器
    private func startDurationTimer() {
        stopDurationTimer()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.callDuration += 1
            self.updateDurationLabel()
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    private func updateDurationLabel() {
        let minutes = callDuration / 60
        let seconds = callDuration % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - 动画效果
    private func animateEntrance() {
        guard AnimationIntegration.shared.config.enablePageTransition else { return }

        // 从底部 spring 弹入
        bottomContainer.transform = CGAffineTransform(translationX: 0, y: 100)
        bottomContainer.alpha = 0

        avatarContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        avatarContainer.alpha = 0

        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.6,
                       options: .curveEaseOut) { [weak self] in
            guard let self = self else { return }
            self.bottomContainer.transform = .identity
            self.bottomContainer.alpha = 1
            self.avatarContainer.transform = .identity
            self.avatarContainer.alpha = 1
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
    }

    private func animateConnected() {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }

        // 头像缩放弹跳
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) { [weak self] in
            guard let self = self else { return }
            self.largeAvatarView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.8,
                           options: .curveEaseOut) { [weak self] in
                self?.largeAvatarView.transform = .identity
            }
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.playHeartbeat()
        }
    }

    private func animateHangup(completion: @escaping () -> Void) {
        guard AnimationIntegration.shared.config.enablePageTransition else {
            completion()
            return
        }

        // 向下滑出 + 淡出
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: .curveEaseIn) { [weak self] in
            guard let self = self else { return }
            self.bottomContainer.transform = CGAffineTransform(translationX: 0, y: 100)
            self.bottomContainer.alpha = 0
            self.avatarContainer.alpha = 0
            self.view.alpha = 0.5
        } completion: { _ in
            completion()
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.playDescend()
        }
    }

    // MARK: - 按钮动作
    @objc private func toggleMute() {
        isMuted.toggle()
        let btn = actionButtons.first
        let iconName = isMuted ? "mic.slash.fill" : "mic.fill"
        btn?.icon = UIImage(systemName: iconName)
        btn?.iconTintColor = isMuted ? .systemRed : .white

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
    }

    @objc private func showKeypad() {
        AppUtility.showToast("键盘功能")
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
    }

    @objc private func toggleSpeaker() {
        isSpeakerOn.toggle()
        let speakerBtnIndex = callType == .voice ? 2 : 2 // 索引可能不同
        if callType == .voice, actionButtons.indices.contains(2) {
            let btn = actionButtons[2]
            let iconName = isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill"
            btn.icon = UIImage(systemName: iconName)
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
    }

    @objc private func addCall() {
        AppUtility.showToast("添加通话")
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
    }

    @objc private func hangup() {
        updateCallStatus(.ended)
        animateHangup { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    @objc private func switchToVideoCall() {
        // 模拟切换到视频通话
        AppUtility.showToast("切换到视频通话")
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }
    }

    @objc private func switchToVoiceCall() {
        AppUtility.showToast("切换到语音通话")
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }
    }

    @objc private func switchCamera() {
        isFrontCamera.toggle()
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
        // 翻转动画
        UIView.transition(with: localVideoView, duration: 0.3, options: .transitionFlipFromLeft, animations: nil)
    }

    @objc private func toggleCamera() {
        isCameraOn.toggle()
        localVideoView.isHidden = !isCameraOn
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
    }

    @objc private func showMoreOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "通话录音", style: .default) { _ in
            AppUtility.showToast("通话录音")
        })
        alert.addAction(UIAlertAction(title: "通话质量", style: .default) { _ in
            AppUtility.showToast("通话质量良好")
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
    }

    @objc private func backTapped() {
        // 视频通话时返回按钮最小化通话
        AppUtility.showToast("最小化通话")
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
    }

    // MARK: - 本地视频窗口拖动
    @objc private func handleLocalVideoPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let location = gesture.location(in: view)

        switch gesture.state {
        case .began:
            isDraggingLocalVideo = true
            localVideoOriginalCenter = localVideoView.center

            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.selectionChanged()
            }

        case .changed:
            guard isDraggingLocalVideo else { return }
            localVideoView.center = CGPoint(
                x: localVideoOriginalCenter.x + translation.x,
                y: localVideoOriginalCenter.y + translation.y
            )

        case .ended, .cancelled:
            isDraggingLocalVideo = false
            // 弹性吸附到边缘
            snapLocalVideoToEdge(location: location)

        default:
            break
        }
    }

    private func snapLocalVideoToEdge(location: CGPoint) {
        let viewWidth = view.bounds.width
        let viewHeight = view.bounds.height
        let videoWidth: CGFloat = 100
        let videoHeight: CGFloat = 140
        let padding: CGFloat = 16
        let topInset = view.safeAreaInsets.top + 70
        let bottomInset = view.safeAreaInsets.bottom + 100

        // 判断吸附到左边还是右边
        let targetX: CGFloat
        if location.x < viewWidth / 2 {
            targetX = padding + videoWidth / 2
        } else {
            targetX = viewWidth - padding - videoWidth / 2
        }

        // 限制垂直范围
        var targetY = location.y
        targetY = max(topInset + videoHeight / 2, targetY)
        targetY = min(viewHeight - bottomInset - videoHeight / 2, targetY)

        // 弹性动画吸附
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) { [weak self] in
            guard let self = self else { return }
            self.localVideoView.center = CGPoint(x: targetX, y: targetY)
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
    }

    @objc private func handleLocalVideoTap(_ gesture: UITapGestureRecognizer) {
        switchCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 更新渐变层 frame
        if let gradientLayer = gradientOverlay.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
        if let gradientLayer = remoteVideoView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
}
