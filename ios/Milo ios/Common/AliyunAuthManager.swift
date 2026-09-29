import Foundation
#if canImport(ATAuthSDK)
import ATAuthSDK
#endif

///
/// 阿里云号码认证管理器
///
/// 一键登录流程:
/// 1. 客户端调用 SDK 获取预取号 token
/// 2. 用户点击一键登录，SDK 拉起授权页
/// 3. 用户同意后，SDK 返回认证 token
/// 4. 客户端将 token 发送到后端 /v1/user/phone_auth
/// 5. 后端用 AccessKey/Secret 调用阿里云 API 换取手机号
/// 6. 后端完成登录/注册，返回 IM token
///

protocol AliyunAuthDelegate: AnyObject {
    func aliyunAuth(didGetToken token: String)
    func aliyunAuth(didFailWithError error: Error)
    func aliyunAuth(didCancel page: UIViewController)
}

class AliyunAuthManager: NSObject {

    static let shared = AliyunAuthManager()

    weak var delegate: AliyunAuthDelegate?

    private var authToken: String?

    private override init() {
        super.init()
    }

    // MARK: - SDK 初始化

    func setupSDK() {
        guard !APIConfig.aliyunAuthSDKInfo.contains("__PLACEHOLDER") else {
            print("[AliyunAuth] SDK Info 未配置，请在 APIConfig.swift 中设置 aliyunAuthSDKInfo")
            return
        }
        #if canImport(ATAuthSDK)
        PNSSdkManager.instance().setAuthSDKInfo(APIConfig.aliyunAuthSDKInfo) { success, result in
            if success {
                print("[AliyunAuth] SDK 初始化成功")
            } else {
                print("[AliyunAuth] SDK 初始化失败: \(String(describing: result))")
            }
        }
        #else
        print("[AliyunAuth] ATAuthSDK 未集成，一键登录不可用")
        #endif
    }

    // MARK: - 预取号

    func preGetToken(completion: @escaping (Bool, String?) -> Void) {
        #if canImport(ATAuthSDK)
        PNSPreCheckModel().carrierTimeout = 5000

        PNSSdkManager.instance().getCellInfo { [weak self] model in
            guard let self = self else { return }

            if model.resultCode == "600000" {
                self.authToken = model.token
                print("[AliyunAuth] 预取号成功")
                completion(true, model.token)
            } else {
                print("[AliyunAuth] 预取号失败: \(model.resultCode ?? "") - \(model.carrierName ?? "")")
                completion(false, nil)
            }
        }
        #else
        print("[AliyunAuth] ATAuthSDK 未集成，预取号不可用")
        completion(false, nil)
        #endif
    }

    // MARK: - 拉起授权页 (一键登录)

