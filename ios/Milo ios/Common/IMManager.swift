import Foundation
import WuKongIMSDK

// MARK: - IM连接管理器
/// 基于WuKongIM SDK管理IM连接、消息收发
class IMManager: NSObject {

    static let shared = IMManager()

    var onMessageReceived: ((Message) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?

    private var isSetup = false

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
        options.apiURL = APIConfig.apiBaseURL

        WKSDK.shared().setup(options: options)

        WKSDK.shared().chatManager.addDelegate(self)
        WKSDK.shared().connectionManager.addDelegate(self)
    }

    // MARK: - 连接
    func connect() {
        guard let uid = UserDefaults.standard.string(forKey: "uid"), !uid.isEmpty else { return }
        let imToken = UserDefaults.standard.string(forKey: "im_token")
            ?? UserDefaults.standard.string(forKey: "token")
            ?? ""
        guard !imToken.isEmpty else { return }

        setupSDK()

        WKSDK.shared().options.connectInfoCallback = {
            let info = WKConnectInfo()
            info.uid = uid
            info.token = imToken
            return info
        }

        WKSDK.shared().connectionManager.connect()
    }

    func disconnect() {
        WKSDK.shared().connectionManager.disconnect(false)
    }

    // MARK: - 发送消息
    func sendTextMessage(channelId: String, content: String) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = WKChannelType.person.rawValue
        let textContent = WKTextContent(content: content)
        WKSDK.shared().chatManager.sendMessage(textContent, channel: channel)
    }
}

// MARK: - WKChatManagerDelegate
extension IMManager: WKChatManagerDelegate {

    func onRecvMessages(_ message: WKMessage!, left: Int) {
        guard let wkMsg = message else { return }
        let textContent = wkMsg.content as? WKTextContent
        let msg = Message(
            messageID: String(wkMsg.messageId),
            channelID: wkMsg.channel.channelId ?? "",
            channelType: Int(wkMsg.channel.channelType),
            fromUID: wkMsg.fromUid ?? "",
            content: textContent?.content ?? "",
            type: .text,
            timestamp: Int64(wkMsg.timestamp * 1000),
            status: 1
        )
        DispatchQueue.main.async {
            self.onMessageReceived?(msg)
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
                print("IM连接成功")
                self.onConnectionChanged?(true)
            case 4: // WKDisconnected
                print("IM断开")
                self.onConnectionChanged?(false)
            case 0: // WKNoConnect
                print("IM未连接")
                self.onConnectionChanged?(false)
            default:
                break
            }
        }
    }

    func onKick(_ reasonCode: WKReason) {
        DispatchQueue.main.async {
            print("IM被踢下线")
            self.onConnectionChanged?(false)
        }
    }
}
