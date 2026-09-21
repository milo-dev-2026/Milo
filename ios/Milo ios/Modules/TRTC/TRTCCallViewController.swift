import UIKit
import SnapKit
import TXLiteAVSDK_TRTC

// MARK: - TRTC通话页
class TRTCCallViewController: UIViewController {

    private let channelId: String
    private let isVideoCall: Bool
    private var trtcCloud: TRTCCloud?
    private var remoteUserID: String?

    private let localView = UIView()
    private let remoteView = UIView()
    private let hangupButton = UIButton(type: .system)
    private let muteButton = UIButton(type: .system)
    private let switchCameraButton = UIButton(type: .system)
    private let speakerButton = UIButton(type: .system)
    private let durationLabel = UILabel()
    private var isMuted = false
    private var isSpeakerOn = true
    private var callDurationTimer: Timer?
    private var callDuration: Int = 0

    init(channelId: String, isVideoCall: Bool) {
        self.channelId = channelId
        self.isVideoCall = isVideoCall
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
        trtcCloud?.stopLocalPreview()
        trtcCloud?.exitRoom()
        TRTCCloud.destroySharedInstance()
    }

    private func setupUI() {
        view.backgroundColor = .black

        let buttonSize = ScreenAdapter.scaleW(60)
        let buttonGap = ScreenAdapter.scaleW(40)
        let sideMargin = ScreenAdapter.scaleW(20)
        let localViewW = ScreenAdapter.scaleW(100)
        let localViewH = ScreenAdapter.scaleH(140)
        let bottomOffset = ScreenAdapter.safeAreaBottom + ScreenAdapter.scaleH(40)

        remoteView.backgroundColor = .systemGray6
        localView.backgroundColor = .systemGray4
        localView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        localView.clipsToBounds = true

        hangupButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        hangupButton.tintColor = .white
        hangupButton.backgroundColor = .systemRed
        hangupButton.layer.cornerRadius = buttonSize / 2

        muteButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        muteButton.tintColor = .white
        muteButton.backgroundColor = UIColor(white: 1, alpha: 0.3)
        muteButton.layer.cornerRadius = buttonSize / 2

        switchCameraButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.backgroundColor = UIColor(white: 1, alpha: 0.3)
        switchCameraButton.layer.cornerRadius = buttonSize / 2

        speakerButton.setImage(UIImage(systemName: "speaker.wave.3.fill"), for: .normal)
        speakerButton.tintColor = .white
        speakerButton.backgroundColor = UIColor(white: 1, alpha: 0.3)
        speakerButton.layer.cornerRadius = buttonSize / 2

        durationLabel.text = "00:00"
        durationLabel.font = ScreenAdapter.font(16)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .center

        hangupButton.addTarget(self, action: #selector(hangup), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        speakerButton.addTarget(self, action: #selector(toggleSpeaker), for: .touchUpInside)

        view.addSubviews(remoteView, localView, hangupButton, muteButton, switchCameraButton, speakerButton, durationLabel)

        remoteView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        localView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.safeAreaTop + ScreenAdapter.scaleH(20))
            make.trailing.equalToSuperview().offset(-sideMargin)
            make.width.equalTo(localViewW)
            make.height.equalTo(localViewH)
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

        switchCameraButton.snp.makeConstraints { make in
            make.leading.equalTo(hangupButton.snp.trailing).offset(buttonGap)
            make.centerY.equalTo(hangupButton)
            make.width.height.equalTo(buttonSize)
        }

        speakerButton.snp.makeConstraints { make in
            make.leading.equalTo(switchCameraButton.snp.trailing).offset(buttonGap)
            make.centerY.equalTo(hangupButton)
            make.width.height.equalTo(buttonSize)
        }

        durationLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.safeAreaTop + ScreenAdapter.scaleH(40))
            make.centerX.equalToSuperview()
        }

        if !isVideoCall {
            localView.isHidden = true
            switchCameraButton.isHidden = true
        }
    }

    private func setupTRTC() async {
        trtcCloud = TRTCCloud.sharedInstance()
        trtcCloud?.delegate = self
        trtcCloud?.setVideoEncoderMirror(true)

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

        trtcCloud?.enterRoom(params, appScene: isVideoCall ? .videoCall : .audioCall)

        if isVideoCall {
            trtcCloud?.startLocalPreview(true, view: localView)
        }
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
    }

    @objc private func switchCamera() {
        trtcCloud?.switchCamera()
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

    func onUserVideoAvailable(_ userId: String, available: Bool) {
        DispatchQueue.main.async {
            if available {
                self.remoteUserID = userId
                self.trtcCloud?.startRemoteView(userId, streamType: .big, view: self.remoteView)
            } else {
                self.trtcCloud?.stopRemoteView(userId, streamType: .big)
            }
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
