import Foundation

///
/// Milo iOS API 配置文件
///
/// 此文件为模板，实际配置通过 GitHub Secrets 注入
/// 本地使用时请替换所有占位符为真实值
///

struct APIConfig {

    // MARK: - 1. 服务器地址
    static let apiBaseURL = "http://43.133.39.170:8090"
    static let imSocketURL = "ws://43.133.39.170:5200"
    static let pushServiceURL = "http://43.133.39.170:5002"
    static let smsServiceURL = "http://43.133.39.170:5001"

    // MARK: - 2. 高德地图 iOS Key
    static let amapKey = "18fc1fe7d76180fe7ebde0ffdb6ddac0"

    // MARK: - 3. APNs 推送配置
    static let apnsKeyID = "__PLACEHOLDER_APNS_KEY_ID__"
    static let apnsTeamID = "__PLACEHOLDER_APNS_TEAM_ID__"
    static let apnsKeyPath = "__PLACEHOLDER_APNS_KEY_PATH__"
    static let apnsBundleID = "com.milo.im"
    static let apnsProduction = false

    // MARK: - 4. 阿里云号码认证服务
    static let aliyunAccessKeyID = "__PLACEHOLDER_ALIYUN_AK_ID__"
    static let aliyunAccessKeySecret = "__PLACEHOLDER_ALIYUN_AK_SECRET__"
    static let aliyunSMSSignName = "__PLACEHOLDER_ALIYUN_SMS_SIGN__"
    static let aliyunSMSTemplateCode = "__PLACEHOLDER_ALIYUN_SMS_TPL__"

    // MARK: - 5. 腾讯云COS对象存储
    static let cosSecretID = "__PLACEHOLDER_COS_SID__"
    static let cosSecretKey = "__PLACEHOLDER_COS_KEY__"
    static let cosRegion = "ap-guangzhou"
    static let cosBucket = "milo-img-1364784323"
    static let cosCDNDomain = "https://milo-img-1364784323.cos.ap-guangzhou.myqcloud.com"

    // MARK: - 6. 腾讯实时音视频 TRTC
    // SDKAppID 和 SecretKey 仅配置在后端 config.py，客户端通过 /v1/trtc/usersig 接口动态获取

    // MARK: - 7. Resend 邮箱服务
    static let resendAPIKey = "__PLACEHOLDER_RESEND_KEY__"
    static let resendFromEmail = "__PLACEHOLDER_RESEND_EMAIL__"
    static let resendFromName = "Milo"

    // MARK: - 8. 数据库配置 (后端使用)
    static let mysqlHost = "__PLACEHOLDER_MYSQL_HOST__"
    static let mysqlPort = 3306
    static let mysqlUser = "__PLACEHOLDER_MYSQL_USER__"
    static let mysqlPassword = "__PLACEHOLDER_MYSQL_PWD__"
    static let mysqlDatabase = "im"

    // MARK: - 9. Redis配置 (后端使用)
    static let redisHost = "__PLACEHOLDER_REDIS_HOST__"
    static let redisPort = 6379
    static let redisPassword = ""

    // MARK: - 10. 应用基础信息
    static let appName = "Milo"
    static let bundleID = "com.milo.im"
    static let appVersion = "1.0"
    static let appBuild = "1"

    // MARK: - 11. 各厂商推送密钥 (后端使用)
    static let huaweiPushAppID = "__PLACEHOLDER_HP_APP_ID__"
    static let huaweiPushProjectID = "__PLACEHOLDER_HP_PROJECT_ID__"
    static let huaweiPushKeyID = "__PLACEHOLDER_HP_KEY_ID__"
    static let huaweiPushSubAccount = "__PLACEHOLDER_HP_SUB_ACCOUNT__"
    static let huaweiPushPrivateKey = "__PLACEHOLDER_HP_PRIVATE_KEY__"

    static let xiaomiPushAppID = "__PLACEHOLDER_XM_APP_ID__"
    static let xiaomiPushAppKey = "__PLACEHOLDER_XM_APP_KEY__"
    static let xiaomiPushAppSecret = "__PLACEHOLDER_XM_APP_SECRET__"

    static let oppoPushAppKey = "__PLACEHOLDER_OPPO_KEY__"
    static let oppoPushAppSecret = "__PLACEHOLDER_OPPO_SECRET__"
    static let oppoPushMasterSecret = "__PLACEHOLDER_OPPO_MASTER__"

    static let vivoPushAppID = "__PLACEHOLDER_VIVO_APP_ID__"
    static let vivoPushAppKey = "__PLACEHOLDER_VIVO_APP_KEY__"
    static let vivoPushAppSecret = "__PLACEHOLDER_VIVO_APP_SECRET__"

    // MARK: - 12. 小米推送模板配置 (后端使用)
    static let xiaomiTplFriend = "__PLACEHOLDER_XM_TPL_FRIEND__"
    static let xiaomiTplGroup = "__PLACEHOLDER_XM_TPL_GROUP__"
    static let xiaomiTplMention = "__PLACEHOLDER_XM_TPL_MENTION__"
    static let xiaomiTplCall = "__PLACEHOLDER_XM_TPL_CALL__"
    static let xiaomiChFriend = "__PLACEHOLDER_XM_CH_FRIEND__"
    static let xiaomiChGroup = "__PLACEHOLDER_XM_CH_GROUP__"
    static let xiaomiChMention = "__PLACEHOLDER_XM_CH_MENTION__"
    static let xiaomiChCall = "__PLACEHOLDER_XM_CH_CALL__"

    // MARK: - 占位符检查工具
    static var hasUnreplacedPlaceholders: Bool {
        let placeholders: [String] = [
            apiBaseURL, amapKey, aliyunAccessKeyID
        ]
        return placeholders.contains { $0.contains("__PLACEHOLDER") }
    }

    static var unreplacedPlaceholders: [String] {
        var result: [String] = []
        if apiBaseURL.contains("__PLACEHOLDER") { result.append("API服务器地址") }
        if amapKey.contains("__PLACEHOLDER") { result.append("高德地图Key") }
        return result
    }
}
