import Foundation

// MARK: - 本地数据存储
class LocalStore {

    static let shared = LocalStore()
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - 用户信息
    var uid: String? {
        get { defaults.string(forKey: "uid") }
        set { defaults.set(newValue, forKey: "uid") }
    }

    var token: String? {
        get { defaults.string(forKey: "token") }
        set { defaults.set(newValue, forKey: "token") }
    }

    var name: String? {
        get { defaults.string(forKey: "name") }
        set { defaults.set(newValue, forKey: "name") }
    }

    var phone: String? {
        get { defaults.string(forKey: "phone") }
        set { defaults.set(newValue, forKey: "phone") }
    }

    var avatar: String? {
        get { defaults.string(forKey: "avatar") }
        set { defaults.set(newValue, forKey: "avatar") }
    }

    // MARK: - 应用锁屏
    var isAppLockEnabled: Bool {
        get { defaults.bool(forKey: "lock_screen_pwd_enabled") }
        set { defaults.set(newValue, forKey: "lock_screen_pwd_enabled") }
    }

    var lockPassword: String? {
        get { defaults.string(forKey: "lock_screen_pwd") }
        set { defaults.set(newValue, forKey: "lock_screen_pwd") }
    }

    var lastBackgroundTime: TimeInterval {
        get { defaults.double(forKey: "lastBackgroundTime") }
        set { defaults.set(newValue, forKey: "lastBackgroundTime") }
    }

    // MARK: - 消息设置
    var isMessageNotificationEnabled: Bool {
        get { defaults.object(forKey: "msg_notification_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "msg_notification_enabled") }
    }

    var isSoundEnabled: Bool {
        get { defaults.object(forKey: "msg_sound_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "msg_sound_enabled") }
    }

    var isVibrationEnabled: Bool {
        get { defaults.object(forKey: "msg_vibration_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "msg_vibration_enabled") }
    }

    // MARK: - 通用设置
    var fontSize: Int {
        get { defaults.object(forKey: "font_size") as? Int ?? 15 }
        set { defaults.set(newValue, forKey: "font_size") }
    }

    // MARK: - 清除
    func clearAll() {
        let keys = ["uid", "token", "name", "phone", "avatar",
                    "lock_screen_pwd_enabled", "lock_screen_pwd",
                    "apns_device_token"]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}
