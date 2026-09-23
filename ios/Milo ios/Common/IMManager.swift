import Foundation
import WuKongIMSDK

// MARK: - IM连接管理器
class IMManager: NSObject {

    static let shared = IMManager()

    var onMessageReceived: ((Message) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?

    private var isSetup = false

    static let messageReceivedNotification = NSNotification.Name("IMMessageReceived")

    private override init() {
        super.init()
    }

    // MARK: - SDK初始化
    func setupSDK() {
        guard !isSetup else { return }
        isSetup = true

        let options = WKOptions()
        options.host = "43.133.39.170"
        options.port = 5100

        WKSDK.shared().setup(options: options)

        WKSDK.shared().chatManager.add(self)
        WKSDK.shared().connectionManager.add(self)
    }

    // MARK: - 连接（动态获取IM服务器地址）
    func connect() {
        guard let uid = UserDefaults.standard.string(forKey: "uid"), !uid.isEmpty else { return }
        let imToken = UserDefaults.standard.string(forKey: "im_token")
            ?? UserDefaults.standard.string(forKey: "token")
            ?? ""
        guard !imToken.isEmpty else { return }

        setupSDK()

        let uidCopy = uid
        let tokenCopy = imToken
        WKSDK.shared().options.connectInfoCallback = {
            let info = WKConnectInfo()
            info.uid = uidCopy
            info.token = tokenCopy
            return info
        }

        // 动态获取IM服务器IP和端口
        Task {
            do {
                let imServer: IMServerResponse = try await APIClient.shared.requestFlexible(.getIMServer(uid: uid))
                let host = imServer.ip ?? "43.133.39.170"
                let port = UInt16(imServer.port ?? 5100)
                print("[IM] 获取到IM服务器: \(host):\(port)")
                DispatchQueue.main.async {
                    WKSDK.shared().options.host = host
                    WKSDK.shared().options.port = port
                    WKSDK.shared().connectionManager.connect()
                }
            } catch {
                print("[IM] 获取IM服务器地址失败，使用默认值: \(error)")
                DispatchQueue.main.async {
                    WKSDK.shared().options.host = "43.133.39.170"
                    WKSDK.shared().options.port = 5100
                    WKSDK.shared().connectionManager.connect()
                }
            }
        }
    }

    func disconnect() {
        WKSDK.shared().connectionManager.disconnect(false)
    }

    // MARK: - 发送消息
    func sendTextMessage(channelId: String, content: String, channelType: Int = 1) {
        let channel = WKChannel(channelId: channelId, channelType: UInt8(channelType))
        let textContent = WKTextContent(content: content)
        WKSDK.shared().chatManager.sendMessage(textContent, channel: channel)
    }
}

// MARK: - WKChatManagerDelegate
extension IMManager: WKChatManagerDelegate {

    func onRecvMessages(_ message: WKMessage!, left: Int) {
        guard let wkMsg = message else { return }

        var content = ""
        var type = MessageType.text

        if let textContent = wkMsg.content as? WKTextContent {
            content = textContent.content ?? ""
            type = .text
        }

        let msg = Message(
            messageID: String(wkMsg.messageId),
            channelID: wkMsg.channel.channelId ?? "",
            channelType: Int(wkMsg.channel.channelType),
            fromUID: wkMsg.fromUid ?? "",
            content: content,
            type: type,
            timestamp: Int64(wkMsg.timestamp * 1000),
            status: 1
        )

        DispatchQueue.main.async {
            self.onMessageReceived?(msg)
            NotificationCenter.default.post(name: IMManager.messageReceivedNotification, object: msg)
        }
    }

    func onMessageUpdate(_ message: WKMessage!) {}
    func onMessageDelete(_ message: WKMessage!) {}
    func onMessageStatusUpdate(_ message: WKMessage!) {}
}

// MARK: - WKConnectionManagerDelegate
extension IMManager: WKConnectionManagerDelegate {

    func onConnectStatus(_ status: WKConnectStatus, reasonCode: WKReason) {
        DispatchQueue.main.async {
            switch status.rawValue {
            case 3: // WKConnected
                print("[IM] 连接成功")
                self.onConnectionChanged?(true)
            case 4: // WKDisconnected
                print("[IM] 断开")
                self.onConnectionChanged?(false)
            case 0: // WKNoConnect
                print("[IM] 未连接")
                self.onConnectionChanged?(false)
            default:
                print("[IM] 状态: \(status.rawValue), reason: \(reasonCode.rawValue)")
                break
            }
        }
    }

    func onKick(_ reasonCode: WKReason) {
        DispatchQueue.main.async {
            print("[IM] 被踢下线")
            self.onConnectionChanged?(false)
        }
    }
}
