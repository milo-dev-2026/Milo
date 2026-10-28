import Foundation
import CommonCrypto
import Compression

// MARK: - TRTC 本地参数（对齐安卓实现：客户端本地生成 UserSig，不再请求后端接口）
enum TRTCConfig {
    static let sdkAppID: UInt32 = 1600159338
    private static let secretKey = "b3132bc984dcaefdb93179dc33cc950a3ca184d03d0e32d4c2c99a73e7220b98"
    /// 7 天有效期，与安卓一致
    private static let expire: Int64 = 604800

    /// 当前用户的 UserSig
    static var userSig: String {
        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
        return UserSigGenerator.generate(sdkAppId: sdkAppID, userId: uid, secretKey: secretKey, expire: expire)
    }
}

// MARK: - 腾讯云 TRTC UserSig 生成（官方 TLS 2.0 算法）
enum UserSigGenerator {

    static func generate(sdkAppId: UInt32, userId: String, secretKey: String, expire: Int64) -> String {
        guard !userId.isEmpty, !secretKey.isEmpty else { return "" }
        let now = Int64(Date().timeIntervalSince1970)

        var doc: [String: Any] = [
            "TLS.ver": "2.0",
            "TLS.identifier": userId,
            "TLS.sdkappid": sdkAppId,
            "TLS.expire": expire,
            "TLS.time": now
        ]

        let sig = hmacSHA256Base64(key: secretKey, text: signContent(userId: userId,
                                                                sdkAppId: sdkAppId,
                                                                time: now,
                                                                expire: expire,
                                                                userbuf: nil))
        guard !sig.isEmpty else { return "" }
        doc["TLS.sig"] = sig

        guard let jsonData = try? JSONSerialization.data(withJSONObject: doc, options: []),
              let compressed = zlibCompress(jsonData) else { return "" }

        let base64 = compressed.base64EncodedString()
        // 与安卓保持一致：+ -> *，/ -> -，= -> _
        return base64
            .replacingOccurrences(of: "+", with: "*")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "=", with: "_")
    }

    private static func signContent(userId: String,
                                    sdkAppId: UInt32,
                                    time: Int64,
                                    expire: Int64,
                                    userbuf: String?) -> String {
        var content = "TLS.identifier:\(userId)\n"
        content += "TLS.sdkappid:\(sdkAppId)\n"
        content += "TLS.time:\(time)\n"
        content += "TLS.expire:\(expire)\n"
        if let userbuf = userbuf {
            content += "TLS.userbuf:\(userbuf)\n"
        }
        return content
    }

    private static func hmacSHA256Base64(key: String, text: String) -> String {
        guard let keyData = key.data(using: .utf8), let textData = text.data(using: .utf8) else { return "" }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            textData.withUnsafeBytes { textBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                       keyBytes.baseAddress, keyData.count,
                       textBytes.baseAddress, textData.count,
                       &digest)
            }
        }
        return Data(digest).base64EncodedString()
    }

    /// zlib 格式压缩（与 Java Deflater 默认输出一致）
    private static func zlibCompress(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        let dstSize = max(data.count * 2 + 64, 256)
        var dst = Data(count: dstSize)
        let written: Int = dst.withUnsafeMutableBytes { dstPtr -> Int in
            guard let dstBase = dstPtr.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return data.withUnsafeBytes { srcPtr -> Int in
                guard let srcBase = srcPtr.bindMemory(to: UInt8.self).baseAddress else { return 0 }
                return compression_encode_buffer(dstBase, dstSize,
                                                 srcBase, data.count,
                                                 nil, COMPRESSION_ZLIB)
            }
        }
        guard written > 0 else { return nil }
        return dst.prefix(written)
    }
}
