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
        return URL(string: APIConfig.apiBaseURL + "/" + avatar)
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
        return URL(string: APIConfig.apiBaseURL + "/" + avatarStr)
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
    var channel_id: String
    var channel_type: Int
    var unread: Int?
    var timestamp: Int64?
    var last_msg_seq: Int?
    var version: Int?
    var recents: [WKMessageData]?

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

    var messageIDString: String {
        if let str = message_idstr, !str.isEmpty { return str }
        if let id = message_id { return String(id) }
        return client_msg_no ?? UUID().uuidString
    }

    var decodedPayload: (type: Int, content: String) {
        guard let payload = payload,
              let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (1, "")
        }
        let type = json["type"] as? Int ?? 1
        let content = json["content"] as? String ?? ""
        return (type, content)
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
        return URL(string: APIConfig.apiBaseURL + "/" + avatar)
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

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case channelID = "channel_id"
        case channelType = "channel_type"
        case fromUID = "from_uid"
        case content
        case type
        case timestamp
        case status
    }

    var isFromMe: Bool {
        return fromUID == UserDefaults.standard.string(forKey: "uid")
    }

    init(messageID: String, channelID: String, channelType: Int, fromUID: String, content: String, type: MessageType, timestamp: Int64, status: Int) {
        self.messageID = messageID
        self.channelID = channelID
        self.channelType = channelType
        self.fromUID = fromUID
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.status = status
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

    enum CodingKeys: String, CodingKey {
        case channelID = "channel_id"
        case channelType = "channel_type"
        case name
        case avatar
        case lastMessage = "last_message"
        case lastMessageTimestamp = "last_message_timestamp"
        case unreadCount = "unread_count"
    }

    var isGroup: Bool {
        return channelType == 2
    }

    var avatarURL: URL? {
        guard let avatar = avatar, !avatar.isEmpty else { return nil }
        if avatar.hasPrefix("http") {
            return URL(string: avatar)
        }
        return URL(string: APIConfig.apiBaseURL + "/" + avatar)
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

    init(channelID: String, channelType: Int, name: String, avatar: String?, lastMessage: String?, lastMessageTimestamp: Int64?, unreadCount: Int) {
        self.channelID = channelID
        self.channelType = channelType
        self.name = name
        self.avatar = avatar
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCount = unreadCount
    }

    init(from wk: WKConversation) {
        self.channelID = wk.channel_id
        self.channelType = wk.channel_type
        self.name = ""
        self.avatar = nil
        let recent = wk.recents?.last
        if let r = recent {
            let decoded = r.decodedPayload
            self.lastMessage = decoded.content
        } else {
            self.lastMessage = nil
        }
        self.lastMessageTimestamp = wk.timestamp.map { $0 * 1000 }
        self.unreadCount = wk.unread ?? 0
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
        return URL(string: APIConfig.apiBaseURL + "/" + avatar)
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
    var status: Int
    var msg: String
    var data: T?
}

// MARK: - 登录响应
struct LoginResponse: Codable {
    var uid: String?
    var token: String?
    var im_token: String?
    var short_no: String?
    var phone: String?
    var zone: String?
    var email: String?
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
