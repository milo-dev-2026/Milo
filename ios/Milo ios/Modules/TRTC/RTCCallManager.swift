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
        // 如果头像为空，尝试从网络获取
        if peerAvatar.isEmpty {
            Task {
                do {
                    let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                        .getChannelInfo(channelId: channelId, channelType: 1)
                    )
                    DispatchQueue.main.async {
                        self.peerAvatar = info.logo ?? ""
                        // 更新通话页面的头像
                        if let callVC = self.callVC {
                            callVC.updatePeerAvatar(info.logo ?? "")
                        }
                    }
                } catch { }
            }
        }
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
        guard let signalType = intValue(payload["signal_type"]),
              let signal = Signal(rawValue: signalType) else { return }
        let signalRoomId = intValue(payload["room_id"]) ?? 0
        let signalCallType = intValue(payload["call_type"]) ?? 0
        // 安卓 RTC 信令字段是 from_name / from_uid（不是 caller_name），兼容两套命名，
        // 都取不到时不再用 uid 兜底显示（否则页面显示一长串乱码）
        var callerName = (payload["from_name"] as? String)
            ?? (payload["caller_name"] as? String)
            ?? ""
        callerName = callerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if callerName.isEmpty {
            callerName = IMManager.shared.getChannelInfo(channelId: fromUID, channelType: 1)?.displayName ?? ""
        }
        if callerName.isEmpty || callerName == fromUID {
            callerName = "用户"
        }

        switch Signal(rawValue: signalType) {
        case .invite:
            // 忙线：回复忙线信令，并发送"忙线"通话结果消息（对齐微信：主叫侧显示"对方忙线中"）
            if isInCall {
                sendSignal(.busy, to: fromUID, roomId: signalRoomId, callType: signalCallType)
                IMManager.shared.sendRTCResultMessage(channelId: fromUID, channelType: 1,
                                                      callType: signalCallType, resultType: 4, second: 0)
                return
            }
            roomId = signalRoomId > 0 ? signalRoomId : Int(Date().timeIntervalSince1970)
            peerChannelId = fromUID
            peerName = callerName
            // 获取对方头像（优先本地缓存，再尝试网络）
            peerAvatar = IMManager.shared.getChannelInfo(channelId: fromUID, channelType: 1)?.logo ?? ""
            if peerAvatar.isEmpty {
                // 如果本地没有头像，尝试从网络获取
                Task {
                    do {
                        let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                            .getChannelInfo(channelId: fromUID, channelType: 1)
                        )
                        DispatchQueue.main.async {
                            self.peerAvatar = info.logo ?? ""
                        }
                    } catch { }
                }
            }
            callType = signalCallType
            isInCall = true
            presentWaitingAnswer(callerId: fromUID, callerName: callerName)
            // 信令里没有昵称（只有 uid）时异步拉取频道信息，拿到后刷新等待接听页
            if callerName == "用户" {
                let pendingCallerId = fromUID
                Task {
                    do {
                        let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                            .getChannelInfo(channelId: pendingCallerId, channelType: 1)
                        )
                        DispatchQueue.main.async {
                            let name = info.displayName
                            guard !name.isEmpty, name != pendingCallerId else { return }
                            self.peerName = name
                            self.waitingVC?.updateCallerName(name, avatar: info.logo)
                        }
                    } catch { }
                }
            }

        case .accept:
            callVC?.handleRemoteSignal(signalType)

        case .cancel:
            if let waiting = waitingVC {
                waiting.dismiss(animated: true)
                waitingVC = nil
            }
            // 被叫侧：主叫取消 → 本地补一条"对方已取消"通话结果气泡（服务端同结果消息到达时会被合并）
            IMManager.shared.insertLocalCallResult(channelId: fromUID, fromUID: fromUID,
                                                   callType: signalCallType, resultType: 0)
            callVC?.handleRemoteSignal(signalType)
            if callVC == nil { reset() }

        case .refuse, .hangup, .busy:
            if let waiting = waitingVC {
                waiting.dismiss(animated: true)
                waitingVC = nil
            }
            // 未接通时的结束信号（拒绝/忙线）本地补结果气泡；
            // 已接通的挂断由服务端结果消息携带真实时长，不本地插入避免出现 00:00 气泡
            if signal == .refuse {
                IMManager.shared.insertLocalCallResult(channelId: fromUID, fromUID: fromUID,
                                                       callType: signalCallType, resultType: 3)
            } else if signal == .busy {
                IMManager.shared.insertLocalCallResult(channelId: fromUID, fromUID: fromUID,
                                                       callType: signalCallType, resultType: 4)
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
            // 对齐安卓 refuseCall：发送"已拒绝"通话结果消息（双方会话可见）
            IMManager.shared.sendRTCResultMessage(channelId: callerId, channelType: 1,
                                                  callType: self.callType, resultType: 3, second: 0)
            self.reset()
        }, onTimeout: { [weak self] in
            guard let self = self else { return }
            self.waitingVC = nil
            self.sendSignal(.refuse, to: callerId)
            // 对齐安卓 WaitingAnswerActivity 超时：发送"未接听"通话结果消息
            IMManager.shared.sendRTCResultMessage(channelId: callerId, channelType: 1,
                                                  callType: self.callType, resultType: 2, second: 0)
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
