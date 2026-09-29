//
//  ThemeDimensions.swift
//  Milo
//
//  尺寸/间距规范 - 对齐安卓端 dimens.xml
//  基于 ScreenAdapter 进行屏幕适配
//

import UIKit

// MARK: - 主题尺寸系统
struct ThemeDimension {

    // MARK: - 间距 (Spacing)
    /// 超小间距 4pt
    static var spacingXS: CGFloat { ScreenAdapter.scaleW(4) }
    /// 小间距 8pt
    static var spacingS: CGFloat { ScreenAdapter.scaleW(8) }
    /// 中间距 12pt
    static var spacingM: CGFloat { ScreenAdapter.scaleW(12) }
    /// 标准间距 16pt
    static var spacing: CGFloat { ScreenAdapter.scaleW(16) }
    /// 大间距 20pt
    static var spacingL: CGFloat { ScreenAdapter.scaleW(20) }
    /// 超大间距 24pt
    static var spacingXL: CGFloat { ScreenAdapter.scaleW(24) }
    /// 特大间距 32pt
    static var spacingXXL: CGFloat { ScreenAdapter.scaleW(32) }

    /// 页面左右边距 16pt
    static var pageHorizontalPadding: CGFloat { ScreenAdapter.scaleW(16) }
    /// 页面上下边距 16pt
    static var pageVerticalPadding: CGFloat { ScreenAdapter.scaleW(16) }

    // MARK: - 圆角 (Corner Radius)
    /// 小圆角 4pt
    static var radiusS: CGFloat { ScreenAdapter.scaleW(4) }
    /// 中圆角 8pt
    static var radiusM: CGFloat { ScreenAdapter.scaleW(8) }
    /// 标准圆角 12pt
    static var radius: CGFloat { ScreenAdapter.scaleW(12) }
    /// 大圆角 16pt
    static var radiusL: CGFloat { ScreenAdapter.scaleW(16) }
    /// 超大圆角 20pt
    static var radiusXL: CGFloat { ScreenAdapter.scaleW(20) }
    /// 胶囊圆角（高度的一半）

    // MARK: - 边框 (Border)
    /// 细边框 0.5pt
    static var borderWidthThin: CGFloat { 0.5 }
    /// 标准边框 1pt
    static var borderWidth: CGFloat { 1.0 }
    /// 粗边框 2pt
    static var borderWidthThick: CGFloat { 2.0 }

    // MARK: - 阴影 (Shadow)
    /// 轻阴影
    static var shadowLight: (color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        (UIColor.black, 0.05, CGSize(width: 0, height: 2), 4)
    }
    /// 标准阴影
    static var shadowNormal: (color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        (UIColor.black, 0.08, CGSize(width: 0, height: 2), 8)
    }
    /// 深阴影
    static var shadowDark: (color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        (UIColor.black, 0.15, CGSize(width: 0, height: 4), 12)
    }

    // MARK: - 行高 (Row Height)
    /// 列表行标准高度 56pt
    static var rowHeight: CGFloat { ScreenAdapter.scaleH(56) }
    /// 列表行小高度 48pt
    static var rowHeightS: CGFloat { ScreenAdapter.scaleH(48) }
    /// 列表行大高度 64pt
    static var rowHeightL: CGFloat { ScreenAdapter.scaleH(64) }

    // MARK: - 按钮高度 (Button Height)
    /// 标准按钮高度 48pt
    static var buttonHeight: CGFloat { ScreenAdapter.scaleH(48) }
    /// 小按钮高度 36pt
    static var buttonHeightS: CGFloat { ScreenAdapter.scaleH(36) }
    /// 大按钮高度 52pt
    static var buttonHeightL: CGFloat { ScreenAdapter.scaleH(52) }

    // MARK: - 输入框高度 (Input Height)
    /// 标准输入框高度 48pt
    static var inputHeight: CGFloat { ScreenAdapter.scaleH(48) }
    /// 搜索框高度 36pt
    static var searchBarHeight: CGFloat { ScreenAdapter.scaleH(36) }

    // MARK: - 头像尺寸 (Avatar Size)
    /// 小头像 32pt
    static var avatarS: CGFloat { ScreenAdapter.scaleW(32) }
    /// 标准头像 44pt
    static var avatar: CGFloat { ScreenAdapter.scaleW(44) }
    /// 大头像 64pt
    static var avatarL: CGFloat { ScreenAdapter.scaleW(64) }
    /// 超大头像 80pt
    static var avatarXL: CGFloat { ScreenAdapter.scaleW(80) }
    /// 巨无霸头像 100pt
    static var avatarXXL: CGFloat { ScreenAdapter.scaleW(100) }

    // MARK: - 聊天气泡
    /// 气泡最大宽度比例 0.7
    static var bubbleMaxWidthRatio: CGFloat { 0.7 }
    /// 气泡圆角 12pt
    static var bubbleCornerRadius: CGFloat { ScreenAdapter.scaleW(12) }
    /// 气泡内边距 10pt
    static var bubblePadding: CGFloat { ScreenAdapter.scaleW(10) }

    // MARK: - 分割线高度
    /// 分割线高度 0.5pt
    static var separatorHeight: CGFloat { 0.5 }

    // MARK: - TabBar / NavBar
    /// TabBar 高度
    static var tabBarHeight: CGFloat { ScreenAdapter.tabBarHeight }
    /// 导航栏高度
    static var navBarHeight: CGFloat { ScreenAdapter.navBarHeight }

    // MARK: - 安全区域
    /// 顶部安全区
    static var safeAreaTop: CGFloat { ScreenAdapter.safeAreaTop }
    /// 底部安全区
    static var safeAreaBottom: CGFloat { ScreenAdapter.safeAreaBottom }
}

// MARK: - UIView 便利扩展
extension UIView {
    /// 设置标准圆角
    func setThemeCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }

    /// 设置标准阴影
    func setThemeShadow(_ shadow: (color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat)) {
        layer.shadowColor = shadow.color.cgColor
        layer.shadowOpacity = shadow.opacity
        layer.shadowOffset = shadow.offset
        layer.shadowRadius = shadow.radius
        layer.masksToBounds = false
    }
}
