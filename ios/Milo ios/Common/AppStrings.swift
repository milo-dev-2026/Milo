//
//  AppStrings.swift
//  Milo
//
//  应用字符串资源管理系统
//  参考 Android strings.xml，集中管理所有硬编码字符串，为国际化打基础
//  使用嵌套 enum 按模块分类，支持通过 NSLocalizedString 预留多语言接口
//
//  使用方式：
//    label.text = AppStrings.Common.confirm
//    button.setTitle(AppStrings.Chat.inputPlaceholder, for: .normal)
//
//  国际化接入：
//    后续替换 static let 为 NSLocalizedString 即可：
//    static let confirm = NSLocalizedString("common_confirm", comment: "确定")
//

import Foundation

// MARK: - 应用字符串总入口
enum AppStrings {

    // MARK: - 通用 / Common
    /// 通用操作类字符串
    enum Common {
        /// 确定按钮
        static let confirm = "确定"
        /// 取消按钮
        static let cancel = "取消"
        /// 删除操作
        static let delete = "删除"
        /// 转发消息
        static let forward = "转发"
        /// 复制内容
        static let copy = "复制"
        /// 保存操作
        static let save = "保存"
        /// 返回
        static let back = "返回"
        /// 完成
        static let done = "完成"
        /// 编辑
        static let edit = "编辑"
        /// 发送
        static let send = "发送"
        /// 撤回
        static let recall = "撤回"
        /// 置顶
        static let pin = "置顶"
        /// 取消置顶
        static let unpin = "取消置顶"
        /// 免打扰
        static let mute = "免打扰"
        /// 取消免打扰
        static let unmute = "取消免打扰"
        /// 搜索
        static let search = "搜索"
        /// 添加
        static let add = "添加"
        /// 移除
        static let remove = "移除"
        /// 更多
        static let more = "更多"
        /// 全部
        static let all = "全部"
        /// 暂无
        static let nothing = "暂无"
        /// 加载中
        static let loading = "加载中..."
        /// 加载失败
        static let loadFailed = "加载失败"
        /// 点击重试
        static let tapToRetry = "点击重试"
        /// 暂无数据
        static let noData = "暂无数据"
        /// 暂无结果
        static let noResults = "暂无结果"
        /// 成功
        static let success = "成功"
        /// 失败
        static let failed = "失败"
        /// 提示
        static let tip = "提示"
        /// 知道了
        static let gotIt = "知道了"
        /// 稍后
        static let later = "稍后"
        /// 立即
        static let now = "立即"
        /// 跳过
        static let skip = "跳过"
        /// 下一步
        static let next = "下一步"
        /// 上一步
        static let previous = "上一步"
        /// 重新加载
        static let reload = "重新加载"
        /// 下拉刷新
        static let pullToRefresh = "下拉刷新"
        /// 上拉加载更多
        static let loadMore = "上拉加载更多"
        /// 没有更多了
        static let noMore = "没有更多了"
        /// 复制成功
        static let copySuccess = "复制成功"
        /// 保存成功
        static let saveSuccess = "保存成功"
        /// 操作成功
        static let operationSuccess = "操作成功"
        /// 操作失败
        static let operationFailed = "操作失败"
        /// 网络错误
        static let networkError = "网络错误，请检查网络连接"
        /// 系统错误
        static let systemError = "系统错误"
        /// 未知错误
        static let unknownError = "未知错误"
    }

