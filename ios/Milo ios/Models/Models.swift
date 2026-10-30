import Foundation
import UIKit
import WuKongIMSDK

// MARK: - 用户模型
struct User: Codable {
    var uid: String
    var name: String
    var avatar: String?
    var phone: String?
    var email: String?
    var gender: Int?
    var sign: String?

    var avatarURL: URL? {
        guard let avatar = avatar, !avatar.isEmpty else { return nil }
        if avatar.hasPrefix("http") {
            return URL(string: avatar)
        }
        let path = avatar.hasPrefix("/") ? avatar : "/\(avatar)"
        return URL(string: APIConfig.apiBaseURL + path)
    }

    init(uid: String = "", name: String = "", avatar: String? = nil, phone: String? = nil, email: String? = nil, gender: Int? = nil, sign: String? = nil) {
        self.uid = uid
        self.name = name
        self.avatar = avatar
        self.phone = phone
        self.email = email
        self.gender = gender
        self.sign = sign
    }
}

// MARK: - 频道信息（WuKongIM /channels/{id}/{type} 响应）
struct ChannelInfo: Codable {
    var channel_id: String?
    var channel_type: Int?
    var name: String?
    var logo: String?
    var avatar: String?
    var remark: String?
    var online: Int?
    /// 最后离线时间（秒级时间戳，与 Android lastOffline 一致）
    var last_offline: Int?
    var status: Int?
    var follow: Int?
    /// 当前用户在群内的角色（1 群主 2 管理员 0 普通成员），仅群频道返回
    var role: Int?
    var extra: [String: AnyCodable]?

    var displayName: String {
        return remark?.isEmpty == false ? remark! : (name ?? "")
    }

    var avatarURL: URL? {
        let avatarStr = logo ?? avatar ?? ""
        guard !avatarStr.isEmpty else { return nil }
        if avatarStr.hasPrefix("http") {
            return URL(string: avatarStr)
        }
        let path = avatarStr.hasPrefix("/") ? avatarStr : "/\(avatarStr)"
        return URL(string: APIConfig.apiBaseURL + path)
    }

    func toUser() -> User {
        return User(
            uid: channel_id ?? "",
            name: displayName,
            avatar: logo ?? avatar
        )
    }
}

// MARK: - AnyCodable (用于解码动态JSON)
struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) { value = intValue }
        else if let doubleValue = try? container.decode(Double.self) { value = doubleValue }
        else if let stringValue = try? container.decode(String.self) { value = stringValue }
        else if let boolValue = try? container.decode(Bool.self) { value = boolValue }
        else { value = "" }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int { try container.encode(intValue) }
        else if let doubleValue = value as? Double { try container.encode(doubleValue) }
        else if let stringValue = value as? String { try container.encode(stringValue) }
        else if let boolValue = value as? Bool { try container.encode(boolValue) }
        else { try container.encodeNil() }
    }
}

// MARK: - WuKongIM 会话同步响应 (POST /conversation/sync 响应)
struct WKSyncChat: Codable {
    var uid: String?
    var conversations: [WKConversation]?
}

// MARK: - WuKongIM 会话模型
struct WKConversation: Codable {
    var channel_id: String?
    var channel_type: Int?
    var unread: Int?
    var timestamp: Int64?
    var last_msg_seq: Int?
    var version: Int?
    var recents: [WKMessageData]?

    enum CodingKeys: String, CodingKey {
        case channel_id, channel_type, unread, timestamp
        case last_msg_seq, version, recents
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        channel_id = try c.decodeIfPresent(String.self, forKey: .channel_id)
        channel_type = try c.decodeIfPresent(Int.self, forKey: .channel_type)
        unread = try c.decodeIfPresent(Int.self, forKey: .unread)
        last_msg_seq = try c.decodeIfPresent(Int.self, forKey: .last_msg_seq)
        version = try c.decodeIfPresent(Int.self, forKey: .version)
        recents = try c.decodeIfPresent([WKMessageData].self, forKey: .recents)
        // timestamp can be Int or String
        if let v = try? c.decodeIfPresent(Int64.self, forKey: .timestamp) {
            timestamp = v
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .timestamp), let v = Int64(s) {
            timestamp = v
        } else {
            timestamp = nil
        }
    }

    var isGroup: Bool { return channel_type == 2 }
}

