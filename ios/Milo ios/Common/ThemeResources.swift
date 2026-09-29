//
//  ThemeResources.swift
//  Milo
//
//  资源统一管理 - 图片、图标、字符串资源
//  对齐安卓端资源命名规范
//

import UIKit

// MARK: - 图标资源统一管理
// ThemeIcon 枚举已迁移至 Common/ThemeIcons.swift，
// 提供类型安全的 SF Symbol 访问、尺寸/颜色/字重/层级色等高级配置。
// 旧字符串常量 API 请使用 ThemeIcon.xxx.rawValue 或 UIImage.icon(_:size:color:) 替代。

// MARK: - 图片资源统一管理
enum ThemeImage {

    // MARK: - 背景图片
    static let chatBgDefault = "chat_bg_default"
    static let chatBgLight = "chat_bg_light"
    static let chatBgDark = "chat_bg_dark"

    // MARK: - Logo
    static let appLogo = "app_logo"
    static let launchLogo = "launch_logo"

    // MARK: - 占位图
    static let placeholderAvatar = "placeholder_avatar"
    static let placeholderGroup = "placeholder_group"
    static let placeholderImage = "placeholder_image"
    static let emptyChat = "empty_chat"
    static let emptyContact = "empty_contact"
    static let emptyMoment = "empty_moment"

    // MARK: - 气泡图片
    static let bubbleRight = "bubble_right"
    static let bubbleLeft = "bubble_left"
    static let bubbleRightHighlight = "bubble_right_highlight"
    static let bubbleLeftHighlight = "bubble_left_highlight"

    // MARK: - 输入栏
    static let inputBg = "input_bg"
    static let voiceBtnNormal = "voice_btn_normal"
    static let voiceBtnPressed = "voice_btn_pressed"

    // MARK: - 获取图片（带 fallback）
    static func image(named name: String, fallback systemName: String? = nil) -> UIImage? {
        if let image = UIImage(named: name) {
            return image
        }
        if let systemName = systemName {
            return UIImage(systemName: systemName)
        }
        return nil
    }
}

// MARK: - 字符串资源统一管理
enum ThemeString {

    // MARK: - 通用
    static let appName = "Milo"
    static let ok = "确定"
    static let cancel = "取消"
    static let delete = "删除"
    static let edit = "编辑"
    static let save = "保存"
    static let cancelEdit = "取消编辑"
    static let loading = "加载中..."
    static let loadFailed = "加载失败"
    static let noMore = "没有更多了"
    static let noData = "暂无数据"
    static let search = "搜索"
    static let searchPlaceholder = "搜索"
    static let send = "发送"
    static let confirm = "确认"
    static let done = "完成"
    static let back = "返回"
    static let more = "更多"
    static let all = "全部"

    // MARK: - 消息
    static let messageTitle = "消息"
    static let newMessage = "新消息"
    static let noMessage = "暂无消息"
    static let messageFailed = "发送失败，点击重试"
    static let messageRecall = "撤回了一条消息"
    static let messageDeleted = "该消息已删除"
    static let typing = "对方正在输入..."

    // MARK: - 通讯录
    static let contactsTitle = "通讯录"
    static let newFriend = "新朋友"
    static let groupChat = "群聊"
    static let tag = "标签"
    static let officialAccount = "公众号"

    // MARK: - 发现
    static let discoverTitle = "发现"
    static let moment = "朋友圈"
    static let scan = "扫一扫"
    static let shake = "摇一摇"
    static let nearby = "附近的人"

    // MARK: - 我的
    static let profileTitle = "我的"
    static let setting = "设置"
    static let collection = "收藏"
    static let wallet = "钱包"
    static let card = "卡包"
    static let expression = "表情"

    // MARK: - 设置
    static let accountSecurity = "账号安全"
    static let messageNotice = "消息通知"
    static let privacy = "隐私设置"
    static let general = "通用设置"
    static let about = "关于我们"
    static let help = "帮助与反馈"
    static let language = "多语言"
    static let chatBackup = "聊天记录备份"

    // MARK: - 错误提示
    static let networkError = "网络连接失败，请检查网络设置"
    static let serverError = "服务器错误，请稍后重试"
    static let parameterError = "参数错误"
    static let tokenExpired = "登录已过期，请重新登录"
    static let permissionDenied = "权限不足"

    // MARK: - 操作提示
    static let copySuccess = "已复制到剪贴板"
    static let deleteSuccess = "删除成功"
    static let saveSuccess = "保存成功"
    static let sendSuccess = "发送成功"
    static let addSuccess = "添加成功"
    static let loadMoreFailed = "加载更多失败"
    static let pullToRefresh = "下拉刷新"
    static let releaseToRefresh = "释放立即刷新"
    static let refreshing = "刷新中..."
}

// MARK: - 字体大小快捷映射
enum ThemeFontSize {
    static let tiny: CGFloat = 10
    static let caption: CGFloat = 12
    static let bodySmall: CGFloat = 13
    static let body: CGFloat = 15
    static let bodyLarge: CGFloat = 16
    static let title3: CGFloat = 17
    static let title2: CGFloat = 18
    static let title1: CGFloat = 24
    static let largeTitle: CGFloat = 28
    static let button: CGFloat = 15
    static let buttonLarge: CGFloat = 16
}

// MARK: - 颜色快捷映射
enum ThemeColorKey {
    // 主色
    static let primary = "theme_primary"
    static let secondary = "theme_secondary"
    static let accent = "theme_accent"

    // 背景
    static let bg = "theme_bg"
    static let bgCard = "theme_bg_card"
    static let bgWhite = "theme_bg_white"
    static let bgInput = "theme_bg_input"

    // 文字
    static let textPrimary = "theme_text_primary"
    static let textSecondary = "theme_text_secondary"
    static let textTertiary = "theme_text_tertiary"
    static let textHint = "theme_text_hint"
    static let textWhite = "theme_text_white"

    // 分割线
    static let separator = "theme_separator"
    static let separatorLight = "theme_separator_light"

    // 功能色
    static let success = "theme_success"
    static let warning = "theme_warning"
    static let error = "theme_error"
    static let info = "theme_info"

    // 聊天
    static let chatBubbleMine = "theme_chat_bubble_mine"
    static let chatBubbleOther = "theme_chat_bubble_other"
    static let chatBubbleTextMine = "theme_chat_text_mine"
    static let chatBubbleTextOther = "theme_chat_text_other"
}

// MARK: - SF Symbol 图标快捷创建
extension UIImage {

    /// 创建 SF Symbol 图标（快捷方式）
    static func icon(_ name: String, size: CGFloat = 20, weight: UIImage.SymbolWeight = .regular) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: weight)
        return UIImage(systemName: name, withConfiguration: config)
    }

    /// 创建指定颜色的 SF Symbol 图标
    static func icon(_ name: String, color: UIColor, size: CGFloat = 20, weight: UIImage.SymbolWeight = .regular) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: weight)
        return UIImage(systemName: name, withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)
    }
}

// MARK: - UIImageView 快捷设置
extension UIImageView {

    /// 设置 SF Symbol 图标
    func setIcon(_ name: String, color: UIColor = .themeColorPrimary, size: CGFloat = 20) {
        image = UIImage.icon(name, color: color, size: size)
        contentMode = .scaleAspectFit
    }
}
