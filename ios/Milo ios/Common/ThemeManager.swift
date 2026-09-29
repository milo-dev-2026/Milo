//
//  ThemeManager.swift
//  Milo
//
//  主题管理器 - 深色模式 / 浅色模式切换
//  支持三种模式：跟随系统、浅色、深色
//  切换时带有淡入淡出过渡动画
//

import UIKit

// MARK: - 主题模式枚举
enum ThemeMode: Int {
    case system = 0     // 跟随系统
    case light = 1      // 浅色模式
    case dark = 2       // 深色模式

    /// 模式显示名称
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

// MARK: - 主题管理器
class ThemeManager {

    static let shared = ThemeManager()

    private init() {}

    // MARK: - 当前主题模式
    private(set) var currentMode: ThemeMode {
        get {
            // 兼容旧版存储键 "appearance_mode" 和新版 "theme_mode"
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "theme_mode") != nil {
                let rawValue = defaults.integer(forKey: "theme_mode")
                return ThemeMode(rawValue: rawValue) ?? .system
            } else if defaults.object(forKey: "appearance_mode") != nil {
                let rawValue = defaults.integer(forKey: "appearance_mode")
                return ThemeMode(rawValue: rawValue) ?? .system
            }
            return .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "theme_mode")
            // 同步到旧键名以保持兼容
            UserDefaults.standard.set(newValue.rawValue, forKey: "appearance_mode")
            applyTheme(animated: true)
        }
    }

    // MARK: - 当前是否为深色模式
    var isDarkMode: Bool {
        switch currentMode {
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }

    // MARK: - 切换动画时长
    var transitionDuration: TimeInterval = 0.35

    // MARK: - 应用主题
    /// 应用当前主题模式到所有窗口
    /// - Parameter animated: 是否使用过渡动画
    func applyTheme(animated: Bool = true) {
        let style: UIUserInterfaceStyle
        switch currentMode {
        case .system:
            style = .unspecified
        case .light:
            style = .light
        case .dark:
            style = .dark
        }

        // 获取所有 window
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }

        if animated {
            // 执行淡入淡出过渡动画
            animateThemeChange(to: style, windows: windows)
        } else {
            // 直接应用，无动画
            windows.forEach { window in
                window.overrideUserInterfaceStyle = style
            }
        }

        // 发送主题变更通知
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
    }

    // MARK: - 切换主题
    /// 设置主题模式
    /// - Parameters:
    ///   - mode: 目标主题模式
    ///   - animated: 是否使用过渡动画
    func setThemeMode(_ mode: ThemeMode, animated: Bool = true) {
        guard mode != currentMode else { return }

        // 存储到新键和旧键（保持兼容）
        UserDefaults.standard.set(mode.rawValue, forKey: "theme_mode")
        UserDefaults.standard.set(mode.rawValue, forKey: "appearance_mode")
        applyTheme(animated: animated)
    }

    /// 在浅色和深色之间切换（不影响系统跟随模式）
    func toggleDarkMode() {
        if isDarkMode {
            setThemeMode(.light)
        } else {
            setThemeMode(.dark)
        }
    }

    // MARK: - 主题切换动画
    /// 执行主题切换的过渡动画
    /// 使用 snapshotView 实现平滑的淡入淡出效果
    private func animateThemeChange(to style: UIUserInterfaceStyle, windows: [UIWindow]) {
        for window in windows {
            // 1. 捕获当前状态的快照
            guard let snapshot = window.snapshotView(afterScreenUpdates: false) else {
                window.overrideUserInterfaceStyle = style
                continue
            }

            // 2. 先应用新主题
            window.overrideUserInterfaceStyle = style

            // 3. 将快照覆盖在最上层
            window.addSubview(snapshot)
            snapshot.frame = window.bounds

            // 4. 动画淡出快照，露出新主题
            UIView.transition(with: window,
                              duration: transitionDuration,
                              options: .transitionCrossDissolve,
                              animations: {
                snapshot.alpha = 0
                              },
                              completion: { _ in
                snapshot.removeFromSuperview()
                              })
        }
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChangeNotification")
}

// MARK: - UIViewController 主题扩展
extension UIViewController {
    /// 监听主题变化
    func observeThemeChange(selector: Selector) {
        NotificationCenter.default.addObserver(
            self,
            selector: selector,
            name: .themeDidChange,
            object: nil
        )
    }

    /// 移除主题变化监听
    func removeThemeObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: .themeDidChange,
            object: nil
        )
    }
}

// MARK: - UIView 主题扩展
extension UIView {
    /// 监听主题变化
    func observeThemeChange(selector: Selector) {
        NotificationCenter.default.addObserver(
            self,
            selector: selector,
            name: .themeDidChange,
            object: nil
        )
    }
}
