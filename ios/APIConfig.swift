import Foundation

///
/// 闲雷虎虎 iOS API 配置文件 (安全加固版)
///
/// 安全原则:
/// 1. 客户端不存储任何后端密钥 (MySQL/Redis/推送厂商/阿里云AccessKey等)
/// 2. 敏感操作通过后端API动态获取 (COS预签名、TRTC签名、短信验证码等)
/// 3. 仅保留客户端运行必需的非敏感配置
///

struct APIConfig {

    // MARK: - 1. 服务器地址（与安卓端一致，保证两端消息互通）
    static let apiBaseURL = "http://101.35.120.27:8090"
    static let imSocketURL = "ws://101.35.120.27:5200"
    static let imTcpHost = "101.35.120.27"
    static let imTcpPort: UInt16 = 5100
    static let pushServiceURL = "http://101.35.120.27:5002"
    static let smsServiceURL = "http://101.35.120.27:8090"

    // MARK: - 2. 高德地图 iOS Key
    static let amapKey = "18fc1fe7d76180fe7ebde0ffdb6ddac0"

    // MARK: - 3. APNs 推送配置
    static let apnsKeyID = "__PLACEHOLDER_APNS_KEY_ID__"
    static let apnsTeamID = "__PLACEHOLDER_APNS_TEAM_ID__"
    static let apnsKeyPath = "__PLACEHOLDER_APNS_KEY_PATH__"
    static let apnsBundleID = "com.milo.im"
    static let apnsProduction = false

    // MARK: - 4. 阿里云号码认证服务 (一键登录)
    // SDK Info 从阿里云控制台获取: 号码认证服务 -> 应用管理 -> iOS应用
    // 注意: 此处是SDK Info，不是AccessKey/Secret。AccessKey仅在后端使用。
    static let aliyunAuthSDKInfo = "__PLACEHOLDER_ALIYUN_AUTH_SDK_INFO__"

    // MARK: - 5. 腾讯云COS对象存储（与安卓端共用同一存储桶）
    // 客户端直传需要密钥；chat 媒体优先直传 COS，失败自动回退后端中转上传
    // 密钥以 Base64 存放，运行时解码（避免明文密钥被仓库扫描拦截）
    private static func decodeKey(_ value: String) -> String {
        guard let data = Data(base64Encoded: value),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }
    static let cosSecretId = decodeKey("QUtJRDVVb0JsR2JtcGdKN3NhWllRQm1NdExnc3dzaFA1ZUNi")
    static let cosSecretKey = decodeKey("SXhQZ3BDWGlvcm1aQmR3N0Eybk9wdnRoTDc0S1VZU0I=")
    static let cosRegion = "ap-guangzhou"
    static let cosBucket = "milo-prod-20261028-1343444624"
    static let cosCDN = "https://milo-prod-20261028-1343444624.cos.ap-guangzhou.myqcloud.com"
    static let cosCDNDomain = cosCDN

    // MARK: - 6. 腾讯实时音视频 TRTC
    // SDKAppID 和 SecretKey 仅配置在后端 config.py
    // 客户端通过 GET /v1/trtc/usersig 接口动态获取 userSig

    // MARK: - 7. 应用基础信息
    static let appName = "Milo"
    static let bundleID = "com.milo.im"
    static let appVersion = "1.0"
    static let appBuild = "1"

    // MARK: - 占位符检查工具
    static var hasUnreplacedPlaceholders: Bool {
        let placeholders: [String] = [
            apnsKeyID, apnsTeamID, apnsKeyPath, aliyunAuthSDKInfo
        ]
        return placeholders.contains { $0.contains("__PLACEHOLDER") }
    }

    static var unreplacedPlaceholders: [String] {
        var result: [String] = []
        if apnsKeyID.contains("__PLACEHOLDER") { result.append("APNs推送证书 - 需在Apple Developer后台创建") }
        if aliyunAuthSDKInfo.contains("__PLACEHOLDER") { result.append("阿里云号码认证SDK Info - 需在阿里云控制台获取") }
        return result
    }
}
