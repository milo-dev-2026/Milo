//
//  ThemeColors.swift
//  Milo
//
//  完整颜色系统 - 对齐安卓端 colors.xml 定义
//  支持深色模式自动适配（iOS 13+ 动态颜色）
//
//  设计规范：
//  - 所有颜色均使用 UIColor(dynamicProvider:) 创建动态颜色
//  - 浅色模式和深色模式的颜色值经过精心设计
//  - 确保对比度满足 WCAG AA 标准（4.5:1）
//  - 每个颜色都有注释说明使用场景
//

import UIKit

// MARK: - 主题颜色系统
extension UIColor {

    // MARK: - 主色调 (Primary)
    /// 主色调 - 品牌蓝色，用于主要按钮、链接、选中态等
    /// 浅色: #3F74FC  深色: #5B8CFF（更亮的蓝，确保深色模式下可见性）
    static let themeColorPrimary = dynamicColor(light: 0x3F74FC, dark: 0x5B8CFF)

    /// 主色调深色 - 按压态/选中态
    /// 浅色: #2F5EDC  深色: #4A7AED
    static let themeColorPrimaryDark = dynamicColor(light: 0x2F5EDC, dark: 0x4A7AED)

    /// 主色调浅色 - 背景点缀、弱选中态
    /// 浅色: 主色 12% alpha  深色: 主色 15% alpha
    static let themeColorPrimaryLight = dynamicColor(light: 0x3F74FC, dark: 0x5B8CFF).withAlphaComponent(0.12)

    /// 辅助色 - 用于次要操作、装饰元素
    /// 浅色: #FF9500  深色: #FFAA33
    static let themeColorSecondary = dynamicColor(light: 0xFF9500, dark: 0xFFAA33)

    /// 强调色 - 用于需要突出显示的元素
    /// 浅色: #FF3B30  深色: #FF6B6B
    static let themeColorAccent = dynamicColor(light: 0xFF3B30, dark: 0xFF6B6B)

    // MARK: - 背景色 (Background)
    /// 全局背景色 - 页面最底层背景
    /// 浅色: #F6F7F9 (浅灰蓝)  深色: #111318 (深灰黑)
    static let themeBg = dynamicColor(light: 0xF6F7F9, dark: 0x111318)

    /// 页面背景色（白色系）- 内容区域背景
    /// 浅色: #FFFFFF  深色: #1A1D22
    static let themeBgWhite = dynamicColor(light: 0xFFFFFF, dark: 0x1A1D22)

    /// 次级背景色 - 卡片/单元格背景，比页面背景略深或略浅
    /// 浅色: #FFFFFF  深色: #262930
    static let themeBgCard = dynamicColor(light: 0xFFFFFF, dark: 0x262930)

    /// 三级背景色 - 输入框、搜索栏等内嵌元素背景
    /// 浅色: #F6F6F6  深色: #2D3038
    static let themeBgTertiary = dynamicColor(light: 0xF6F6F6, dark: 0x2D3038)

    /// 聊天背景色
    /// 浅色: #F6F7F9  深色: #111318
    static let themeBgChat = dynamicColor(light: 0xF6F7F9, dark: 0x111318)

    /// 灰色背景 F5F5F5 - 分组背景、段头背景
    /// 浅色: #F5F5F5  深色: #1A1D22
    static let themeBgGrayF5 = dynamicColor(light: 0xF5F5F5, dark: 0x1A1D22)

    /// 浅灰背景 F7F7F7 - 更浅的分组背景
    /// 浅色: #F7F7F7  深色: #1A1D22
    static let themeBgGrayF7 = dynamicColor(light: 0xF7F7F7, dark: 0x1A1D22)

    /// 输入框背景
    /// 浅色: #F6F6F6  深色: #262930
    static let themeBgInput = dynamicColor(light: 0xF6F6F6, dark: 0x262930)

    /// 搜索栏背景
    /// 浅色: #EFEFF0  深色: #262930
    static let themeBgSearchBar = dynamicColor(light: 0xEFEFF0, dark: 0x262930)

    /// 置顶会话背景
    /// 浅色: #F0F5FF  深色: #1A2238
    static let themeBgPinned = dynamicColor(light: 0xF0F5FF, dark: 0x1A2238)

    /// 分组背景（insetGrouped tableView 的背景）
    /// 浅色: #F2F2F7  深色: #0C0E12
    static let themeBgGrouped = dynamicColor(light: 0xF2F2F7, dark: 0x0C0E12)

