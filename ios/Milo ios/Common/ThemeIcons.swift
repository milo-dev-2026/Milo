//
//  ThemeIcons.swift
//  Milo
//
//  自定义图标统一管理系统
//  基于 SF Symbols 的枚举封装，提供类型安全的图标访问
//  对齐安卓端图标资源命名规范
//

import UIKit

// MARK: - 自定义图标统一管理
/// 以枚举封装 SF Symbol 名称，避免到处硬编码字符串，
/// 同时提供尺寸/颜色/字重等快捷配置能力。
enum ThemeIcon: String {

    // MARK: - 消息类型
    /// 文本消息
    case text = "text.bubble"
    /// 图片消息
    case image = "photo"
    /// 视频消息
    case video = "video"
    /// 语音消息
    case voice = "mic"
    /// 文件消息
    case file = "doc"
    /// 位置消息
    case location = "location"
    /// 名片消息
    case card = "person.crop.square"
    /// 表情贴纸
    case sticker = "face.smiling"
    /// GIF
    case gif = "rectangle.badge.plus"

    // MARK: - 导航
    /// 返回
    case back = "chevron.left"
    /// 前进
    case forward = "chevron.right"
    /// 关闭
    case close = "xmark"
    /// 搜索
    case search = "magnifyingglass"
    /// 添加
    case add = "plus"
    /// 更多
    case more = "ellipsis"
    /// 设置
    case settings = "gearshape"

    // MARK: - 通讯录
    /// 联系人
    case contacts = "person.2"
    /// 群聊
    case group = "person.3"
    /// 标签
    case tag = "tag"
    /// 机器人
    case robot = "sparkles"
    /// 新的朋友
    case newFriend = "person.badge.plus"

    // MARK: - 聊天
    /// 表情
    case emoji = "face.smiling.fill"
    /// 发送
    case send = "paperplane"
    /// 麦克风
    case mic = "mic.fill"
    /// 相机
    case camera = "camera"
    /// 相册
    case photo = "photo.on.rectangle"
    /// 贴纸面板
    case stickerIcon = "rectangle.stack"
    /// 语音通话
    case call = "phone"
    /// 视频通话
    case videoCall = "video.fill"

    // MARK: - 状态
    /// 置顶
    case pin = "pin.fill"
    /// 免打扰
    case mute = "bell.slash.fill"
    /// 未读圆点
    case unread = "circle.fill"
    /// 单勾
    case checkmark = "checkmark"
    /// 双勾
    case checkmarkDouble = "checkmark.circle.fill"
    /// 警告
    case warning = "exclamationmark.triangle.fill"

    // MARK: - 功能
    /// 扫一扫
    case scan = "qrcode.viewfinder"
    /// 分享
    case share = "square.and.arrow.up"
    /// 收藏
    case favorite = "star"
    /// 删除
    case delete = "trash"
    /// 编辑
    case edit = "pencil"
    /// 复制
    case copy = "doc.on.doc"
    /// 翻译
    case translate = "character.bubble"
    /// 回复
    case reply = "arrowshape.turn.up.left"
    /// 转发
    case forwardIcon = "arrowshape.turn.up.right"
    /// 多选
    case multiSelect = "checklist"

    // MARK: - TabBar（兼容旧资源）
    /// 消息 Tab
    case chat = "message.fill"
    /// 发现 Tab
    case discover = "safari.fill"
    /// 我的 Tab
    case profile = "person.crop.circle.fill"

    // MARK: - 媒体控制（兼容旧资源）
    /// 播放
    case play = "play.fill"
    /// 暂停
    case pause = "pause.fill"
    /// 电话
    case phone = "phone.fill"
    /// 二维码
    case qrcode = "qrcode"