    // MARK: - 聊天 / Chat
    /// 聊天页面相关字符串
    enum Chat {
        /// 输入框占位符
        static let inputPlaceholder = "输入消息"
        /// 按住说话
        static let holdToTalk = "按住说话"
        /// 松开发送
        static let releaseToSend = "松开发送"
        /// 松开取消发送
        static let releaseToCancel = "松开取消发送"
        /// 新消息数量后缀
        static let newMessages = "条新消息"
        /// 对方正在输入
        static let typing = "对方正在输入..."
        /// 消息已发出，但被对方拒收了
        static let messageRejected = "消息已发出，但被对方拒收了"
        /// 消息已撤回
        static let messageRecalled = "撤回了一条消息"
        /// 你撤回了一条消息
        static let youRecalled = "你撤回了一条消息"
        /// 删除此消息？
        static let deleteConfirm = "删除此消息？"
        /// 转发给
        static let forwardTo = "转发给"
        /// 选择聊天
        static let selectChat = "选择聊天"
        /// 逐条转发
        static let forwardOneByOne = "逐条转发"
        /// 合并转发
        static let forwardCombined = "合并转发"
        /// 收藏
        static let favorite = "收藏"
        /// 已收藏
        static let favorited = "已收藏"
        /// 引用
        static let quote = "引用"
        /// 回复
        static let reply = "回复"
        /// 多选
        static let multiSelect = "多选"
        /// 翻译
        static let translate = "翻译"
        /// 听筒播放
        static let earpiecePlay = "听筒播放"
        /// 扬声器播放
        static let speakerPlay = "扬声器播放"
        /// 语音转文字
        static let voiceToText = "转文字"
        /// 正在录音
        static let recording = "正在录音..."
        /// 录音时间太短
        static let recordingTooShort = "说话时间太短"
        /// 正在加载
        static let loadingMessage = "加载中..."
        /// 发送失败，点击重发
        static let sendFailed = "发送失败，点击重发"
        /// 红包消息
        static let redPacketMessage = "[红包]"
        /// 语音消息
        static let voiceMessage = "[语音]"
        /// 图片消息
        static let imageMessage = "[图片]"
        /// 视频消息
        static let videoMessage = "[视频]"
        /// 文件消息
        static let fileMessage = "[文件]"
        /// 位置消息
        static let locationMessage = "[位置]"
        /// 名片消息
        static let cardMessage = "[名片]"
        /// 笔记消息
        static let noteMessage = "[笔记]"
        /// 表情消息
        static let stickerMessage = "[表情]"
        /// GIF 动图消息
        static let gifMessage = "[GIF]"
        /// 截屏消息
        static let screenshotMessage = "[截屏]"
        /// GIF 动图标识
        static let gifBadge = "GIF"
        /// 截屏标识
        static let screenshotBadge = "截屏"
        /// 系统消息
        static let systemMessage = "系统消息"
        /// 聊天记录
        static let chatHistory = "聊天记录"
        /// 查找聊天记录
        static let searchChatHistory = "查找聊天记录"
        /// 消息免打扰
        static let muteNotification = "消息免打扰"
        /// 置顶聊天
        static let pinChat = "置顶聊天"
        /// 清空聊天记录
        static let clearChatHistory = "清空聊天记录"
        /// 确认清空聊天记录？
        static let clearChatConfirm = "确认清空聊天记录？"
        /// 设置当前聊天背景
        static let setChatBackground = "设置当前聊天背景"
        /// @我
        static let mentionMe = "@我"
        /// 有人@你
        static let someoneMentionedYou = "有人@你"
        /// 消息反应
        static let messageReaction = "消息反应"
        /// 消息回执
        static let readReceipt = "消息回执"
        /// 已读
        static let read = "已读"
        /// 未读
        static let unread = "未读"
    }

    // MARK: - 会话列表 / Conversation
    /// 会话列表页面相关字符串
    enum Conversation {
        /// 页面标题
        static let title = "消息"
        /// 全部标记已读
        static let markAllRead = "全部标为已读"
        /// 删除聊天确认
        static let deleteConfirm = "删除此聊天？"
        /// 删除后将清空聊天记录
        static let deleteHint = "删除后将清空聊天记录"
        /// 发起群聊
        static let startGroupChat = "发起群聊"
        /// 添加朋友
        static let addFriend = "添加朋友"
        /// 扫一扫
        static let scan = "扫一扫"
        /// 收付款
        static let payment = "收付款"
        /// 未读消息
        static let unread = "未读"
        /// 草稿
        static let draft = "草稿"
        /// 群聊已解散
        static let groupDismissed = "群聊已解散"
        /// [有人@我]
        static let mentionedPrefix = "[有人@我]"
    }