// MARK: - WuKongIM 消息数据 (会话同步和消息同步中的消息对象)
struct WKMessageData: Codable {
    var message_id: Int64?
    var message_idstr: String?
    var client_msg_no: String?
    var message_seq: Int?
    var from_uid: String?
    var channel_id: String?
    var channel_type: Int?
    var timestamp: Int64?
    var payload: String?
    /// 当 payload 是字典而非 base64 字符串时，存储原始字典
    var payloadDict: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case message_id, message_idstr, client_msg_no, message_seq
        case from_uid, channel_id, channel_type, timestamp, payload
        case seq // 兼容 seq 字段（部分 API 返回 seq 而非 message_seq）
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        message_idstr = try c.decodeIfPresent(String.self, forKey: .message_idstr)
        client_msg_no = try c.decodeIfPresent(String.self, forKey: .client_msg_no)
        from_uid = try c.decodeIfPresent(String.self, forKey: .from_uid)
        channel_id = try c.decodeIfPresent(String.self, forKey: .channel_id)
        channel_type = try c.decodeIfPresent(Int.self, forKey: .channel_type)

        // message_seq: 兼容 message_seq 和 seq 两种字段名
        if let seq = try c.decodeIfPresent(Int.self, forKey: .message_seq) {
            message_seq = seq
        } else if let seq = try c.decodeIfPresent(Int.self, forKey: .seq) {
            message_seq = seq
        } else {
            message_seq = nil
        }

        // timestamp can be Int or String
        if let v = try? c.decodeIfPresent(Int64.self, forKey: .timestamp) {
            timestamp = v
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .timestamp), let v = Int64(s) {
            timestamp = v
        } else {
            timestamp = nil
        }
        // message_id can be Int or String in JSON
        if let v = try? c.decodeIfPresent(Int64.self, forKey: .message_id) {
            message_id = v
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .message_id), let v = Int64(s) {
            message_id = v
        } else {
            message_id = nil
        }

        // payload: 兼容 String (base64) 和 Dictionary 两种格式
        if let payloadStr = try? c.decodeIfPresent(String.self, forKey: .payload) {
            payload = payloadStr
            payloadDict = nil
        } else if let payloadDict = try? c.decodeIfPresent([String: AnyCodable].self, forKey: .payload) {
            // payload 是字典格式，转为 [String: Any] 并同时序列化为 JSON 字符串存入 payload
            var dict = [String: Any]()
            for (key, value) in payloadDict {
                dict[key] = value.value
            }
            self.payloadDict = dict
            // 将字典转回 JSON 字符串，保持 payload 字段兼容
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
               let jsonStr = String(data: jsonData, encoding: .utf8) {
                // 注意：这里存的是原始 JSON 字符串，不是 base64
                // decodedPayload 会识别并正确处理
                self.payload = jsonStr
            } else {
                self.payload = nil
            }
        } else {
            payload = nil
            payloadDict = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(message_id, forKey: .message_id)
        try c.encodeIfPresent(message_idstr, forKey: .message_idstr)
        try c.encodeIfPresent(client_msg_no, forKey: .client_msg_no)
        try c.encodeIfPresent(message_seq, forKey: .message_seq)
        try c.encodeIfPresent(from_uid, forKey: .from_uid)
        try c.encodeIfPresent(channel_id, forKey: .channel_id)
        try c.encodeIfPresent(channel_type, forKey: .channel_type)
        try c.encodeIfPresent(timestamp, forKey: .timestamp)
        // payload: 如果有字典格式，序列化为 JSON 字符串后编码
        if let dict = payloadDict {
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
               let jsonStr = String(data: jsonData, encoding: .utf8) {
                try c.encode(jsonStr, forKey: .payload)
            } else {
                try c.encodeIfPresent(payload, forKey: .payload)
            }
        } else {
            try c.encodeIfPresent(payload, forKey: .payload)
        }
    }

    var messageIDString: String {
        if let str = message_idstr, !str.isEmpty { return str }
        if let id = message_id { return String(id) }
        return client_msg_no ?? UUID().uuidString
    }

    /// 将任意 JSON 对象归一化为字典（兼容 JSON 字符串外层再包一层的情况）
    private static func dictionary(fromJSONObject object: Any) -> [String: Any]? {
        if let dict = object as? [String: Any] { return dict }
        if let str = object as? String,
           let data = str.data(using: .utf8),
           let inner = try? JSONSerialization.jsonObject(with: data) {
            return dictionary(fromJSONObject: inner)
        }
        return nil
    }