    func oneClickLogin(navigationController: UINavigationController) {
        guard authToken != nil else {
            print("[AliyunAuth] 请先调用 preGetToken 进行预取号")
            return
        }
        #if canImport(ATAuthSDK)
        let model = PNSAuthModel()
        model.controllerPresentType = .present

        let customModel = PNSCustomModel()
        customModel.navCustom = PNSNavCustomModel()
        customModel.navCustom?.navBarTintColor = UIColor(red: 0x2B/255, green: 0x8B/255, blue: 0x57/255, alpha: 1)
        customModel.navCustom?.navTitle = "一键登录"
        customModel.navCustom?.navTitleColor = .white
        customModel.navCustom?.navBackButtonHidden = false

        let logoModel = PNSLogoCustomModel()
        logoModel.logoImageName = "LaunchLogo"
        logoModel.logoHidden = false
        customModel.logoCustom = logoModel

        let sloganModel = PNSSloganCustomModel()
        sloganModel.sloganText = "闲雷虎虎 一键登录"
        sloganModel.sloganTextColor = .gray
        customModel.sloganCustom = sloganModel

        let numberModel = PNSPhoneNumCustomModel()
        numberModel.numberColor = .black
        numberModel.numberFontSize = 28
        customModel.phoneNumCustom = numberModel

        let loginBtnModel = PNSLoginBtnCustomModel()
        loginBtnModel.loginBtnText = "本机号码一键登录"
        loginBtnModel.loginBtnBgColor = UIColor(red: 0x2B/255, green: 0x8B/255, blue: 0x57/255, alpha: 1)
        loginBtnModel.loginBtnTextColor = .white
        loginBtnModel.loginBtnCornerRadius = 24
        customModel.loginBtnCustom = loginBtnModel

        let checkProtocolModel = PNSCheckBoxCustomModel()
        checkProtocolModel.uncheckedImageName = "checkbox_unchecked"
        checkProtocolModel.checkedImageName = "checkbox_checked"
        customModel.checkBoxCustom = checkProtocolModel

        let protocolModel = PNSProtocolCustomModel()
        protocolModel.protocolOneURL = APIConfig.apiBaseURL + "/agreement/service.html"
        protocolModel.protocolOneName = "用户服务协议"
        protocolModel.protocolTwoURL = APIConfig.apiBaseURL + "/agreement/privacy.html"
        protocolModel.protocolTwoName = "隐私政策"
        protocolModel.protocolColor = UIColor(red: 0x2B/255, green: 0x8B/255, blue: 0x57/255, alpha: 1)
        protocolModel.protocolTextFontSize = 12
        customModel.protocolCustom = protocolModel

        model.customModel = customModel

        PNSSdkManager.instance().auth(model) { [weak self] success, result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if success, let result = result as? PNSResultModel {
                    if result.resultCode == "600001" {
                        print("[AliyunAuth] 用户取消授权")
                    } else if result.resultCode == "600000" {
                        print("[AliyunAuth] 授权成功，token: \(result.token ?? "")")
                        self.sendTokenToBackend(result.token ?? "")
                    } else {
                        print("[AliyunAuth] 授权失败: \(result.resultCode ?? "") - \(result.resultMsg ?? "")")
                        self.delegate?.aliyunAuth(didFailWithError: AliyunAuthError.authFailed(result.resultMsg ?? ""))
                    }
                } else {
                    print("[AliyunAuth] 授权流程异常")
                    self.delegate?.aliyunAuth(didFailWithError: AliyunAuthError.unknown)
                }
            }
        }
        #else
        print("[AliyunAuth] ATAuthSDK 未集成，一键登录不可用")
        delegate?.aliyunAuth(didFailWithError: AliyunAuthError.unknown)
        #endif
    }

    // MARK: - 发送 token 到后端验证

    private func sendTokenToBackend(_ token: String) {
        let url = APIConfig.apiBaseURL + "/v1/user/phone_auth"

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: String] = [
            "auth_token": token,
            "device_name": UIDevice.current.name,
            "device_model": UIDevice.current.model,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.delegate?.aliyunAuth(didFailWithError: error)
                    return
                }

                guard let data = data else {
                    self.delegate?.aliyunAuth(didFailWithError: AliyunAuthError.noResponse)
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? Int {
                    if status == 200 {
                        if let token = json["token"] as? String {
                            UserDefaults.standard.set(token, forKey: "token")
                            let imToken = json["im_token"] as? String ?? token
                            UserDefaults.standard.set(imToken, forKey: "im_token")
                        }
                        if let uid = json["uid"] as? String {
                            UserDefaults.standard.set(uid, forKey: "uid")
                        }
                        if let name = json["name"] as? String, !name.isEmpty {
                            UserDefaults.standard.set(name, forKey: "name")
                        }
                        if let avatar = json["avatar"] as? String {
                            UserDefaults.standard.set(avatar, forKey: "avatar")
                        }
                        if let phone = json["phone"] as? String {
                            UserDefaults.standard.set(phone, forKey: "phone")
                        }
                        if let shortNo = json["short_no"] as? String {
                            UserDefaults.standard.set(shortNo, forKey: "short_no")
                        }
                        if let zone = json["zone"] as? String {
                            UserDefaults.standard.set(zone, forKey: "zone")
                        }
                        self.delegate?.aliyunAuth(didGetToken: token)
                    } else {
                        let msg = json["msg"] as? String ?? "登录失败"
                        self.delegate?.aliyunAuth(didFailWithError: AliyunAuthError.serverError(msg))
                    }
                } else {
                    self.delegate?.aliyunAuth(didFailWithError: AliyunAuthError.invalidResponse)
                }
            }
        }.resume()
    }

    // MARK: - 其他手机号登录 (非本机号码)

    func loginWithOtherPhone(on navigationController: UINavigationController) {
        print("[AliyunAuth] 回退到短信验证码登录方式")
    }
}

// MARK: - 错误类型

enum AliyunAuthError: Error, LocalizedError {
    case authFailed(String)
    case noResponse
    case invalidResponse
    case serverError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .authFailed(let msg): return "认证失败: \(msg)"
        case .noResponse: return "服务器无响应"
        case .invalidResponse: return "服务器返回格式错误"
        case .serverError(let msg): return "服务器错误: \(msg)"
        case .unknown: return "未知错误"
        }
    }
}