    // MARK: - 预设颜色
    /// 主题色（用于主要操作图标）
    static let iconPrimary: UIColor = .themeColorPrimary
    /// 次要灰色（用于辅助图标）
    static let iconSecondary: UIColor = .themeTextSecondary
    /// 危险红色（用于删除/警告）
    static let iconDanger: UIColor = .systemRed
    /// 成功绿色（用于成功状态）
    static let iconSuccess: UIColor = .systemGreen

    // MARK: - 基础取图
    /// 直接获取 SF Symbol 图像（默认配置）
    var image: UIImage? {
        return UIImage(systemName: self.rawValue)
    }

    /// 按尺寸 + 颜色生成图标（中等字重，alwaysOriginal）
    func image(size: CGFloat, color: UIColor) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
        return UIImage(systemName: self.rawValue, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }

    /// 按尺寸 + 颜色 + 字重生成图标
    func image(size: CGFloat, color: UIColor, weight: UIImage.SymbolWeight) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: weight)
        return UIImage(systemName: self.rawValue, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }

    // MARK: - 便捷静态方法
    /// 通过字符串名便捷获取图标（兼容旧 API，等价于 UIImage.icon(_:size:color:)）
    static func icon(_ name: String, size: CGFloat, color: UIColor) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
        return UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }

    /// 通过字符串名便捷获取图标（指定字重）
    static func icon(_ name: String, size: CGFloat, color: UIColor, weight: UIImage.SymbolWeight) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: weight)
        return UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }

    /// 高级配置取图，支持通过字典灵活配置：
    /// - "size": CGFloat        点大小
    /// - "weight": UIImage.SymbolWeight  字重
    /// - "color": UIColor       单色着色
    /// - "scale": UIImage.SymbolScale    缩放
    /// - "hierarchical": UIColor 层级色（需 iOS 15+）
    static func systemImage(_ icon: ThemeIcon, configurations: [String: Any]) -> UIImage? {
        var pointSize: CGFloat = 17
        var weight: UIImage.SymbolWeight = .regular
        var scale: UIImage.SymbolScale?
        var baseColor: UIColor?
        var hierarchicalColor: UIColor?

        if let size = configurations["size"] as? CGFloat { pointSize = size }
        if let w = configurations["weight"] as? UIImage.SymbolWeight { weight = w }
        if let s = configurations["scale"] as? UIImage.SymbolScale { scale = s }
        if let c = configurations["color"] as? UIColor { baseColor = c }
        if let hc = configurations["hierarchical"] as? UIColor { hierarchicalColor = hc }

        // 优先使用层级色（iOS 15+）
        if let hc = hierarchicalColor {
            let hierConfig = UIImage.SymbolConfiguration(hierarchicalColor: hc)
            let pointConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
            let combined = pointConfig.applying(hierConfig)
            let finalConfig: UIImage.SymbolConfiguration
            if let scale = scale {
                finalConfig = combined.applying(UIImage.SymbolConfiguration(scale: scale))
            } else {
                finalConfig = combined
            }
            return UIImage(systemName: icon.rawValue, withConfiguration: finalConfig)
        }

        let pointConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        let finalConfig: UIImage.SymbolConfiguration
        if let scale = scale {
            finalConfig = pointConfig.applying(UIImage.SymbolConfiguration(scale: scale))
        } else {
            finalConfig = pointConfig
        }

        if let baseColor = baseColor {
            return UIImage(systemName: icon.rawValue, withConfiguration: finalConfig)?
                .withTintColor(baseColor, renderingMode: .alwaysOriginal)
        }
        return UIImage(systemName: icon.rawValue, withConfiguration: finalConfig)
    }
}

// MARK: - UIImageView 便捷扩展（基于 ThemeIcon）
extension UIImageView {

    /// 设置 ThemeIcon 图标
    func setThemeIcon(_ icon: ThemeIcon, size: CGFloat = 20, color: UIColor = ThemeIcon.iconPrimary) {
        image = icon.image(size: size, color: color)
        contentMode = .scaleAspectFit
        tintColor = color
    }
}