    private static func dictionary(fromJSONString string: String) -> [String: Any]? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.hasPrefix("{") || trimmed.hasPrefix("\"") else { return nil }
        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
        return dictionary(fromJSONObject: object)
    }

    /// base64 → UTF-8 文本；仅接受可读文本，避免把普通字符串误判为 base64
    private static func base64DecodedText(_ string: String) -> String? {
        let compact = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard compact.count >= 8, !compact.contains("{"), !compact.contains("["),
              let data = Data(base64Encoded: compact),
              let text = String(data: data, encoding: .utf8),
              !text.isEmpty else { return nil }
        return text
    }

    /// 清理不可见控制字符与替换字符，避免出现乱码方框
    private static func sanitizedText(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            if scalar == "\n" || scalar == "\t" || scalar == "\r" {
                result.append(String(scalar))
                continue
            }
            if CharacterSet.controlCharacters.contains(scalar) { continue }
            if scalar.value == 0xFFFD { continue }
            result.append(String(scalar))
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 将payload字典归一化为 [String: Any]
    private var payloadJSONDict: [String: Any]? {
        if let dict = payloadDict { return dict }
        guard let payload = payload, !payload.isEmpty else { return nil }
        if let dict = WKMessageData.dictionary(fromJSONString: payload) { return dict }
        if let text = WKMessageData.base64DecodedText(payload),
           let dict = WKMessageData.dictionary(fromJSONString: text) { return dict }
        return nil
    }

    private static func anyToInt(_ v: Any?) -> Int {
        if let i = v as? Int { return i }
        if let n = v as? NSNumber { return n.intValue }
        if let s = v as? String { return Int(s) ?? 0 }
        return 0
    }

    private static func anyToDouble(_ v: Any?) -> Double {
        if let d = v as? Double { return d }
        if let n = v as? NSNumber { return n.doubleValue }
        if let s = v as? String { return Double(s) ?? 0 }
        return 0
    }

    /// 解析payload为 (type, content)，content格式与各消息Cell约定一致
    var decodedPayload: (type: Int, content: String) {
        // ① base64→JSON / ② 直接 JSON（含 JSON 字符串外层包裹）
        if let dict = payloadJSONDict {
            return WKMessageData.decode(dictionary: dict)
        }
        guard let raw = payload, !raw.isEmpty else { return (1, "") }
        // ③ base64 解码出的纯文本（或再包一层的 JSON 字符串）
        if let text = WKMessageData.base64DecodedText(raw) {
            let cleaned = WKMessageData.sanitizedText(text)
            if let dict = WKMessageData.dictionary(fromJSONString: cleaned) {
                return WKMessageData.decode(dictionary: dict)
            }
            if !cleaned.isEmpty { return (1, cleaned) }
        }
        // ④ 原始 payload 本身就是可读文本
        let cleanedRaw = WKMessageData.sanitizedText(raw)
        if let dict = WKMessageData.dictionary(fromJSONString: cleanedRaw) {
            return WKMessageData.decode(dictionary: dict)
        }
        // ⑤ 完全不可读：返回空文本，由上层过滤掉，避免乱码方框
        return (1, cleanedRaw)
    }

    /// 按 payload 的 type 映射到各消息 Cell 约定的 content 格式
    private static func decode(dictionary dict: [String: Any]) -> (type: Int, content: String) {
        var type = anyToInt(dict["type"])
        let str: (String) -> String = { key in
            if let s = dict[key] as? String { return s }
            if let n = dict[key] as? NSNumber { return n.stringValue }
            return ""
        }
        switch type {
        case 1: // 文本
            let c = str("content")
            return (type, c.isEmpty ? str("text") : c)
        case 2: // 图片: content = url（部分端把地址放在 content）
            let url = str("url").isEmpty ? str("content") : str("url")
            return (type, url)
        case 3: // 语音: "duration|url"
            let duration = anyToInt(dict["duration"] ?? dict["second"] ?? dict["time_tradition"])
            let url = str("url").isEmpty ? str("voice_url") : str("url")
            return (type, "\(duration)|\(url)")
        case 4: // 视频: "thumbURL|videoURL"（兼容安卓驼峰字段）
            let thumb = firstNonEmpty([str("thumb_url"), str("thumbURL"), str("thumbUrl"), str("thumb"), str("cover")])
            let video = firstNonEmpty([str("video_url"), str("videoURL"), str("videoUrl"), str("url"), str("video")])
            return (type, "\(thumb)|\(video)")
        case 5: // 文件: "fileName|fileSize|url"
            let name = str("file_name").isEmpty ? str("name") : str("file_name")
            let size = anyToInt(dict["file_size"] ?? dict["size"])
            return (type, "\(name)|\(size)|\(str("url"))")
        case 6: // 位置: "name\naddress|lat,lng"（兼容安卓 title/address/lat/lng）
            let name = firstNonEmpty([str("title"), str("name")])
            let address = str("address")
            let lat = anyToDouble(dict["lat"] ?? dict["latitude"])
            let lng = anyToDouble(dict["lng"] ?? dict["longitude"])
            let displayName = address.isEmpty ? name : "\(name)\n\(address)"
            return (type, "\(displayName)|\(lat),\(lng)")
        case 7: // 名片: "uid|name|avatar|vercode"
            return (type, "\(str("uid"))|\(str("name"))|\(str("avatar"))|\(str("vercode"))")
        case 100: // 笔记: 优先note_json，否则整体JSON
            if let noteJSON = dict["note_json"] as? String, !noteJSON.isEmpty {
                return (type, noteJSON)
            }
            if let n = dict["note"] {
                if let s = n as? String, !s.isEmpty {
                    return (type, s)
                }
                if let data = try? JSONSerialization.data(withJSONObject: n),
                   let s = String(data: data, encoding: .utf8) {
                    return (type, s)
                }
            }
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let s = String(data: data, encoding: .utf8) {
                return (type, s)
            }
            return (type, "")
        case 9989: // 通话结果：保留完整 JSON 供 CallMessageCell 解析（call_type/result_type/second）
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let s = String(data: data, encoding: .utf8) {
                return (type, s)
            }
            return (type, "")
        default:
            // 兼容安卓端未带 type 或字段不同的笔记消息
            if dict["note_json"] != nil || (dict["title"] != nil && dict["content"] != nil && str("blocks").isEmpty) {
                let payload = (dict["note_json"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                if let p = payload { return (100, p) }
                if let data = try? JSONSerialization.data(withJSONObject: dict),
                   let s = String(data: data, encoding: .utf8) {
                    return (100, s)
                }
            }
            if (1000...2000).contains(type) {
                // 系统/群事件消息：content+extra 重新打包为 JSON，供 SystemMessageCell 替换 {0} 占位符
                var repack: [String: Any] = ["content": str("content")]
                if let extra = dict["extra"] { repack["extra"] = extra }
                if let data = try? JSONSerialization.data(withJSONObject: repack),
                   let s = String(data: data, encoding: .utf8) {
                    return (type, s)
                }
                return (type, str("content"))
            }
            // 未知消息：优先可读文本，其次保留原始 type
            let content = str("content")
            if content.isEmpty {
                type = 1
            }
            return (type, content)
        }
    }

    /// 取第一个非空字符串（兼容不同端字段命名）
    private static func firstNonEmpty(_ values: [String]) -> String {
        for v in values where !v.isEmpty { return v }
        return ""
    }
}

// MARK: - WuKongIM 消息同步响应 (POST /channel/messagesync)
struct WKMessageSyncResponse: Codable {
    var start_message_seq: Int?
    var end_message_seq: Int?
    var more: Int?
    var messages: [WKMessageData]?
}

// MARK: - 好友同步响应
struct FriendSyncInfo: Codable {
    var uid: String
    var name: String?
    var avatar: String?
    var remark: String?

    var displayName: String {
        return remark?.isEmpty == false ? remark! : (name ?? uid)
    }

    var avatarURL: URL? {
        guard let avatar = avatar, !avatar.isEmpty else { return nil }
        if avatar.hasPrefix("http") {
            return URL(string: avatar)
        }
        let path = avatar.hasPrefix("/") ? avatar : "/\(avatar)"
        return URL(string: APIConfig.apiBaseURL + path)
    }

    func toUser() -> User {
        return User(uid: uid, name: displayName, avatar: avatar)
    }
}

// MARK: - 消息模型
enum MessageType: Int, Codable {
    case text = 1
    case image = 2
    case voice = 3
    case video = 4
    case file = 5
    case location = 6
    case card = 7
    case note = 100
    case system = 99
    case call = 9989 // 通话结果消息（对齐安卓 WKRTCType.WK_P2P_CALL）
    case multiForward = 9
}

struct Message: Codable {
    var messageID: String
    var channelID: String
    var channelType: Int
    var fromUID: String
    var content: String
    var type: MessageType
    var timestamp: Int64
    var status: Int
    var messageSeq: Int
    /// SDK 发送时的 clientMsgNo（本地占位消息 messageID 为 UUID，靠它与 sendack 回执关联，撤回/已读都依赖该映射）
    /// 不入 CodingKeys：旧缓存无此字段可正常解码，且只有本会话发送的消息需要它
    var clientMsgNo: String = ""

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case channelID = "channel_id"
        case channelType = "channel_type"
        case fromUID = "from_uid"
        case content
        case type
        case timestamp
        case status
        case messageSeq = "message_seq"
    }

    var isFromMe: Bool {
        return fromUID == UserDefaults.standard.string(forKey: "uid")
    }

    init(messageID: String, channelID: String, channelType: Int, fromUID: String, content: String, type: MessageType, timestamp: Int64, status: Int, messageSeq: Int = 0, clientMsgNo: String = "") {
        self.messageID = messageID
        self.channelID = channelID
        self.channelType = channelType
        self.fromUID = fromUID
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.status = status
        self.messageSeq = messageSeq
        self.clientMsgNo = clientMsgNo
    }

    init(from wk: WKMessageData) {
        self.messageID = wk.messageIDString
        self.channelID = wk.channel_id ?? ""
        self.channelType = wk.channel_type ?? 1
        self.fromUID = wk.from_uid ?? ""
        self.clientMsgNo = wk.client_msg_no ?? ""
        let decoded = wk.decodedPayload
        self.content = decoded.content
        // 与安卓一致：contentType 1000~2000 为系统/群事件消息（邀请入群、退群等）
        if (1000...2000).contains(decoded.type) {
            self.type = .system
        } else {
            self.type = MessageType(rawValue: decoded.type) ?? .text
        }
        self.timestamp = (wk.timestamp ?? 0) * 1000
        self.status = 1
        self.messageSeq = wk.message_seq ?? 0
    }

    var timeString: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 会话模型
struct Conversation: Codable {
    var channelID: String
    var channelType: Int
    var name: String
    var avatar: String?
    var lastMessage: String?
    var lastMessageTimestamp: Int64?
    var unreadCount: Int
    var lastMsgSeq: Int
    var lastMessageType: Int

    enum CodingKeys: String, CodingKey {
        case channelID = "channel_id"
        case channelType = "channel_type"
        case name
        case avatar
        case lastMessage = "last_message"
        case lastMessageTimestamp = "last_message_timestamp"
        case unreadCount = "unread_count"
        case lastMsgSeq = "last_msg_seq"
        case lastMessageType = "last_message_type"
    }

    var isGroup: Bool {
        return channelType == 2
    }

    var avatarURL: URL? {
        guard let avatar = avatar, !avatar.isEmpty else { return nil }
        if avatar.hasPrefix("http") {
            return URL(string: avatar)
        }
        let path = avatar.hasPrefix("/") ? avatar : "/\(avatar)"
        return URL(string: APIConfig.apiBaseURL + path)
    }

    var timeString: String {
        guard let ts = lastMessageTimestamp, ts > 0 else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(ts / 1000))
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨天"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }

    /// 会话列表显示的最后一条消息（带类型前缀，与Android一致）
    var lastMessageDisplay: String {
        guard let msg = lastMessage, !msg.isEmpty else { return "" }
        switch lastMessageType {
        case MessageType.image.rawValue: return "[图片]"
        case MessageType.voice.rawValue: return "[语音]"
        case MessageType.video.rawValue: return "[视频]"
        case MessageType.file.rawValue: return "[文件]"
        case MessageType.location.rawValue: return "[位置]"
        case MessageType.card.rawValue: return "[名片]"
        case MessageType.note.rawValue: return "[笔记]"
        case MessageType.call.rawValue:
            // 对齐安卓 RTCMsgContent.getDisplayContent：按 call_type 区分语音/视频
            if let data = msg.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let ct = (json["call_type"] as? Int) ?? (json["call_type"] as? NSNumber)?.intValue ?? 0
                return ct == 1 ? "[视频通话]" : "[语音通话]"
            }
            return "[语音通话]"
        case MessageType.system.rawValue: return parseSystemPreview(msg)
        default:
            // WuKongIM 系统/群事件消息 contentType 1000~2000（邀请入群、退群等）
            if (1000...2000).contains(lastMessageType) {
                return parseSystemPreview(msg)
            }
            return msg
        }
    }

    /// 系统消息会话列表预览：从 JSON content 里提取纯文本 + extra 替换 {0}/{1} 占位符
    private func parseSystemPreview(_ content: String) -> String {
        guard !content.isEmpty else { return "" }
        // 尝试解析为 JSON（WKMessageData.decode default 分支重打包的格式）
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // 不是 JSON（裸模板），清理占位符后返回
            return Self.stripLeftoverPlaceholders(content)
        }
        // 从 JSON 中取模板 content
        guard let template = json["content"] as? String, !template.isEmpty else {
            return Self.stripLeftoverPlaceholders(content)
        }
        // extra 数组：[{"name":"xxx"}, ...] —— 按序替换 {0}/{1}/{2}
        if let extra = json["extra"] as? [[String: Any]] {
            var result = template
            for (index, item) in extra.enumerated() {
                let name = item["name"] as? String ?? item["value"] as? String ?? ""
                result = result.replacingOccurrences(of: "{\(index)}", with: name)
            }
            return Self.stripLeftoverPlaceholders(result)
        }
        // extra 单对象
        if let extraObj = json["extra"] as? [String: Any],
           let name = extraObj["name"] as? String {
            return Self.stripLeftoverPlaceholders(template.replacingOccurrences(of: "{0}", with: name))
        }
        return Self.stripLeftoverPlaceholders(template)
    }

    /// 清理残留的 {n} 占位符
    private static func stripLeftoverPlaceholders(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "\\{\\d+\\}") else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "").trimmingCharacters(in: .whitespaces)
    }

    init(channelID: String, channelType: Int, name: String, avatar: String?, lastMessage: String?, lastMessageTimestamp: Int64?, unreadCount: Int, lastMsgSeq: Int = 0, lastMessageType: Int = 1) {
        self.channelID = channelID
        self.channelType = channelType
        self.name = name
        self.avatar = avatar
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCount = unreadCount
        self.lastMsgSeq = lastMsgSeq
        self.lastMessageType = lastMessageType
    }

    init(from wk: WKConversation) {
        self.channelID = wk.channel_id ?? ""
        self.channelType = wk.channel_type ?? 1
        self.name = ""
        self.avatar = nil
        let recent = wk.recents?.last
        if let r = recent {
            let decoded = r.decodedPayload
            self.lastMessage = decoded.content
            self.lastMessageType = decoded.type
        } else {
            self.lastMessage = nil
            self.lastMessageType = 1
        }
        self.lastMessageTimestamp = wk.timestamp.map { $0 * 1000 }
        self.unreadCount = wk.unread ?? 0
        self.lastMsgSeq = wk.last_msg_seq ?? 0
    }
}