    // MARK: - 通讯录 / Contacts
    /// 通讯录页面相关字符串
    enum Contacts {
        /// 页面标题
        static let title = "通讯录"
        /// 新的朋友
        static let newFriends = "新的朋友"
        /// 群聊
        static let groups = "群聊"
        /// 标签
        static let tags = "标签"
        /// 公众号
        static let officialAccounts = "公众号"
        /// 我的好友
        static let myFriends = "我的好友"
        /// 添加好友
        static let addFriend = "添加好友"
        /// 搜索好友
        static let searchFriend = "搜索好友"
        /// 手机号/账号
        static let phoneOrAccount = "手机号/账号"
        /// 该用户不存在
        static let userNotExist = "该用户不存在"
        /// 发送好友请求
        static let sendFriendRequest = "发送好友请求"
        /// 验证信息
        static let verifyMessage = "验证信息"
        /// 备注名
        static let remarkName = "备注名"
        /// 设置备注和标签
        static let setRemarkAndTag = "设置备注和标签"
        /// 朋友权限
        static let friendPermission = "朋友权限"
        /// 删除好友
        static let deleteFriend = "删除好友"
        /// 确认删除好友？
        static let deleteFriendConfirm = "确认删除好友？"
        /// 删除后将同时清空聊天记录
        static let deleteFriendHint = "删除后将同时清空聊天记录"
        /// 加入黑名单
        static let block = "加入黑名单"
        /// 移出黑名单
        static let unblock = "移出黑名单"
        /// 接受
        static let accept = "接受"
        /// 拒绝
        static let reject = "拒绝"
        /// 已添加
        static let added = "已添加"
        /// 等待验证
        static let waitingVerify = "等待验证"
        /// 位联系人
        static let contactCount = "位联系人"
    }

    // MARK: - 设置 / Setting
    /// 设置页面相关字符串
    enum Setting {
        /// 页面标题
        static let title = "设置"
        /// 个人资料
        static let profile = "个人资料"
        /// 账号与安全
        static let security = "账号与安全"
        /// 关于
        static let about = "关于"
        /// 新消息通知
        static let notifications = "新消息通知"
        /// 聊天
        static let chat = "聊天"
        /// 隐私
        static let privacy = "隐私"
        /// 通用
        static let general = "通用"
        /// 帮助与反馈
        static let helpAndFeedback = "帮助与反馈"
        /// 切换账号
        static let switchAccount = "切换账号"
        /// 退出登录
        static let logout = "退出登录"
        /// 确认退出登录？
        static let logoutConfirm = "确认退出登录？"
        /// 头像
        static let avatar = "头像"
        /// 昵称
        static let nickname = "昵称"
        /// 性别
        static let gender = "性别"
        /// 男
        static let male = "男"
        /// 女
        static let female = "女"
        /// 地区
        static let region = "地区"
        /// 个性签名
        static let signature = "个性签名"
        /// 我的二维码
        static let myQRCode = "我的二维码"
        /// 二维码名片
        static let qrCodeCard = "二维码名片"
        /// 版本
        static let version = "版本"
        /// 检查更新
        static let checkUpdate = "检查更新"
        /// 已是最新版本
        static let alreadyLatest = "已是最新版本"
        /// 清理存储空间
        static let clearStorage = "清理存储空间"
        /// 语言
        static let language = "语言"
        /// 深色模式
        static let darkMode = "深色模式"
        /// 跟随系统
        static let followSystem = "跟随系统"
        /// 字体大小
        static let fontSize = "字体大小"
        /// 聊天背景
        static let chatBackground = "聊天背景"
    }

