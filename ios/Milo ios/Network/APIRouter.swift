import Foundation
import UIKit
import Alamofire

enum APIRouter: URLRequestConvertible {

    case login(username: String, password: String, device: [String: Any]?)
    case register(zone: String, phone: String, code: String, password: String)
    case sendSMSCode(phone: String)
    case sendEmailCode(email: String)
    case isRegister(phone: String?, email: String?)
    case sendForgetSMSCode(phone: String)
    case sendForgetEmailCode(email: String)
    case resetPasswordByPhone(phone: String, code: String, password: String)
    case resetPasswordByEmail(email: String, code: String, password: String)
    case sendLoginAuthCode(uid: String)
    case checkLoginAuth(uid: String, code: String)
    case searchGroupMembers(keyword: String, groupId: String)
    case syncConversations
    case syncChannelMessages(channelId: String, channelType: Int, startMessageSeq: Int, limit: Int)
    case sendTextMessage(channelId: String, content: String, channelType: Int)
    case sendMessage(channelId: String, content: String, type: Int, channelType: Int)
    case deleteMessage(messageId: String)
    case syncFriends
    case getChannelInfo(channelId: String, channelType: Int)
    case updateUserInfo(name: String?, avatar: String?)
    case getGroupInfo(groupId: String)
    case uploadFile(fileName: String, data: Data)
    case getFriendsApply
    case applyFriend(uid: String, remark: String)
    case acceptFriendApply(uid: String)
    case deleteFriend(uid: String)
    case getTRTCUserSig
    case searchMessages(keyword: String)
    case globalSearch(keyword: String, page: Int)
    case getFavorites
    case addFavorite(type: Int, content: String, extra: String?)
    case deleteFavorite(favId: Int)
    case reactMessage(messageId: String, channelId: String, channelType: Int, emoji: String)
    case getGroupAnnouncement(groupId: String)
    case updateGroupAnnouncement(groupId: String, notice: String)
    // Group management
    case getGroupMembers(groupId: String, page: Int, size: Int, keyword: String?)
    case addGroupMembers(groupId: String, uids: [String])
    case removeGroupMembers(groupId: String, uids: [String])
    case updateGroupInfo(groupId: String, name: String?, avatar: String?)
    case getGroupAdmins(groupId: String)
    case addGroupAdmin(groupId: String, uid: String)
    case removeGroupAdmin(groupId: String, uid: String)
    case transferGroupOwner(groupId: String, uid: String)
    case muteGroupMember(groupId: String, uid: String, muted: Bool)
    case getMutedMembers(groupId: String)
    case getGroupBlackList(groupId: String)
    case addToBlackList(groupId: String, uid: String)
    case removeFromBlackList(groupId: String, uid: String)
    case setJoinApproval(groupId: String, enabled: Bool)
    case setGroupMuteAll(groupId: String, muted: Bool)
    case setForbidAddFriend(groupId: String, forbidden: Bool)
    case setForbidTempChat(groupId: String, forbidden: Bool)
    case setForbidNewMemberViewHistory(groupId: String, forbidden: Bool)
    case leaveGroup(groupId: String)
    case dismissGroup(groupId: String)
    case updateMyNicknameInGroup(groupId: String, nickname: String)
    case setMessageDisturb(groupId: String, disturbed: Bool)
    case setChatTop(groupId: String, topped: Bool)
    case saveToContacts(groupId: String, saved: Bool)
    case setShowGroupNickname(groupId: String, show: Bool)
    case clearChatHistory(groupId: String)
    case getLeftGroupMembers(groupId: String)
    // Security module
    case verifyLoginPwd(pwd: String)
    case setLockScreenPwd(pwd: String)
    case deleteLockScreenPwd
    case updateLockAfterMinute(minute: Int)
    case sendBindPhoneCode(zone: String, phone: String)
    case bindPhone(zone: String, phone: String, code: String)
    case sendBindEmailCode(email: String)
    case bindEmail(email: String, code: String)
    case sendChangePwdPhoneCode(zone: String, phone: String)
    case changePwdByPhone(zone: String, phone: String, code: String, pwd: String)
    case sendChangePwdEmailCode(email: String)
    case changePwdByEmail(email: String, code: String, pwd: String)
    case sendDestroyPhoneCode(zone: String, phone: String)
    case sendDestroyEmailCode(email: String)
    case destroyAccount(account: String, code: String, type: String, zone: String)
    case logout
    // Device management
    case getDeviceList
    case kickDevice(deviceId: String)
    // IM server info
    case getIMServer(uid: String)

