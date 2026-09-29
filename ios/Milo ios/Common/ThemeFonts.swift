//
//  ThemeFonts.swift
//  Milo
//
//  字体系统 - 对齐安卓端字号规范
//  基于 ScreenAdapter 进行屏幕适配
//

import UIKit

// MARK: - 主题字体系统
struct ThemeFont {

    // MARK: - 标题字体
    /// 大标题 24pt Bold
    static func titleLarge(_ size: CGFloat = 24) -> UIFont {
        ScreenAdapter.font(size, weight: .bold)
    }

    /// 标题1 20pt Bold
    static func title1(_ size: CGFloat = 20) -> UIFont {
        ScreenAdapter.font(size, weight: .bold)
    }

    /// 标题2 18pt Semibold
    static func title2(_ size: CGFloat = 18) -> UIFont {
        ScreenAdapter.font(size, weight: .semibold)
    }

    /// 标题3 16pt Medium
    static func title3(_ size: CGFloat = 16) -> UIFont {
        ScreenAdapter.font(size, weight: .medium)
    }

    // MARK: - 正文字体
    /// 正文大号 17pt Regular
    static func bodyLarge(_ size: CGFloat = 17) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    /// 正文 16pt Regular
    static func body(_ size: CGFloat = 16) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    /// 正文小号 14pt Regular
    static func bodySmall(_ size: CGFloat = 14) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    // MARK: - 辅助文字
    /// 辅助文字 13pt Regular
    static func caption(_ size: CGFloat = 13) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    /// 小字 12pt Regular
    static func small(_ size: CGFloat = 12) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    /// 最小号 10pt Regular
    static func tiny(_ size: CGFloat = 10) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    // MARK: - 粗体变体
    /// 正文粗体 16pt Medium
    static func bodyMedium(_ size: CGFloat = 16) -> UIFont {
        ScreenAdapter.font(size, weight: .medium)
    }

    /// 正文粗体 16pt Bold
    static func bodyBold(_ size: CGFloat = 16) -> UIFont {
        ScreenAdapter.font(size, weight: .bold)
    }

    /// 辅助文字粗体 14pt Medium
    static func captionMedium(_ size: CGFloat = 14) -> UIFont {
        ScreenAdapter.font(size, weight: .medium)
    }

    /// 小字粗体 12pt Medium
    static func smallMedium(_ size: CGFloat = 12) -> UIFont {
        ScreenAdapter.font(size, weight: .medium)
    }

    // MARK: - 数字字体 (等宽)
    /// 数字字体 16pt Medium (等宽)
    static func number(_ size: CGFloat = 16) -> UIFont {
        let font = ScreenAdapter.font(size, weight: .medium)
        let descriptor = font.fontDescriptor.addingAttributes([
            .featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector
            ]]
        ])
        return UIFont(descriptor: descriptor, size: 0)
    }

    // MARK: - 聊天气泡字体
    /// 聊天消息文字 16pt Regular
    static func chatMessage(_ size: CGFloat = 16) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    /// 聊天时间戳 11pt Regular
    static func chatTimestamp(_ size: CGFloat = 11) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    // MARK: - TabBar / NavBar
    /// TabBar 标题 10pt Regular
    static func tabBarTitle(_ size: CGFloat = 10) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }

    /// 导航栏标题 17pt Semibold
    static func navBarTitle(_ size: CGFloat = 17) -> UIFont {
        ScreenAdapter.font(size, weight: .semibold)
    }

    // MARK: - 按钮字体
    /// 按钮大字 17pt Medium
    static func buttonLarge(_ size: CGFloat = 17) -> UIFont {
        ScreenAdapter.font(size, weight: .medium)
    }

    /// 按钮普通 16pt Regular
    static func button(_ size: CGFloat = 16) -> UIFont {
        ScreenAdapter.font(size, weight: .regular)
    }
}

// MARK: - UILabel 便利扩展
extension UILabel {
    /// 设置主题字体
    func setThemeFont(_ font: UIFont) {
        self.font = font
    }
}
