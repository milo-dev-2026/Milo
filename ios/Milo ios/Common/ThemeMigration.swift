//
//  ThemeMigration.swift
//  Milo
//
//  主题迁移工具 - 全局走查与样式统一
//  用于统一管理所有页面的颜色、字体、间距规范
//

import UIKit
import SnapKit

// MARK: - 全局样式配置
final class ThemeMigration {

    static let shared = ThemeMigration()
    private init() {}

    // MARK: - 统一配置导航栏
    func configureGlobalNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .themeBgWhite
        appearance.titleTextAttributes = [
            .font: ThemeFont.title2(17),
            .foregroundColor: UIColor.themeTextPrimary
        ]
        appearance.largeTitleTextAttributes = [
            .font: ThemeFont.title1(28),
            .foregroundColor: UIColor.themeTextPrimary
        ]
        appearance.shadowColor = .themeSeparatorLight

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .themeColorPrimary
        UINavigationBar.appearance().isTranslucent = false
    }

    // MARK: - 统一配置 TabBar
    func configureGlobalTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .themeBgWhite
        appearance.shadowColor = .themeSeparatorLight

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        UITabBar.appearance().tintColor = .themeColorPrimary
        UITabBar.appearance().unselectedItemTintColor = .themeTextTertiary
        UITabBar.appearance().isTranslucent = false
    }

    // MARK: - 统一配置 TableView
    func configureGlobalTableView() {
        UITableView.appearance().backgroundColor = .themeBg
        UITableView.appearance().separatorColor = .themeSeparatorLight
        UITableViewCell.appearance().backgroundColor = .themeBgWhite
        UITableViewCell.appearance().textLabel?.font = ThemeFont.body(16)
        UITableViewCell.appearance().textLabel?.textColor = .themeTextPrimary
        UITableViewCell.appearance().detailTextLabel?.font = ThemeFont.bodySmall(14)
        UITableViewCell.appearance().detailTextLabel?.textColor = .themeTextSecondary
    }

    // MARK: - 统一配置 Button
    func configureGlobalButton() {
        UIButton.appearance().tintColor = .themeColorPrimary
    }

    // MARK: - 统一配置 TextField
    func configureGlobalTextField() {
        UITextField.appearance().tintColor = .themeColorPrimary
        UITextField.appearance().textColor = .themeTextPrimary
        UITextField.appearance().font = ThemeFont.body(16)
    }

    // MARK: - 统一配置 SearchBar
    func configureGlobalSearchBar() {
        UISearchBar.appearance().tintColor = .themeColorPrimary
        UISearchBar.appearance().searchTextField.textColor = .themeTextPrimary
        UISearchBar.appearance().searchTextField.font = ThemeFont.body(15)
    }

    // MARK: - 全局初始化（在 AppDelegate 中调用）
    func setupGlobalTheme() {
        configureGlobalNavigationBar()
        configureGlobalTabBar()
        configureGlobalTableView()
        configureGlobalButton()
        configureGlobalTextField()
        configureGlobalSearchBar()
    }
}

// MARK: - 常用 UI 组件快速构建器
final class ThemeUI {