    // MARK: - 登录注册 / Login
    /// 登录注册相关字符串
    enum Login {
        /// 手机号
        static let phoneNumber = "手机号"
        /// 验证码
        static let verifyCode = "验证码"
        /// 密码
        static let password = "密码"
        /// 登录
        static let login = "登录"
        /// 注册
        static let register = "注册"
        /// 请输入手机号
        static let phonePlaceholder = "请输入手机号"
        /// 请输入验证码
        static let verifyCodePlaceholder = "请输入验证码"
        /// 请输入密码
        static let passwordPlaceholder = "请输入密码"
        /// 获取验证码
        static let getVerifyCode = "获取验证码"
        /// 重新发送
        static let resend = "重新发送"
        /// 秒后重发
        static let resendInSeconds = "秒后重发"
        /// 忘记密码
        static let forgotPassword = "忘记密码"
        /// 重置密码
        static let resetPassword = "重置密码"
        /// 确认密码
        static let confirmPassword = "确认密码"
        /// 请再次输入密码
        static let confirmPasswordPlaceholder = "请再次输入密码"
        /// 同意以下协议
        static let agreeProtocol = "我已阅读并同意"
        /// 用户协议
        static let userAgreement = "《用户协议》"
        /// 和
        static let and = "和"
        /// 隐私政策
        static let privacyPolicy = "《隐私政策》"
        /// 手机号格式不正确
        static let invalidPhone = "手机号格式不正确"
        /// 验证码错误
        static let invalidVerifyCode = "验证码错误"
        /// 密码不能为空
        static let passwordEmpty = "密码不能为空"
        /// 两次密码不一致
        static let passwordMismatch = "两次密码不一致"
        /// 密码长度至少6位
        static let passwordTooShort = "密码长度至少6位"
        /// 登录中...
        static let loggingIn = "登录中..."
        /// 注册中...
        static let registering = "注册中..."
        /// 欢迎回来
        static let welcomeBack = "欢迎回来"
        /// 创建新账号
        static let createNewAccount = "创建新账号"
        /// 已有账号？去登录
        static let haveAccountGoLogin = "已有账号？去登录"
        /// 还没有账号？去注册
        static let noAccountGoRegister = "还没有账号？去注册"
        /// 第三方登录
        static let thirdPartyLogin = "其他登录方式"
        /// 微信登录
        static let wechatLogin = "微信登录"
        /// QQ登录
        static let qqLogin = "QQ登录"
        /// 手机号登录
        static let phoneLogin = "手机号登录"
    }

    // MARK: - 群组 / Group
    /// 群组相关字符串
    enum Group {
        /// 群成员
        static let groupMembers = "群成员"
        /// 群公告
        static let groupNotice = "群公告"
        /// 群管理
        static let groupManage = "群管理"
        /// 全员禁言
        static let muteAll = "全员禁言"
        /// 群聊名称
        static let groupName = "群聊名称"
        /// 群二维码
        static let groupQRCode = "群二维码"
        /// 群描述
        static let groupDescription = "群描述"
        /// 我在本群的昵称
        static let myNicknameInGroup = "我在本群的昵称"
        /// 显示群成员昵称
        static let showMemberNickname = "显示群成员昵称"
        /// 清空聊天记录
        static let clearChatHistory = "清空聊天记录"
        /// 退出群聊
        static let leaveGroup = "退出群聊"
        /// 确认退出群聊？
        static let leaveGroupConfirm = "确认退出群聊？"
        /// 解散群聊
        static let dismissGroup = "解散群聊"
        /// 确认解散群聊？
        static let dismissGroupConfirm = "确认解散群聊？"
        /// 转让群主
        static let transferOwner = "转让群主"
        /// 设为管理员
        static let setAsAdmin = "设为管理员"
        /// 取消管理员
        static let removeAdmin = "取消管理员"
        /// 移出群聊
        static let removeFromGroup = "移出群聊"
        /// 禁言
        static let muteMember = "禁言"
        /// 解除禁言
        static let unmuteMember = "解除禁言"
        /// 发布群公告
        static let publishNotice = "发布群公告"
        /// 编辑群公告
        static let editNotice = "编辑群公告"
        /// 群公告占位符
        static let noticePlaceholder = "写点什么通知群成员吧..."
        /// 人
        static let memberCount = "人"
        /// 群主
        static let owner = "群主"
        /// 管理员
        static let admin = "管理员"
        /// 添加成员
        static let addMember = "添加成员"
        /// 删除成员
        static let deleteMember = "删除成员"
        /// 群聊已解散
        static let groupDismissed = "群聊已解散"
        /// 你被移出群聊
        static let youWereRemoved = "你被移出群聊"
        /// 加入群聊
        static let joinGroup = "加入群聊"
        /// 创建群聊
        static let createGroup = "创建群聊"
    }