// MARK: - 群组模型
struct Group: Codable {
    var groupID: String
    var name: String
    var avatar: String?
    var notice: String?
    var memberCount: Int?
    var ownerUid: String?
    var myRole: Int?
    var joinApproval: Bool?
    var muteAll: Bool?
    var forbidAddFriend: Bool?
    var forbidTempChat: Bool?
    var forbidNewViewHistory: Bool?
    var messageDisturb: Bool?
    var chatTop: Bool?
    var savedToContacts: Bool?
    var showGroupNickname: Bool?
    var myNickname: String?
    var members: [GroupMember]?

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case name
        case avatar
        case notice
        case memberCount = "member_count"
        case ownerUid = "owner_uid"
        case myRole = "my_role"
        case joinApproval = "join_approval"
        case muteAll = "mute_all"
        case forbidAddFriend = "forbid_add_friend"
        case forbidTempChat = "forbid_temp_chat"
        case forbidNewViewHistory = "forbid_new_view_history"
        case messageDisturb = "message_disturb"
        case chatTop = "chat_top"
        case savedToContacts = "saved_to_contacts"
        case showGroupNickname = "show_group_nickname"
        case myNickname = "my_nickname"
        case members
    }

    /// 兼容唐僧叨叨 TangSeng 群详情返回的 int 字段（invite/forbidden/mute/top/save/show_nick/group_no 等）
    private struct TangSengKeys: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(groupID: String = "", name: String = "", avatar: String? = nil, notice: String? = nil,
         memberCount: Int? = nil, ownerUid: String? = nil, myRole: Int? = nil,
         joinApproval: Bool? = nil, muteAll: Bool? = nil, forbidAddFriend: Bool? = nil,
         forbidTempChat: Bool? = nil, forbidNewViewHistory: Bool? = nil,
         messageDisturb: Bool? = nil, chatTop: Bool? = nil, savedToContacts: Bool? = nil,
         showGroupNickname: Bool? = nil, myNickname: String? = nil, members: [GroupMember]? = nil) {
        self.groupID = groupID
        self.name = name
        self.avatar = avatar
        self.notice = notice
        self.memberCount = memberCount
        self.ownerUid = ownerUid
        self.myRole = myRole
        self.joinApproval = joinApproval
        self.muteAll = muteAll
        self.forbidAddFriend = forbidAddFriend
        self.forbidTempChat = forbidTempChat
        self.forbidNewViewHistory = forbidNewViewHistory
        self.messageDisturb = messageDisturb
        self.chatTop = chatTop
        self.savedToContacts = savedToContacts
        self.showGroupNickname = showGroupNickname
        self.myNickname = myNickname
        self.members = members
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let t = try decoder.container(keyedBy: TangSengKeys.self)
        // 宽松解码 Bool：兼容 true/false 与 0/1
        func boolValue(_ key: CodingKeys) -> Bool? {
            if let v = try? c.decodeIfPresent(Bool.self, forKey: key) { return v }
            if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v == 1 }
            return nil
        }
        func tangBool(_ key: String) -> Bool? {
            guard let k = TangSengKeys(stringValue: key) else { return nil }
            if let v = try? t.decodeIfPresent(Int.self, forKey: k) { return v == 1 }
            if let v = try? t.decodeIfPresent(Bool.self, forKey: k) { return v }
            return nil
        }
        groupID = (try c.decodeIfPresent(String.self, forKey: .groupID))
            ?? (try? t.decodeIfPresent(String.self, forKey: TangSengKeys(stringValue: "group_no")!)) ?? nil
            ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar)
        notice = try c.decodeIfPresent(String.self, forKey: .notice)
        memberCount = try c.decodeIfPresent(Int.self, forKey: .memberCount)
        ownerUid = try c.decodeIfPresent(String.self, forKey: .ownerUid)
        myRole = try c.decodeIfPresent(Int.self, forKey: .myRole)
        joinApproval = boolValue(.joinApproval) ?? tangBool("invite")
        muteAll = boolValue(.muteAll) ?? tangBool("forbidden")
        forbidAddFriend = boolValue(.forbidAddFriend) ?? tangBool("forbidden_add_friend")
        forbidTempChat = boolValue(.forbidTempChat) ?? tangBool("forbid_member_send_temp_msg")
        // TangSeng 字段语义为"允许新成员查看历史"，取反得到"禁止"
        if let v = boolValue(.forbidNewViewHistory) {
            forbidNewViewHistory = v
        } else if let allow = tangBool("allow_view_history_msg") {
            forbidNewViewHistory = !allow
        } else {
            forbidNewViewHistory = nil
        }
        messageDisturb = boolValue(.messageDisturb) ?? tangBool("mute")
        chatTop = boolValue(.chatTop) ?? tangBool("top")
        savedToContacts = boolValue(.savedToContacts) ?? tangBool("save")
        showGroupNickname = boolValue(.showGroupNickname) ?? tangBool("show_nick")
        myNickname = try c.decodeIfPresent(String.self, forKey: .myNickname)
        members = try c.decodeIfPresent([GroupMember].self, forKey: .members)
    }

    var isOwner: Bool {
        let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
        return ownerUid == myUid || myRole == 1
    }

    var isAdmin: Bool {
        return myRole == 1 || myRole == 2
    }
}

