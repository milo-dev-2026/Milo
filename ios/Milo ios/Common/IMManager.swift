import Foundation
import WuKongIMSDK

// MARK: - IM连接管理器
class IMManager: NSObject {

    static let shared = IMManager()

    // 消息回调
    var onMessageReceived: ((Message) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?
    var onMessageStatusUpdate: ((Message) -> Void)?
    var onChannelInfoUpdate: ((WKChannelInfo) -> Void)?
    var onConversationUpdate: (([WuKongIMSDK.WKConversation]) -> Void)?
    var onConversationUnreadUpdate: ((WKChannel, Int) -> Void)?
    var onConversationDelete: ((WKChannel) -> Void)?
    var onTotalUnreadCountChanged: ((Int) -> Void)?

    private var isSetup = false

    static let messageReceivedNotification = NSNotification.Name("IMMessageReceived")
    static let messageStatusUpdateNotification = NSNotification.Name("IMMessageStatusUpdate")
    static let connectionStatusChangedNotification = NSNotification.Name("IMConnectionStatusChanged")
    static let channelInfoUpdateNotification = NSNotification.Name("IMChannelInfoUpdate")
    static let conversationUpdateNotification = NSNotification.Name("IMConversationUpdate")
    static let conversationUnreadUpdateNotification = NSNotification.Name("IMConversationUnreadUpdate")
    static let conversationDeleteNotification = NSNotification.Name("IMConversationDelete")
    static let totalUnreadCountChangedNotification = NSNotification.Name("IMTotalUnreadCountChanged")

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
        WKSDK.shared().channelManager.add(self)
        WKSDK.shared().conversationManager.add(self)

        // 设置频道信息提供者
        setupChannelInfoProvider()

        // 设置会话同步提供者
        setupConversationProvider()
    }

    // MARK: - 设置频道信息提供者
    private func setupChannelInfoProvider() {
        WKSDK.shared().channelInfoUpdate = { [weak self] channel, callback in
            guard let self = self else {
                callback(nil, false)
                return nil
            }

            let channelId = channel.channelId ?? ""
            let channelType = Int(channel.channelType)

            Task {
                do {
                    let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                        .getChannelInfo(channelId: channelId, channelType: channelType)
                    )

                    // 转换为 WKChannelInfo
                    let wkInfo = WKChannelInfo()
                    wkInfo.channel = channel
                    wkInfo.name = info.name ?? ""
                    wkInfo.logo = info.logo ?? info.avatar ?? ""
                    wkInfo.remark = info.remark ?? ""
                    wkInfo.status = info.status ?? 0
                    wkInfo.online = (info.online ?? 0) == 1

                    // 处理 follow 状态
                    if let follow = info.follow {
                        wkInfo.follow = WKChannelInfoFollow(rawValue: UInt(follow)) ?? WKChannelInfoFollow(rawValue: 0)
                    }

                    // 保存到 SDK
                    WKSDK.shared().channelManager.addOrUpdate(wkInfo)

                    DispatchQueue.main.async {
                        callback(nil, false)
                    }
                } catch {
                    print("[IM] 获取频道信息失败: \(error)")
                    DispatchQueue.main.async {
                        callback(error, false)
                    }
                }
            }

            return nil
        }
    }

    // MARK: - 设置会话同步提供者
    private func setupConversationProvider() {
        // 会话同步提供者
        WKSDK.shared().conversationManager.setSyncConversationProviderAndAck({ [weak self] version, lastMsgSeqs, callback in
            guard let self = self else { return }

            Task {
                do {
                    let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
                    let uid = UserDefaults.standard.string(forKey: "uid") ?? ""

                    // 构造请求参数
                    let params: [String: Any] = [
                        "uid": uid,
                        "last_msg_seqs": lastMsgSeqs ?? "",
                        "msg_count": 100,
                        "version": version,
                        "device_uuid": deviceUUID
                    ]

                    let data = try JSONSerialization.data(withJSONObject: params)

                    // 使用 Alamofire 或 URLSession 发送请求
                    let url = URL(string: APIConfig.apiBaseURL + "/v1/conversation/sync")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = data
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    if let token = UserDefaults.standard.string(forKey: "token") {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }

                    let (responseData, _) = try await URLSession.shared.data(for: request)

                    // 解析为 WKSyncConversationWrapModel
                    let wrapModel = WKSyncConversationWrapModel()
                    if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                        if let conversations = json["conversations"] as? [[String: Any]] {
                            var wkConversations = [WuKongIMSDK.WKConversation]()
                            for convDict in conversations {
                                let conv = WuKongIMSDK.WKConversation()
                                if let channelId = convDict["channel_id"] as? String,
                                   let channelType = convDict["channel_type"] as? Int {
                                    let ch = WKChannel()
                                    ch.channelId = channelId
                                    ch.channelType = UInt8(channelType)
                                    conv.channel = ch
                                }
                                conv.lastMsgTimestamp = convDict["timestamp"] as? Int ?? 0
                                conv.unreadCount = convDict["unread"] as? Int ?? 0
                                conv.lastMessageSeq = UInt32(convDict["last_msg_seq"] as? Int ?? 0)
                                conv.version = convDict["version"] as? Int64 ?? 0
                                wkConversations.append(conv)
                            }
                            wrapModel.conversations = wkConversations
                        }
                    }

                    DispatchQueue.main.async {
                        callback(wrapModel, nil)
                    }
                } catch {
                    print("[IM] 同步会话失败: \(error)")
                    DispatchQueue.main.async {
                        callback(nil, error)
                    }
                }
            }
        }, ack: { cmdVersion, complete in
            // 同步ACK
            print("[IM] 会话同步ACK, version: \(cmdVersion)")
            complete?(nil)
        })
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