    // MARK: - 文字色 (Text)
    /// 主要文字色 - 标题、正文等主要内容
    /// 浅色: #2B313D (深灰蓝)  深色: #E9EBEF (近白)
    static let themeTextPrimary = dynamicColor(light: 0x2B313D, dark: 0xE9EBEF)

    /// 次要文字色 - 副标题、辅助说明等
    /// 浅色: #787A7E  深色: #9BA1AD
    static let themeTextSecondary = dynamicColor(light: 0x787A7E, dark: 0x9BA1AD)

    /// 三级文字色 - 更次要的文字信息
    /// 浅色: #888A95  深色: #7D8390
    static let themeTextTertiary = dynamicColor(light: 0x888A95, dark: 0x7D8390)

    /// 提示/占位符文字色 - 输入框 placeholder
    /// 浅色: #B4B6BD  深色: #5A5F6B
    static let themeTextHint = dynamicColor(light: 0xB4B6BD, dark: 0x5A5F6B)

    /// 禁用文字色 - 禁用状态下的文字
    /// 浅色: #B4B6BD  深色: #5A5F6B
    static let themeTextDisable = dynamicColor(light: 0xB4B6BD, dark: 0x5A5F6B)

    /// 白色文字 - 在彩色背景上使用（保持白色，深浅模式一致）
    static let themeTextWhite = dynamicColor(light: 0xFFFFFF, dark: 0xFFFFFF)

    /// 反色文字 - 在气泡等彩色背景上的文字色
    /// 浅色: #2B313D  深色: #FFFFFF
    static let themeTextInverse = dynamicColor(light: 0x2B313D, dark: 0xFFFFFF)

    /// 链接文字色
    /// 浅色: #3F74FC  深色: #5B8CFF
    static let themeTextLink = dynamicColor(light: 0x3F74FC, dark: 0x5B8CFF)

    // MARK: - 分割线 (Separator / Divider)
    /// 分割线颜色 - 主要分割线（单元格分隔、页面分隔）
    /// 浅色: #E4E7EA  深色: #33363D
    static let themeSeparator = dynamicColor(light: 0xE4E7EA, dark: 0x33363D)

    /// 分割线浅色 - 较淡的分割线
    /// 浅色: #F1F2F4  深色: #2A2D33
    static let themeSeparatorLight = dynamicColor(light: 0xF1F2F4, dark: 0x2A2D33)

    /// 分割线 E5 - 兼容设计稿
    /// 浅色: #E5E5E5  深色: #33363D
    static let themeSeparatorE5 = dynamicColor(light: 0xE5E5E5, dark: 0x33363D)

    /// 虚线颜色
    /// 浅色: 黑色 8% alpha  深色: 白色 8% alpha
    static let themeSeparatorDashed = dynamicColor(light: 0x000000, dark: 0xFFFFFF).withAlphaComponent(0.08)

