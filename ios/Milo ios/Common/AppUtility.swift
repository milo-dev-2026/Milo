import UIKit
import SnapKit
import Kingfisher

// MARK: - 通用工具类
// Build trigger: ebe76ee
class AppUtility {

    static let shared = AppUtility()
    private init() {}

    // MARK: - 显示Toast
    static func showToast(_ message: String, in view: UIView? = nil) {
        DispatchQueue.main.async {
            let targetView = view ?? ScreenAdapter.keyWindow
            guard let targetView = targetView else { return }

            let toastLabel = UILabel()
            toastLabel.text = message
            toastLabel.textColor = .white
            toastLabel.font = ScreenAdapter.font(14)
            toastLabel.textAlignment = .center
            toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            toastLabel.layer.cornerRadius = ScreenAdapter.scaleW(10)
            toastLabel.layer.masksToBounds = true
            toastLabel.numberOfLines = 0
            let maxWidth = ScreenAdapter.screenWidth * 0.7
            let size = message.size(withAttributes: [.font: ScreenAdapter.font(14)])
            let toastWidth = min(size.width + 32, maxWidth)
            let toastHeight = max(size.height + 24, ScreenAdapter.scaleW(36))
            toastLabel.frame = CGRect(x: 0, y: 0, width: toastWidth, height: toastHeight)
            toastLabel.center = CGPoint(x: targetView.bounds.midX, y: targetView.bounds.midY)
            toastLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            targetView.addSubview(toastLabel)

            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }

    // MARK: - 短信验证码回显处理
    /// 短信通道不可用（如签名未报备）时后端会回显验证码，弹窗提示并回调填充，保障注册/登录流程可用
    @discardableResult
    static func handleSMSCodeEcho(_ response: [String: Any], onCode: ((String) -> Void)? = nil) -> Bool {
        guard (response["sms_sent"] as? Bool) == false,
              let code = response["code"] as? String, !code.isEmpty else { return false }
        let reason = response["sms_msg"] as? String ?? "短信通道异常"
        DispatchQueue.main.async {
            onCode?(code)
            guard let root = ScreenAdapter.keyWindow?.rootViewController else { return }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            let alert = UIAlertController(title: "短信未送达", message: "\(reason)\n本次验证码：\(code)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            top.present(alert, animated: true)
        }
        return true
    }

    // MARK: - 加载头像
    static func loadAvatar(_ url: URL?, into imageView: UIImageView, placeholder: String? = nil) {
        let defaultImg = defaultAvatarImage(name: placeholder ?? "", size: 96)
        guard let url = url else {
            imageView.image = defaultImg
            return
        }
        imageView.kf.setImage(
            with: url,
            placeholder: defaultImg,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        ) { result in
            if case .failure = result {
                imageView.image = defaultImg
            }
        }
    }

    // MARK: - 头像URL构造（与Android一致：/v1/users/{uid}/avatar 或 /v1/groups/{gid}/avatar）
    static func avatarURL(forChannelId channelId: String, channelType: Int) -> URL? {
        let path = channelType == 2 ? "/v1/groups/\(channelId)/avatar" : "/v1/users/\(channelId)/avatar"
        return URL(string: APIConfig.apiBaseURL + path)
    }

    // MARK: - 头像本地缓存（内存 + 沙盒文件，冷启动时同步读取，避免先闪首字符占位图）
    private static let avatarMemory = NSCache<NSString, UIImage>()

    private static func avatarCacheURL(_ key: String) -> URL? {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AvatarCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(key.replacingOccurrences(of: "/", with: "_"))
    }

    // MARK: - 加载频道头像（与Android AvatarView一致，失败显示首字符彩色头像）
    static func loadChannelAvatar(channelId: String, channelType: Int, name: String, into imageView: UIImageView) {
        let placeholder = defaultAvatarImage(name: name, size: 96)
        let key = "\(channelType)_\(channelId)"

        // 1. 内存命中
        if let cached = avatarMemory.object(forKey: key as NSString) {
            imageView.image = cached
            return
        }
        // 2. 本地文件命中（同步读取，冷启动也能直接显示真实头像）
        if let path = avatarCacheURL(key),
           let data = try? Data(contentsOf: path),
           let cached = UIImage(data: data) {
            avatarMemory.setObject(cached, forKey: key as NSString)
            imageView.image = cached
            return
        }

        guard let url = avatarURL(forChannelId: channelId, channelType: channelType) else {
            imageView.image = placeholder
            return
        }
        imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [.cacheOriginalImage, .backgroundDecode]
        ) { result in
            switch result {
            case .success(let value):
                avatarMemory.setObject(value.image, forKey: key as NSString)
                let image = value.image
                DispatchQueue.global(qos: .utility).async {
                    if let data = image.jpegData(compressionQuality: 0.8),
                       let path = avatarCacheURL(key) {
                        try? data.write(to: path)
                    }
                }
            case .failure:
                imageView.image = placeholder
            }
        }
    }

    // MARK: - 默认头像（名字首字符 + 彩色背景，对齐Android AvatarView）
    static func defaultAvatarImage(name: String, size: CGFloat) -> UIImage {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstChar = trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
        let colors: [UInt32] = [0xE07A9F, 0xA97FD6, 0x7F92D6, 0x7FC8D6, 0x7FD69F, 0xD6C87F, 0xD6977F, 0xD67F7F]
        let colorIndex = abs(trimmed.hashValue) % colors.count
        let bgColor = UIColor.hex(String(format: "%06X", colors[colorIndex]))
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            bgColor.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            let font = UIFont.boldSystemFont(ofSize: size * 0.42)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]
            let text = firstChar as NSString
            let textSize = text.size(withAttributes: attrs)
            let rect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: rect, withAttributes: attrs)
        }
    }

    // MARK: - 验证手机号
    static func isValidPhone(_ phone: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "^1[3-9]\\d{9}$")
        return predicate.evaluate(with: phone)
    }

    // MARK: - 获取用户显示名（优先SDK缓存，缺失时触发拉取）
    static func displayName(for uid: String, completion: @escaping (String) -> Void) {
        if let cached = IMManager.shared.getChannelInfo(channelId: uid, channelType: 1) {
            let remark = cached.remark ?? ""
            let name = cached.name ?? ""
            let display = remark.isEmpty ? name : remark
            if !display.isEmpty {
                DispatchQueue.main.async { completion(display) }
                return
            }
        }
        IMManager.shared.fetchChannelInfo(channelId: uid, channelType: 1) { info in
            let remark = info?.remark ?? ""
            let name = info?.name ?? ""
            let display = remark.isEmpty ? name : remark
            completion(display.isEmpty ? uid : display)
        }
    }

    // MARK: - 时间格式化
    static func formatTimestamp(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        let now = Date()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨天"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }

    // MARK: - 安全区域
    static var safeAreaBottom: CGFloat { ScreenAdapter.safeAreaBottom }
    static var safeAreaTop: CGFloat { ScreenAdapter.safeAreaTop }

    // MARK: - 振动反馈
    static func lightFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - UIView扩展
extension UIView {
    func addSubviews(_ subviews: UIView...) {
        subviews.forEach { addSubview($0) }
    }

    func pin(to view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func roundCorners(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }

    /// 根据屏幕适配圆角
    func adaptiveRoundCorners(_ baseRadius: CGFloat) {
        layer.cornerRadius = ScreenAdapter.scaleW(baseRadius)
        layer.masksToBounds = true
    }

    // MARK: - 毛玻璃效果
    /// 添加毛玻璃背景效果
    @discardableResult
    func addBlurEffect(style: UIBlurEffect.Style = .systemMaterial, at index: Int = 0) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(blurView, at: index)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        return blurView
    }

    // MARK: - 阴影效果
    /// 添加 iOS 风格的轻阴影
    func addShadow(
        color: UIColor = .black,
        opacity: Float = 0.08,
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 8
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }

    /// 移除阴影
    func removeShadow() {
        layer.shadowColor = nil
        layer.shadowOpacity = 0
        layer.shadowOffset = .zero
        layer.shadowRadius = 0
    }
}

// MARK: - UIButton 主题扩展
extension UIButton {

    /// 配置为主题填充按钮（蓝色背景、白色文字、圆角）
    func configureAsThemeButton(title: String? = nil, fontSize: CGFloat = 17) {
        if let title = title {
            setTitle(title, for: .normal)
        }
        backgroundColor = .themePrimary
        setTitleColor(.white, for: .normal)
        titleLabel?.font = ScreenAdapter.mediumFont(fontSize)
        layer.cornerRadius = ScreenAdapter.scaleW(12)
        layer.masksToBounds = true
    }

    /// 配置为文字按钮（蓝色文字、透明背景）
    func configureAsTextButton(title: String? = nil, fontSize: CGFloat = 16) {
        if let title = title {
            setTitle(title, for: .normal)
        }
        backgroundColor = .clear
        setTitleColor(.themePrimary, for: .normal)
        titleLabel?.font = ScreenAdapter.font(fontSize)
    }

    /// 配置为边框按钮（蓝色边框、蓝色文字）
    func configureAsBorderButton(title: String? = nil, fontSize: CGFloat = 16) {
        if let title = title {
            setTitle(title, for: .normal)
        }
        backgroundColor = .clear
        setTitleColor(.themePrimary, for: .normal)
        titleLabel?.font = ScreenAdapter.mediumFont(fontSize)
        layer.borderWidth = 1
        layer.borderColor = UIColor.themePrimary.cgColor
        layer.cornerRadius = ScreenAdapter.scaleW(12)
        layer.masksToBounds = true
    }
}

// MARK: - UILabel 适配扩展
extension UILabel {
    var adaptiveFont: UIFont {
        get { self.font }
        set { self.font = newValue }
    }

    func setAdaptiveFont(_ size: CGFloat, weight: UIFont.Weight = .regular) {
        self.font = ScreenAdapter.font(size, weight: weight)
    }
}