// MARK: - WKChannelManagerDelegate
extension IMManager: WKChannelManagerDelegate {

    func channelInfoUpdate(_ channelInfo: WKChannelInfo!) {
        guard let info = channelInfo else { return }
        DispatchQueue.main.async {
            self.onChannelInfoUpdate?(info)
            NotificationCenter.default.post(name: IMManager.channelInfoUpdateNotification, object: info)
        }
    }

    func channelInfoUpdate(_ channelInfo: WKChannelInfo!, oldChannelInfo: WKChannelInfo?) {
        guard let info = channelInfo else { return }
        DispatchQueue.main.async {
            self.onChannelInfoUpdate?(info)
            NotificationCenter.default.post(name: IMManager.channelInfoUpdateNotification, object: info)
        }
    }
}

// MARK: - 频道管理
extension IMManager {

    // MARK: 获取频道信息
    func getChannelInfo(channelId: String, channelType: Int = 1) -> WKChannelInfo? {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        return WKSDK.shared().channelManager.getChannelInfo(channel)
    }

    // MARK: 获取用户频道信息
    func getChannelInfoOfUser(uid: String) -> WKChannelInfo? {
        return WKSDK.shared().channelManager.getChannelInfo(ofUser: uid)
    }

    // MARK: 拉取频道信息（从服务器）
    func fetchChannelInfo(channelId: String, channelType: Int = 1, completion: ((WKChannelInfo?) -> Void)? = nil) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        WKSDK.shared().channelManager.fetchChannelInfo(channel) { channelInfo in
            DispatchQueue.main.async {
                completion?(channelInfo)
            }
        }
    }

    // MARK: 更新频道设置（置顶/免打扰）
    func updateChannelSetting(channelId: String, channelType: Int = 1, setting: [String: Any]) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        WKSDK.shared().channelManager.updateChannelSetting(channel, setting: setting)
    }

    // MARK: 设置置顶
    func setChannelStick(channelId: String, channelType: Int = 1, stick: Bool) {
        updateChannelSetting(channelId: channelId, channelType: channelType, setting: ["stick": stick])
    }

    // MARK: 设置免打扰
    func setChannelMute(channelId: String, channelType: Int = 1, mute: Bool) {
        updateChannelSetting(channelId: channelId, channelType: channelType, setting: ["mute": mute])
    }

    // MARK: 添加/更新频道信息
    func addOrUpdateChannelInfo(_ channelInfo: WKChannelInfo) {
        WKSDK.shared().channelManager.addOrUpdate(channelInfo)
    }

    // MARK: 删除频道信息
    func deleteChannelInfo(channelId: String, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        WKSDK.shared().channelManager.deleteChannelInfo(channel)
    }
}

// MARK: - WKConversationManagerDelegate
extension IMManager: WKConversationManagerDelegate {