    // MARK: - URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        let url = try APIConfig.apiBaseURL.asURL().appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        let token = UserDefaults.standard.string(forKey: "token") ?? ""
        if !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "token")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        switch self {
        case let .login(username, password, device):
            var body: [String: Any] = ["username": username, "password": password]
            if let device = device { body["device"] = device }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        case let .register(zone, phone, code, password):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": zone, "phone": phone, "code": code, "password": password])
        case let .sendSMSCode(phone):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": "0086", "phone": phone])
        case let .isRegister(phone, email):
            var body: [String: Any] = ["zone": "0086"]
            if let phone = phone { body["phone"] = phone }
            if let email = email { body["email"] = email }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        case let .sendForgetSMSCode(phone):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": "0086", "phone": phone])
        case let .sendForgetEmailCode(email):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        case let .resetPasswordByPhone(phone, code, password):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": "0086", "phone": phone, "code": code, "pwd": password])
        case let .resetPasswordByEmail(email, code, password):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "code": code, "pwd": password])
        case .syncConversations:
            let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
            let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "uid": uid,
                "last_msg_seqs": "",
                "msg_count": 1000,
                "version": 0,
                "device_uuid": deviceUUID
            ])
        case let .syncChannelMessages(channelId, channelType, startMessageSeq, limit):
            let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "channel_id": channelId,
                "channel_type": channelType,
                "start_message_seq": startMessageSeq,
                "end_message_seq": 0,
                "limit": limit,
                "pull_mode": 0,
                "device_uuid": deviceUUID
            ])
        case let .sendTextMessage(channelId, content, channelType):
            let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
            let payloadJson = try JSONSerialization.data(withJSONObject: ["type": 1, "content": content])
            let payloadBase64 = payloadJson.base64EncodedString()
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "header": ["no_persist": 0, "red_dot": 1, "sync_once": 0],
                "from_uid": uid,
                "channel_id": channelId,
                "channel_type": channelType,
                "payload": payloadBase64
            ])
        case let .sendMessage(channelId, content, type, channelType):
            let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
            let payloadJson = try JSONSerialization.data(withJSONObject: ["type": type, "content": content])
            let payloadBase64 = payloadJson.base64EncodedString()
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "header": ["no_persist": 0, "red_dot": 1, "sync_once": 0],
                "from_uid": uid,
                "channel_id": channelId,
                "channel_type": channelType,
                "payload": payloadBase64
            ])
        case let .deleteMessage(messageId):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["message_id": messageId])
        case let .sendEmailCode(email):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        case let .sendLoginAuthCode(uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["uid": uid])
        case let .checkLoginAuth(uid, code):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["uid": uid, "code": code])
        case let .searchGroupMembers(keyword, groupId):
            request = try URLEncoding.default.encode(request, with: ["keyword": keyword, "group_id": groupId])
        case .syncFriends:
            request = try URLEncoding.default.encode(request, with: [
                "version": 0,
                "limit": 500,
                "api_version": 1
            ])
        case let .getChannelInfo(channelId, channelType):
            break
        case let .updateUserInfo(name, avatar):
            var body: [String: Any] = [:]
            if let n = name { body["name"] = n }
            if let a = avatar { body["avatar"] = a }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        case let .getGroupInfo(groupId):
            request = try URLEncoding.default.encode(request, with: ["group_id": groupId])
        case let .uploadFile(fileName, data):
            request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        case let .applyFriend(uid, remark):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["uid": uid, "remark": remark])
        case let .acceptFriendApply(uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["uid": uid])
        case let .deleteFriend(uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["uid": uid])
        case .logout:
            break
        case let .getIMServer(uid):
            break
        case let .searchMessages(keyword):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["keyword": keyword])
        case let .globalSearch(keyword, page):
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "keyword": keyword,
                "only_message": 0,
                "page": page,
                "size": 20,
                "content_types": [1, 3]
            ])
        case let .addFavorite(type, content, extra):
            var body: [String: Any] = ["type": type, "content": content]
            if let e = extra { body["extra"] = e }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        case let .deleteFavorite(favId):
            request.httpMethod = "DELETE"
        case let .reactMessage(messageId, channelId, channelType, emoji):
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "message_id": messageId,
                "channel_id": channelId,
                "channel_type": channelType,
                "emoji": emoji
            ])
        case let .updateGroupAnnouncement(groupId, notice):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["notice": notice])
        case let .getGroupMembers(groupId, page, size, keyword):
            var params: [String: Any] = ["group_id": groupId, "page": page, "size": size]
            if let kw = keyword { params["keyword"] = kw }
            request = try URLEncoding.default.encode(request, with: params)
        case let .addGroupMembers(groupId, uids):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "uids": uids])
        case let .removeGroupMembers(groupId, uids):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "uids": uids])
        case let .updateGroupInfo(groupId, name, avatar):
            var body: [String: Any] = ["group_id": groupId]
            if let n = name { body["name"] = n }
            if let a = avatar { body["avatar"] = a }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        case let .getGroupAdmins(groupId):
            request = try URLEncoding.default.encode(request, with: ["group_id": groupId])
        case let .addGroupAdmin(groupId, uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "uid": uid])
        case let .removeGroupAdmin(groupId, uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "uid": uid])
        case let .transferGroupOwner(groupId, uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "uid": uid])
        case let .muteGroupMember(groupId, uid, muted):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "uid": uid, "muted": muted])
        case let .getMutedMembers(groupId):
            request = try URLEncoding.default.encode(request, with: ["group_id": groupId])
        case let .getGroupBlackList(groupId):
            request = try URLEncoding.default.encode(request, with: ["group_id": groupId])
        case let .addToBlackList(groupId, uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "uid": uid])
        case let .removeFromBlackList(groupId, uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "uid": uid])
        case let .setJoinApproval(groupId, enabled):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "enabled": enabled])
        case let .setGroupMuteAll(groupId, muted):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "muted": muted])
        case let .setForbidAddFriend(groupId, forbidden):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "forbidden": forbidden])
        case let .setForbidTempChat(groupId, forbidden):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "forbidden": forbidden])
        case let .setForbidNewMemberViewHistory(groupId, forbidden):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "forbidden": forbidden])
        case let .leaveGroup(groupId):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId])
        case let .dismissGroup(groupId):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId])
        case let .updateMyNicknameInGroup(groupId, nickname):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "nickname": nickname])
        case let .setMessageDisturb(groupId, disturbed):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "disturbed": disturbed])
        case let .setChatTop(groupId, topped):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "topped": topped])
        case let .saveToContacts(groupId, saved):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "saved": saved])
        case let .setShowGroupNickname(groupId, show):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId, "show": show])
        case let .clearChatHistory(groupId):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["group_id": groupId])
        case let .getLeftGroupMembers(groupId):
            request = try URLEncoding.default.encode(request, with: ["group_id": groupId])
        case let .verifyLoginPwd(pwd):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["pwd": pwd])
        case let .setLockScreenPwd(pwd):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["pwd": pwd])
        case .deleteLockScreenPwd:
            break
        case let .updateLockAfterMinute(minute):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["minute": minute])
        case let .sendBindPhoneCode(zone, phone):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": zone, "phone": phone])
        case let .bindPhone(zone, phone, code):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": zone, "phone": phone, "code": code])
        case let .sendBindEmailCode(email):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        case let .bindEmail(email, code):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "code": code])
        case let .sendChangePwdPhoneCode(zone, phone):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": zone, "phone": phone])
        case let .changePwdByPhone(zone, phone, code, pwd):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": zone, "phone": phone, "code": code, "pwd": pwd])
        case let .sendChangePwdEmailCode(email):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        case let .changePwdByEmail(email, code, pwd):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "code": code, "pwd": pwd])
        case let .sendDestroyPhoneCode(zone, phone):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["zone": zone, "phone": phone])
        case let .sendDestroyEmailCode(email):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        case let .destroyAccount(account, code, type, zone):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["account": account, "code": code, "type": type, "zone": zone])
        default:
            break
        }

        return request
    }

    private var path: String {
        switch self {
        case .login: return "/v1/user/login"
        case .register: return "/v1/user/register"
        case .sendSMSCode: return "/v1/user/sms/registercode"
        case .sendEmailCode: return "/v1/user/email/registercode"
        case .isRegister: return "/v1/user/isregister"
        case .sendForgetSMSCode: return "/v1/user/sms/forgetpwd"
        case .sendForgetEmailCode: return "/v1/user/email/forgetpwd"
        case .resetPasswordByPhone: return "/v1/user/pwdforget"
        case .resetPasswordByEmail: return "/v1/user/email/pwdforget"
        case .sendLoginAuthCode: return "/v1/user/login_auth/sendcode"
        case .checkLoginAuth: return "/v1/user/login_auth/check"
        case .searchGroupMembers: return "/v1/groups/members/search"
        case .syncConversations: return "/v1/conversation/sync"
        case .syncChannelMessages: return "/v1/message/channel/sync"
        case .sendTextMessage: return "/v1/message/send"
        case .sendMessage: return "/v1/message/send"
        case .deleteMessage: return "/v1/messages/delete"
        case .syncFriends: return "/v1/friend/sync"
        case let .getChannelInfo(channelId, channelType): return "/v1/channels/\(channelId)/\(channelType)"
        case .updateUserInfo: return "/v1/user/current"
        case .getGroupInfo: return "/v1/groups/info"
        case .uploadFile: return "/v1/files/upload"
        case .getFriendsApply: return "/v1/friends/apply"
        case .applyFriend: return "/v1/friends/apply"
        case .acceptFriendApply: return "/v1/friends/accept"
        case .deleteFriend: return "/v1/friends/delete"
        case .logout: return "/v1/user/logout"
        case .getTRTCUserSig: return "/v1/trtc/usersig"
        case .searchMessages: return "/v1/messages/search"
        case .globalSearch: return "/v1/search/global"
        case .getFavorites: return "/v1/favorites"
        case .addFavorite: return "/v1/favorites"
        case .deleteFavorite(let favId): return "/v1/favorites/\(favId)"
        case .reactMessage: return "/v1/messages/react"
        case .getGroupAnnouncement(let groupId): return "/v1/groups/\(groupId)/announcement"
        case .updateGroupAnnouncement(let groupId, _): return "/v1/groups/\(groupId)/announcement"
        case .getGroupMembers: return "/v1/groups/members"
        case .addGroupMembers: return "/v1/groups/members/add"
        case .removeGroupMembers: return "/v1/groups/members/remove"
        case .updateGroupInfo: return "/v1/groups/info/update"
        case .getGroupAdmins: return "/v1/groups/admins"
        case .addGroupAdmin: return "/v1/groups/admins/add"
        case .removeGroupAdmin: return "/v1/groups/admins/remove"
        case .transferGroupOwner: return "/v1/groups/transfer"
        case .muteGroupMember: return "/v1/groups/mute/member"
        case .getMutedMembers: return "/v1/groups/mute/members"
        case .getGroupBlackList: return "/v1/groups/blacklist"
        case .addToBlackList: return "/v1/groups/blacklist/add"
        case .removeFromBlackList: return "/v1/groups/blacklist/remove"
        case .setJoinApproval: return "/v1/groups/settings/join_approval"
        case .setGroupMuteAll: return "/v1/groups/settings/mute_all"
        case .setForbidAddFriend: return "/v1/groups/settings/forbid_add_friend"
        case .setForbidTempChat: return "/v1/groups/settings/forbid_temp_chat"
        case .setForbidNewMemberViewHistory: return "/v1/groups/settings/forbid_new_view_history"
        case .leaveGroup: return "/v1/groups/leave"
        case .dismissGroup: return "/v1/groups/dismiss"
        case .updateMyNicknameInGroup: return "/v1/groups/my_nickname"
        case .setMessageDisturb: return "/v1/groups/settings/message_disturb"
        case .setChatTop: return "/v1/groups/settings/chat_top"
        case .saveToContacts: return "/v1/groups/settings/save_contacts"
        case .setShowGroupNickname: return "/v1/groups/settings/show_nickname"
        case .clearChatHistory: return "/v1/groups/clear_history"
        case .getLeftGroupMembers: return "/v1/groups/left_members"
        case .verifyLoginPwd: return "/v1/user/verify_login_pwd"
        case .setLockScreenPwd: return "/v1/user/lockscreenpwd"
        case .deleteLockScreenPwd: return "/v1/user/lockscreenpwd"
        case .updateLockAfterMinute: return "/v1/user/lock_after_minute"
        case .sendBindPhoneCode: return "/v1/user/sms/bindcode"
        case .bindPhone: return "/v1/user/bindphone"
        case .sendBindEmailCode: return "/v1/user/email/bindcode"
        case .bindEmail: return "/v1/user/bindemail"
        case .sendChangePwdPhoneCode: return "/v1/user/sms/pwdchangecode"
        case .changePwdByPhone: return "/v1/user/sms/pwdchange"
        case .sendChangePwdEmailCode: return "/v1/user/email/forgetpwd"
        case .changePwdByEmail: return "/v1/user/email/pwdchange"
        case .sendDestroyPhoneCode: return "/v1/user/sms/destroycode"
        case .sendDestroyEmailCode: return "/v1/user/email/destroycode"
        case .destroyAccount: return "/v1/user/destroy"
        case .getDeviceList: return "/v1/user/devices"
        case .kickDevice(let deviceId): return "/v1/user/devices/\(deviceId)"
        case .getIMServer(let uid): return "/v1/users/\(uid)/im"
        }
    }

    private var method: HTTPMethod {
        switch self {
        case .syncFriends, .getChannelInfo,
             .getGroupInfo, .getFriendsApply, .getTRTCUserSig,
             .getFavorites, .getGroupAnnouncement, .getDeviceList,
             .getGroupMembers, .getGroupAdmins, .getMutedMembers,
             .getGroupBlackList, .getLeftGroupMembers,
             .getIMServer:
            return .get
        case .updateGroupAnnouncement, .updateLockAfterMinute,
             .updateGroupInfo, .setJoinApproval, .setGroupMuteAll,
             .setForbidAddFriend, .setForbidTempChat, .setForbidNewMemberViewHistory,
             .updateMyNicknameInGroup, .setMessageDisturb, .setChatTop,
             .saveToContacts, .setShowGroupNickname:
            return .put
        case .deleteFavorite, .deleteLockScreenPwd, .kickDevice,
             .dismissGroup:
            return .delete
        default:
            return .post
        }
    }
}