// MARK: - 群成员模型
struct GroupMember: Codable {
    var uid: String
    var name: String
    var avatar: String?
    var role: Int?
    var nickname: String?
    var joinTime: Int64?
    var isMuted: Bool?
    /// membersync 返回的删除标记（1=已退出/被移除），展示时需过滤
    var isDeleted: Int?

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case avatar
        case role
        case nickname
        case joinTime = "join_time"
        case isMuted = "is_muted"
        case isDeleted = "is_deleted"
    }

    var roleText: String {
        switch role {
        case 1: return "群主"
        case 2: return "管理员"
        default: return ""
        }
    }

    var roleColor: UIColor {
        switch role {
        case 1: return .themePrimary
        case 2: return .systemOrange
        default: return .clear
        }
    }

    var avatarURL: URL? {
        guard let avatar = avatar, !avatar.isEmpty else { return nil }
        if avatar.hasPrefix("http") {
            return URL(string: avatar)
        }
        let path = avatar.hasPrefix("/") ? avatar : "/\(avatar)"
        return URL(string: APIConfig.apiBaseURL + path)
    }
}

// MARK: - 群成员列表响应
struct GroupMembersResponse: Codable {
    var list: [GroupMember]
    var total: Int
    var page: Int
    var size: Int
}

// MARK: - 好友申请模型
struct FriendApply: Codable {
    var uid: String
    var name: String
    var avatar: String?
    var remark: String?
    var status: Int
    var token: String?
    /// 0 好友申请 1 入群申请（对齐 Android NewFriendEntity.type）
    var type: Int?
    /// 入群申请时的群号/群名称
    var groupNo: String?
    var groupName: String?
}

