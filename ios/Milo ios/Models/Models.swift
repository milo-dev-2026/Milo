import Foundation
import UIKit

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
    var status: Int?
    var follow: Int?
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

    /// 将payload字典归一化为 [String: Any]
    private var payloadJSONDict: [String: Any]? {
        if let dict = payloadDict { return dict }
        guard let payload = payload, !payload.isEmpty else { return nil }
        if let data = Data(base64Encoded: payload),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }
        if let data = payload.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }
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
        guard let dict = payloadJSONDict else {
            // 回退：payload 不是 JSON 字典时，按纯文本处理，避免消息内容丢失显示为小点
            if let payload = payload, !payload.isEmpty {
                if let data = Data(base64Encoded: payload),
                   let text = String(data: data, encoding: .utf8), !text.isEmpty {
                    // base64 解码后若是 JSON 字符串字面量（带引号），去掉首尾引号
                    if text.count > 1, text.hasPrefix("\""), text.hasSuffix("\"") {
                        return (1, String(text.dropFirst().dropLast()))
                    }
                    return (1, text)
                }
                return (1, payload)
            }
            return (1, "")
        }
        let type = WKMessageData.anyToInt(dict["type"])
        let str = { (key: String) -> String in dict[key] as? String ?? "" }
        switch type {
        case 1: // 文本
            let c = str("content")
            return (type, c.isEmpty ? str("text") : c)
        case 2: // 图片: content = url
            return (type, str("url"))
        case 3: // 语音: "duration|url"
            let duration = WKMessageData.anyToInt(dict["duration"] ?? dict["second"] ?? dict["time_tradition"])
            return (type, "\(duration)|\(str("url"))")
        case 4: // 视频: "thumbURL|videoURL"
            let thumb = dict["thumb_url"] as? String ?? dict["thumb"] as? String ?? ""
            let video = dict["video_url"] as? String ?? str("url")
            return (type, "\(thumb)|\(video)")
        case 5: // 文件: "fileName|fileSize|url"
            let name = dict["file_name"] as? String ?? str("name")
            let size = WKMessageData.anyToInt(dict["file_size"] ?? dict["size"])
            return (type, "\(name)|\(size)|\(str("url"))")
        case 6: // 位置: "name|lat,lng"
            let name = str("name")
            let lat = WKMessageData.anyToDouble(dict["latitude"] ?? dict["lat"])
            let lng = WKMessageData.anyToDouble(dict["longitude"] ?? dict["lng"])
            return (type, "\(name)|\(lat),\(lng)")
        case 7: // 名片: "uid|name|avatar|vercode"
            return (type, "\(str("uid"))|\(str("name"))|\(str("avatar"))|\(str("vercode"))")
        case 100: // 笔记: 优先note_json，否则整体JSON
            if let noteJSON = dict["note_json"] as? String, !noteJSON.isEmpty {
                return (type, noteJSON)
            }
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let s = String(data: data, encoding: .utf8) {
                return (type, s)
            }
            return (type, "")
        default:
            return (type, str("content"))
        }
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
    case call = 8
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

    init(messageID: String, channelID: String, channelType: Int, fromUID: String, content: String, type: MessageType, timestamp: Int64, status: Int, messageSeq: Int = 0) {
        self.messageID = messageID
        self.channelID = channelID
        self.channelType = channelType
        self.fromUID = fromUID
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.status = status
        self.messageSeq = messageSeq
    }

    init(from wk: WKMessageData) {
        self.messageID = wk.messageIDString
        self.channelID = wk.channel_id ?? ""
        self.channelType = wk.channel_type ?? 1
        self.fromUID = wk.from_uid ?? ""
        let decoded = wk.decodedPayload
        self.content = decoded.content
        self.type = MessageType(rawValue: decoded.type) ?? .text
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
        default: return msg
        }
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

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case avatar
        case role
        case nickname
        case joinTime = "join_time"
        case isMuted = "is_muted"
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