    // MARK: - 搜索 / Search
    /// 搜索相关字符串
    enum Search {
        /// 搜索
        static let search = "搜索"
        /// 搜索占位符
        static let searchPlaceholder = "搜索"
        /// 暂无结果
        static let noResults = "暂无结果"
        /// 搜索历史
        static let searchHistory = "搜索历史"
        /// 热门搜索
        static let hotSearch = "热门搜索"
        /// 清空历史
        static let clearHistory = "清空历史"
        /// 全部
        static let all = "全部"
        /// 联系人
        static let contacts = "联系人"
        /// 群聊
        static let groups = "群聊"
        /// 聊天记录
        static let chatHistory = "聊天记录"
        /// 收藏
        static let favorite = "收藏"
        /// 笔记
        static let note = "笔记"
        /// 取消
        static let cancel = "取消"
    }

    // MARK: - 贴纸 / Sticker
    /// 贴纸表情相关字符串
    enum Sticker {
        /// 贴纸商店
        static let stickerShop = "贴纸商店"
        /// 我的贴纸
        static let myStickers = "我的贴纸"
        /// 热门
        static let hot = "热门"
        /// 最新
        static let new = "最新"
        /// 添加
        static let add = "添加"
        /// 已添加
        static let added = "已添加"
        /// 表情
        static let emoji = "表情"
        /// 贴纸
        static let sticker = "贴纸"
        /// 个表情
        static let stickerCount = "个表情"
        /// 搜索表情包
        static let searchPlaceholder = "搜索表情包"
        /// 管理
        static let manage = "管理"
        /// 完成
        static let done = "完成"
        /// 排序
        static let sort = "排序"
        /// 移除
        static let remove = "移除"
        /// 表情预览
        static let preview = "表情预览"
        /// 下载
        static let download = "下载"
        /// 已下载
        static let downloaded = "已下载"
        /// 免费
        static let free = "免费"
        /// 推荐
        static let recommend = "推荐"
        /// 更多
        static let more = "更多"
        /// 分类
        static let category = "分类"
        /// 表情详情
        static let detail = "表情详情"
        /// 自定义表情
        static let custom = "自定义表情"
        /// 添加自定义表情
        static let addCustom = "添加自定义表情"
    }

    // MARK: - 机器人 / Robot
    /// 机器人相关字符串
    enum Robot {
        /// 机器人
        static let robots = "机器人"
        /// 机器人商店
        static let robotShop = "机器人商店"
        /// 我的机器人
        static let myRobots = "我的机器人"
        /// 添加机器人
        static let addRobot = "添加机器人"
        /// 已添加
        static let added = "已添加"
        /// 热门
        static let hot = "热门"
        /// 最新
        static let new = "最新"
        /// 搜索机器人
        static let searchPlaceholder = "搜索机器人"
    }

    // MARK: - 标签 / Tag
    /// 标签相关字符串
    enum Tag {
        /// 标签
        static let tags = "标签"
        /// 新建标签
        static let addTag = "新建标签"
        /// 编辑标签
        static let editTag = "编辑标签"
        /// 标签成员
        static let tagMembers = "标签成员"
        /// 删除标签
        static let deleteTag = "删除标签"
        /// 标签名称
        static let tagName = "标签名称"
        /// 请输入标签名称
        static let tagNamePlaceholder = "请输入标签名称"
        /// 个成员
        static let memberCount = "个成员"
        /// 管理标签
        static let manageTags = "管理标签"
        /// 保存
        static let save = "保存"
        /// 删除标签后，标签内的联系人不会被删除
        static let deleteHint = "删除标签后，标签内的联系人不会被删除"
    }

    // MARK: - 笔记 / Notes
    /// 笔记相关字符串
    enum Note {
        /// 笔记
        static let title = "笔记"
        /// 新建笔记
        static let newNote = "新建笔记"
        /// 编辑笔记
        static let editNote = "编辑笔记"
        /// 笔记详情
        static let noteDetail = "笔记详情"
        /// 标题
        static let titlePlaceholder = "标题"
        /// 内容
        static let contentPlaceholder = "写点什么..."
        /// 删除笔记
        static let deleteNote = "删除笔记"
        /// 确认删除此笔记？
        static let deleteConfirm = "确认删除此笔记？"
        /// 分享笔记
        static let shareNote = "分享笔记"
        /// 收藏笔记
        static let favoriteNote = "收藏笔记"
        /// 搜索笔记
        static let searchPlaceholder = "搜索笔记"
        /// 暂无笔记
        static let noNotes = "暂无笔记"
        /// 全部笔记
        static let allNotes = "全部笔记"
        /// 置顶笔记
        static let pinnedNotes = "置顶笔记"
    }

