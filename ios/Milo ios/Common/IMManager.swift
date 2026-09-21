import Foundation
import Starscream

// MARK: - IM连接管理器
/// 管理与WuKongIM服务器的WebSocket连接
class IMManager: NSObject {

    static let shared = IMManager()

    private var socket: WebSocket?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var reconnectCount = 0
    private let maxReconnectCount = 10

    // 回调
    var onMessageReceived: ((Message) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - 连接
    func connect() {
        guard let uid = UserDefaults.standard.string(forKey: "uid"), !uid.isEmpty else { return }
        guard let token = UserDefaults.standard.string(forKey: "token"), !token.isEmpty else { return }

        var request = URLRequest(url: URL(string: APIConfig.imSocketURL)!)
        request.timeoutInterval = 10
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    // MARK: - 发送消息
    func sendTextMessage(channelId: String, content: String) {
        let payload: [String: Any] = [
            "type": 1,
            "channel_id": channelId,
            "content": content,
            "from_uid": UserDefaults.standard.string(forKey: "uid") ?? ""
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            socket?.write(data: data)
        }
    }

    // MARK: - 重连
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        guard reconnectCount < maxReconnectCount else {
            print("IM连接: 达到最大重连次数")
            return
        }
        let delay = min(pow(2.0, Double(reconnectCount)), 30.0)
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            self.reconnectCount += 1
            print("IM连接: 第\(self.reconnectCount)次重连...")
            self.connect()
        }
    }
}

// MARK: - WebSocketDelegate
extension IMManager: WebSocketDelegate {

    func websocketDidConnect(socket: WebSocketClient) {
        print("IM连接成功")
        isConnected = true
        reconnectCount = 0
        onConnectionChanged?(true)
        sendAuthPacket()
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("IM断开: \(error?.localizedDescription ?? "")")
        isConnected = false
        onConnectionChanged?(false)
        scheduleReconnect()
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        handleMessage(text)
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        if let text = String(data: data, encoding: .utf8) {
            handleMessage(text)
        }
    }

    // MARK: - 认证包
    private func sendAuthPacket() {
        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
        let token = UserDefaults.standard.string(forKey: "token") ?? ""
        let authPacket: [String: Any] = [
            "type": "auth",
            "uid": uid,
            "token": token
        ]
        if let data = try? JSONSerialization.data(withJSONObject: authPacket) {
            socket?.write(data: data)
        }
    }

    // MARK: - 消息处理
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let type = json["type"] as? String ?? ""

        switch type {
        case "message":
            if let msgData = try? JSONSerialization.data(withJSONObject: json["data"] ?? [:]),
               let msg = try? JSONDecoder().decode(Message.self, from: msgData) {
                DispatchQueue.main.async {
                    self.onMessageReceived?(msg)
                }
            }
        case "ack":
            break
        case "receipt":
            break
        default:
            break
        }
    }
}
