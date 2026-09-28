import Foundation
import WuKongIMSDK

// MARK: - IM连接管理器
class IMManager: NSObject {

    static let shared = IMManager()

    // 消息回调
    var onMessageReceived: ((Message) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?
    var onMessageStatusUpdate: ((Message) -> Void)?

    private var isSetup = false

    static let messageReceivedNotification = NSNotification.Name("IMMessageReceived")
    static let messageStatusUpdateNotification = NSNotification.Name("IMMessageStatusUpdate")
    static let connectionStatusChangedNotification = NSNotification.Name("IMConnectionStatusChanged")

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
        options.heartbeatInterval = 30

        WKSDK.shared().options = options

        // 注册自定义消息类型
        WKMessageContentRegistrar.registerAll()

        // 设置delegate
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

    // MARK: - 发送文本消息
    func sendTextMessage(channelId: String, content: String, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let textContent = WKTextContent(content: content)
        _ = WKSDK.shared().chatManager.sendMessage(textContent, channel: channel)
    }

    // MARK: - 发送图片消息
    func sendImageMessage(channelId: String, imageURL: String, width: CGFloat, height: CGFloat, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let imageContent = WKImageMessageContent()
        imageContent.url = imageURL
        imageContent.width = width
        imageContent.height = height
        _ = WKSDK.shared().chatManager.sendMessage(imageContent, channel: channel)
    }

    // MARK: - 发送语音消息
    func sendVoiceMessage(channelId: String, voiceURL: String, duration: Int, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let voiceContent = WKVoiceMessageContent()
        voiceContent.url = voiceURL
        voiceContent.duration = duration
        _ = WKSDK.shared().chatManager.sendMessage(voiceContent, channel: channel)
    }

    // MARK: - 发送视频消息
    func sendVideoMessage(channelId: String, thumbURL: String, videoURL: String, duration: Int, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let videoContent = WKVideoMessageContent()
        videoContent.thumbURL = thumbURL
        videoContent.videoURL = videoURL
        videoContent.duration = duration
        _ = WKSDK.shared().chatManager.sendMessage(videoContent, channel: channel)
    }

    // MARK: - 发送文件消息
    func sendFileMessage(channelId: String, fileName: String, fileSize: Int64, fileURL: String, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let fileContent = WKFileMessageContent()
        fileContent.fileName = fileName
        fileContent.fileSize = fileSize
        fileContent.url = fileURL
        _ = WKSDK.shared().chatManager.sendMessage(fileContent, channel: channel)
    }

    // MARK: - 发送位置消息
    func sendLocationMessage(channelId: String, name: String, latitude: Double, longitude: Double, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let locationContent = WKLocationMessageContent()
        locationContent.name = name
        locationContent.latitude = latitude
        locationContent.longitude = longitude
        _ = WKSDK.shared().chatManager.sendMessage(locationContent, channel: channel)
    }

    // MARK: - 发送名片消息
    func sendCardMessage(channelId: String, uid: String, name: String, avatar: String, vercode: String, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let cardContent = WKCardMessageContent()
        cardContent.uid = uid
        cardContent.name = name
        cardContent.avatar = avatar
        cardContent.vercode = vercode
        _ = WKSDK.shared().chatManager.sendMessage(cardContent, channel: channel)
    }

    // MARK: - 发送笔记消息
    func sendNoteMessage(channelId: String, noteJSON: String, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let noteContent = WKNoteMessageContent()
        noteContent.noteJSON = noteJSON
        // 尝试解析标题和内容
        if let data = noteJSON.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            noteContent.title = json["title"] as? String ?? ""
            noteContent.noteContent = json["content"] as? String ?? ""
            noteContent.noteId = json["id"] as? String ?? ""
        }
        _ = WKSDK.shared().chatManager.sendMessage(noteContent, channel: channel)
    }
}

// MARK: - WKChatManagerDelegate
extension IMManager: WKChatManagerDelegate {

    func onRecvMessages(_ message: WKMessage!, left: Int) {
        guard let wkMsg = message else { return }

        let msg = convertWKMessageToMessage(wkMsg)

        DispatchQueue.main.async {
            self.onMessageReceived?(msg)
            NotificationCenter.default.post(name: IMManager.messageReceivedNotification, object: msg)
        }
    }

    func onMessageUpdate(_ message: WKMessage!) {
        guard let wkMsg = message else { return }
        let msg = convertWKMessageToMessage(wkMsg)
        DispatchQueue.main.async {
            self.onMessageStatusUpdate?(msg)
            NotificationCenter.default.post(name: IMManager.messageStatusUpdateNotification, object: msg)
        }
    }

    func onMessageDelete(_ message: WKMessage!) {}

    func onMessageStatusUpdate(_ message: WKMessage!) {
        guard let wkMsg = message else { return }
        let msg = convertWKMessageToMessage(wkMsg)
        DispatchQueue.main.async {
            self.onMessageStatusUpdate?(msg)
            NotificationCenter.default.post(name: IMManager.messageStatusUpdateNotification, object: msg)
        }
    }