// MARK: - Session
class APIClient {
    static let shared = APIClient()
    let session: Session
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = Session(configuration: config)
        decoder = JSONDecoder()
    }

    func request<T: Decodable>(_ router: APIRouter) async throws -> T {
        let response = await session.request(router).serializingData().response
        if let statusCode = response.response?.statusCode, !(200...299).contains(statusCode) {
            if let data = response.data {
                if let errorResp = try? JSONDecoder().decode(MessageResponse.self, from: data) {
                    throw APIError.serverError(message: errorResp.msg ?? "未知错误", code: statusCode)
                }
            }
            throw APIError.serverError(message: "请求失败(\(statusCode))", code: statusCode)
        }
        guard let data = response.data else {
            throw APIError.noData
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func requestFlexible<T: Decodable>(_ router: APIRouter) async throws -> T {
        let response = await session.request(router).serializingData().response
        if let statusCode = response.response?.statusCode, !(200...299).contains(statusCode) {
            if let data = response.data {
                if let errorResp = try? JSONDecoder().decode(MessageResponse.self, from: data) {
                    throw APIError.serverError(message: errorResp.msg ?? "未知错误", code: statusCode)
                }
                let rawStr = String(data: data, encoding: .utf8) ?? ""
                print("[API] HTTP \(statusCode): \(rawStr.prefix(500))")
            }
            throw APIError.serverError(message: "请求失败(\(statusCode))", code: statusCode)
        }
        guard let data = response.data else {
            throw APIError.noData
        }
        // Strategy 1: Direct decode as T
        if let result = try? JSONDecoder().decode(T.self, from: data) {
            return result
        }
        // Strategy 2: Wrapped in APIResponse {status, msg, data}
        if let apiResponse = try? JSONDecoder().decode(APIResponse<T>.self, from: data), let result = apiResponse.data {
            return result
        }
        // Strategy 3: Bare array response when T expects a single object with array field
        // (e.g. WuKongIM might return [...] instead of {conversations: [...]})
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let wrappedData = try JSONSerialization.data(withJSONObject: ["conversations": jsonArray])
            if let result = try? JSONDecoder().decode(T.self, from: wrappedData) {
                return result
            }
        }
        // Strategy 4: Bare object response when T expects an array
        if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let conversations = jsonObj["conversations"] as? [[String: Any]] {
                let arrData = try JSONSerialization.data(withJSONObject: conversations)
                if let result = try? JSONDecoder().decode(T.self, from: arrData) {
                    return result
                }
            }
        }
        // Strategy 5: Object with "data" field containing an array (when T is array type)
        if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let dataArr = jsonObj["data"] as? [[String: Any]] {
                let arrData = try JSONSerialization.data(withJSONObject: dataArr)
                if let result = try? JSONDecoder().decode(T.self, from: arrData) {
                    return result
                }
            }
        }
        // Strategy 6: Object with "data" field containing a dictionary (when T is object type)
        if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let dataDict = jsonObj["data"] as? [String: Any] {
                let dictData = try JSONSerialization.data(withJSONObject: dataDict)
                if let result = try? JSONDecoder().decode(T.self, from: dictData) {
                    return result
                }
            }
        }
        // Strategy 7: Object with "friends" field containing an array (friend sync response)
        if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let friendsArr = jsonObj["friends"] as? [[String: Any]] {
                let arrData = try JSONSerialization.data(withJSONObject: friendsArr)
                if let result = try? JSONDecoder().decode(T.self, from: arrData) {
                    return result
                }
            }
        }
        // Strategy 8: Object with "results" field containing an array
        if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let resultsArr = jsonObj["results"] as? [[String: Any]] {
                let arrData = try JSONSerialization.data(withJSONObject: resultsArr)
                if let result = try? JSONDecoder().decode(T.self, from: arrData) {
                    return result
                }
            }
        }
        // Strategy 9: Object with "list" field containing an array
        if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let listArr = jsonObj["list"] as? [[String: Any]] {
                let arrData = try JSONSerialization.data(withJSONObject: listArr)
                if let result = try? JSONDecoder().decode(T.self, from: arrData) {
                    return result
                }
            }
        }
        let rawStr = String(data: data, encoding: .utf8) ?? ""
        print("[API] Decode failed. Raw: \(rawStr.prefix(500))")
        throw APIError.decodingError(NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应解析失败: \(rawStr.prefix(200))"]))
    }

    func requestRaw(_ router: APIRouter) async throws -> [String: Any] {
        let response = try await session.request(router).serializingData().value
        return (try? JSONSerialization.jsonObject(with: response) as? [String: Any]) ?? [:]
    }

    func upload(data: Data, fileName: String) async throws -> String {
        let url = try APIConfig.apiBaseURL.asURL().appendingPathComponent("/v1/files/upload")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let token = UserDefaults.standard.string(forKey: "token") ?? ""
        if !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "token")
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = createMultipartBody(data: data, fileName: fileName, boundary: boundary)
        request.httpBody = body
        let responseData = try await session.request(request).serializingData().value
        let result = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        return result?["path"] as? String ?? ""
    }

    private func createMultipartBody(data: Data, fileName: String, boundary: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

// MARK: - API错误
enum APIError: LocalizedError {
    case serverError(message: String, code: Int)
    case noData
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case let .serverError(message, _):
            return message
        case .noData:
            return "网络连接失败，请检查网络后重试"
        case .decodingError:
            return "数据解析失败"
        }
    }
}

// MARK: - 验证码发送响应
struct SendCodeResponse: Codable {
    var exist: Int  // 0=未注册, 1=已注册
}

// MARK: - 检查注册响应（同 SendCodeResponse 结构）

// MARK: - 忘记密码-手机发送响应
struct ForgetSMSResponse: Codable {
    var status: Int?
    var msg: String?
}

// MARK: - 重置密码响应
struct ResetPasswordResponse: Codable {
    var status: Int?
    var msg: String?
}

// MARK: - 通用消息响应（用于错误处理）
struct MessageResponse: Codable {
    var status: Int?
    var msg: String?
}

// MARK: - IM服务器地址响应
struct IMServerResponse: Codable {
    var ip: String?
    var port: Int?
    var tcp_addr: String?
    var ws_addr: String?
}