    // MARK: - 收藏 / Favorite
    /// 收藏相关字符串
    enum Favorite {
        /// 我的收藏
        static let title = "我的收藏"
        /// 搜索收藏
        static let searchPlaceholder = "搜索收藏"
        /// 暂无收藏
        static let noFavorites = "暂无收藏"
        /// 已收藏
        static let favorited = "已收藏"
        /// 取消收藏
        static let unfavorite = "取消收藏"
        /// 删除收藏
        static let deleteFavorite = "删除收藏"
        /// 转发给朋友
        static let forwardToFriend = "转发给朋友"
    }

    // MARK: - 安全 / Security
    /// 安全中心相关字符串
    enum Security {
        /// 账号与安全
        static let title = "账号与安全"
        /// 登录密码
        static let loginPassword = "登录密码"
        /// 修改密码
        static let changePassword = "修改密码"
        /// 锁屏密码
        static let lockScreenPassword = "锁屏密码"
        /// 修改锁屏密码
        static let changeLockPassword = "修改锁屏密码"
        /// 设置锁屏密码
        static let setLockPassword = "设置锁屏密码"
        /// 消息隐私
        static let messagePrivacy = "消息隐私"
        /// 设备管理
        static let deviceManage = "设备管理"
        /// 账号绑定
        static let accountBinding = "账号绑定"
        /// 注销账号
        static let destroyAccount = "注销账号"
        /// 屏幕保护
        static let screenSaver = "屏幕保护"
        /// 已绑定
        static let bound = "已绑定"
        /// 未绑定
        static let unbound = "未绑定"
        /// 去绑定
        static let goBind = "去绑定"
        /// 当前设备
        static let currentDevice = "当前设备"
        /// 登录设备
        static let loginDevices = "登录设备"
        /// 下线
        static let offline = "下线"
    }

    // MARK: - 扫一扫 / Scan
    /// 扫一扫相关字符串
    enum Scan {
        /// 扫一扫
        static let title = "扫一扫"
        /// 我的二维码
        static let myQRCode = "我的二维码"
        /// 相册
        static let album = "相册"
        /// 扫描二维码/条码
        static let scanQRCode = "扫描二维码/条码"
        /// 将二维码放入框内，即可自动扫描
        static let scanHint = "将二维码放入框内，即可自动扫描"
        /// 识别中...
        static let recognizing = "识别中..."
        /// 无法识别二维码
        static let recognizeFailed = "无法识别二维码"
        /// 添加到通讯录
        static let addToContacts = "添加到通讯录"
    }

    // MARK: - 位置 / Location
    /// 位置相关字符串
    enum Location {
        /// 发送位置
        static let sendLocation = "发送位置"
        /// 搜索地点
        static let searchPlaceholder = "搜索地点"
        /// 定位中...
        static let locating = "定位中..."
        /// 定位失败
        static let locateFailed = "定位失败"
        /// 附近
        static let nearby = "附近"
        /// 发送
        static let send = "发送"
    }

    // MARK: - 文件 / File
    /// 文件相关字符串
    enum File {
        /// 文件
        static let files = "文件"
        /// 发送文件
        static let sendFile = "发送文件"
        /// 下载文件
        static let downloadFile = "下载文件"
        /// 打开文件
        static let openFile = "打开文件"
        /// 另存为
        static let saveAs = "另存为"
        /// 文件大小
        static let fileSize = "文件大小"
        /// 下载中
        static let downloading = "下载中..."
        /// 下载失败
        static let downloadFailed = "下载失败"
        /// 打开失败
        static let openFailed = "打开失败"
    }

