import UIKit
import SnapKit
import Kingfisher

// MARK: - 通用工具类
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

    // MARK: - 加载头像
    static func loadAvatar(_ url: URL?, into imageView: UIImageView, placeholder: String? = nil) {
        guard let url = url else {
            imageView.image = UIImage(systemName: "person.circle.fill")
            imageView.tintColor = UIColor.systemGray5
            return
        }
        imageView.kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "person.circle.fill"),
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        ) { result in
            switch result {
            case .failure:
                imageView.image = UIImage(systemName: "person.circle.fill")
                imageView.tintColor = UIColor.systemGray5
            case .success: break
            }
        }
    }

    // MARK: - 验证手机号
    static func isValidPhone(_ phone: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "^1[3-9]\\d{9}$")
        return predicate.evaluate(with: phone)
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
