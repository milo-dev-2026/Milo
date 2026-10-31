import UIKit
import SnapKit
import Kingfisher
import AVFoundation
import AudioToolbox
import TXLiteAVSDK_TRTC

// MARK: - TRTC语音通话页
class TRTCCallViewController: UIViewController {

    private let channelId: String
    private let peerName: String
    private let peerAvatar: String
    /// 通话房间号：由主叫生成并随信令同步给被叫（对齐安卓），0 表示本地推导
    private let callRoomId: Int
    private let isCaller: Bool
    /// 通话结束回调（供 RTCCallManager 清理状态）
    var onFinish: (() -> Void)?
    private var trtcCloud: TRTCCloud?
    private var remoteUserID: String?
    private var isConnected = false
    /// 稳定的房间号：由 channelId 计算（跨设备一致），仅在未传入 roomId 时使用
    private var stableRoomId: UInt32 {
        var hash: UInt32 = 2166136261
        for ch in channelId.utf8 {
            hash ^= UInt32(ch)
            hash = hash &* 16777619
        }
        return hash & 0x7FFFFFFF
    }

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
    private var ringbackTimer: Timer?
    /// 通话结果消息是否已发送（防重复）
    private var resultMessageSent = false
    /// 是否已执行结束流程（防重复挂断/信令）
    private var didEnd = false

    init(channelId: String, peerName: String = "语音通话", peerAvatar: String = "", roomId: Int = 0, isCaller: Bool = true) {
        self.channelId = channelId
        self.peerName = peerName
        self.peerAvatar = peerAvatar
        self.callRoomId = roomId
        self.isCaller = isCaller
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // 对齐安卓 checkPermissionsAndStart：先确保麦克风权限再进房
        requestMicPermissionThenStart()
    }

