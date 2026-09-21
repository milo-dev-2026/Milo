import UIKit

// MARK: - 屏幕适配工具
/// 自动适配 iPhone SE ~ iPhone 15 Pro Max / iPad
/// 基于 375pt 逻辑宽度（iPhone 标准宽度）作为基准缩放
struct ScreenAdapter {

    // MARK: - 基准宽度（iPhone 标准点宽度）
    static let baseWidth: CGFloat = 375.0

    // MARK: - 屏幕信息
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// 获取当前活跃的 keyWindow
    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    /// 是否为刘海屏（iPhone X 及以上）
    static var hasNotch: Bool {
        return keyWindow?.safeAreaInsets.top ?? 0 > 20
    }

    // MARK: - 安全区域
    static var safeAreaTop: CGFloat {
        return keyWindow?.safeAreaInsets.top ?? 20
    }

    static var safeAreaBottom: CGFloat {
        return keyWindow?.safeAreaInsets.bottom ?? 0
    }

    static var safeAreaLeft: CGFloat {
        return keyWindow?.safeAreaInsets.left ?? 0
    }

    static var safeAreaRight: CGFloat {
        return keyWindow?.safeAreaInsets.right ?? 0
    }

    // MARK: - 缩放比例
    /// 横向缩放比例（大于1=大屏手机，小于1=小屏如iPhone SE）
    static var horizontalScale: CGFloat {
        let width = UIScreen.main.bounds.width
        if isPad {
            return min(width / baseWidth, 1.3)
        }
        return width / baseWidth
    }

    /// 纵向缩放比例
    static var verticalScale: CGFloat {
        let height = UIScreen.main.bounds.height
        if isPad {
            return min(height / 812.0, 1.3)
        }
        return height / 812.0
    }

    // MARK: - 动态尺寸适配
    /// 按屏幕宽度等比缩放（用于间距、圆角等）
    static func scaleW(_ value: CGFloat) -> CGFloat {
        return value * horizontalScale
    }

    /// 按屏幕高度等比缩放
    static func scaleH(_ value: CGFloat) -> CGFloat {
        return value * verticalScale
    }

    /// 按最小比例缩放（保守缩放，避免元素过大）
    static func scaleMin(_ value: CGFloat) -> CGFloat {
        return value * min(horizontalScale, verticalScale)
    }

    // MARK: - 动态字号
    /// 基于屏幕宽度的字号缩放
    static func font(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let scaledSize = size * horizontalScale
        // 限制最小字号，避免小屏上太小
        let finalSize = max(min(scaledSize, size * 1.3), size * 0.85)
        return .systemFont(ofSize: finalSize, weight: weight)
    }

    /// 粗体字号
    static func boldFont(_ size: CGFloat) -> UIFont {
        return font(size, weight: .bold)
    }

    /// 中等字号
    static func mediumFont(_ size: CGFloat) -> UIFont {
        return font(size, weight: .medium)
    }

    // MARK: - 通用尺寸
    /// 导航栏高度（含安全区域）
    static var navBarHeight: CGFloat {
        return safeAreaTop + 44
    }

    /// TabBar高度（含安全区域）
    static var tabBarHeight: CGFloat {
        return 49 + safeAreaBottom
    }

    /// 输入栏底部偏移
    static var inputBarBottomOffset: CGFloat {
        return safeAreaBottom
    }

    // MARK: - 比例宽度
    /// 屏幕宽度的百分比
    static func widthRatio(_ ratio: CGFloat) -> CGFloat {
        return screenWidth * ratio
    }

    /// 屏幕高度的百分比
    static func heightRatio(_ ratio: CGFloat) -> CGFloat {
        return screenHeight * ratio
    }
}

// MARK: - UILayoutPriority 扩展
extension UILayoutPriority {
    static let medium = UILayoutPriority(500)
    static let lowPriority = UILayoutPriority(250)
}
