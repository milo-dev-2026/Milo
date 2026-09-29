import Foundation

///
/// Milo iOS API 配置文件 (模板)
///
/// 此文件为模板，实际配置通过 GitHub Secrets 注入
/// 本地使用时请替换所有占位符为真实值
///
/// 安全原则:
/// 1. 客户端不存储任何后端密钥 (MySQL/Redis/推送厂商/阿里云AccessKey等)
/// 2. 敏感操作通过后端API动态获取 (COS预签名、TRTC签名、短信验证码等)
/// 3. 仅保留客户端运行必需的非敏感配置
///

struct APIConfig {

    // MARK: - 1. 服务器地址
    static let apiBaseURL = "__PLACEHOLDER_API_BASE_URL__"
    static let imSocketURL = "__PLACEHOLDER_IM_SOCKET_URL__"
    static let imTcpHost = "__PLACEHOLDER_IM_TCP_HOST__"
    static let imTcpPort: UInt16 = 5100
    static let pushServiceURL = "__PLACEHOLDER_PUSH_URL__"
    static let smsServiceURL = "__PLACEHOLDER_SMS_URL__"

    // MARK: - 2. 高德地图 iOS Key
    static let amapKey = "__PLACEHOLDER_AMAP_KEY__"

    // MARK: - 3. APNs 推送配置
    static let apnsKeyID = "__PLACEHOLDER_APNS_KEY_ID__"
    static let apnsTeamID = "__PLACEHOLDER_APNS_TEAM_ID__"
    static let apnsKeyPath = "__PLACEHOLDER_APNS_KEY_PATH__"
    static let apnsBundleID = "__PLACEHOLDER_BUNDLE_ID__"
    static let apnsProduction = false

    // MARK: - 4. 阿里云号码认证服务 (一键登录)
    // SDK Info 从阿里云控制台获取: 号码认证服务 -> 应用管理 -> iOS应用
    // 注意: 此处是SDK Info，不是AccessKey/Secret。AccessKey仅在后端使用。
    static let aliyunAuthSDKInfo = "__PLACEHOLDER_ALIYUN_AUTH_SDK_INFO__"

    // MARK: - 5. 腾讯云COS对象存储 (非敏感信息)
    // SecretID/SecretKey 不存储在客户端，通过后端 /v1/file/presign 接口获取预签名URL
    static let cosRegion = "__PLACEHOLDER_COS_REGION__"
    static let cosBucket = "__PLACEHOLDER_COS_BUCKET__"
    static let cosCDNDomain = "__PLACEHOLDER_COS_CDN__"

    // MARK: - 6. 腾讯实时音视频 TRTC
    // SDKAppID 和 SecretKey 仅配置在后端 config.py
    // 客户端通过 GET /v1/trtc/usersig 接口动态获取 userSig

    // MARK: - 7. 应用基础信息
    static let appName = "__PLACEHOLDER_APP_NAME__"
    static let bundleID = "__PLACEHOLDER_BUNDLE_ID__"
    static let appVersion = "__PLACEHOLDER_APP_VERSION__"
    static let appBuild = "__PLACEHOLDER_APP_BUILD__"

    // MARK: - 占位符检查工具
    static var hasUnreplacedPlaceholders: Bool {
        let placeholders: [String] = [
            apiBaseURL, amapKey, apnsKeyID, aliyunAuthSDKInfo
        ]
        return placeholders.contains { $0.contains("__PLACEHOLDER") }
    }

    static var unreplacedPlaceholders: [String] {
        var result: [String] = []
        if apiBaseURL.contains("__PLACEHOLDER") { result.append("API服务器地址") }
        if amapKey.contains("__PLACEHOLDER") { result.append("高德地图Key") }
        if apnsKeyID.contains("__PLACEHOLDER") { result.append("APNs推送证书") }
        if aliyunAuthSDKInfo.contains("__PLACEHOLDER") { result.append("阿里云号码认证SDK Info") }
        return result
    }
}
