import Foundation
import Alamofire

enum APIRouter: URLRequestConvertible {

    case login(phone: String, code: String)
    case loginWithEmail(email: String, code: String)
    case register(phone: String, code: String, name: String)
    case sendSMSCode(phone: String)
    case sendEmailCode(email: String)
    case sendLoginAuthCode(uid: String)
    case checkLoginAuth(uid: String, code: String)
    case searchGroupMembers(keyword: String, groupId: String)
    case getConversationList
    case getMessages(channelId: String, startMessageId: String, limit: Int)
    case sendTextMessage(channelId: String, content: String)
    case sendMessage(channelId: String, content: String, type: Int)
    case deleteMessage(messageId: String)
    case getContacts
    case getUserInfo(uid: String)
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

    // MARK: - URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        let url = try APIConfig.apiBaseURL.asURL().appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        let token = UserDefaults.standard.string(forKey: "token") ?? ""
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        switch self {
        case let .login(phone, code):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["phone": phone, "code": code])
        case let .register(phone, code, name):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["phone": phone, "code": code, "name": name])
        case let .sendSMSCode(phone):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["phone": phone])
        case let .getMessages(channelId, startMessageId, limit):
            let params: [String: Any] = [
                "channel_id": channelId,
                "start_message_id": startMessageId,
                "limit": limit
            ]
            request = try URLEncoding.default.encode(request, with: params)
        case let .sendTextMessage(channelId, content):
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "channel_id": channelId,
                "content": content,
                "type": 1
            ])
        case let .sendMessage(channelId, content, type):
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "channel_id": channelId,
                "content": content,
                "type": type
            ])
        case let .deleteMessage(messageId):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["message_id": messageId])
        case let .loginWithEmail(email, code):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "code": code])
        case let .sendEmailCode(email):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        case let .sendLoginAuthCode(uid):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["uid": uid])
        case let .checkLoginAuth(uid, code):
            request.httpBody = try JSONSerialization.data(withJSONObject: ["uid": uid, "code": code])
        case let .searchGroupMembers(keyword, groupId):
            request = try URLEncoding.default.encode(request, with: ["keyword": keyword, "group_id": groupId])
        case let .getUserInfo(uid):
            request = try URLEncoding.default.encode(request, with: ["uid": uid])
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
        case .loginWithEmail: return "/v1/user/login/email"
        case .register: return "/v1/user/register"
        case .sendSMSCode: return "/v1/user/sms/code"
        case .sendEmailCode: return "/v1/user/email/code"
        case .sendLoginAuthCode: return "/v1/user/login_auth/sendcode"
        case .checkLoginAuth: return "/v1/user/login_auth/check"
        case .searchGroupMembers: return "/v1/groups/members/search"
        case .getConversationList: return "/v1/conversations"
        case .getMessages: return "/v1/messages"
        case .sendTextMessage: return "/v1/messages/send"
        case .sendMessage: return "/v1/messages/send"
        case .deleteMessage: return "/v1/messages/delete"
        case .getContacts: return "/v1/friends"
        case .getUserInfo: return "/v1/users/info"
        case .updateUserInfo: return "/v1/users/update"
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
        }
    }

    private var method: HTTPMethod {
        switch self {
        case .getConversationList, .getMessages, .getContacts,
             .getUserInfo, .getGroupInfo, .getFriendsApply, .getTRTCUserSig,
             .getFavorites, .getGroupAnnouncement, .getDeviceList:
            return .get
        case .updateGroupAnnouncement, .updateLockAfterMinute:
            return .put
        case .deleteFavorite, .deleteLockScreenPwd, .kickDevice:
            return .delete
        default:
            return .post
        }
    }
}

// MARK: - Session
class APIClient {
    static let shared = APIClient()
    private let session: Session
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = Session(configuration: config)
        decoder = JSONDecoder()
    }

    func request<T: Decodable>(_ router: APIRouter) async throws -> T {
        let response = try await session.request(router).serializingDecodable(T.self, decoder: decoder).value
        return response
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
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