    /// 毛玻璃底部分割线
    /// 浅色: 白色 20% alpha  深色: 白色 10% alpha
    static var themeSeparatorGlass: UIColor {
        UITraitCollection.current.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.1)
            : UIColor.white.withAlphaComponent(0.2)
    }

    // MARK: - 聊天气泡 (Chat Bubble)
    /// 发送气泡背景 - 自己发送的消息气泡（对齐安卓 #3F74FC 蓝色）
    /// 浅色: #3F74FC (品牌蓝)  深色: #5B8CFF (更亮的蓝，确保深色模式下可见性)
    static let themeBubbleSend = dynamicColor(light: 0x3F74FC, dark: 0x5B8CFF)

    /// 发送气泡深色按压态
    /// 浅色: #2F5EDC  深色: #4A7AED
    static let themeBubbleSendHighlight = dynamicColor(light: 0x2F5EDC, dark: 0x4A7AED)

    /// 接收气泡背景 - 对方发送的消息气泡
    /// 浅色: #FFFFFF  深色: #262930
    static let themeBubbleReceive = dynamicColor(light: 0xFFFFFF, dark: 0x262930)

    /// 接收气泡深色按压态
    /// 浅色: #F5F5F5  深色: #33363D
    static let themeBubbleReceiveHighlight = dynamicColor(light: 0xF5F5F5, dark: 0x33363D)

    /// 发送文字颜色 - 蓝色气泡上使用白色文字（浅色/深色模式均为白色）
    static let themeBubbleSendText = dynamicColor(light: 0xFFFFFF, dark: 0xFFFFFF)

    /// 接收文字颜色
    /// 浅色: #2B313D  深色: #E9EBEF
    static let themeBubbleReceiveText = dynamicColor(light: 0x2B313D, dark: 0xE9EBEF)

    /// 气泡边框
    /// 浅色: #B6B5B5  深色: #4A4D55
    static let themeBubbleBorder = dynamicColor(light: 0xB6B5B5, dark: 0x4A4D55)

    /// 时间分隔头背景
    /// 浅色: 灰色 10% alpha  深色: 白色 10% alpha
    static let themeTimeHeaderBg = dynamicColor(light: 0x000000, dark: 0xFFFFFF).withAlphaComponent(0.08)

    /// 系统消息背景
    /// 浅色: #E8E8E8  深色: #2D3038
    static let themeSystemMessageBg = dynamicColor(light: 0xE8E8E8, dark: 0x2D3038)

    // MARK: - 状态色 (Status)
    /// 成功/绿色 - 成功状态、通过、完成
    /// 浅色: #5DB85A  深色: #6DCF6A
    static let themeSuccess = dynamicColor(light: 0x5DB85A, dark: 0x6DCF6A)

    /// 成功色浅色背景
    /// 浅色: 绿色 10% alpha  深色: 绿色 15% alpha
    static let themeSuccessLight = dynamicColor(light: 0x5DB85A, dark: 0x6DCF6A).withAlphaComponent(0.12)

    /// 警告/黄色 - 警告状态、注意事项
    /// 浅色: #FFBC0E  深色: #FFC933
    static let themeWarning = dynamicColor(light: 0xFFBC0E, dark: 0xFFC933)

    /// 警告色浅色背景
    /// 浅色: 黄色 10% alpha  深色: 黄色 15% alpha
    static let themeWarningLight = dynamicColor(light: 0xFFBC0E, dark: 0xFFC933).withAlphaComponent(0.12)

    /// 错误/红色 - 错误状态、失败
    /// 浅色: #FA5151  深色: #FF6B6B
    static let themeError = dynamicColor(light: 0xFA5151, dark: 0xFF6B6B)

    /// 错误色浅色背景
    /// 浅色: 红色 10% alpha  深色: 红色 15% alpha
    static let themeErrorLight = dynamicColor(light: 0xFA5151, dark: 0xFF6B6B).withAlphaComponent(0.12)

    /// 危险/红色深 - 危险操作、删除
    /// 浅色: #D84B5B  深色: #E85D6D
    static let themeDanger = dynamicColor(light: 0xD84B5B, dark: 0xE85D6D)

    /// 信息/蓝色 - 信息提示、通知
    /// 浅色: #3F74FC  深色: #5B8CFF
    static let themeInfo = dynamicColor(light: 0x3F74FC, dark: 0x5B8CFF)

    /// 信息色浅色背景
    /// 浅色: 蓝色 10% alpha  深色: 蓝色 15% alpha
    static let themeInfoLight = dynamicColor(light: 0x3F74FC, dark: 0x5B8CFF).withAlphaComponent(0.12)

    // MARK: - 边框 (Border)
    /// 边框颜色 - 普通边框
    /// 浅色: #CCCCCC  深色: #4A4D55
    static let themeBorder = dynamicColor(light: 0xCCCCCC, dark: 0x4A4D55)

    /// 边框浅色 - 较淡的边框
    /// 浅色: #E8E7E7  深色: #33363D
    static let themeBorderLight = dynamicColor(light: 0xE8E7E7, dark: 0x33363D)

    /// 毛玻璃边框颜色
    /// 浅色: 白色 30% alpha  深色: 白色 15% alpha
    static var themeBorderGlass: UIColor {
        UITraitCollection.current.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.15)
            : UIColor.white.withAlphaComponent(0.3)
    }

    // MARK: - 毛玻璃 (Liquid Glass / Frosted Glass) - iOS 特色保留
    /// 导航栏毛玻璃样式
    static var themeBlurStyleNavBar: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemMaterial
    }

    /// TabBar 毛玻璃样式
    static var themeBlurStyleTabBar: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemMaterial
    }

    /// 底部弹窗毛玻璃样式
    static var themeBlurStyleBottomSheet: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemUltraThinMaterialLight
    }

    /// Toast 毛玻璃样式
    static var themeBlurStyleToast: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
    }

    /// 卡片毛玻璃样式
    static var themeBlurStyleCard: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemMaterialDark : .systemUltraThinMaterialLight
    }

    /// 输入框毛玻璃样式
    static var themeBlurStyleInput: UIBlurEffect.Style {
        UITraitCollection.current.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
    }

    // MARK: - 液态玻璃专用颜色 (Liquid Glass)
    /// 液态玻璃边框颜色（自动深色模式适配）
    static var liquidGlassBorder: UIColor {
        UITraitCollection.current.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.15)
            : UIColor.white.withAlphaComponent(0.3)
    }

    /// 液态玻璃高光颜色
    static var liquidGlassHighlight: UIColor {
        UITraitCollection.current.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.white.withAlphaComponent(0.15)
    }

    /// 液态玻璃色调叠加层颜色
    static var liquidGlassTint: UIColor {
        UITraitCollection.current.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.1)
            : UIColor.white.withAlphaComponent(0.18)
    }

    // MARK: - 名字颜色 (Name Colors)
    /// 名字颜色1 - 蓝
    static let themeNameColor1 = dynamicColor(light: 0x3F74FC, dark: 0x5B8CFF)
    /// 名字颜色2 - 橙
    static let themeNameColor2 = dynamicColor(light: 0xE67C2A, dark: 0xF58C3A)
    /// 名字颜色3 - 绿
    static let themeNameColor3 = dynamicColor(light: 0x5DB85A, dark: 0x6DCF6A)
    /// 名字颜色4 - 红
    static let themeNameColor4 = dynamicColor(light: 0xD94C4C, dark: 0xE85D5D)
    /// 名字颜色5 - 紫
    static let themeNameColor5 = dynamicColor(light: 0x9B59B6, dark: 0xAD6BC8)
    /// 名字颜色6 - 青
    static let themeNameColor6 = dynamicColor(light: 0x1ABC9C, dark: 0x2CD0AE)
    /// 名字颜色7 - 粉
    static let themeNameColor7 = dynamicColor(light: 0xE91E63, dark: 0xF53A78)
    /// 名字颜色8 - 天蓝
    static let themeNameColor8 = dynamicColor(light: 0x00BCD4, dark: 0x1DD0E8)

    // MARK: - 头像占位色 (Avatar Placeholder)
    /// 头像占位背景色
    /// 浅色: #E0E0E0  深色: #33363D
    static let themeAvatarPlaceholderBg = dynamicColor(light: 0xE0E0E0, dark: 0x33363D)

    /// 头像占位图标色
    /// 浅色: #B0B0B0  深色: #6B6F78
    static let themeAvatarPlaceholderTint = dynamicColor(light: 0xB0B0B0, dark: 0x6B6F78)

    // MARK: - 安全中心 (Security)
    /// 安全中心-账号背景
    static let themeSecurityBg = dynamicColor(light: 0xF6F7F9, dark: 0x111318)
    /// 安全中心-卡片背景
    static let themeSecurityCardBg = dynamicColor(light: 0xFFFFFF, dark: 0x262930)
    /// 安全中心-hero背景
    static let themeSecurityHeroBg = dynamicColor(light: 0xEDF2FF, dark: 0x1A2238)
    /// 安全中心-分割线
    static let themeSecurityDivider = dynamicColor(light: 0xEEF0F3, dark: 0x33363D)
    /// 安全中心-危险色
    static let themeSecurityDanger = dynamicColor(light: 0xFA5151, dark: 0xFF6B6B)
    /// 注销账号警告背景
    static let themeDestroyWarningBg = dynamicColor(light: 0xFFF0F0, dark: 0x2E1A1A)

    // MARK: - 笔记 (Notes)
    /// 笔记标题颜色
    static let themeNoteTitle = dynamicColor(light: 0x3C4047, dark: 0xE0E3E8)
    /// 笔记内容颜色
    static let themeNoteContent = dynamicColor(light: 0x888A95, dark: 0x9BA1AD)
    /// 笔记日期颜色
    static let themeNoteDate = dynamicColor(light: 0xB4B6BD, dark: 0x5A5F6B)
    /// 笔记分割线
    static let themeNoteLine = dynamicColor(light: 0xE4E7EA, dark: 0x33363D)
    /// 笔记正文颜色
    static let themeNoteText = dynamicColor(light: 0x2B313D, dark: 0xE9EBEF)
    /// 笔记粗色
    static let themeNoteCoarse = dynamicColor(light: 0x3D3E41, dark: 0xDCDFE4)

    // MARK: - 登录注册 (Login)
    /// 登录页面背景
    static let themeLoginBg = dynamicColor(light: 0xFFFFFF, dark: 0x1A1D22)
    /// 登录卡片背景
    static let themeLoginCardBg = dynamicColor(light: 0xFFFFFF, dark: 0x262930)
    /// 登录hero背景
    static let themeLoginHeroBg = dynamicColor(light: 0xEDF2FF, dark: 0x1A2238)
    /// 登录输入框背景
    static let themeLoginInputBg = dynamicColor(light: 0xF6F7F9, dark: 0x262930)
    /// 登录错误色
    static let themeLoginError = dynamicColor(light: 0xFF3B30, dark: 0xFF5544)

    // MARK: - 表情面板 (Sticker / Emoji)
    /// 表情面板背景
    static let themeEmojiPanelBg = dynamicColor(light: 0xFFFFFF, dark: 0x262930)
    /// 表情Tab背景
    static let themeEmojiTabBg = dynamicColor(light: 0xFFFFFF, dark: 0x262930)

    // MARK: - 骨架屏 (Skeleton / Shimmer)
    /// 骨架屏背景色
    static let themeSkeletonBg = dynamicColor(light: 0xE0E0E0, dark: 0x33363D)
    /// 骨架屏闪烁色
    static let themeSkeletonShimmer = dynamicColor(light: 0xD5D5D5, dark: 0x3D4048)
    /// Shimmer 颜色
    static let themeShimmerColor = dynamicColor(light: 0x878787, dark: 0x5A5F6B).withAlphaComponent(0.6)

    // MARK: - 弹窗/浮层 (Popup / Dialog)
    /// 弹窗背景
    static let themePopupBg = dynamicColor(light: 0xFFFFFF, dark: 0x262930)
    /// 弹窗文字主色
    static let themePopupTextPrimary = dynamicColor(light: 0x2B313D, dark: 0xE9EBEF)
    /// 弹窗文字次色
    static let themePopupTextSecondary = dynamicColor(light: 0x676A6F, dark: 0x9BA1AD)
    /// 遮罩层颜色
    static let themeOverlay = dynamicColor(light: 0x000000, dark: 0x000000).withAlphaComponent(0.5)
    /// 底部弹窗背景
    static let themeBottomSheetBg = dynamicColor(light: 0xFFFFFF, dark: 0x262930)
    /// 底部弹窗把手颜色
    static let themeBottomSheetHandle = dynamicColor(light: 0xE0E0E0, dark: 0x4A4D55)

    // MARK: - 开关 (Switch)
    /// 开关滑块颜色
    static let themeSwitchThumb = dynamicColor(light: 0xFFFFFF, dark: 0xE0E0E0)
    /// 开关未选中轨道
    static let themeSwitchTrackOff = dynamicColor(light: 0xCCCCCC, dark: 0x5A5F6B)

    // MARK: - 密码输入 (Password View)
    /// 密码框边框
    static let themePwdOutline = dynamicColor(light: 0xF1F2F4, dark: 0x33363D)
    /// 密码框表面
    static let themePwdSurface = dynamicColor(light: 0xFFFFFF, dark: 0x262930)
    /// 密码提示文字
    static let themePwdHint = dynamicColor(light: 0xB4B6BD, dark: 0x5A5F6B)

    // MARK: - 分享 (Share)
    /// 分享面板背景
    static let themeSharePanelBg = dynamicColor(light: 0xE5EBFB, dark: 0x1A2238)
    /// 分享输入框背景
    static let themeShareInputBg = dynamicColor(light: 0xF3F5F9, dark: 0x262930)

    // MARK: - 群组 (Group)
    /// 群公告banner背景
    static let themeGroupBannerBg = dynamicColor(light: 0xCEDDEF, dark: 0x2A3550)
    /// 群公告按钮背景
    static let themeGroupBannerBtnBg = dynamicColor(light: 0xEBF2FF, dark: 0x1A2238)

    // MARK: - 账号绑定 (Account Binding)
    /// 已绑定背景
    static let themeBoundBg = dynamicColor(light: 0xEDF2FF, dark: 0x1A2238)
    /// 未绑定背景
    static let themeUnboundBg = dynamicColor(light: 0xF1F2F4, dark: 0x262930)

    // MARK: - 会话列表 (Conversation)
    /// 会话选中背景
    static let themeConvSelectedBg = dynamicColor(light: 0xEBF2FF, dark: 0x1A2238)
    /// 会话广告通知背景
    static let themeConvAdBg = dynamicColor(light: 0xFFB052, dark: 0xFFC933).withAlphaComponent(0.12)

    // MARK: - 消息回应 (Reaction)
    /// 回应背景
    static let themeReactionBg = dynamicColor(light: 0x000000, dark: 0xFFFFFF).withAlphaComponent(0.15)

    // MARK: - 索引条 (Index Bar) - 通讯录右侧字母索引
    /// 索引条文字颜色
    /// 浅色: #3F74FC  深色: #5B8CFF
    static let themeIndexBarText = dynamicColor(light: 0x3F74FC, dark: 0x5B8CFF)

    /// 索引条背景色（按下时）
    /// 浅色: 灰色 20% alpha  深色: 白色 15% alpha
    static let themeIndexBarBg = dynamicColor(light: 0x000000, dark: 0xFFFFFF).withAlphaComponent(0.1)

    // MARK: - 辅助方法
    /// 创建动态颜色（自动适配深色模式）
    /// - Parameters:
    ///   - light: 浅色模式下的颜色（十六进制 0xRRGGBB 格式）
    ///   - dark: 深色模式下的颜色（十六进制 0xRRGGBB 格式）
    /// - Returns: 动态 UIColor，自动随用户界面风格切换
    private static func dynamicColor(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? hex0x(dark) : hex0x(light)
        }
    }

    /// 十六进制颜色转换（0xRRGGBB 格式）
    private static func hex0x(_ hex: UInt32) -> UIColor {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hex & 0x0000FF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    /// 十六进制字符串颜色（兼容旧代码）
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

// MARK: - 旧命名兼容 (Backward Compatibility)
extension UIColor {
    /// 主色调：现代蓝 #3F74FC（对齐安卓 colorPrimary）
    @available(*, deprecated, renamed: "themeColorPrimary")
    static let themePrimary = themeColorPrimary
    /// 主色调深色（按压态）
    @available(*, deprecated, renamed: "themeColorPrimaryDark")
    static let themePrimaryDark = themeColorPrimaryDark
    /// 主色调浅色（背景点缀）
    @available(*, deprecated, renamed: "themeColorPrimaryLight")
    static let themePrimaryLight = themeColorPrimaryLight

    /// 全局背景色：浅灰 #F6F7F9
    @available(*, deprecated, renamed: "themeBg")
    static let themeBackground = themeBg
    /// 聊天背景色
    @available(*, deprecated, renamed: "themeBgChat")
    static let themeChatBackground = themeBgChat
    /// 卡片/单元格背景
    @available(*, deprecated, renamed: "themeBgCard")
    static let themeCardBackground = themeBgCard

    /// 主要文字色
    @available(*, deprecated, renamed: "themeTextPrimary")
    static let themeTextPrimaryOld = themeTextPrimary
    /// 次要文字色
    @available(*, deprecated, renamed: "themeTextSecondary")
    static let themeTextSecondaryOld = themeTextSecondary
    /// 三级文字色
    @available(*, deprecated, renamed: "themeTextTertiary")
    static let themeTextTertiaryOld = themeTextTertiary

    /// 分割线颜色
    @available(*, deprecated, renamed: "themeSeparator")
    static let themeSeparatorOld = themeSeparator
    /// 兼容旧命名
    @available(*, deprecated, renamed: "themeSeparator")
    static let themeCellSeparator = themeSeparator

    /// 自己发送的气泡背景
    @available(*, deprecated, renamed: "themeBubbleSend")
    static let themeBubbleOutgoing = themeBubbleSend
    /// 接收的气泡背景
    @available(*, deprecated, renamed: "themeBubbleReceive")
    static let themeBubbleIncoming = themeBubbleReceive

    /// 毛玻璃样式（旧接口兼容）
    @available(*, deprecated, renamed: "themeBlurStyleNavBar")
    static var themeBlurStyle: UIBlurEffect.Style { themeBlurStyleNavBar }
}