// MARK: - API响应包装
struct APIResponse<T: Decodable>: Decodable {
    var status: Int?
    var msg: String?
    var data: T?
    var message: String?
}

// MARK: - 登录响应
struct LoginResponse: Codable {
    var uid: String?
    var token: String?
    var im_token: String?
    var short_no: String?
    var name: String?
    var username: String?
    var avatar: String?
    var phone: String?
    var zone: String?
    var email: String?
    var sex: Int?
    var short_status: Int?
    var server_id: Int?
}

// MARK: - WKMessage → 业务 Message（首屏读取 SDK 本地消息库时使用）
extension WKMessage {
    func toBusinessMessage() -> Message {
        var body = ""
        var type = MessageType.text

        switch Int(content.realContentType) {
        case 1: // 文本
            if let textContent = content as? WKTextContent { body = textContent.content ?? "" }
            type = .text
        case 2: // 图片
            if let imageContent = content as? WKImageMessageContent { body = imageContent.url }
            type = .image
        case 3: // 语音
            if let voiceContent = content as? WKVoiceMessageContent {
                body = "\(voiceContent.duration)|\(voiceContent.url)"
            }
            type = .voice
        case 4: // 视频
            if let videoContent = content as? WKVideoMessageContent {
                body = "\(videoContent.thumbURL)|\(videoContent.videoURL)"
            }
            type = .video
        case 5: // 文件
            if let fileContent = content as? WKFileMessageContent {
                body = "\(fileContent.fileName)|\(fileContent.fileSize)|\(fileContent.url)"
            }
            type = .file
        case 6: // 位置
            if let locationContent = content as? WKLocationMessageContent {
                let locName = locationContent.address.isEmpty ? locationContent.name : "\(locationContent.name)\n\(locationContent.address)"
                body = "\(locName)|\(locationContent.latitude),\(locationContent.longitude)"
            }
            type = .location
        case 7: // 名片
            if let cardContent = content as? WKCardMessageContent {
                body = "\(cardContent.uid)|\(cardContent.name)|\(cardContent.avatar)|\(cardContent.vercode)"
            }
            type = .card
        case 100: // 笔记
            if let noteContent = content as? WKNoteMessageContent {
                if !noteContent.noteJSON.isEmpty {
                    body = noteContent.noteJSON
                } else if let data = try? JSONSerialization.data(withJSONObject: [
                    "id": noteContent.noteId,
                    "title": noteContent.title,
                    "content": noteContent.noteContent
                ]), let str = String(data: data, encoding: .utf8) {
                    body = str
                }
            }
            type = .note
        default:
            if let textContent = content as? WKTextContent { body = textContent.content ?? "" }
            type = .text
        }

        let sendStatus: Int
        switch self.status.rawValue {
        case 0, 3:
            sendStatus = 0
        case 4:
            sendStatus = -1
        default:
            sendStatus = 1
        }

        return Message(
            messageID: String(messageId),
            channelID: channel.channelId ?? "",
            channelType: Int(channel.channelType),
            fromUID: fromUid ?? "",
            content: body,
            type: type,
            timestamp: Int64(timestamp) * 1000,
            status: sendStatus,
            messageSeq: Int(messageSeq)
        )
    }
}

// MARK: - TRTC UserSig 响应
struct TRTCParamsResponse: Codable {
    var sdkAppID: Int
    var userID: String
    var userSig: String
    var expire: Int

    enum CodingKeys: String, CodingKey {
        case sdkAppID = "sdk_app_id"
        case userID = "user_id"
        case userSig = "user_sig"
        case expire
    }
}
