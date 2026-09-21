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
