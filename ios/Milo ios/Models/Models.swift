import Foundation

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
}

// MARK: - 消息模型
enum MessageType: Int, Codable {
    case text = 1
    case image = 2
    case voice = 3
    case video = 4
    case file = 5
    case location = 6
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
}

// MARK: - 群组模型
struct Group: Codable {
    var groupID: String
    var name: String
    var avatar: String?
    var notice: String?
    var memberCount: Int?

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case name
        case avatar
        case notice
        case memberCount = "member_count"
    }
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
struct APIResponse<T: Codable>: Codable {
    var status: Int
    var msg: String
    var data: T?
}

// MARK: - 登录响应
struct LoginResponse: Codable {
    var uid: String
    var token: String
    var name: String?
    var avatar: String?
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
