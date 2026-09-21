//
//  COSUploadManager.swift
//  Milo
//
//  腾讯云 COS 对象存储上传管理器
//  负责图片、视频、文件等资源的直传 COS
//

import Foundation
import UIKit
import QCloudCOSXML

/// COS 上传管理器 - 单例模式
class COSUploadManager: NSObject {

    // MARK: - Singleton

    static let shared = COSUploadManager()

    private override init() {
        super.init()
    }

    // MARK: - Properties

    /// 是否已初始化
    private var isInitialized = false

    // MARK: - Setup

    /// 初始化 COS SDK（在 AppDelegate 中调用一次即可）
    ///
    /// 使用永久密钥方式，通过 signatureProvider 回调提供密钥
    /// 注意：生产环境建议使用临时密钥以提高安全性
    func setup() {
        guard !isInitialized else { return }

        let config = QCloudServiceConfiguration()
        let endpoint = QCloudCOSXMLEndPoint()

        // 地域，例如 ap-guangzhou
        endpoint.regionName = APIConfig.cosRegion
        // 使用 HTTPS
        endpoint.useHTTPS = true

        config.endpoint = endpoint
        // 设置签名提供者（使用永久密钥）
        config.signatureProvider = self

        // 注册 COS 服务
        QCloudCOSXMLService.registerDefaultCOSXML(with: config)
        // 注册传输管理服务（用于上传/下载，支持断点续传等）
        QCloudCOSTransferMangerService.registerDefaultCOSTransferManger(with: config)

        isInitialized = true
    }

    // MARK: - Public Methods

    /// 上传图片
    /// - Parameters:
    ///   - image: 要上传的图片
    ///   - progress: 上传进度回调 (0.0 ~ 1.0)
    ///   - completion: 完成回调，返回 CDN 完整 URL 或错误
    func uploadImage(_ image: UIImage,
                     progress: ((Double) -> Void)?,
                     completion: @escaping (Result<String, Error>) -> Void) {
        // 压缩为 JPEG，质量 0.6
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            completion(.failure(NSError(domain: "COSUploadManager",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "图片数据转换失败"])))
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid8 = String(UUID().uuidString.prefix(8))
        let objectKey = "chat/images/\(timestamp)_\(uuid8).jpg"