    // MARK: - 主按钮
    static func primaryButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = ThemeFont.buttonLarge(16)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .themeColorPrimary
        btn.layer.cornerRadius = 10
        btn.addPressScaleEffect()
        return btn
    }

    // MARK: - 次要按钮
    static func secondaryButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = ThemeFont.button(15)
        btn.setTitleColor(.themeColorPrimary, for: .normal)
        btn.backgroundColor = .themeColorPrimary.withAlphaComponent(0.1)
        btn.layer.cornerRadius = 10
        btn.addPressScaleEffect()
        return btn
    }

    // MARK: - 文字按钮
    static func textButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = ThemeFont.body(15)
        btn.setTitleColor(.themeColorPrimary, for: .normal)
        return btn
    }

    // MARK: - 输入框
    static func textField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = ThemeFont.body(16)
        tf.textColor = .themeTextPrimary
        tf.tintColor = .themeColorPrimary
        tf.backgroundColor = .themeBgInput
        tf.layer.cornerRadius = 10
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        return tf
    }

    // MARK: - 卡片容器
    static func cardView() -> UIView {
        let view = UIView()
        view.backgroundColor = .themeBgCard
        view.layer.cornerRadius = 12
        return view
    }

    // MARK: - 分割线
    static func separatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = .themeSeparatorLight
        return view
    }

    // MARK: - 标签（Badge）
    static func badgeLabel(text: String, color: UIColor = .themeColorPrimary) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = ThemeFont.tiny(11)
        label.textColor = .white
        label.backgroundColor = color
        label.textAlignment = .center
        label.layer.cornerRadius = 9
        label.layer.masksToBounds = true
        return label
    }

    // MARK: - 搜索栏
    static func searchBar(placeholder: String) -> UISearchBar {
        let sb = UISearchBar()
        sb.placeholder = placeholder
        sb.searchBarStyle = .minimal
        sb.tintColor = .themeColorPrimary
        return sb
    }

    // MARK: - 圆形头像容器
    static func avatarContainer(size: CGFloat) -> UIView {
        let view = UIView()
        view.backgroundColor = .themeBgInput
        view.layer.cornerRadius = size / 2
        view.clipsToBounds = true
        return view
    }
}

// MARK: - UIViewController 通用扩展
extension UIViewController {

    /// 设置导航栏右侧按钮（图标）
    func setRightBarButton(systemName: String, target: Any?, action: Selector?) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: systemName),
            style: .plain,
            target: target,
            action: action
        )
    }

    /// 设置导航栏右侧按钮（文字）
    func setRightBarButton(title: String, target: Any?, action: Selector?) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: title,
            style: .plain,
            target: target,
            action: action
        )
    }

    /// 设置返回按钮（自定义图标）
    func setCustomBackButton() {
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(defaultBackAction)
        )
        navigationItem.leftBarButtonItem = backBtn
    }

    @objc private func defaultBackAction() {
        navigationController?.popViewController(animated: true)
    }

    /// 显示简单的 Alert
    func showAlert(title: String, message: String, confirmTitle: String = "确定",
                   cancelTitle: String? = nil, onConfirm: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm?()
        })
        if let cancel = cancelTitle {
            alert.addAction(UIAlertAction(title: cancel, style: .cancel))
        }
        present(alert, animated: true)
    }

    /// 显示 BottomSheet
    func showBottomSheet(_ vc: UIViewController, height: CGFloat = 300) {
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
}

// MARK: - UIColor 便捷扩展
extension UIColor {

    /// 十六进制颜色
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// 生成随机颜色（调试用）
    static var random: UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
}

// MARK: - UIView 便捷布局扩展
extension UIView {

    /// 设置圆角
    func setCornerRadius(_ radius: CGFloat, corners: UIRectCorner = .allCorners) {
        if corners == .allCorners {
            layer.cornerRadius = radius
            layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
        } else {
            let path = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }

    /// 设置边框
    func setBorder(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }

    /// 设置阴影
    func setShadow(color: UIColor = .black,
                   opacity: Float = 0.1,
                   offset: CGSize = CGSize(width: 0, height: 2),
                   radius: CGFloat = 4) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }

    /// 添加渐变背景
    func addGradient(colors: [UIColor],
                     startPoint: CGPoint = CGPoint(x: 0.5, y: 0),
                     endPoint: CGPoint = CGPoint(x: 0.5, y: 1)) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

// MARK: - String 便捷扩展
extension String {

    /// 计算文本高度
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }

    /// 计算文本宽度
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.width)
    }
}

// MARK: - Date 便捷扩展
extension Date {

    /// 格式化日期为字符串
    func formattedString(format: String = "yyyy-MM-dd HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    /// 相对时间描述
    var relativeString: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear], from: self, to: now)

        if let week = components.weekOfYear, week >= 1 {
            return formattedString(format: "yyyy-MM-dd")
        } else if let day = components.day, day >= 1 {
            return "\(day)天前"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
}
