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
        imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
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

// MARK: - 颜色扩展
extension UIColor {
    static let themePrimary = UIColor(red: 0.0, green: 0.51, blue: 1.0, alpha: 1.0)
    static let themeBackground = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    static let themeCellSeparator = UIColor(white: 0.9, alpha: 1.0)
    static let themeChatBackground = UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)

    static func hex(_ hex: String) -> UIColor {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.removeFirst()
        }
        if cString.count != 6 {
            return .gray
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
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
