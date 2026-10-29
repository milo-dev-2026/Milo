import UIKit

/// 语音通话信令管理（对齐安卓 TRTCCallActivity + WaitingAnswerActivity + WKIMUtils.handleRTCSignal）
/// 信令通过 IM 消息（type=9996）在双方之间传递，roomId 由主叫生成并随信令下发，双方进入同一房间
final class RTCCallManager {

    static let shared = RTCCallManager()

    enum Signal: Int {
        case invite = 0
        case accept = 1
        case cancel = 2
        case hangup = 3
        case refuse = 4
        case busy = 7
    }

    /// 当前是否在通话流程中（等待接听或通话中）
    private(set) var isInCall = false
    private(set) var roomId = 0
    private(set) var peerChannelId = ""
    private var peerName = ""
    private var peerAvatar = ""
    private var callType = 0

    private weak var callVC: TRTCCallViewController?
    private weak var waitingVC: WaitingAnswerViewController?

    private init() {}

    // MARK: - 主叫发起通话
    func startCall(from presenter: UIViewController, channelId: String, peerName: String, peerAvatar: String, callType: Int = 0) {
        guard TRTCConfig.sdkAppID > 0, !TRTCConfig.userSig.isEmpty else {
            AppUtility.showToast("TRTC未配置，请联系管理员")
            return
        }
        guard !isInCall else {
            AppUtility.showToast("正在通话中")
            return
        }
        // 与安卓一致：roomId 使用秒级时间戳
        roomId = Int(Date().timeIntervalSince1970)
        self.peerChannelId = channelId
        self.peerName = peerName.isEmpty ? "用户" : peerName
        self.peerAvatar = peerAvatar
        self.callType = callType
        isInCall = true

        sendSignal(.invite, to: channelId)

        let vc = makeCallViewController(isCaller: true)
        callVC = vc
        vc.modalPresentationStyle = .fullScreen
        presenter.present(vc, animated: true)
    }

    // MARK: - 收到信令
    func handleSignal(fromUID: String, payload: [String: Any]) {
        let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
        guard !fromUID.isEmpty, fromUID != myUid else { return }
        guard let signalType = intValue(payload["signal_type"]) else { return }
        let signalRoomId = intValue(payload["room_id"]) ?? 0
        let signalCallType = intValue(payload["call_type"]) ?? 0
        var callerName = (payload["caller_name"] as? String) ?? ""
        if callerName.isEmpty {
            callerName = IMManager.shared.getChannelInfo(channelId: fromUID, channelType: 1)?.displayName ?? fromUID
        }

        switch Signal(rawValue: signalType) {
        case .invite:
            // 忙线：直接回复忙线信令
            if isInCall {
                sendSignal(.busy, to: fromUID, roomId: signalRoomId, callType: signalCallType)
                return
            }
            roomId = signalRoomId > 0 ? signalRoomId : Int(Date().timeIntervalSince1970)
            peerChannelId = fromUID
            peerName = callerName
            peerAvatar = IMManager.shared.getChannelInfo(channelId: fromUID, channelType: 1)?.logo
                ?? IMManager.shared.getChannelInfo(channelId: fromUID, channelType: 1)?.avatar ?? ""
            callType = signalCallType
            isInCall = true
            presentWaitingAnswer(callerId: fromUID, callerName: callerName)

        case .accept:
            callVC?.handleRemoteSignal(signalType)

        case .cancel:
            if let waiting = waitingVC {
                waiting.dismiss(animated: true)
                waitingVC = nil
            }
            reset()

        case .refuse, .hangup, .busy:
            if let waiting = waitingVC {
                waiting.dismiss(animated: true)
                waitingVC = nil
            }
            callVC?.handleRemoteSignal(signalType)
            if callVC == nil { reset() }

        case .none:
            break
        }
    }

    // MARK: - 被叫接听 / 拒绝
    private func presentWaitingAnswer(callerId: String, callerName: String) {
        let waiting = WaitingAnswerViewController(channelId: callerId, callerName: callerName, onAccept: { [weak self] in
            guard let self = self else { return }
            self.waitingVC = nil
            self.sendSignal(.accept, to: callerId)
            let vc = self.makeCallViewController(isCaller: false)
            self.callVC = vc
            vc.modalPresentationStyle = .fullScreen
            self.topViewController()?.present(vc, animated: true)
        }, onReject: { [weak self] in
            guard let self = self else { return }
            self.waitingVC = nil
            self.sendSignal(.refuse, to: callerId)
            self.reset()
        })
        waitingVC = waiting
        waiting.modalPresentationStyle = .fullScreen
        topViewController()?.present(waiting, animated: true)
    }

    private func makeCallViewController(isCaller: Bool) -> TRTCCallViewController {
        let vc = TRTCCallViewController(channelId: peerChannelId,
                                       peerName: peerName,
                                       peerAvatar: peerAvatar,
                                       roomId: roomId,
                                       isCaller: isCaller)
        vc.onFinish = { [weak self] in
            self?.callVC = nil
            self?.reset()
        }
        return vc
    }

    // MARK: - 发送信令
    func sendSignal(_ type: Signal, to channelId: String, roomId: Int? = nil, callType: Int? = nil) {
        IMManager.shared.sendRTCSignal(channelId: channelId,
                                       channelType: 1,
                                       signalType: type.rawValue,
                                       callType: callType ?? self.callType,
                                       roomId: roomId ?? self.roomId,
                                       callerName: myName())
    }

    private func myName() -> String {
        let name = UserDefaults.standard.string(forKey: "name") ?? ""
        return name.isEmpty ? "用户" : name
    }

    func reset() {
        isInCall = false
        roomId = 0
        callType = 0
    }

    // MARK: - 工具
    private func intValue(_ value: Any?) -> Int? {
        if let v = value as? Int { return v }
        if let v = value as? NSNumber { return v.intValue }
        if let v = value as? String { return Int(v) }
        return nil
    }

    private func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow })
            ?? scenes.flatMap { $0.windows }.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
