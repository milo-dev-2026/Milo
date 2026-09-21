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

    // MARK: - 消息通知设置
    var isMessageNotificationEnabled: Bool {
        get { defaults.object(forKey: "msg_notification_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "msg_notification_enabled") }
    }

    var isNotificationDetailEnabled: Bool {
        get { defaults.object(forKey: "msg_notification_detail_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "msg_notification_detail_enabled") }
    }

    var isSoundEnabled: Bool {
        get { defaults.object(forKey: "msg_sound_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "msg_sound_enabled") }
    }

    var isVibrationEnabled: Bool {
        get { defaults.object(forKey: "msg_vibration_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "msg_vibration_enabled") }
    }

    var isGroupMuteEnabled: Bool {
        get { defaults.object(forKey: "msg_group_mute_enabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "msg_group_mute_enabled") }
    }

    // MARK: - 通用设置
    var fontSize: Int {
        get { defaults.object(forKey: "font_size") as? Int ?? 15 }
        set { defaults.set(newValue, forKey: "font_size") }
    }

    /// 深色模式：0=跟随系统，1=浅色，2=深色
    var appearanceMode: Int {
        get { defaults.object(forKey: "appearance_mode") as? Int ?? 0 }
        set { defaults.set(newValue, forKey: "appearance_mode") }
    }

    /// 字体大小级别：0=小，1=标准，2=大，3=超大
    var fontSizeLevel: Int {
        get { defaults.object(forKey: "font_size_level") as? Int ?? 1 }
        set { defaults.set(newValue, forKey: "font_size_level") }
    }

    /// 语言设置：0=简体中文，1=繁体中文，2=English
    var languageSetting: Int {
        get { defaults.object(forKey: "language_setting") as? Int ?? 0 }
        set { defaults.set(newValue, forKey: "language_setting") }
    }

    /// 聊天背景
    var chatBackground: String? {
        get { defaults.string(forKey: "chat_background") }
        set { defaults.set(newValue, forKey: "chat_background") }
    }

    // MARK: - 清除
    func clearAll() {
        let keys = ["uid", "token", "name", "phone", "avatar",
                    "lock_screen_pwd_enabled", "lock_screen_pwd",
                    "apns_device_token"]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}