    private func requestMicPermissionThenStart() {
        let start = { [weak self] in
            Task { await self?.setupTRTC() }
        }
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            start()
        case .denied:
            AppUtility.showToast("请在系统设置中允许使用麦克风")
            dismiss(animated: true)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        start()
                    } else {
                        AppUtility.showToast("需要麦克风权限才能通话")
                        self.dismiss(animated: true)
                    }
                }
            }
        @unknown default:
            start()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 页面关闭（无论何种原因）都通知管理器清理通话状态
        if isBeingDismissed || navigationController?.isBeingDismissed == true || presentingViewController == nil {
            onFinish?()
        }
    }

    deinit {
        stopCallDurationTimer()
        trtcCloud?.stopLocalAudio()
        trtcCloud?.exitRoom()
        TRTCCloud.destroySharedInstance()
    }

    /// 加载对方头像
    private func loadPeerAvatar() {
        guard !peerAvatar.isEmpty else { return }
        updatePeerAvatar(peerAvatar)
    }

    /// 更新对方头像（供 RTCCallManager 在获取到头像后调用）
    func updatePeerAvatar(_ avatarUrl: String) {
        guard !avatarUrl.isEmpty else { return }
        var urlString = avatarUrl
        if !urlString.hasPrefix("http") {
            urlString = APIConfig.chatMediaURL(avatarUrl)?.absoluteString ?? ""
        }
        if let url = URL(string: urlString), !urlString.isEmpty {
            avatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "phone.fill"))
            avatarView.tintColor = nil
        }
    }

    /// 处理对方信令（由 RTCCallManager 调用）
    func handleRemoteSignal(_ type: Int) {
        DispatchQueue.main.async {
            switch type {
            case RTCCallManager.Signal.accept.rawValue:
                self.statusLabel.text = self.isConnected ? "通话中" : "对方已接听，连接中..."
            case RTCCallManager.Signal.refuse.rawValue:
                self.showPeerEndTip("对方已拒绝")
            case RTCCallManager.Signal.hangup.rawValue:
                self.showPeerEndTip("对方已挂断")
            case RTCCallManager.Signal.busy.rawValue:
                self.showPeerEndTip("对方忙线中")
            default:
                break
            }
        }
    }

    /// 发送通话结果消息（对齐安卓 finishWithResult：由结束方发送，双方会话可见）
    /// 已接通 → 正常结束(1)+时长；未接通（主叫取消/进房失败等）→ 取消(0)
    /// 对方结束（拒绝/挂断/忙线信令）时本端不发送，对方已发
    private func sendResultMessageIfNeeded() {
        guard !resultMessageSent else { return }
        resultMessageSent = true
        if isConnected {
            IMManager.shared.sendRTCResultMessage(channelId: channelId, channelType: 1,
                                                  callType: 0, resultType: 1, second: callDuration)
        } else {
            IMManager.shared.sendRTCResultMessage(channelId: channelId, channelType: 1,
                                                  callType: 0, resultType: 0, second: 0)
        }
    }

    private func endCall(notifyPeer: Bool, sendResult: Bool = true) {
        if didEnd { return }
        didEnd = true
        if sendResult {
            sendResultMessageIfNeeded()
        }
        if notifyPeer {
            RTCCallManager.shared.sendSignal(isConnected ? .hangup : .cancel, to: channelId)
        }
        stopCallDurationTimer()
        stopRingbackTone()
        trtcCloud?.stopLocalAudio()
        trtcCloud?.exitRoom()
        // 恢复音频会话，避免 playAndRecord 会话残留影响后续消息提示音
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        dismiss(animated: true) { [weak self] in
            self?.onFinish?()
        }
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
        // 显示对方头像（对齐安卓通话页）
        loadPeerAvatar()
        avatarView.layer.borderWidth = 3
        avatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

        // 名称标签
        nameLabel.text = peerName.isEmpty ? "语音通话" : peerName
        nameLabel.font = ScreenAdapter.mediumFont(22)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center

        // 状态标签（对齐安卓：主叫显示"正在等待对方接受邀请..."，被叫显示"对方邀请你语音通话"）
        statusLabel.text = isCaller ? "正在等待对方接受邀请..." : "对方邀请你语音通话"
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

        // 与安卓一致：本地生成 UserSig（SDKAppID + UserSig），不依赖后端接口
        let sdkAppID = TRTCConfig.sdkAppID
        let userSig = TRTCConfig.userSig
        guard sdkAppID > 0, !userSig.isEmpty, !uid.isEmpty else {
            AppUtility.showToast("TRTC未配置，请联系管理员")
            dismiss(animated: true)
            return
        }

        // 音频会话：通话模式（保证能听到对方声音、支持耳机/蓝牙）
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .voiceChat,
                                 options: [.allowBluetooth, .defaultToSpeaker, .allowBluetoothA2DP])
        try? session.setActive(true)

        // 主叫等待时播放回铃音（对齐安卓 WaitingAnswerActivity 的铃声）
        if isCaller {
            startRingbackTone()
        }

        let params = TRTCParams()
        params.sdkAppId = sdkAppID
        params.userId = uid
        params.roomId = callRoomId > 0 ? UInt32(callRoomId) : stableRoomId
        params.role = .anchor
        params.userSig = userSig

        print("[TRTC] enterRoom sdkAppId=\(sdkAppID) uid=\(uid) roomId=\(params.roomId) sigLen=\(userSig.count)")
        trtcCloud?.enterRoom(params, appScene: .audioCall)
        trtcCloud?.startLocalAudio(.default)
        // 语音通话默认使用扬声器（与安卓一致）
        if let speakerRoute = TRTCAudioRoute(rawValue: 1) {
            trtcCloud?.setAudioRoute(speakerRoute)
        }
    }

    @objc private func hangup() {
        endCall(notifyPeer: true)
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
                self.statusLabel.text = self.isCaller ? "正在等待对方接受邀请..." : "通话中"
                if !self.isCaller {
                    self.markConnected()
                }
            } else {
                self.statusLabel.text = "进入房间失败(\(result))"
                AppUtility.showToast("进入房间失败(\(result))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.endCall(notifyPeer: self.isCaller)
                }
            }
        }
    }

    func onError(_ errCode: Int, errMsg: String?, extInfo: [AnyHashable : Any]!) {
        print("[TRTC] onError code=\(errCode) msg=\(errMsg ?? "")")
        DispatchQueue.main.async {
            let text = errMsg?.isEmpty == false ? errMsg! : "错误码 \(errCode)"
            self.statusLabel.text = "通话错误: \(text)"
            AppUtility.showToast("通话错误: \(text)")
            // 对齐安卓 onError：1.5秒后结束通话并发送结果消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.endCall(notifyPeer: false, sendResult: true)
            }
        }
    }

    /// 主叫回铃音（对齐微信：等待接听时循环播放"嘟—嘟—"回铃音）
    private func startRingbackTone() {
        stopRingbackTone()
        RingtonePlayer.shared.startRingback()
    }

    private func stopRingbackTone() {
        ringbackTimer?.invalidate()
        ringbackTimer = nil
        RingtonePlayer.shared.stop()
    }

    private func markConnected() {
        guard !isConnected else { return }
        isConnected = true
        stopRingbackTone() // 接通后停止回铃音
        statusLabel.text = "通话中"
        durationLabel.isHidden = false
        startCallDurationTimer()
    }

    /// 对方拒绝/挂断/忙线时的提示（对齐安卓：任何状态下都结束通话；结果消息由对方发送）
    private func showPeerEndTip(_ text: String) {
        statusLabel.text = text
        statusLabel.textColor = .systemRed
        // 1.5秒后自动消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.endCall(notifyPeer: false, sendResult: false)
        }
    }

    func onExitRoom(_ reason: Int) {
        print("TRTC退出房间: \(reason)")
    }

    func onUserAudioAvailable(_ userId: String, available: Bool) {
        if available {
            remoteUserID = userId
            DispatchQueue.main.async {
                self.markConnected()
            }
        }
    }

    func onUserLeave(_ userId: String, reason: Int) {
        if remoteUserID == userId {
            remoteUserID = nil
            DispatchQueue.main.async {
                self.statusLabel.text = "对方已离开"
                self.stopCallDurationTimer()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.endCall(notifyPeer: false, sendResult: false)
            }
        }
    }
}