        uploadDataInternal(imageData,
                           objectKey: objectKey,
                           contentType: "image/jpeg",
                           progress: progress,
                           completion: completion)
    }

    /// 上传视频
    /// - Parameters:
    ///   - fileURL: 视频文件本地路径
    ///   - progress: 上传进度回调 (0.0 ~ 1.0)
    ///   - completion: 完成回调，返回 CDN 完整 URL 或错误
    func uploadVideo(_ fileURL: URL,
                     progress: ((Double) -> Void)?,
                     completion: @escaping (Result<String, Error>) -> Void) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid8 = String(UUID().uuidString.prefix(8))
        let objectKey = "chat/videos/\(timestamp)_\(uuid8).mp4"

        uploadFileURLInternal(fileURL,
                              objectKey: objectKey,
                              contentType: "video/mp4",
                              progress: progress,
                              completion: completion)
    }

    /// 上传通用文件（Data 方式）
    /// - Parameters:
    ///   - data: 文件数据
    ///   - fileName: 文件名（包含扩展名）
    ///   - contentType: MIME 类型，如 image/jpeg、video/mp4、application/octet-stream
    ///   - progress: 上传进度回调 (0.0 ~ 1.0)
    ///   - completion: 完成回调，返回 CDN 完整 URL 或错误
    func uploadFile(data: Data,
                    fileName: String,
                    contentType: String,
                    progress: ((Double) -> Void)?,
                    completion: @escaping (Result<String, Error>) -> Void) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid8 = String(UUID().uuidString.prefix(8))
        let objectKey = "chat/files/\(timestamp)_\(uuid8)_\(fileName)"

        uploadDataInternal(data,
                           objectKey: objectKey,
                           contentType: contentType,
                           progress: progress,
                           completion: completion)
    }

    /// 上传通用文件（文件路径方式，适合大文件）
    /// - Parameters:
    ///   - fileURL: 本地文件路径
    ///   - fileName: 文件名（包含扩展名）
    ///   - contentType: MIME 类型
    ///   - progress: 上传进度回调 (0.0 ~ 1.0)
    ///   - completion: 完成回调，返回 CDN 完整 URL 或错误
    func uploadFile(fileURL: URL,
                    fileName: String,
                    contentType: String,
                    progress: ((Double) -> Void)?,
                    completion: @escaping (Result<String, Error>) -> Void) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid8 = String(UUID().uuidString.prefix(8))
        let objectKey = "chat/files/\(timestamp)_\(uuid8)_\(fileName)"

        uploadFileURLInternal(fileURL,
                              objectKey: objectKey,
                              contentType: contentType,
                              progress: progress,
                              completion: completion)
    }

    // MARK: - Private Internal Upload Methods

    /// 内部上传方法（Data 方式）
    private func uploadDataInternal(_ data: Data,
                                    objectKey: String,
                                    contentType: String,
                                    progress: ((Double) -> Void)?,
                                    completion: @escaping (Result<String, Error>) -> Void) {
        guard isInitialized else {
            completion(.failure(NSError(domain: "COSUploadManager",
                                        code: -2,
                                        userInfo: [NSLocalizedDescriptionKey: "COS SDK 未初始化，请先调用 setup()"])))
            return
        }

        let put = QCloudCOSXMLUploadObjectRequest<AnyObject>()

        // 存储桶名称
        put.bucket = APIConfig.cosBucket
        // 对象键（COS 上的完整路径）
        put.object = objectKey
        // 上传数据
        put.body = data as AnyObject

        // 设置 Content-Type
        put.contentType = contentType

        // 上传进度回调
        put.sendProcessBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
            if totalBytesExpectedToSend > 0 {
                let progressValue = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
                DispatchQueue.main.async {
                    progress?(progressValue)
                }
            }
        }

        // 上传完成回调
        put.setFinish { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    // 拼接 CDN 完整 URL
                    let cdnURL = COSUploadManager.buildCDNURL(objectKey: objectKey)
                    completion(.success(cdnURL))
                }
            }
        }

        // 发起上传
        QCloudCOSTransferMangerService.defaultCOSTransferManager().uploadObject(put)
    }

    /// 内部上传方法（文件路径方式）
    private func uploadFileURLInternal(_ fileURL: URL,
                                       objectKey: String,
                                       contentType: String,
                                       progress: ((Double) -> Void)?,
                                       completion: @escaping (Result<String, Error>) -> Void) {
        guard isInitialized else {
            completion(.failure(NSError(domain: "COSUploadManager",
                                        code: -2,
                                        userInfo: [NSLocalizedDescriptionKey: "COS SDK 未初始化，请先调用 setup()"])))
            return
        }

        let put = QCloudCOSXMLUploadObjectRequest<AnyObject>()

        put.bucket = APIConfig.cosBucket
        put.object = objectKey
        put.body = fileURL as AnyObject
        put.contentType = contentType

        // 上传进度回调
        put.sendProcessBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
            if totalBytesExpectedToSend > 0 {
                let progressValue = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
                DispatchQueue.main.async {
                    progress?(progressValue)
                }
            }
        }

        // 上传完成回调
        put.setFinish { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    let cdnURL = COSUploadManager.buildCDNURL(objectKey: objectKey)
                    completion(.success(cdnURL))
                }
            }
        }

        QCloudCOSTransferMangerService.defaultCOSTransferManager().uploadObject(put)
    }

    // MARK: - Private Methods

    /// 构建 CDN 完整 URL
    /// - Parameter objectKey: COS 对象键（完整路径）
    /// - Returns: 完整的 CDN 访问 URL
    private static func buildCDNURL(objectKey: String) -> String {
        let domain = APIConfig.cosCDNDomain
        // 确保 domain 不以 / 结尾，objectKey 不以 / 开头
        var baseURL = domain
        if baseURL.hasSuffix("/") {
            baseURL = String(baseURL.dropLast())
        }
        let safeKey = objectKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? objectKey
        return "\(baseURL)/\(safeKey)"
    }
}

// MARK: - QCloudSignatureProvider

extension COSUploadManager: QCloudSignatureProvider {

    /// 签名回调 - SDK 在每次请求时调用此方法获取签名凭证
    ///
    /// 这里使用永久密钥直接签名
    /// 注意：永久密钥硬编码在客户端存在安全风险，仅适合内部测试或对安全性要求不高的场景
    /// 生产环境建议：
    /// 1. 从后端接口获取临时密钥（STS）
    /// 2. 由后端计算签名，客户端只负责发起请求
    func signature(with fileds: QCloudSignatureFields!,
                   request: QCloudBizHTTPRequest!,
                   urlRequest urlRequst: NSMutableURLRequest!,
                   compelete continueBlock: QCloudHTTPAuthentationContinueBlock!) {

        let credential = QCloudCredential()
        // 永久密钥 SecretID
        credential.secretID = APIConfig.cosSecretID
        // 永久密钥 SecretKey
        credential.secretKey = APIConfig.cosSecretKey
        // 永久密钥不需要 token
        credential.token = nil
        // 密钥生效时间（当前时间）
        credential.startDate = Date()
        // 密钥过期时间（当前时间 + 1 小时，可按需调整）
        credential.expirationDate = Date(timeIntervalSinceNow: 3600)

        // 创建 V5 签名器
        let creator = QCloudAuthentationV5Creator(credential: credential)
        // 生成签名
        let signature = creator?.signature(forData: urlRequst)

        // 回调 SDK，传入签名
        continueBlock(signature, nil)
    }
}