    // MARK: - 通话 / Call
    /// 音视频通话相关字符串
    enum Call {
        /// 语音通话
        static let voiceCall = "语音通话"
        /// 视频通话
        static let videoCall = "视频通话"
        /// 正在呼叫...
        static let calling = "正在呼叫..."
        /// 等待对方接听
        static let waitingAnswer = "等待对方接听..."
        /// 通话中
        static let inCall = "通话中"
        /// 已挂断
        static let hungUp = "已挂断"
        /// 对方已拒绝
        static let rejected = "对方已拒绝"
        /// 对方无人接听
        static let noAnswer = "对方无人接听"
        /// 通话结束
        static let callEnded = "通话结束"
        /// 通话时长
        static let callDuration = "通话时长"
        /// 静音
        static let mute = "静音"
        /// 取消静音
        static let unmute = "取消静音"
        /// 免提
        static let speaker = "免提"
        /// 摄像头
        static let camera = "摄像头"
        /// 切换摄像头
        static let switchCamera = "切换摄像头"
        /// 挂断
        static let hangUp = "挂断"
        /// 接听
        static let answer = "接听"
        /// 拒接
        static let reject = "拒接"
    }

    // MARK: - 个人主页 / Profile
    /// 个人主页相关字符串
    enum Profile {
        /// 个人信息
        static let personalInfo = "个人信息"
        /// 头像
        static let avatar = "头像"
        /// 昵称
        static let nickname = "昵称"
        /// 性别
        static let gender = "性别"
        /// 地区
        static let region = "地区"
        /// 个性签名
        static let signature = "个性签名"
        /// 资料设置
        static let profileSetting = "资料设置"
        /// 发送消息
        static let sendMessage = "发送消息"
        /// 音视频通话
        static let videoVoiceCall = "音视频通话"
        /// 朋友圈
        static let moments = "朋友圈"
        /// 更多信息
        static let moreInfo = "更多信息"
    }

    // MARK: - 备份恢复 / Backup
    /// 聊天记录备份与恢复相关字符串
    enum Backup {
        /// 页面标题
        static let title = "聊天记录备份与恢复"
        /// 备份
        static let backup = "备份"
        /// 恢复
        static let restore = "恢复"
        /// 自动备份
        static let autoBackup = "自动备份"
        /// 立即备份
        static let backupNow = "立即备份"
        /// 恢复聊天记录
        static let restoreNow = "恢复聊天记录"
        /// 上次备份时间
        static let lastBackupTime = "上次备份时间"
        /// 暂无备份记录
        static let noBackup = "暂无备份记录"
        /// 备份内容
        static let backupContent = "备份内容"
        /// 聊天记录
        static let chatHistory = "聊天记录"
        /// 图片
        static let images = "图片"
        /// 视频
        static let videos = "视频"
        /// 文件
        static let files = "文件"
        /// 预计大小
        static let estimatedSize = "预计大小"
        /// 备份频率
        static let frequency = "备份频率"
        /// 每天
        static let daily = "每天"
        /// 每周
        static let weekly = "每周"
        /// 每月
        static let monthly = "每月"
        /// 仅 WiFi 下备份
        static let wifiOnly = "仅 Wi-Fi 下备份"
        /// 备份时间
        static let backupTime = "备份时间"
        /// 可用备份
        static let availableBackups = "可用备份"
        /// 备份中
        static let backingUp = "备份中..."
        /// 恢复中
        static let restoring = "恢复中..."
        /// 备份完成
        static let backupComplete = "备份完成"
        /// 恢复完成
        static let restoreComplete = "恢复完成"
        /// 备份失败
        static let backupFailed = "备份失败"
        /// 恢复失败
        static let restoreFailed = "恢复失败"
        /// 内容摘要
        static let contentSummary = "内容摘要"
        /// 确认恢复？
        static let restoreConfirm = "确认恢复此备份？恢复将覆盖当前聊天记录。"
        /// 删除备份
        static let deleteBackup = "删除备份"
        /// 自动备份设置
        static let autoBackupSettings = "自动备份设置"
    }
}

// MARK: - 国际化预留接口
/// 国际化辅助方法，后续接入多语言时统一替换
/// 目前直接返回中文，接入时改为 NSLocalizedString 即可
func Localized(_ key: String, comment: String = "") -> String {
    // TODO: 接入多语言后改为 NSLocalizedString(key, comment: comment)
    return key
}
