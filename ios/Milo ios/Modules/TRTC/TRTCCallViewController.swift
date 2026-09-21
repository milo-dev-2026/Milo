import UIKit
import SnapKit
import TXLiteAVSDK_TRTC

// MARK: - TRTC语音通话页
class TRTCCallViewController: UIViewController {

    private let channelId: String
    private var trtcCloud: TRTCCloud?
    private var remoteUserID: String?

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let durationLabel = UILabel()
    private let hangupButton = UIButton(type: .system)
    private let muteButton = UIButton(type: .system)
    private let speakerButton = UIButton(type: .system)

    private var isMuted = false
    private var isSpeakerOn = true
    private var callDurationTimer: Timer?
    private var callDuration: Int = 0

    init(channelId: String) {
        self.channelId = channelId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        Task { await setupTRTC() }
    }

    deinit {
        stopCallDurationTimer()
        trtcCloud?.stopLocalAudio()
        trtcCloud?.exitRoom()
        TRTCCloud.destroySharedInstance()
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

        let buttonSize = ScreenAdapter.scaleW(64)
        let buttonGap = ScreenAdapter.scaleW(48)
        let bottomOffset = ScreenAdapter.safeAreaBottom + ScreenAdapter.scaleH(50)

        // 头像/语音图标
        let avatarSize = ScreenAdapter.scaleW(120)
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "phone.fill")
        avatarView.tintColor = .white
        avatarView.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.8)
        avatarView.layer.borderWidth = 3
        avatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

        // 名称标签
        nameLabel.text = "语音通话"
        nameLabel.font = ScreenAdapter.mediumFont(22)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center

        // 状态标签
        statusLabel.text = "连接中..."
        statusLabel.font = ScreenAdapter.font(15)
        statusLabel.textColor = .systemGray4
        statusLabel.textAlignment = .center

        // 通话时长
        durationLabel.text = "00:00"
        durationLabel.font = ScreenAdapter.font(16)
        durationLabel.textColor = .systemGray4
        durationLabel.textAlignment = .center
        durationLabel.isHidden = true

        // 挂断按钮
        hangupButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        hangupButton.tintColor = .white
        hangupButton.backgroundColor = .systemRed
        hangupButton.layer.cornerRadius = buttonSize / 2

        // 静音按钮
        muteButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        muteButton.tintColor = .white
        muteButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        muteButton.layer.cornerRadius = buttonSize / 2

        // 免提按钮
        speakerButton.setImage(UIImage(systemName: "speaker.wave.3.fill"), for: .normal)
        speakerButton.tintColor = .white
        speakerButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        speakerButton.layer.cornerRadius = buttonSize / 2

        hangupButton.addTarget(self, action: #selector(hangup), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        speakerButton.addTarget(self, action: #selector(toggleSpeaker), for: .touchUpInside)

        blurView.contentView.addSubviews(avatarView, nameLabel, statusLabel, durationLabel,
                                         muteButton, hangupButton, speakerButton)

        avatarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(ScreenAdapter.safeAreaTop + ScreenAdapter.scaleH(80))
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(avatarView.snp.bottom).offset(ScreenAdapter.scaleH(24))
            make.leading.trailing.equalToSuperview().inset(ScreenAdapter.scaleW(20))
        }

        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
        }

        durationLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(statusLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
        }

        hangupButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomOffset)
            make.width.height.equalTo(buttonSize)
        }

        muteButton.snp.makeConstraints { make in
            make.trailing.equalTo(hangupButton.snp.leading).offset(-buttonGap)
            make.centerY.equalTo(hangupButton)
            make.width.height.equalTo(buttonSize)
        }

        speakerButton.snp.makeConstraints { make in
            make.leading.equalTo(hangupButton.snp.trailing).offset(buttonGap)
            make.centerY.equalTo(hangupButton)
            make.width.height.equalTo(buttonSize)
        }
    }

    private func setupTRTC() async {
        trtcCloud = TRTCCloud.sharedInstance()
        trtcCloud?.delegate = self

        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""

        // 从服务器获取 TRTC 参数（SDKAppID + UserSig）
        var sdkAppID: UInt32 = 0
        var userSig = ""
        do {
            let response: APIResponse<TRTCParamsResponse> = try await APIClient.shared.request(.getTRTCUserSig)
            if let data = response.data {
                sdkAppID = UInt32(data.sdkAppID)
                userSig = data.userSig
            }
        } catch {
            DispatchQueue.main.async {
                AppUtility.showToast("获取通话参数失败: \(error.localizedDescription)")
                self.dismiss(animated: true)
            }
            return
        }

        guard sdkAppID > 0, !userSig.isEmpty else {
            DispatchQueue.main.async {
                AppUtility.showToast("TRTC未配置，请联系管理员")
                self.dismiss(animated: true)
            }
            return
        }

        let params = TRTCParams()
        params.sdkAppId = sdkAppID
        params.userId = uid
        params.roomId = UInt32(channelId.hashValue & 0x7FFFFFFF)
        params.role = .anchor
        params.userSig = userSig

        trtcCloud?.enterRoom(params, appScene: .audioCall)
        trtcCloud?.startLocalAudio(.default)
    }

    @objc private func hangup() {
        dismiss(animated: true)
    }

    @objc private func toggleMute() {
        isMuted.toggle()
        trtcCloud?.muteLocalAudio(isMuted)
        let imageName = isMuted ? "mic.slash.fill" : "mic.fill"
        muteButton.setImage(UIImage(systemName: imageName), for: .normal)
        muteButton.backgroundColor = isMuted ? UIColor.systemRed.withAlphaComponent(0.8) : UIColor.white.withAlphaComponent(0.2)
    }

    @objc private func toggleSpeaker() {
        isSpeakerOn.toggle()
        trtcCloud?.setAudioRoute(isSpeakerOn ? TRTCAudioRoute(rawValue: 1)! : TRTCAudioRoute(rawValue: 2)!)
        let imageName = isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.1.fill"
        speakerButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private func startCallDurationTimer() {
        callDurationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.callDuration += 1
            let min = self.callDuration / 60
            let sec = self.callDuration % 60
            self.durationLabel.text = String(format: "%02d:%02d", min, sec)
        }
    }

    private func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }
}

// MARK: - TRTCCloudDelegate
extension TRTCCallViewController: TRTCCloudDelegate {

    func onEnterRoom(_ result: Int) {
        DispatchQueue.main.async {
            if result > 0 {
                self.statusLabel.text = "通话中"
                self.durationLabel.isHidden = false
                self.startCallDurationTimer()
            } else {
                AppUtility.showToast("进入房间失败")
            }
        }
    }

    func onExitRoom(_ reason: Int) {
        print("TRTC退出房间: \(reason)")
    }

    func onUserAudioAvailable(_ userId: String, available: Bool) {
        if available {
            remoteUserID = userId
        }
    }

    func onUserEnter(_ userId: String) {
        remoteUserID = userId
    }

    func onUserLeave(_ userId: String, reason: Int) {
        if remoteUserID == userId {
            remoteUserID = nil
            DispatchQueue.main.async {
                self.stopCallDurationTimer()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dismiss(animated: true)
            }
        }
    }
}