    // MARK: - WKMessage 转 业务 Message
    private func convertWKMessageToMessage(_ wkMsg: WKMessage) -> Message {
        var content = ""
        var msgType = MessageType.text

        let contentType = Int(wkMsg.content.realContentType)

        switch contentType {
        case 1: // 文本
            if let textContent = wkMsg.content as? WKTextContent {
                content = textContent.content ?? ""
            }
            msgType = .text

        case 2: // 图片
            if let imageContent = wkMsg.content as? WKImageMessageContent {
                content = imageContent.url
            }
            msgType = .image

        case 3: // 语音
            if let voiceContent = wkMsg.content as? WKVoiceMessageContent {
                // 兼容旧格式: "duration|url"
                content = "\(voiceContent.duration)|\(voiceContent.url)"
            }
            msgType = .voice

        case 4: // 视频
            if let videoContent = wkMsg.content as? WKVideoMessageContent {
                // 兼容旧格式: "thumbURL|videoURL"
                content = "\(videoContent.thumbURL)|\(videoContent.videoURL)"
            }
            msgType = .video

        case 5: // 文件
            if let fileContent = wkMsg.content as? WKFileMessageContent {
                // 兼容旧格式: "fileName|fileSize|url"
                content = "\(fileContent.fileName)|\(fileContent.fileSize)|\(fileContent.url)"
            }
            msgType = .file

        case 6: // 位置
            if let locationContent = wkMsg.content as? WKLocationMessageContent {
                // 兼容旧格式: "name|lat,lng"
                content = "\(locationContent.name)|\(locationContent.latitude),\(locationContent.longitude)"
            }
            msgType = .location

        case 7: // 名片
            if let cardContent = wkMsg.content as? WKCardMessageContent {
                // 兼容旧格式: "uid|name|avatar|vercode"
                content = "\(cardContent.uid)|\(cardContent.name)|\(cardContent.avatar)|\(cardContent.vercode)"
            }
            msgType = .card

        case 100: // 笔记
            if let noteContent = wkMsg.content as? WKNoteMessageContent {
                // 优先使用完整JSON
                if !noteContent.noteJSON.isEmpty {
                    content = noteContent.noteJSON
                } else {
                    // 降级：构造简单JSON
                    let dict: [String: Any] = [
                        "id": noteContent.noteId,
                        "title": noteContent.title,
                        "content": noteContent.noteContent
                    ]
                    if let data = try? JSONSerialization.data(withJSONObject: dict),
                       let str = String(data: data, encoding: .utf8) {
                        content = str
                    }
                }
            }
            msgType = .note

        default:
            if let textContent = wkMsg.content as? WKTextContent {
                content = textContent.content ?? ""
            }
            msgType = .text
        }

        let status: Int
        switch wkMsg.status.rawValue {
        case 0, 3: // WK_MESSAGE_WAITSEND 等待发送 / WK_MESSAGE_UPLOADING 上传中
            status = 0 // 发送中
        case 4: // WK_MESSAGE_FAIL 发送失败
            status = -1 // 失败
        default: // WK_MESSAGE_SUCCESS 成功
            status = 1 // 成功
        }

        let chId = wkMsg.channel.channelId ?? ""
        let chType = Int(wkMsg.channel.channelType)

        return Message(
            messageID: String(wkMsg.messageId),
            channelID: chId,
            channelType: chType,
            fromUID: wkMsg.fromUid ?? "",
            content: content,
            type: msgType,
            timestamp: Int64(wkMsg.timestamp * 1000),
            status: status
        )
    }
}

// MARK: - WKConnectionManagerDelegate
extension IMManager: WKConnectionManagerDelegate {

    func onConnectStatus(_ status: WKConnectStatus, reasonCode: WKReason) {
        DispatchQueue.main.async {
            var isConnected = false
            switch status.rawValue {
            case 3: // WKConnected
                print("[IM] 连接成功")
                isConnected = true
            case 4: // WKDisconnected
                print("[IM] 断开连接, reason: \(reasonCode.rawValue)")
                isConnected = false
            case 0: // WKNoConnect
                print("[IM] 未连接")
                isConnected = false
            case 1: // WKConnecting
                print("[IM] 连接中...")
                isConnected = false
            case 2: // WKPullingOffline
                print("[IM] 拉取离线消息中...")
                isConnected = false
            default:
                print("[IM] 状态: \(status.rawValue), reason: \(reasonCode.rawValue)")
                break
            }
            self.onConnectionChanged?(isConnected)
            NotificationCenter.default.post(name: IMManager.connectionStatusChangedNotification, object: NSNumber(value: isConnected))
        }
    }

    func onKick(_ reasonCode: WKReason) {
        DispatchQueue.main.async {
            print("[IM] 被踢下线, reason: \(reasonCode.rawValue)")
            self.onConnectionChanged?(false)
            NotificationCenter.default.post(name: IMManager.connectionStatusChangedNotification, object: NSNumber(value: false))
        }
    }
}