    func onConversationUpdate(_ conversations: [WKConversation]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let sdkConversations = conversations as [WuKongIMSDK.WKConversation]
            self.onConversationUpdate?(sdkConversations)
            NotificationCenter.default.post(name: IMManager.conversationUpdateNotification, object: sdkConversations)

            // 通知总未读数变化
            let totalUnread = WKSDK.shared().conversationManager.getAllConversationUnreadCount()
            self.onTotalUnreadCountChanged?(totalUnread)
            NotificationCenter.default.post(name: IMManager.totalUnreadCountChangedNotification, object: NSNumber(value: totalUnread))
        }
    }

    func onConversationUnreadCountUpdate(_ channel: WKChannel!, unreadCount: Int) {
        guard let ch = channel else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onConversationUnreadUpdate?(ch, unreadCount)
            NotificationCenter.default.post(name: IMManager.conversationUnreadUpdateNotification, object: [
                "channel": ch,
                "unreadCount": unreadCount
            ] as [String: Any])

            // 通知总未读数变化
            let totalUnread = WKSDK.shared().conversationManager.getAllConversationUnreadCount()
            self.onTotalUnreadCountChanged?(totalUnread)
            NotificationCenter.default.post(name: IMManager.totalUnreadCountChangedNotification, object: NSNumber(value: totalUnread))
        }
    }

    func onConversationDelete(_ channel: WKChannel!) {
        guard let ch = channel else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onConversationDelete?(ch)
            NotificationCenter.default.post(name: IMManager.conversationDeleteNotification, object: ch)

            // 通知总未读数变化
            let totalUnread = WKSDK.shared().conversationManager.getAllConversationUnreadCount()
            self.onTotalUnreadCountChanged?(totalUnread)
            NotificationCenter.default.post(name: IMManager.totalUnreadCountChangedNotification, object: NSNumber(value: totalUnread))
        }
    }

    func onConversationAllDelete() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 通知总未读数变化
            let totalUnread = WKSDK.shared().conversationManager.getAllConversationUnreadCount()
            self.onTotalUnreadCountChanged?(totalUnread)
            NotificationCenter.default.post(name: IMManager.totalUnreadCountChangedNotification, object: NSNumber(value: totalUnread))
        }
    }
}

// MARK: - 会话管理
extension IMManager {

    // MARK: 获取会话列表
    func getConversationList() -> [WuKongIMSDK.WKConversation] {
        return WKSDK.shared().conversationManager.getConversationList()
    }

    // MARK: 获取指定频道的会话
    func getConversation(channelId: String, channelType: Int = 1) -> WuKongIMSDK.WKConversation? {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        return WKSDK.shared().conversationManager.getConversation(channel)
    }

    // MARK: 获取所有会话未读数
    func getAllUnreadCount() -> Int {
        return WKSDK.shared().conversationManager.getAllConversationUnreadCount()
    }

    // MARK: 清除指定频道未读数
    func clearConversationUnread(channelId: String, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        WKSDK.shared().conversationManager.clearConversationUnreadCount(channel)
    }

    // MARK: 设置未读数
    func setConversationUnread(channelId: String, channelType: Int = 1, unread: Int) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        WKSDK.shared().conversationManager.setConversationUnreadCount(channel, unread: unread)
    }

    // MARK: 删除会话
    func deleteConversation(channelId: String, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        WKSDK.shared().conversationManager.deleteConversation(channel)
    }

    // MARK: 恢复会话
    func recoveryConversation(channelId: String, channelType: Int = 1) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        WKSDK.shared().conversationManager.recoveryConversation(channel)
    }

    // MARK: 添加会话
    func addConversation(_ conversation: WuKongIMSDK.WKConversation) {
        WKSDK.shared().conversationManager.addConversation(conversation)
    }

    // MARK: 更新或添加会话扩展（草稿等）
    func updateOrAddConversationExtra(_ extra: WKConversationExtra) {
        WKSDK.shared().conversationManager.updateOrAdd(extra)
    }

    // MARK: 设置草稿
    func setDraft(channelId: String, channelType: Int = 1, draft: String) {
        let channel = WKChannel()
        channel.channelId = channelId
        channel.channelType = UInt8(channelType)
        let extra = WKConversationExtra()
        extra.channel = channel
        extra.draft = draft
        updateOrAddConversationExtra(extra)
    }

    // MARK: 获取草稿（通过extra方式获取）
    func getDraft(channelId: String, channelType: Int = 1) -> String? {
        // 草稿存储在 WKConversationExtra 中，这里暂时返回 nil
        // 实际项目中可以通过 DB 或 extra 方式获取
        return nil
    }
}
