import UIKit
import SnapKit
import Kingfisher
import Photos
import PhotosUI
import MAMapKit
import AMapLocationKit
import AMapSearchKit
import UniformTypeIdentifiers
import AVKit
import CoreImage
import WuKongIMSDK

// MARK: - 聊天页
class ChatViewController: UIViewController {

    let channelId: String
    private let titleText: String
    private let channelType: Int // 1: 单聊, 2: 群聊

    private let tableView = UITableView()
    private let inputBar = ChatInputBar()
    private var messages: [Message] = []
    /// 特殊群聊（西安修车大队/西安交流群等）：该群系统消息只显示"对方撤回了一条消息"等纯文案，不显示操作详情
    private var isSpecialGroup: Bool { SpecialUserUtils.isSpecialGroup(name: titleText) }
    /// 特殊好友888（单聊）：昵称红色、徽章显示在在线状态行、只保留语音按钮
    private var isSpecialSingleChat: Bool {
        channelType == 1 && SpecialUserUtils.isSpecialUser(uid: channelId, shortNo: "", name: titleText)
    }
    /// 历史消息分页状态（滑到顶部继续加载更早的记录）
    private var isLoadingOlder = false
    private var hasMoreHistory = true
    /// 翻页游标（时间秒 + seq）：独立于界面消息列表维护。
    /// 若直接用界面最老消息当游标，遇到"整页都是已展示消息"时会误判没有更多历史
    private var historyCursorTs: Int = 0
    private var historyCursorSeq: Int = 0
    private var imagePicker: UIImagePickerController?
    /// 消息扩展（已读回执/撤回）同步版本号与轮询定时器
    private var extraVersion: Int64 = 0
    private var extraSyncTimer: Timer?

    /// 上传中的本地缩略图（messageID → 图片），用于立刻展示占位气泡
    private var pendingMedia: [String: UIImage] = [:]
    /// 上传任务缓存（失败后点击气泡可重发）
    private var pendingUploads: [String: PendingUpload] = [:]
    /// 已上传成功、等待 SDK 回显替换的本地占位消息
    private var confirmedLocalIDs: Set<String> = []
    /// 本地占位语音消息的时长（messageID → 秒）
    private var pendingVoiceDurations: [String: Int] = [:]
    private let loadingContainer = UIView()
    private let emptyLabel = UILabel()
    private let onlineStatusLabel = UILabel()
    private var hasFinishedLoading = false
    /// 待执行弹性浮现动画的新消息 ID
    private var pendingAppearIDs = Set<String>()
    /// 回到底部悬浮按钮（远离底部时浮现）
    private let scrollDownButton = UIButton(type: .system)
    /// 最近一次头像点击时间：表格层命中头像后，抑制紧随其后的 didSelectRow 默认跳转
    private var avatarTapAt: Date?
    /// 最近一次在线状态文案，供「正在输入」切换后还原
    private var lastOnlineStatusText: String?
    /// 当前用户在群内的角色（1 群主 2 管理员 0 普通成员），控制群管理入口可见性（对齐安卓 hideOrShowRightView）
    private var myGroupRole: Int = 0
    private var isGroupAdmin: Bool { myGroupRole == 1 || myGroupRole == 2 }

    /// 聊天文件上传专用会话（默认 30/60 秒对原图/视频不够）
    private let uploadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    private struct PendingUpload {
        let type: MessageType
        let data: Data?
        let sourceURL: URL?
        let fileName: String
        let width: CGFloat
        let height: CGFloat
        let duration: Int
        let thumbnail: UIImage?
    }

    init(channelId: String, title: String, channelType: Int = 1) {
        self.channelId = channelId
        self.titleText = title
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
        // 打开聊天窗口时隐藏底部 Tab 栏
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        inputBar.isGroupChat = (channelType == 2)
        setupLoadingView()
        setupNavBar()
        // 先读磁盘消息缓存秒显，再读 SDK 本地库，最后异步拉服务端补齐
        loadDiskCachedMessages()
        loadCachedMessages()
        loadMessages()
        setupKeyboardObserver()

        IMManager.shared.onMessageReceived = { [weak self] msg in
            self?.handleIncomingMessage(msg)
        }

        IMManager.shared.onMessageStatusUpdate = { [weak self] msg in
            self?.handleMessageStatusUpdate(msg)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMessageNotification(_:)),
            name: IMManager.messageReceivedNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMessageStatusNotification(_:)),
            name: IMManager.messageStatusUpdateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMessageRevokedNotification(_:)),
            name: NSNotification.Name("IMMessageRevoked"),
            object: nil
        )
    }

    /// 对方撤回消息的实时 CMD：立即把对应气泡替换为"对方撤回了一条消息"
    @objc private func handleMessageRevokedNotification(_ notification: Notification) {
        guard let messageId = notification.userInfo?["messageId"] as? String,
              let idx = messages.firstIndex(where: { $0.messageID == messageId }),
              messages[idx].type != .system else { return }
        messages[idx].type = .system
        messages[idx].content = messages[idx].isFromMe ? "你撤回了一条消息" : "对方撤回了一条消息"
        tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
        saveMessagesCacheDebounced()
    }

    @objc private func handleMessageNotification(_ notification: Notification) {
        guard let msg = notification.object as? Message else { return }
        handleIncomingMessage(msg)
    }

    @objc private func handleMessageStatusNotification(_ notification: Notification) {
        guard let msg = notification.object as? Message else { return }
        handleMessageStatusUpdate(msg)
    }

    private func handleMessageStatusUpdate(_ msg: Message) {
        guard msg.channelID == channelId else { return }
        // sendack 回执：SDK 消息的 clientMsgNo 与发送时一致，messageID 为真实服务端 ID。
        // 先按 clientMsgNo 找回本地占位消息，回写真实 messageID（撤回/已读/搜索都依赖服务端 ID）
        if msg.isFromMe, !msg.clientMsgNo.isEmpty,
           let idx = messages.firstIndex(where: { $0.clientMsgNo == msg.clientMsgNo }) {
            let localID = messages[idx].messageID
            if localID != msg.messageID {
                confirmedLocalIDs.remove(localID)
                pendingAppearIDs.remove(localID)
                pendingAppearIDs.insert(msg.messageID)
                messages[idx].messageID = msg.messageID
            }
            messages[idx].messageSeq = msg.messageSeq
            if messages[idx].status != 2 { messages[idx].status = msg.status }
            DispatchQueue.main.async { self.tableView.reloadData() }
            return
        }
        // 非本端发送或已知服务端 ID 的消息：直接按 messageID 更新状态
        if let index = messages.firstIndex(where: { $0.messageID == msg.messageID }) {
            messages[index].status = msg.status
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private func handleIncomingMessage(_ msg: Message) {
        guard msg.channelID == channelId else { return }
        // 通话结果气泡：本端可能已根据信令本地插入过一条（对方服务端生成的结果消息随后到达），
        // 按"同方向 + 10 秒内"合并，避免出现两个通话气泡
        if msg.type == .call {
            if let idx = messages.lastIndex(where: {
                $0.type == .call && !$0.isFromMe == !msg.isFromMe &&
                abs($0.timestamp - msg.timestamp) < 10_000
            }) {
                messages[idx].messageID = msg.messageID
                messages[idx].messageSeq = msg.messageSeq
                messages[idx].content = msg.content
                messages[idx].timestamp = msg.timestamp
                messages[idx].status = msg.status
                DispatchQueue.main.async { self.tableView.reloadData() }
                return
            }
        }
        // 特殊群聊：系统/群事件消息与后台已删消息不显示
        if isSpecialGroup {
            if msg.type == .system { return }
            if let data = msg.content.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let deleted = dict["is_deleted"] as? Int, deleted == 1 { return }
        }
        if messages.contains(where: { $0.messageID == msg.messageID }) { return }
        // 自己消息的"回显/服务端同步"：发送占位气泡的内容是 NoteEntity JSON，
        // 回显内容是安卓线缆格式（noteTitle/blockListJson），文本比对永远不等 → 必须用 clientMsgNo 去重
        if msg.isFromMe && !msg.clientMsgNo.isEmpty,
           let idx = messages.firstIndex(where: { $0.isFromMe && $0.clientMsgNo == msg.clientMsgNo }) {
            // 回显比 sendack 先到时，占位消息还是临时 ID：回写真实 messageID，避免重复气泡
            messages[idx].messageID = msg.messageID
            messages[idx].messageSeq = msg.messageSeq
            messages[idx].timestamp = msg.timestamp
            if messages[idx].status != 2 { messages[idx].status = 1 }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        // 位置消息回显：SDK 回显未带 clientMsgNo 时，按"同方向同类型同内容（忽略 [位置] 前缀）15 秒内"合并，
        // 避免一次发送出现多条位置气泡（对齐安卓只显示一条）
        if msg.isFromMe, msg.type == .location,
           let idx = messages.lastIndex(where: {
               $0.isFromMe && $0.type == .location &&
               self.normalizeForCompare($0.content) == self.normalizeForCompare(msg.content) &&
               abs($0.timestamp - msg.timestamp) < 15_000
           }) {
            messages[idx].messageID = msg.messageID
            messages[idx].messageSeq = msg.messageSeq
            messages[idx].timestamp = msg.timestamp
            if messages[idx].status != 2 { messages[idx].status = 1 }
            DispatchQueue.main.async { self.tableView.reloadData() }
            return
        }
        // 自己发送成功的消息回显：替换本地占位气泡，避免重复
        if msg.isFromMe,
           let idx = messages.firstIndex(where: {
               $0.isFromMe && self.confirmedLocalIDs.contains($0.messageID) && $0.type == msg.type && $0.content == msg.content
           }) {
            confirmedLocalIDs.remove(messages[idx].messageID)
            messages[idx] = msg
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.scrollToBottom()
            }
            return
        }
        // 兜底：同一位置/媒体消息以占位、回显、历史同步三种来源到达时合并，避免出现多个气泡
        if let idx = messages.firstIndex(where: { isSameMessage($0, msg) }) {
            messages[idx] = mergedMessage(messages[idx], msg)
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.scrollToBottom()
            }
            saveMessagesCacheDebounced()
            return
        }
        messages.append(msg)
        if msg.isFromMe {
            pendingAppearIDs.insert(msg.messageID)
        } else {
            pendingAppearIDs.insert(msg.messageID)
            // 收到对方消息时的轻触感反馈（与系统信息一致）
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
        saveMessagesCacheDebounced()
    }

    private func setupUI() {
        title = titleText
        applyChatBackground()
        emptyLabel.text = "暂无消息"
        emptyLabel.font = ScreenAdapter.font(14)
        emptyLabel.textColor = .tertiaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TextMessageCell.self, forCellReuseIdentifier: "TextMessageCell")
        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: "ImageMessageCell")
        tableView.register(VoiceMessageCell.self, forCellReuseIdentifier: "VoiceMessageCell")
        tableView.register(VideoMessageCell.self, forCellReuseIdentifier: "VideoMessageCell")
        tableView.register(FileMessageCell.self, forCellReuseIdentifier: "FileMessageCell")
        tableView.register(LocationMessageCell.self, forCellReuseIdentifier: "LocationMessageCell")
        tableView.register(CardMessageCell.self, forCellReuseIdentifier: "CardMessageCell")
        tableView.register(NoteMessageCell.self, forCellReuseIdentifier: "NoteMessageCell")
        tableView.register(SystemMessageCell.self, forCellReuseIdentifier: "SystemMessageCell")
        tableView.register(CallMessageCell.self, forCellReuseIdentifier: "CallMessageCell")
        tableView.register(PendingMediaMessageCell.self, forCellReuseIdentifier: "PendingMediaMessageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        // 自适应行高：气泡高度随内容撑开
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = ScreenAdapter.scaleH(64)

        // 长按菜单使用 iOS 原生 ContextMenu（气泡弹出 + 菜单），见 UITableViewDelegate 扩展

        // 头像点击兜底：通话/合并转发等自定义 cell 的头像没有走 ChatBubbleLayout 的点击中继，
        // 统一在表格层命中头像区域，保证任何消息点击头像都能进入个人资料页（对齐微信）
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(handleTableAvatarTap(_:)))
        avatarTap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(avatarTap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        // 点击消息气泡头像：进入对方个人主页 / 群资料
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAvatarTapped(_:)),
                                               name: ChatAvatarTapRelay.notification,
                                               object: nil)

        inputBar.delegate = self

        view.addSubviews(tableView, inputBar)

        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top)
        }

        // 回到底部悬浮按钮：圆形描边 + 阴影，远离底部时浮现
        scrollDownButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        scrollDownButton.tintColor = .label
        scrollDownButton.backgroundColor = .themeBg
        scrollDownButton.layer.cornerRadius = ScreenAdapter.scaleW(18)
        scrollDownButton.layer.borderWidth = 0.5
        scrollDownButton.layer.borderColor = UIColor.themeSeparator.cgColor
        scrollDownButton.layer.shadowColor = UIColor.black.cgColor
        scrollDownButton.layer.shadowOpacity = 0.12
        scrollDownButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        scrollDownButton.layer.shadowRadius = 6
        scrollDownButton.alpha = 0
        scrollDownButton.addTarget(self, action: #selector(scrollDownTapped), for: .touchUpInside)
        view.addSubview(scrollDownButton)
        scrollDownButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalTo(inputBar.snp.top).offset(-ScreenAdapter.scaleH(12))
            make.width.height.equalTo(ScreenAdapter.scaleW(36))
        }

        inputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 聊天页导航栏：透明玻璃，消息可滚到状态栏下方
        applyGlassNavBar()
        // 标记当前正在聊天的频道（对齐安卓：本频道新消息不播放提示音）
        IMManager.shared.currentChattingChannelId = channelId
        // 从聊天背景设置页返回时刷新背景
        applyChatBackground()
        refreshCachedOnlineStatus()
        // 进入会话立即清除未读数，并通知会话列表刷新（修复"看过了仍显示未读"）
        IMManager.shared.clearConversationUnread(channelId: channelId, channelType: channelType)
        NotificationCenter.default.post(name: NSNotification.Name("ConversationsSynced"), object: nil)
        markMessagesAsRead()
        startExtraSync()
        // 通话结束返回等场景：服务端生成的消息可能未实时推送，从本地库补齐一次
        refreshMessagesFromLocalStore()
    }

    /// 从 SDK 本地消息库补齐（只追加缺失消息，有新消息时才滚动到底部）
    private func refreshMessagesFromLocalStore() {
        IMManager.shared.pullLastMessages(channelId: channelId, channelType: channelType, limit: 100) { [weak self] wkMessages, _ in
            guard let self = self, let wkMessages = wkMessages, !wkMessages.isEmpty else { return }
            let cached = wkMessages.map { $0.toBusinessMessage() }
            DispatchQueue.main.async {
                let oldLastID = self.messages.last?.messageID
                self.applyLoadedMessages(cached, scroll: false, finish: false, merge: true)
                if self.messages.last?.messageID != oldLastID {
                    self.scrollToBottom()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 离开聊天页时恢复导航栏默认外观，避免影响其它页面
        restoreNavBarAppearance()
        if IMManager.shared.currentChattingChannelId == channelId {
            IMManager.shared.currentChattingChannelId = nil
        }
        stopExtraSync()
        // 离开时立即落盘消息缓存，下次进入秒显
        msgCacheWorkItem?.cancel()
        let snapshot = Array(messages.suffix(50))
        if !snapshot.isEmpty {
            let url = msgCacheFileURL
            DispatchQueue.global(qos: .utility).async {
                if let data = try? JSONEncoder().encode(snapshot) {
                    try? data.write(to: url, options: .atomic)
                }
            }
        }
    }

    /// 玻璃导航栏：透明背景 + 毛玻璃，去掉底部分割线
    private func applyGlassNavBar() {
        guard let navBar = navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        appearance.shadowColor = .clear
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.isTranslucent = true
        edgesForExtendedLayout = .all
    }

    /// 恢复导航栏默认外观
    private func restoreNavBarAppearance() {
        guard let navBar = navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.isTranslucent = false
    }

    // MARK: - 首屏加载骨架
    private func setupLoadingView() {
        loadingContainer.isUserInteractionEnabled = false
        view.addSubview(loadingContainer)
        loadingContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(12))
            make.leading.trailing.equalToSuperview().inset(ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(300))
        }

        var offset: CGFloat = 0
        let heights: [CGFloat] = [40, 40, 64, 40]
        let widths: [CGFloat] = [0.58, 0.42, 0.66, 0.5]
        for index in 0..<heights.count {
            let bar = UIView()
            bar.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.75)
            bar.layer.cornerRadius = ScreenAdapter.scaleW(10)
            loadingContainer.addSubview(bar)
            let widthRatio = widths[index]
            let isFromMe = index % 2 == 1
            bar.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(offset)
                make.height.equalTo(ScreenAdapter.scaleH(heights[index]))
                make.width.equalToSuperview().multipliedBy(widthRatio)
                if isFromMe {
                    make.trailing.equalToSuperview()
                } else {
                    make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(44))
                }
            }
            offset += ScreenAdapter.scaleH(heights[index]) + ScreenAdapter.scaleH(16)
        }

        UIView.animate(withDuration: 0.9, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.loadingContainer.alpha = 0.45
        }
    }

    private func finishLoading() {
        hasFinishedLoading = true
        loadingContainer.layer.removeAllAnimations()
        loadingContainer.isHidden = true
        emptyLabel.isHidden = !messages.isEmpty
    }

    // MARK: - 聊天背景（会话级 > 全局 > 兼容 chat_bg_index）
    private static let androidChatBgColors: [UIColor] = [
        0xFFFFFF, 0xF5F5F5, 0xE8F5E9, 0xE3F2FD, 0xFCE4EC, 0xFFF3E0,
        0xF3E5F5, 0xE0F7FA, 0xEFEBE9, 0xECEFF1, 0xFFFDE7, 0xF1F8E9
    ].map { UIColor.hex(String(format: "%06X", $0)) }

    /// 默认聊天背景图（品牌渐变，固定在 view 上不随消息滚动）
    private let chatBgImageView = UIImageView()
    private var chatBgImageInstalled = false

    private func applyChatBackground() {
        let defaults = UserDefaults.standard

        // 一次性迁移：清空旧版本写入的纯色背景设置，统一回退到与安卓一致的浅灰纹理背景
        if !defaults.bool(forKey: "chat_bg_migrated_v3") {
            for key in defaults.dictionaryRepresentation().keys
            where key.hasPrefix("chat_bg_") && key != "chat_bg_migrated_v3" {
                defaults.removeObject(forKey: key)
            }
            defaults.set(true, forKey: "chat_bg_migrated_v3")
        }

        var color: UIColor?

        // 会话级背景：chat_bg_<channelId>
        if let value = defaults.string(forKey: "chat_bg_\(channelId)"), !value.isEmpty {
            color = ChatViewController.color(from: value)
        }
        // 全局背景：chat_bg_global
        if color == nil, let value = defaults.string(forKey: "chat_bg_global"), !value.isEmpty {
            color = ChatViewController.color(from: value)
        }
        // 兼容聊天背景设置页写入的 chat_bg_index（0-7）；未设置过该键时保持默认背景
        if color == nil, defaults.object(forKey: "chat_bg_index") != nil {
            let index = defaults.integer(forKey: "chat_bg_index")
            if ChatViewController.androidChatBgColors.indices.contains(index) {
                color = ChatViewController.androidChatBgColors[index]
            }
        }

        if let color = color {
            // 用户自定义纯色背景
            chatBgImageView.isHidden = true
            view.backgroundColor = color
        } else {
            // 默认聊天背景：安卓同款浅灰暗纹图案（不随列表滚动）
            view.backgroundColor = .themeChatBackground
            if !chatBgImageInstalled {
                chatBgImageInstalled = true
                chatBgImageView.contentMode = .scaleAspectFill
                chatBgImageView.isUserInteractionEnabled = false
                let pattern = UIImage(named: "ChatBgPattern") ?? UIImage(named: "chat_bg_pattern")
                chatBgImageView.image = pattern ?? ChatViewController.makeDefaultChatBackground()
                print("[Chat] 聊天背景图加载: \(pattern == nil ? "失败(回退渐变)" : "成功")")
                view.insertSubview(chatBgImageView, at: 0)
                chatBgImageView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
            chatBgImageView.isHidden = false
        }
        tableView.backgroundColor = .clear
    }

    /// 生成默认聊天背景：柔和的品牌蓝紫渐变（与启动页同色系）
    private static func makeDefaultChatBackground() -> UIImage {
        let size = CGSize(width: ScreenAdapter.screenWidth, height: ScreenAdapter.screenHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [
                UIColor.hex("F8F9FE").cgColor,
                UIColor.hex("EFF2FB").cgColor,
                UIColor.hex("EAEEF9").cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray,
                                      locations: [0, 0.55, 1])!
            ctx.cgContext.drawLinearGradient(gradient,
                                             start: .zero,
                                             end: CGPoint(x: 0, y: size.height),
                                             options: [])
        }
    }

    private static func color(from storedValue: String) -> UIColor? {
        var value = storedValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("0X") { value = String(value.dropFirst(2)) }
        if value.hasPrefix("#") { value = String(value.dropFirst()) }
        // 纯索引（0-11）映射到内置 12 色
        if let index = Int(value), androidChatBgColors.indices.contains(index) {
            return androidChatBgColors[index]
        }
        if value.count == 8, let argb = UInt64(value, radix: 16) {
            return UIColor(
                red: CGFloat((argb >> 16) & 0xFF) / 255.0,
                green: CGFloat((argb >> 8) & 0xFF) / 255.0,
                blue: CGFloat(argb & 0xFF) / 255.0,
                alpha: CGFloat((argb >> 24) & 0xFF) / 255.0
            )
        }
        if value.count == 6, UInt64(value, radix: 16) != nil {
            return UIColor.hex(value)
        }
        return nil
    }

    private func setupNavBar() {
        // 自定义标题视图（头像 + 名字 + 在线状态，左对齐，对齐安卓标题栏）
        // 宽度预留左右两侧按钮空间，避免长昵称超出标题栏遮挡按钮
        let maxTitleWidth = max(ScreenAdapter.scaleW(170), ScreenAdapter.screenWidth - 185)
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: maxTitleWidth, height: 44)

        // 对方/群头像（安卓标题栏同款）
        let navAvatar = UIImageView()
        navAvatar.layer.cornerRadius = ScreenAdapter.scaleW(15)
        navAvatar.clipsToBounds = true
        navAvatar.contentMode = .scaleAspectFill
        navAvatar.backgroundColor = .secondarySystemFill
        titleView.addSubview(navAvatar)
        navAvatar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(30))
        }
        AppUtility.loadChannelAvatar(channelId: channelId, channelType: channelType, name: titleText, into: navAvatar)

        // 名字（过长截断，不遮挡两侧按钮）
        let navTitleLabel = UILabel()
        navTitleLabel.text = titleText
        navTitleLabel.font = ScreenAdapter.mediumFont(16)
        navTitleLabel.textColor = .label
        navTitleLabel.lineBreakMode = .byTruncatingTail
        navTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleView.addSubview(navTitleLabel)

        // 单聊在线状态（在线 / 离线X分钟），无数据时隐藏
        onlineStatusLabel.font = ScreenAdapter.font(11)
        onlineStatusLabel.textColor = .secondaryLabel
        onlineStatusLabel.isHidden = true
        onlineStatusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // 特殊好友888：昵称红色，徽章放到"手机在线"那一行前面（安卓 subtitleView 中 specialBadgeLayout 在 subtitleTv 之前）
        let isSpecialPeer = isSpecialSingleChat
        if isSpecialPeer {
            navTitleLabel.textColor = SpecialUserUtils.specialUserNameColor
        }
        let subtitleStack = UIStackView()
        subtitleStack.axis = .horizontal
        subtitleStack.spacing = ScreenAdapter.scaleW(4)
        subtitleStack.alignment = .center
        if isSpecialPeer {
            subtitleStack.addArrangedSubview(SpecialUserUtils.makeBadgesView(fontSize: 9))
        }
        subtitleStack.addArrangedSubview(onlineStatusLabel)
        titleView.addSubview(subtitleStack)

        let hasStatus = channelType == 1
        if hasStatus {
            // 单聊：昵称+在线状态两行整体与头像垂直居中（总高约 34pt）
            navTitleLabel.snp.makeConstraints { make in
                make.leading.equalTo(navAvatar.snp.trailing).offset(ScreenAdapter.scaleW(8))
                make.trailing.lessThanOrEqualToSuperview()
                make.top.equalTo(navAvatar.snp.top).offset(-ScreenAdapter.scaleH(2))
            }
            subtitleStack.snp.makeConstraints { make in
                make.leading.equalTo(navTitleLabel)
                make.trailing.lessThanOrEqualToSuperview()
                make.top.equalTo(navTitleLabel.snp.bottom).offset(ScreenAdapter.scaleH(1))
            }
        } else {
            // 群聊：昵称与头像同一水平线（垂直中心对齐头像）
            navTitleLabel.snp.makeConstraints { make in
                make.leading.equalTo(navAvatar.snp.trailing).offset(ScreenAdapter.scaleW(8))
                make.trailing.lessThanOrEqualToSuperview()
                make.centerY.equalTo(navAvatar.snp.centerY)
            }
        }

        // 加载频道名称与在线状态（与Android一致：通过频道ID获取频道信息）
        Task {
            do {
                let channelInfo: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: channelId, channelType: channelType)
                )
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    navTitleLabel.text = channelInfo.displayName
                    // 昵称拉到后再次判定特殊好友（名称兜底），标红
                    if self.channelType == 1 && SpecialUserUtils.isSpecialUser(uid: self.channelId, shortNo: "", name: channelInfo.displayName) {
                        navTitleLabel.textColor = SpecialUserUtils.specialUserNameColor
                    }
                    // 用真实昵称刷新标题头像占位图
                    AppUtility.loadChannelAvatar(channelId: self.channelId, channelType: self.channelType, name: channelInfo.displayName, into: navAvatar)
                    self.updateOnlineStatus(
                        online: (channelInfo.online ?? 0) == 1,
                        lastOffline: channelInfo.last_offline
                    )
                    // 群聊：根据角色控制右上角"三横"管理入口（仅群主/管理员可见）
                    if self.channelType == 2 {
                        // 线上 /v1/channels/{id}/2 不返回顶层 role，角色放在 extra 里（extra.role=1 群主/2 管理员）
                        // 之前只读顶层 role 恒为 nil，导致群主永远看不到管理入口
                        var role = channelInfo.role ?? 0
                        if role == 0, let extra = channelInfo.extra?["role"]?.value {
                            if let intRole = extra as? Int {
                                role = intRole
                            } else if let strRole = extra as? String, let parsed = Int(strRole) {
                                role = parsed
                            }
                        }
                        self.myGroupRole = role
                        self.updateGroupRightBarButton()
                        // 频道信息未返回 role 时（部分群频道响应不带该字段），
                        // 回退到群成员列表查当前用户角色，避免群主/管理员看不到管理入口
                        if self.myGroupRole == 0 {
                            self.loadMyGroupRoleFromMembers()
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshCachedOnlineStatus()
                    // 频道信息请求失败时也要兜底查询群角色，否则管理入口永远不显示
                    if self?.channelType == 2 {
                        self?.loadMyGroupRoleFromMembers()
                    }
                }
            }
        }

        navigationItem.titleView = titleView

        // 右侧：语音通话（仅单聊）+ 更多（三个横杠，进入聊天信息页）
        let moreBtn = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(showMoreOptions)
        )
        moreBtn.tintColor = .label
        if channelType == 1 {
            let callBtn = UIBarButtonItem(
                image: UIImage(systemName: "phone.fill"),
                style: .plain,
                target: self,
                action: #selector(startVoiceCall)
            )
            callBtn.tintColor = .themePrimary
            if isSpecialSingleChat {
                // 特殊好友888：昵称后的按钮只保留语音，删掉聊天信息页入口，确保长昵称完整显示
                navigationItem.rightBarButtonItems = [callBtn]
            } else {
                navigationItem.rightBarButtonItems = [moreBtn, callBtn]
            }
        } else {
            // 群聊：群标题右侧管理入口所有人可见；点进去后按角色分流
            // 群主/管理员 → 群管理页（可编辑），普通成员 → 群资料页（只读）
            navigationItem.rightBarButtonItems = [moreBtn]
            titleView.isUserInteractionEnabled = true
            titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTitleView)))
        }

        // 返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 右上角"三个横杠"：单聊进入聊天信息页；群聊按角色分流（管理员→群管理页，普通成员→只读群资料页）
    @objc private func showMoreOptions() {
        if channelType == 2 {
            if isGroupAdmin {
                openGroupDetail()
            } else {
                navigationController?.pushViewController(GroupInfoViewController(groupId: channelId), animated: true)
            }
        } else {
            openChatPersonal()
        }
    }

    /// 群聊：右上角"三横"入口所有人可见（权限差异在进入的页面内按角色控制）
    private func updateGroupRightBarButton() {
        guard channelType == 2 else { return }
        if navigationItem.rightBarButtonItems?.isEmpty ?? true {
            let moreBtn = UIBarButtonItem(
                image: UIImage(systemName: "line.3.horizontal"),
                style: .plain,
                target: self,
                action: #selector(showMoreOptions)
            )
            moreBtn.tintColor = .label
            navigationItem.rightBarButtonItems = [moreBtn]
        }
    }

    /// 从群成员列表查询当前用户角色（频道信息接口不返回 role 时的兜底，对齐安卓本地成员表）
    private func loadMyGroupRoleFromMembers() {
        guard channelType == 2 else { return }
        let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
        guard !myUid.isEmpty else { return }
        Task {
            do {
                let members: [GroupMember] = try await APIClient.shared.requestFlexible(
                    .getGroupMembers(groupId: channelId, page: 1, size: 1000, keyword: nil)
                )
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let me = members.first(where: { $0.uid == myUid && ($0.isDeleted ?? 0) == 0 }) {
                        let role = me.role ?? 0
                        print("[Chat] 群成员兜底查到我的角色: \(role)")
                        if role > 0, role != self.myGroupRole {
                            self.myGroupRole = role
                            self.updateGroupRightBarButton()
                        }
                    }
                }
            } catch {
                print("[Chat] 群成员角色兜底查询失败: \(error)")
            }
        }
    }

    /// 点击群聊标题：所有成员统一进群详情页（含群成员、群二维码、群管理面板；修改权限由角色控制）
    @objc private func didTapTitleView() {
        guard channelType == 2 else { return }
        openGroupDetail()
    }

    // MARK: - 点击气泡头像
    /// 表格层头像命中：返回命中后的消息（用于任何 cell 形态的头像点击）
    @objc private func handleTableAvatarTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              indexPath.row < messages.count,
              let cell = tableView.cellForRow(at: indexPath) else { return }
        let message = messages[indexPath.row]
        guard message.type != .system, !message.fromUID.isEmpty else { return }
        let cellPoint = gesture.location(in: cell)

        var hit = false
        // 标准气泡布局的头像带固定 tag（987_002），命中该视图的 frame 即为点击头像
        if let avatarView = cell.contentView.viewWithTag(987_002), !avatarView.isHidden {
            let rect = avatarView.convert(avatarView.bounds, to: cell)
            hit = rect.insetBy(dx: -4, dy: -4).contains(cellPoint)
        } else {
            // 自定义 cell（通话结果/合并转发等）按左右头像区域近似命中
            let size = ChatBubbleLayout.avatarSize
            let inset = ChatBubbleLayout.sideInset
            let rect = message.isFromMe
                ? CGRect(x: cell.bounds.width - inset - size, y: 0, width: size + 8, height: ScreenAdapter.scaleH(110))
                : CGRect(x: 0, y: 0, width: inset + size + 8, height: ScreenAdapter.scaleH(110))
            hit = rect.contains(cellPoint)
        }
        guard hit else { return }
        // 标记时间戳，抑制紧随其后的 didSelectRowAt 默认跳转（如点开图片预览）
        avatarTapAt = Date()
        NotificationCenter.default.post(
            name: ChatAvatarTapRelay.notification,
            object: nil,
            userInfo: ["channelId": message.fromUID, "channelType": 1, "name": message.fromUID]
        )
    }

    @objc private func handleAvatarTapped(_ note: Notification) {
        guard let info = note.userInfo,
              let tappedId = info["channelId"] as? String else { return }
        let tappedType = (info["channelType"] as? Int) ?? 1
        let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""

        if tappedType == 2 {
            // 群头像 → 所有成员统一进群详情页
            openGroupDetail()
            return
        }
        // 自己的头像 → 我的主页
        if tappedId == myUid {
            openChatPersonal()
            return
        }
        // 系统账号头像 → 专属资料页（文件传输助手/系统通知，与会话列表头像一致）
        let lowered = tappedId.lowercased()
        if lowered == "filehelper" || lowered == "system_file_helper" {
            navigationController?.pushViewController(SystemAccountProfileViewController(account: .fileHelper), animated: true)
            return
        }
        if lowered == "u_10000" || lowered == "system_notice" || lowered == "system_team" {
            navigationController?.pushViewController(SystemAccountProfileViewController(account: .systemNotice), animated: true)
            return
        }
        // 他人头像 → 个人主页（统一走联系人详情页）
        let vc = ContactDetailViewController(uid: tappedId, source: channelType == 2 ? "来自群聊" : "来自聊天")
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 单聊语音通话
    @objc private func startVoiceCall() {
        guard channelType == 1 else { return }
        let peer = IMManager.shared.getChannelInfo(channelId: channelId, channelType: 1)
        RTCCallManager.shared.startCall(from: self,
                                        channelId: channelId,
                                        peerName: peer?.displayName ?? titleText,
                                        peerAvatar: peer?.logo ?? "")
    }

    // MARK: - 单聊在线状态（数据缺失时不显示，不伪造）
    private func updateOnlineStatus(online: Bool, lastOffline: Int?) {
        guard channelType == 1 else {
            onlineStatusLabel.isHidden = true
            lastOnlineStatusText = nil
            return
        }
        if online {
            lastOnlineStatusText = "手机在线" // 对齐安卓：device(手机)+在线
        } else if let lastOffline = lastOffline, lastOffline > 0 {
            lastOnlineStatusText = ChatViewController.offlineText(seconds: lastOffline)
        } else {
            lastOnlineStatusText = nil
        }
        onlineStatusLabel.text = lastOnlineStatusText
        onlineStatusLabel.isHidden = lastOnlineStatusText == nil
    }

    /// 优先使用 IMManager 已缓存的频道信息（仅能判断在线，无 last_offline 时隐藏）
    private func refreshCachedOnlineStatus() {
        guard channelType == 1 else { return }
        if let info = IMManager.shared.getChannelInfo(channelId: channelId, channelType: 1), info.online {
            updateOnlineStatus(online: true, lastOffline: nil)
        }
    }

    private static func offlineText(seconds: Int) -> String {
        let now = Int(Date().timeIntervalSince1970)
        let diff = max(now - seconds, 0)
        if diff < 60 { return "刚刚离线" }
        if diff < 3600 { return "离线\(diff / 60)分钟" }
        if diff < 86400 { return "离线\(diff / 3600)小时" }
        return "离线\(diff / 86400)天"
    }

    private func openContactDetail(uid: String) {
        let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
        guard !uid.isEmpty, uid != myUid else { return }
        let detailVC = ContactDetailViewController(uid: uid)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func openChatPersonal() {
        let vc = ChatPersonalViewController(channelId: channelId, title: titleText, channelType: channelType)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func searchChatHistory() {
        let vc = ChatSearchViewController(channelId: channelId, channelType: channelType)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func clearChatHistory() {
        let alert = UIAlertController(title: "确认清空聊天记录？", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.messages.removeAll()
            self.tableView.reloadData()
            // 同步删除磁盘消息缓存，避免下次进入旧消息闪现
            try? FileManager.default.removeItem(at: self.msgCacheFileURL)
            AppUtility.showToast("已清空")
        })
        present(alert, animated: true)
    }

    @objc private func showGroupMoreOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "语音通话", style: .default) { [weak self] _ in
            self?.startGroupVoiceCall()
        })

        alert.addAction(UIAlertAction(title: "群聊详情", style: .default) { [weak self] _ in
            self?.openGroupDetail()
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        // iPad 适配
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }

    private func startGroupVoiceCall() {
        let vc = ChooseVideoCallMembersViewController(groupId: channelId, groupType: channelType)
        vc.onSelected = { [weak self] (uids: [String]) in
            guard let self = self else { return }
            // 发起语音通话
            let callVC = TRTCCallViewController(channelId: self.channelId)
            callVC.modalPresentationStyle = .fullScreen
            self.present(callVC, animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openGroupDetail() {
        let vc = GroupDetailViewController(groupId: channelId)
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 首屏先用 SDK 本地消息库渲染，避免等待网络导致白屏
    private func loadCachedMessages() {
        // 从 SDK 本地库读取最近消息：条数提升到 100 条，进入会话即可见较完整记录
        IMManager.shared.pullLastMessages(channelId: channelId, channelType: channelType, limit: 100) { [weak self] wkMessages, _ in
            guard let self = self, let wkMessages = wkMessages, !wkMessages.isEmpty else { return }
            let cached = wkMessages.map { $0.toBusinessMessage() }
            guard cached.contains(where: { !($0.type == .text && $0.content.isEmpty) }) else { return }
            self.applyLoadedMessages(cached, scroll: true, finish: false, merge: true)
        }
    }

    // MARK: - 消息磁盘缓存（进入会话秒显，不等网络/IM 连接）
    private var msgCacheWorkItem: DispatchWorkItem?

    private var msgCacheFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let safeId = String(channelId.map { $0.isLetter || $0.isNumber ? $0 : "_" })
        return docs.appendingPathComponent("msg_cache_\(safeId)_\(channelType).json")
    }

    /// 读取磁盘缓存消息并立即渲染（存在则骨架屏直接消失）
    private func loadDiskCachedMessages() {
        guard let data = try? Data(contentsOf: msgCacheFileURL),
              let cached = try? JSONDecoder().decode([Message].self, from: data),
              !cached.isEmpty else { return }
        applyLoadedMessages(cached, scroll: true, finish: false)
    }

    /// 防抖 0.5 秒落盘最近 50 条消息
    private func saveMessagesCacheDebounced() {
        msgCacheWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let snapshot = Array(self.messages.suffix(50))
            guard !snapshot.isEmpty else { return }
            let url = self.msgCacheFileURL
            DispatchQueue.global(qos: .utility).async {
                if let data = try? JSONEncoder().encode(snapshot) {
                    try? data.write(to: url, options: .atomic)
                }
            }
        }
        msgCacheWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    /// 内容比对归一化：本地位置占位消息带 "[位置] " 前缀，服务端线缆解析结果没有
    private func normalizeForCompare(_ content: String) -> String {
        guard content.hasPrefix("[位置] "), content.count > 5 else { return content }
        return String(content.dropFirst(5))
    }

    /// 解析位置内容中的经纬度（兼容 JSON、name|lat,lng、[位置] name|lat,lng 三种格式）
    private func locationCoordinate(from content: String) -> (Double, Double)? {
        let raw = normalizeForCompare(content)
        if raw.hasPrefix("{"),
           let data = raw.data(using: .utf8),
           let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            let lat = (dict["lat"] as? NSNumber)?.doubleValue ?? (dict["latitude"] as? NSNumber)?.doubleValue
            let lng = (dict["longitude"] as? NSNumber)?.doubleValue ?? (dict["lng"] as? NSNumber)?.doubleValue
            if let lat = lat, let lng = lng { return (lat, lng) }
        }
        if let barIndex = raw.lastIndex(of: "|") {
            let coordPart = String(raw[raw.index(after: barIndex)...])
            let nums = coordPart.components(separatedBy: ",")
            if nums.count >= 2, let lat = Double(nums[0].trimmingCharacters(in: .whitespaces)),
               let lng = Double(nums[1].trimmingCharacters(in: .whitespaces)) {
                return (lat, lng)
            }
        }
        return nil
    }

    /// 判断两条消息是否为同一条（用于位置/媒体消息的占位、回显、历史同步去重）
    private func isSameMessage(_ a: Message, _ b: Message) -> Bool {
        if !a.messageID.isEmpty && !b.messageID.isEmpty && a.messageID == b.messageID { return true }
        if !a.clientMsgNo.isEmpty && !b.clientMsgNo.isEmpty && a.clientMsgNo == b.clientMsgNo { return true }
        guard a.isFromMe == b.isFromMe, a.type == b.type else { return false }
        switch a.type {
        case .location:
            // 同一次发送的占位/回显/历史同步内容格式可能不同（"[位置] 名|经纬度" vs JSON），
            // 因此优先比较经纬度，取不到坐标时再退回文本比较
            if let c1 = locationCoordinate(from: a.content), let c2 = locationCoordinate(from: b.content),
               abs(c1.0 - c2.0) < 0.0001, abs(c1.1 - c2.1) < 0.0001 {
                return abs(a.timestamp - b.timestamp) < 20_000
            }
            return normalizeForCompare(a.content) == normalizeForCompare(b.content)
                && abs(a.timestamp - b.timestamp) < 15_000
        case .image, .voice, .video, .file, .card, .note:
            return a.content == b.content && abs(a.timestamp - b.timestamp) < 5_000
        default:
            return false
        }
    }

    /// 合并重复消息：保留最新状态与真实服务端 ID
    private func mergedMessage(_ a: Message, _ b: Message) -> Message {
        var result = a
        if b.messageSeq > 0 {
            result.messageID = b.messageID
            result.messageSeq = b.messageSeq
        }
        result.timestamp = max(a.timestamp, b.timestamp)
        result.status = max(a.status, b.status)
        if result.content.isEmpty { result.content = b.content }
        return result
    }

    /// 全量去重（防止同一位置消息以占位/回显/历史同步三种来源重复出现）
    private func dedupeForDisplay(_ list: [Message]) -> [Message] {
        var kept: [Message] = []
        for msg in list {
            if let idx = kept.firstIndex(where: { isSameMessage($0, msg) }) {
                kept[idx] = mergedMessage(kept[idx], msg)
            } else {
                kept.append(msg)
            }
        }
        return kept
    }

    /// 合并服务端消息与本地消息（保留发送中/失败占位），按 seq + 时间排序
    /// - Parameter merge: 为 true 时保留已有本地消息（服务端只返回部分消息也不丢内容）
    private func applyLoadedMessages(_ loaded: [Message], scroll: Bool, finish: Bool, merge: Bool = false) {
        var result = loaded.filter { !($0.type == .text && $0.content.isEmpty) }
        // 黑名单过滤（微信逻辑：拉黑后对方消息不展示）
        if channelType == 1 {
            let blackUids = UserDefaults.standard.stringArray(forKey: "blacklist_uids") ?? []
            if !blackUids.isEmpty {
                result = result.filter { $0.isFromMe || !blackUids.contains($0.fromUID) }
            }
        }
        // 特殊群聊：过滤掉管理后台已删除的消息（is_deleted=1）以及全部系统/群事件消息
        if isSpecialGroup {
            result = result.filter { msg in
                // 系统消息（谁邀请谁、改群名、退群等）不显示
                if msg.type == .system { return false }
                // 从原始 payload 中检查删除标记（如果后端在 content 里返回了 is_deleted）
                if let data = msg.content.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let deleted = dict["is_deleted"] as? Int, deleted == 1 {
                    return false
                }
                return true
            }
        }
        let base = merge ? messages : []
        for local in base {
            // 本地消息 ID 与服务端 ID 相同时视为同一条；发送中的占位消息 ID 为 UUID，
            // 用 clientMsgNo 或"同方向同类型同内容（位置去掉前缀）时间相近"兜底去重
            let duplicated = result.contains { r in
                if r.messageID == local.messageID { return true }
                if !r.clientMsgNo.isEmpty && !local.clientMsgNo.isEmpty && r.clientMsgNo == local.clientMsgNo { return true }
                if r.messageID.isEmpty && local.messageID.isEmpty { return true }
                guard r.isFromMe == local.isFromMe, r.type == local.type else { return false }
                let window: Int64 = local.type == .location ? 15_000 : 5_000
                return normalizeForCompare(r.content) == normalizeForCompare(local.content)
                    && abs(r.timestamp - local.timestamp) < window
            }
            if !duplicated { result.append(local) }
        }
        for local in messages where (local.status == 0 || local.status == -1) {
            if !result.contains(where: { $0.messageID == local.messageID }) {
                result.append(local)
            }
        }
        // 以时间为主要排序键：服务端历史中存在 message_seq 重复（后端的系统消息与 IM 消息 seq 冲突），
        // 仅按 seq 排序会让顺序错乱；seq 只作为同一秒内的稳定次序
        result.sort { lhs, rhs in
            let lTime = lhs.timestamp > 0 ? lhs.timestamp : Int64.max
            let rTime = rhs.timestamp > 0 ? rhs.timestamp : Int64.max
            if lTime != rTime { return lTime < rTime }
            let lSeq = lhs.messageSeq == 0 ? Int.max : lhs.messageSeq
            let rSeq = rhs.messageSeq == 0 ? Int.max : rhs.messageSeq
            return lSeq < rSeq
        }
        messages = dedupeForDisplay(result)
        tableView.reloadData()
        if finish || !messages.isEmpty {
            finishLoading()
        }
        if scroll {
            scrollToBottom()
        }
        saveMessagesCacheDebounced()
    }

    private func loadMessages() {
        Task {
            do {
                let response: WKMessageSyncResponse = try await APIClient.shared.requestFlexible(
                    .syncChannelMessages(channelId: channelId, channelType: self.channelType, startMessageSeq: 0, limit: 50, startTimestamp: 0)
                )
                DispatchQueue.main.async {
                    if let msgs = response.messages {
                        print("[Chat] 加载到 \(msgs.count) 条服务端消息")
                        let page = msgs.map { Message(from: $0) }
                        // merge: 服务端只返回部分消息时保留本地已有内容，避免"加载不完整"
                        self.applyLoadedMessages(page, scroll: self.messages.isEmpty, finish: true, merge: true)
                        // 用首屏服务端响应的最老一条初始化翻页游标（不依赖本地缓存是否完整）
                        self.bootstrapHistoryCursor(from: page, more: (response.more ?? 0) != 0)
                        // 首屏不足一屏时自动继续向上翻，保证进入会话就能看到尽量完整的历史
                        self.fillScreenIfNeeded()
                    } else {
                        print("[Chat] 消息列表为空")
                        self.applyLoadedMessages([], scroll: false, finish: true, merge: true)
                    }
                }
            } catch {
                print("[Chat] 加载消息失败: \(error)")
                DispatchQueue.main.async {
                    self.finishLoading()
                    if self.messages.isEmpty {
                        AppUtility.showToast("加载消息失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        updateScrollDownButtonVisibility()
    }

    @objc private func scrollDownTapped() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        updateScrollDownButtonVisibility()
    }

    /// 离底部超过一屏左右时显示「回到底部」按钮
    private func updateScrollDownButtonVisibility() {
        guard tableView.bounds.height > 0 else { return }
        let distance = tableView.contentSize.height - tableView.contentOffset.y - tableView.bounds.height
        let shouldShow = distance > ScreenAdapter.scaleH(240) && !messages.isEmpty
        let isShown = scrollDownButton.alpha > 0.5
        guard shouldShow != isShown else { return }
        UIView.animate(withDuration: 0.2) {
            self.scrollDownButton.alpha = shouldShow ? 1 : 0
        }
    }

    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let bottomInset = view.safeAreaInsets.bottom
            let offset = max(frame.height - bottomInset, 0)
            UIView.animate(withDuration: 0.25) {
                self.inputBar.snp.updateConstraints { make in
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-offset)
                }
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.25) {
            self.inputBar.snp.updateConstraints { make in
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        // 分组间距：与相邻同方向消息收紧间距
        let prevMsg = indexPath.row > 0 ? messages[indexPath.row - 1] : nil
        let nextMsg = indexPath.row + 1 < messages.count ? messages[indexPath.row + 1] : nil
        let groupedAbove = prevMsg?.isFromMe == message.isFromMe
        let groupedBelow = nextMsg?.isFromMe == message.isFromMe
        // 时间分隔：与上一条相隔超过 5 分钟（或是首条）时，在气泡上方显示居中时间
        let timeHeader: String?
        if let prev = prevMsg, message.timestamp - prev.timestamp <= 5 * 60 * 1000 {
            timeHeader = nil
        } else {
            timeHeader = ChatBubbleLayout.clusterTimeText(timestampMs: message.timestamp)
        }
        // 上传中的图片/视频：先展示本地缩略图占位气泡
        if (message.type == .image || message.type == .video), pendingMedia[message.messageID] != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PendingMediaMessageCell", for: indexPath) as! PendingMediaMessageCell
            let messageID = message.messageID
            cell.configure(with: message, thumbnail: pendingMedia[messageID], timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow) { [weak self] in
                self?.retryUpload(messageID: messageID)
            }
            return cell
        }
        switch message.type {
        case .image:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageMessageCell", for: indexPath) as! ImageMessageCell
            cell.configure(with: message, timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow)
            return cell
        case .voice:
            let cell = tableView.dequeueReusableCell(withIdentifier: "VoiceMessageCell", for: indexPath) as! VoiceMessageCell
            cell.configure(with: message, timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow)
            return cell
        case .video:
            let cell = tableView.dequeueReusableCell(withIdentifier: "VideoMessageCell", for: indexPath) as! VideoMessageCell
            cell.configure(with: message, timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow)
            return cell
        case .file:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FileMessageCell", for: indexPath) as! FileMessageCell
            cell.configure(with: message, timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow)
            return cell
        case .location:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocationMessageCell", for: indexPath) as! LocationMessageCell
            cell.configure(with: message, timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow)
            return cell
        case .card:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CardMessageCell", for: indexPath) as! CardMessageCell
            cell.configure(with: message, timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow)
            return cell
        case .note:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoteMessageCell", for: indexPath) as! NoteMessageCell
            cell.configure(with: message, timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow)
            return cell
        case .call:
            // 通话结果气泡（对齐安卓 WKCallProvider）
            let cell = tableView.dequeueReusableCell(withIdentifier: "CallMessageCell", for: indexPath) as! CallMessageCell
            cell.configure(with: message)
            cell.configureTimeHeader(text: timeHeader, isNew: pendingAppearIDs.contains(message.messageID))
            cell.onBubbleTapped = { [weak self] in
                // 点击通话气泡重新发起语音通话（对齐安卓点击重拨）
                self?.startVoiceCall()
            }
            return cell
        case .system:
            // 系统/群事件消息：居中灰色圆角条，无头像，{0}/{1} 占位符在解析时替换为昵称
            // 特殊群聊的系统消息已在 applyLoadedMessages 数据层过滤，不会走到这里
            let cell = tableView.dequeueReusableCell(withIdentifier: "SystemMessageCell", for: indexPath) as! SystemMessageCell
            cell.configure(with: message)
            cell.configureTimeHeader(text: timeHeader, isNew: pendingAppearIDs.contains(message.messageID))
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextMessageCell", for: indexPath) as! TextMessageCell
            cell.configure(with: message, timeHeader: timeHeader, groupedAbove: groupedAbove, groupedBelow: groupedBelow)
            return cell
        }
    }

    /// 新消息进入时的弹性浮现动画（只作用于刚插入的行）
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < messages.count else { return }
        let id = messages[indexPath.row].messageID
        guard pendingAppearIDs.remove(id) != nil else { return }
        cell.contentView.transform = CGAffineTransform(translationX: 0, y: 24).scaledBy(x: 0.96, y: 0.96)
        cell.contentView.alpha = 0
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4, options: [.curveEaseOut, .allowUserInteraction]) {
            cell.contentView.transform = .identity
            cell.contentView.alpha = 1
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateScrollDownButtonVisibility()
        // 滑到顶部附近自动拉取更早的历史消息（修复"部分聊天记录加载不出来"）
        if scrollView.contentOffset.y < 50, !isLoadingOlder, hasMoreHistory {
            loadOlderMessages()
        }
    }

    // MARK: - 首屏历史游标初始化
    /// 用首屏服务端响应的最老一条初始化翻页游标，不依赖本地缓存是否完整
    private func bootstrapHistoryCursor(from page: [Message], more: Bool) {
        guard !page.isEmpty else { return }
        guard let oldest = page.filter({ $0.messageSeq > 0 }).min(by: { lhs, rhs in
            let lt = lhs.timestamp > 0 ? lhs.timestamp : Int64.max
            let rt = rhs.timestamp > 0 ? rhs.timestamp : Int64.max
            if lt != rt { return lt < rt }
            return lhs.messageSeq < rhs.messageSeq
        }) else { return }
        if historyCursorSeq == 0 || oldest.messageSeq < historyCursorSeq {
            historyCursorSeq = oldest.messageSeq
            historyCursorTs = Int(max(0, oldest.timestamp / 1000))
        }
        if more { hasMoreHistory = true }
    }

    /// 首屏内容不足一屏且仍有更早历史时，自动继续向上翻页
    private func fillScreenIfNeeded() {
        guard hasMoreHistory, !isLoadingOlder, tableView.bounds.height > 0 else { return }
        if tableView.contentSize.height < tableView.bounds.height + ScreenAdapter.scaleH(100) {
            loadOlderMessages()
        }
    }

    // MARK: - 历史消息分页
    /// 向上翻页：按游标拉取服务端历史，直至取完全部记录（单聊从加好友起、群聊从建群起）
    private func loadOlderMessages() {
        guard !isLoadingOlder, hasMoreHistory else { return }
        // 游标未初始化时，取当前已加载消息里最早的一条（时间, seq）作为起点
        if historyCursorSeq <= 0 {
            let oldest = messages
                .filter { $0.messageSeq > 0 }
                .min { lhs, rhs in
                    let lt = lhs.timestamp > 0 ? lhs.timestamp : Int64.max
                    let rt = rhs.timestamp > 0 ? rhs.timestamp : Int64.max
                    if lt != rt { return lt < rt }
                    return lhs.messageSeq < rhs.messageSeq
                }
            guard let oldestMsg = oldest else {
                hasMoreHistory = false
                return
            }
            historyCursorSeq = oldestMsg.messageSeq
            historyCursorTs = Int(max(0, oldestMsg.timestamp / 1000))
        }
        let cursorSeq = historyCursorSeq
        let cursorTs = historyCursorTs
        isLoadingOlder = true
        Task {
            do {
                let response: WKMessageSyncResponse = try await APIClient.shared.requestFlexible(
                    .syncChannelMessages(channelId: channelId, channelType: channelType,
                                         startMessageSeq: cursorSeq, limit: 30, startTimestamp: cursorTs)
                )
                DispatchQueue.main.async {
                    self.isLoadingOlder = false
                    let fetched = (response.messages ?? []).map { Message(from: $0) }
                    let more = (response.more ?? 0) != 0
                    // 无论是否重复，都用本页最老的一条推进游标
                    var cursorAdvanced = false
                    if let oldestFetched = fetched.filter({ $0.messageSeq > 0 }).min(by: { lhs, rhs in
                        let lt = lhs.timestamp > 0 ? lhs.timestamp : Int64.max
                        let rt = rhs.timestamp > 0 ? rhs.timestamp : Int64.max
                        if lt != rt { return lt < rt }
                        return lhs.messageSeq < rhs.messageSeq
                    }) {
                        let ts = Int(max(0, oldestFetched.timestamp / 1000))
                        if ts < cursorTs || (ts == cursorTs && oldestFetched.messageSeq < cursorSeq) {
                            self.historyCursorTs = ts
                            self.historyCursorSeq = oldestFetched.messageSeq
                            cursorAdvanced = true
                        }
                    }
                    if !more || !cursorAdvanced {
                        self.hasMoreHistory = false
                    }
                    let older = fetched.filter { o in
                        !self.messages.contains(where: { $0.messageID == o.messageID })
                    }
                    if older.isEmpty {
                        // 整页重复但还有更早历史：立即继续向上翻，不中断
                        if self.hasMoreHistory {
                            self.loadOlderMessages()
                        }
                        return
                    }
                    let oldHeight = self.tableView.contentSize.height
                    let oldOffset = self.tableView.contentOffset.y
                    self.messages = (older + self.messages).sorted { lhs, rhs in
                        let lTime = lhs.timestamp > 0 ? lhs.timestamp : Int64.max
                        let rTime = rhs.timestamp > 0 ? rhs.timestamp : Int64.max
                        if lTime != rTime { return lTime < rTime }
                        let lSeq = lhs.messageSeq == 0 ? Int.max : lhs.messageSeq
                        let rSeq = rhs.messageSeq == 0 ? Int.max : rhs.messageSeq
                        return lSeq < rSeq
                    }
                    self.tableView.reloadData()
                    let newHeight = self.tableView.contentSize.height
                    self.tableView.contentOffset.y = max(0, oldOffset + (newHeight - oldHeight))
                    self.saveMessagesCacheDebounced()
                    // 本页去重后很少或内容不足一屏且服务端标记还有更多：继续翻，避免"看起来没有历史"
                    if self.hasMoreHistory {
                        if older.count < 10 {
                            self.loadOlderMessages()
                        } else {
                            self.fillScreenIfNeeded()
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async { self.isLoadingOlder = false }
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 头像点击已由表格层手势处理，避免同时触发图片预览/笔记打开等默认动作
        if let t = avatarTapAt, Date().timeIntervalSince(t) < 0.6 {
            avatarTapAt = nil
            return
        }
        let message = messages[indexPath.row]
        // 上传中的占位消息不做跳转
        if pendingMedia[message.messageID] != nil { return }
        switch message.type {
        case .image:
            guard let imgURL = APIConfig.chatMediaURL(message.content) else { return }
            let previewVC = ImagePreviewViewController(url: imgURL)
            previewVC.modalPresentationStyle = .fullScreen
            present(previewVC, animated: true)
        case .voice:
            if let cell = tableView.cellForRow(at: indexPath) as? VoiceMessageCell {
                cell.playVoice()
            }
        case .video:
            if let cell = tableView.cellForRow(at: indexPath) as? VideoMessageCell {
                cell.playVideo(from: self)
            }
        case .location:
            if let cell = tableView.cellForRow(at: indexPath) as? LocationMessageCell {
                cell.openLocationMap(from: self)
            }
        case .card:
            if let cardInfo = CardMessageInfo.parse(from: message.content) {
                let detailVC = ContactDetailViewController(uid: cardInfo.uid)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        case .note:
            // 解析笔记消息内容并展示详情（解析失败时给出提示而非无响应）
            if let note = parseNoteMessage(message.content) {
                let detailVC = NoteDetailViewController(note: note)
                navigationController?.pushViewController(detailVC, animated: true)
            } else {
                AppUtility.showToast("笔记内容无法解析")
            }
        default:
            break
        }
    }

    // MARK: - 长按气泡菜单（iMessage 式：气泡弹出 + 操作菜单）
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let message = messages[indexPath.row]
        guard message.type != .system else { return nil }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            var actions: [UIMenuElement] = []

            // 复制（仅文本类消息）
            if message.type == .text {
                actions.append(UIAction(title: "复制", image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.string = message.content
                    AppUtility.showToast("已复制")
                })
            }
            // 图片消息：识别图中二维码（与安卓长按识图对齐，支持一张图多个二维码）
            if message.type == .image {
                actions.append(UIAction(title: "识别图中二维码", image: UIImage(systemName: "qrcode.viewfinder")) { [weak self] _ in
                    self?.recognizeQRCode(in: message)
                })
            }
            // 转发
            actions.append(UIAction(title: "转发", image: UIImage(systemName: "arrowshape.turn.up.right")) { [weak self] _ in
                self?.forwardMessage(message)
            })
            // 收藏
            actions.append(UIAction(title: "收藏", image: UIImage(systemName: "star")) { [weak self] _ in
                self?.favoriteMessage(message)
            })
            // 表情回应
            actions.append(UIAction(title: "回复表情", image: UIImage(systemName: "face.smiling")) { [weak self] _ in
                guard let self = self else { return }
                MessageReactionView.showReactionPicker(for: message.messageID, from: self.tableView) { emoji in
                    self.sendReaction(message: message, emoji: emoji)
                }
            })
            // 撤回（仅自己的消息）
            if message.isFromMe {
                actions.append(UIAction(title: "撤回", image: UIImage(systemName: "arrow.uturn.backward")) { [weak self] _ in
                    self?.recallMessage(message)
                })
            }
            // 删除
            actions.append(UIAction(title: "删除", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteMessage(message)
            })

            return UIMenu(title: "", children: actions)
        }
    }

    // MARK: - 长按识图（二维码）
    /// 识别图片中的二维码，支持一张图里存在多个二维码
    private func recognizeQRCode(in message: Message) {
        guard let url = APIConfig.chatMediaURL(message.content) else {
            AppUtility.showToast("图片地址无效")
            return
        }
        AppUtility.showToast("正在识别…")
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data), let ciImage = image.cgImage else {
                    DispatchQueue.main.async { AppUtility.showToast("图片加载失败") }
                    return
                }
                let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                          context: nil,
                                          options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                let features = detector?.features(in: CIImage(cgImage: ciImage)) as? [CIQRCodeFeature] ?? []
                let payloads = features.compactMap { $0.messageString }.filter { !$0.isEmpty }
                DispatchQueue.main.async { self.handleQRPayloads(payloads) }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("识别失败") }
            }
        }
    }

    private func handleQRPayloads(_ payloads: [String]) {
        guard !payloads.isEmpty else {
            AppUtility.showToast("未识别到二维码")
            return
        }
        if payloads.count == 1 {
            openQRPayload(payloads[0])
            return
        }
        // 多个二维码：弹出列表让用户选择要打开哪一个
        let sheet = UIAlertController(title: "识别到 \(payloads.count) 个二维码", message: nil, preferredStyle: .actionSheet)
        for (i, p) in payloads.enumerated() {
            sheet.addAction(UIAlertAction(title: "\(i + 1). " + (p.count > 30 ? String(p.prefix(30)) + "…" : p), style: .default) { [weak self] _ in
                self?.openQRPayload(p)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

    private func openQRPayload(_ payload: String) {
        if let url = URL(string: payload), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) {
            UIApplication.shared.open(url)
        } else {
            UIPasteboard.general.string = payload
            AppUtility.showToast("已复制二维码内容")
        }
    }

    /// 菜单弹出时高亮区域对准气泡（而非整行），呈现 iMessage 式气泡浮起效果
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return targetedBubblePreview(configuration: configuration)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return targetedBubblePreview(configuration: configuration)
    }

    private func targetedBubblePreview(configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        return UITargetedPreview(view: cell.contentView, parameters: params)
    }

    // MARK: - 已读回执
    /// 上报已读（对齐后端 /v1/message/readed），不再误删消息
    private func markMessagesAsRead() {
        let incoming = messages.filter { !$0.isFromMe }
        guard !incoming.isEmpty else { return }
        let ids = incoming.map { $0.messageID }
        let payload = incoming.map { msg -> [String: Any] in
            ["message_id": msg.messageID, "message_seq": msg.messageSeq]
        }
        Task {
            _ = try? await APIClient.shared.requestRaw(.reportReaded(
                channelId: channelId,
                channelType: channelType,
                messageIds: ids,
                messages: payload
            ))
        }
    }

    // MARK: - 消息扩展同步（已读回执 + 对方撤回，对齐安卓 syncExtraMsg）
    private func startExtraSync() {
        extraSyncTimer?.invalidate()
        syncMessageExtra()
        extraSyncTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.syncMessageExtra()
        }
    }

    private func stopExtraSync() {
        extraSyncTimer?.invalidate()
        extraSyncTimer = nil
    }

    private func syncMessageExtra() {
        Task {
            guard let response = try? await APIClient.shared.requestRaw(.syncMessageExtra(
                channelId: channelId, channelType: channelType, version: extraVersion)) else { return }
            let items = ChatViewController.extraItems(from: response)
            guard !items.isEmpty else { return }
            DispatchQueue.main.async {
                var changedRows: [IndexPath] = []
                for item in items {
                    if let ver = (item["version"] as? NSNumber)?.int64Value,
                       ver > self.extraVersion { self.extraVersion = ver }
                    if let ver = (item["extra_version"] as? NSNumber)?.int64Value,
                       ver > self.extraVersion { self.extraVersion = ver }
                    guard let mid = item["message_id"] as? String,
                          let idx = self.messages.firstIndex(where: { $0.messageID == mid }) else { continue }
                    let readed = (item["readed"] as? NSNumber)?.intValue ?? 0
                    let readedCount = (item["readed_count"] as? NSNumber)?.intValue ?? 0
                    let revoked = (item["revoke"] as? NSNumber)?.intValue ?? 0
                    if revoked == 1 {
                        if self.messages[idx].type != .system {
                            self.messages[idx].type = .system
                            self.messages[idx].content = self.messages[idx].isFromMe ? "你撤回了一条消息" : "对方撤回了一条消息"
                            changedRows.append(IndexPath(row: idx, section: 0))
                        }
                    } else if self.messages[idx].isFromMe, readed == 1 || readedCount > 0,
                              self.messages[idx].status != 2 {
                        // 2 = 已读（双勾，主题色）
                        self.messages[idx].status = 2
                        changedRows.append(IndexPath(row: idx, section: 0))
                    }
                }
                guard !changedRows.isEmpty else { return }
                self.tableView.reloadRows(at: changedRows, with: .none)
            }
        }
    }

    /// 递归解析扩展同步返回（服务端可能返回 data/items/list 等多种包裹）
    private static func extraItems(from value: Any) -> [[String: Any]] {
        if let array = value as? [[String: Any]] {
            if array.contains(where: { $0["message_id"] != nil }) { return array }
            for item in array where item["message_id"] == nil {
                let nested = extraItems(from: item)
                if !nested.isEmpty { return nested }
            }
            return []
        }
        if let dict = value as? [String: Any] {
            for (key, item) in dict where key != "message_id" {
                let nested = extraItems(from: item)
                if !nested.isEmpty { return nested }
            }
        }
        return []
    }

    private func recallMessage(_ message: Message) {
        // 本地占位消息（UUID 且尚未收到 sendack 回写真实 messageID）服务端查不到，直接拦截
        let isServerID = Int64(message.messageID) != nil
        if !isServerID {
            AppUtility.showToast("消息发送中，稍后重试")
            return
        }
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.revokeMessage(
                    channelId: channelId,
                    channelType: channelType,
                    messageId: message.messageID,
                    clientMsgNo: message.clientMsgNo.isEmpty ? message.messageID : message.clientMsgNo,
                    messageSeq: UInt32(max(0, message.messageSeq))
                ))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        // 对齐安卓/微信：撤回后替换为居中系统条
                        if let idx = self.messages.firstIndex(where: { $0.messageID == message.messageID }) {
                            self.messages[idx].type = .system
                            self.messages[idx].content = "你撤回了一条消息"
                            self.tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
                        }
                        self.saveMessagesCacheDebounced()
                    }
                } else {
                    let msg = (response["msg"] as? String) ?? "撤回失败"
                    DispatchQueue.main.async { AppUtility.showToast(msg) }
                }
            } catch {
                AppUtility.showToast("撤回失败")
            }
        }
    }

    private func deleteMessage(_ message: Message) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.deleteMessage(messageId: message.messageID))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        if let idx = self.messages.firstIndex(where: { $0.messageID == message.messageID }) {
                            self.messages.remove(at: idx)
                            self.tableView.deleteRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
                        }
                    }
                }
            } catch {
                AppUtility.showToast("删除失败")
            }
        }
    }

    private func forwardMessage(_ message: Message) {
        let alert = UIAlertController(title: "转发到", message: "请选择转发目标", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "输入对方ID"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "发送", style: .default) { [weak self] _ in
            guard let targetId = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !targetId.isEmpty else { return }
            Task {
                do {
                    let response = try await APIClient.shared.requestRaw(.sendMessage(channelId: targetId, content: message.content, type: message.type.rawValue, channelType: 1))
                    if response["status"] as? Int == 200 {
                        DispatchQueue.main.async {
                            AppUtility.showToast("已转发")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("转发失败")
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func favoriteMessage(_ message: Message) {
        // 使用本地存储收藏
        let favItem = FavoriteStorageManager.shared.createFavorite(from: message, senderName: titleText)
        FavoriteStorageManager.shared.addFavorite(favItem)
        AppUtility.showToast("已收藏")
        
        // 同时尝试同步到服务器（失败不影响本地）
        Task {
            do {
                let typeVal: Int
                switch message.type {
                case .text: typeVal = 1
                case .image: typeVal = 2
                case .voice: typeVal = 3
                case .video: typeVal = 4
                case .file: typeVal = 5
                case .location: typeVal = 6
                case .card: typeVal = 7
                case .note: typeVal = 100
                default: typeVal = 1
                }
                _ = try await APIClient.shared.requestRaw(.addFavorite(type: typeVal, content: message.content, extra: nil))
            } catch {
                // 静默失败，本地已保存
            }
        }
    }

    private func sendReaction(message: Message, emoji: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.reactMessage(
                    messageId: message.messageID,
                    channelId: channelId,
                    channelType: self.channelType,
                    emoji: emoji
                ))
                DispatchQueue.main.async {
                    AppUtility.showToast("表情已发送")
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }
}

// MARK: - ChatInputBarDelegate
extension ChatViewController: ChatInputBarDelegate {

    func didSendTextMessage(_ text: String) {
        if !IMManager.shared.isConnected {
            AppUtility.showToast("连接已断开，正在重连...")
        }
        // 立即判断发送结果：成功直接显示单勾，失败显示红色感叹号，不再停留在“发送中”转圈
        // SDK 返回的 WKMessage 携带 clientMsgNo，用于 sendack 回执把真实 messageID 回写到本条消息
        let sentWK = IMManager.shared.sendTextMessage(channelId: channelId, content: text, channelType: channelType)
        let msg = Message(
            messageID: UUID().uuidString,
            channelID: channelId,
            channelType: self.channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: text,
            type: .text,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: sentWK != nil ? 1 : -1,
            clientMsgNo: sentWK?.clientMsgNo ?? ""
        )
        messages.append(msg)
        // 会话列表预览同步为自己发出的最新一条（SDK 会话库对自定义消息更新滞后）
        IMManager.shared.recordLastPreview(msg)
        // 纳入回显匹配集：SDK 回显时替换本地气泡，避免重复
        confirmedLocalIDs.insert(msg.messageID)
        pendingAppearIDs.insert(msg.messageID)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }

    func didTapMoreButton() {
        view.endEditing(true)
    }

    func didStartTyping() {
        // 预留：接入对方「正在输入」事件后再展示
    }

    func didStopTyping() {
        // 预留：接入对方「正在输入」事件后再展示
    }

    func didInsertEmoji(_ emoji: String) {
    }

    func didTapPhotoButton() {
        // PHPicker 系统选择器，无需相册权限弹窗，秒开
        presentPhotoPicker()
    }

    func didTapCameraButton() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            AppUtility.showToast("相机不可用")
            return
        }
        // 与安卓一致：拍照和录像都可选
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "拍摄照片", style: .default) { [weak self] _ in
            self?.requestCameraAccess(mode: .photo)
        })
        alert.addAction(UIAlertAction(title: "录制视频", style: .default) { [weak self] _ in
            self?.requestCameraAccess(mode: .video)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 1, height: 1)
        }
        present(alert, animated: true)
    }

    private func requestCameraAccess(mode: UIImagePickerController.CameraCaptureMode) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            presentCamera(mode: mode)
        } else {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.presentCamera(mode: mode)
                    } else {
                        AppUtility.showToast("请在设置中允许访问相机")
                    }
                }
            }
        }
    }

    func didTapLocationButton() {
        let vc = LocationPickerViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.onLocationSelected = { [weak self] location in
            self?.sendLocationMessage(location)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    func didTapFileButton() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func didTapNoteButton() {
        let noteSelectVC = NoteSelectViewController()
        noteSelectVC.onNoteSelected = { [weak self] note in
            self?.sendNoteMessage(note)
        }
        let nav = UINavigationController(rootViewController: noteSelectVC)
        nav.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        present(nav, animated: true)
    }
    
    func didTapCardButton() {
        let chooseVC = ChooseContactsViewController(maxSelection: 1) { [weak self] selected in
            guard let contact = selected.first else { return }
            self?.sendCardMessage(uid: contact.uid, name: contact.name, avatar: "", vercode: contact.uid)
        }
        navigationController?.pushViewController(chooseVC, animated: true)
    }

    func didTapFavorite() {
        navigationController?.pushViewController(
            FavoriteViewController(channelId: channelId, channelType: channelType),
            animated: true
        )
    }

    func didTapMentionButton() {
        guard channelType == 2 else {
            AppUtility.showToast("仅群聊可@成员")
            return
        }
        inputBar.insertText("@")
    }

    /// 语音消息：本地占位 → 上传 → 发送
    func didSendVoiceMessage(fileURL: URL, duration: TimeInterval) {
        let messageID = UUID().uuidString
        // 占位 content 直接带时长和本地文件路径：气泡秒数/宽度立即正确，上传完成前也能本地播放
        let localPlaceholder = "\(max(1, Int(duration)))|\(fileURL.path)"
        let msg = Message(
            messageID: messageID,
            channelID: channelId,
            channelType: channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: localPlaceholder,
            type: .voice,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: 0
        )
        messages.append(msg)
        pendingAppearIDs.insert(msg.messageID)
        pendingVoiceDurations[messageID] = Int(duration)
        tableView.reloadData()
        scrollToBottom()

        Task {
            do {
                let data = try Data(contentsOf: fileURL)
                let path = try await uploadChatFile(data: data, fileName: "voice_\(messageID).m4a")
                DispatchQueue.main.async {
                    if let index = self.messages.firstIndex(where: { $0.messageID == messageID }) {
                        // 与接收端格式统一为 duration|url，保证气泡宽度/秒数/收藏解析一致
                        self.messages[index].content = "\(max(1, Int(duration)))|\(path)"
                        self.messages[index].status = 1
                        self.confirmedLocalIDs.insert(messageID)
                        self.tableView.reloadData()
                    }
                    let sentWK = IMManager.shared.sendVoiceMessage(
                        channelId: self.channelId,
                        voiceURL: path,
                        duration: max(1, Int(duration)),
                        channelType: self.channelType
                    )
                    if let cmno = sentWK?.clientMsgNo,
                       let idx = self.messages.firstIndex(where: { $0.messageID == messageID }) {
                        self.messages[idx].clientMsgNo = cmno
                    }
                }
            } catch {
                print("语音上传失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    if let index = self.messages.firstIndex(where: { $0.messageID == messageID }) {
                        self.messages[index].status = -1
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                    AppUtility.showToast("语音发送失败")
                }
            }
        }
    }

    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentCamera(mode: UIImagePickerController.CameraCaptureMode) {
        // 录制视频需要麦克风：若音频会话当前处于 .playback（播放语音/提示音后遗留），
        // 相机启动录制会因类别不兼容抛异常导致 App 闪退，先切到可录音类别
        if mode == .video {
            let session = AVAudioSession.sharedInstance()
            _ = try? session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
            _ = try? session.setActive(true)
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = mode
        if mode == .video {
            picker.mediaTypes = [UTType.movie.identifier]
            picker.videoQuality = .typeMedium
            picker.videoMaximumDuration = 60
        } else {
            picker.mediaTypes = [UTType.image.identifier]
        }
        picker.delegate = self
        imagePicker = picker
        // 等 actionSheet 完全消失后再 present，避免 present 冲突
        DispatchQueue.main.async { [weak self] in
            self?.present(picker, animated: true)
        }
    }

    /// 相机页面关闭后恢复音频会话（避免影响后续语音播放）
    private func restoreAudioSessionIfNeeded() {
        _ = try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - 图片发送（压缩 → 本地占位 → 上传 → 发送）
    private func sendImageMessage(data: Data) {
        guard let image = UIImage(data: data) else {
            AppUtility.showToast("图片数据无效")
            return
        }
        let compressed = compressImage(image, maxSide: 1600)
        guard let jpegData = compressed.jpegData(compressionQuality: 0.7) else {
            AppUtility.showToast("图片处理失败")
            return
        }

        let messageID = UUID().uuidString
        let msg = Message(
            messageID: messageID,
            channelID: channelId,
            channelType: channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: "local:\(messageID)",
            type: .image,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: 0 // 发送中
        )
        messages.append(msg)
        pendingAppearIDs.insert(msg.messageID)
        pendingMedia[messageID] = compressed
        pendingUploads[messageID] = PendingUpload(
            type: .image, data: jpegData, sourceURL: nil, fileName: "image.jpg",
            width: compressed.size.width, height: compressed.size.height,
            duration: 0, thumbnail: compressed
        )
        tableView.reloadData()
        scrollToBottom()
        performUpload(messageID: messageID)
    }

    // MARK: - 视频发送（限制体积 → 缩略图占位 → 上传 → 发送）
    private func sendVideoMessage(url: URL) {
        let maxVideoSize: Int64 = 50 * 1024 * 1024
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        guard fileSize == 0 || fileSize <= maxVideoSize else {
            AppUtility.showToast("视频超过 50MB，无法发送")
            return
        }
        // 相册返回的临时文件会被系统清理，先复制到沙盒临时目录再异步上传
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("chat_video_\(UUID().uuidString).mp4")
        let sourceURL: URL
        if (try? FileManager.default.copyItem(at: url, to: tempURL)) != nil {
            sourceURL = tempURL
        } else {
            sourceURL = url
        }

        let asset = AVAsset(url: sourceURL)
        let durationSeconds = Int(CMTimeGetSeconds(asset.duration).rounded())
        var thumbnail: UIImage?
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
            thumbnail = UIImage(cgImage: cgImage)
        }

        let messageID = UUID().uuidString
        let msg = Message(
            messageID: messageID,
            channelID: channelId,
            channelType: channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: "local:\(messageID)",
            type: .video,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: 0 // 发送中
        )
        messages.append(msg)
        pendingAppearIDs.insert(msg.messageID)
        pendingMedia[messageID] = thumbnail ?? UIImage(systemName: "video")
        pendingUploads[messageID] = PendingUpload(
            type: .video, data: nil, sourceURL: sourceURL, fileName: "video.mp4",
            width: thumbnail?.size.width ?? 0, height: thumbnail?.size.height ?? 0,
            duration: durationSeconds, thumbnail: thumbnail
        )
        tableView.reloadData()
        scrollToBottom()
        performUpload(messageID: messageID)
    }

    private func compressImage(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxSide else { return image }
        let ratio = maxSide / longestSide
        let newSize = CGSize(width: floor(image.size.width * ratio), height: floor(image.size.height * ratio))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - 上传执行 / 失败重发
    private func performUpload(messageID: String) {
        guard let upload = pendingUploads[messageID],
              let index = messages.firstIndex(where: { $0.messageID == messageID }) else { return }
        messages[index].status = 0
        tableView.reloadData()

        Task {
            do {
                var path = ""
                var thumbPath = ""
                switch upload.type {
                case .image:
                    guard let data = upload.data else { throw APIError.noData }
                    print("[Chat] 开始上传图片 \(data.count) bytes")
                    path = try await uploadMedia(data: data, fileName: upload.fileName, contentType: "image/jpeg")
                    print("[Chat] 图片上传成功: \(path)")
                case .video:
                    guard let url = upload.sourceURL else { throw APIError.noData }
                    let videoData = try Data(contentsOf: url)
                    print("[Chat] 开始上传视频 \(videoData.count) bytes")
                    path = try await uploadMedia(data: videoData, fileName: upload.fileName, contentType: "video/mp4")
                    print("[Chat] 视频上传成功: \(path)")
                    if let thumbData = upload.thumbnail?.jpegData(compressionQuality: 0.7) {
                        thumbPath = (try? await uploadMedia(data: thumbData, fileName: "thumb.jpg", contentType: "image/jpeg")) ?? ""
                    }
                default:
                    throw APIError.noData
                }
                DispatchQueue.main.async {
                    self.completeUpload(messageID: messageID, path: path, thumbPath: thumbPath, upload: upload)
                }
            } catch {
                print("[Chat] 媒体上传失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    if let index = self.messages.firstIndex(where: { $0.messageID == messageID }) {
                        self.messages[index].status = -1
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                    AppUtility.showToast(upload.type == .video ? "视频上传失败，点击气泡重发" : "图片上传失败，点击气泡重发")
                }
            }
        }
    }

    private func retryUpload(messageID: String) {
        guard let index = messages.firstIndex(where: { $0.messageID == messageID }),
              messages[index].status == -1,
              pendingUploads[messageID] != nil else { return }
        performUpload(messageID: messageID)
    }

    private func completeUpload(messageID: String, path: String, thumbPath: String, upload: PendingUpload) {
        guard let index = messages.firstIndex(where: { $0.messageID == messageID }) else { return }
        var sentWK: WKMessage?
        switch upload.type {
        case .image:
            messages[index].content = path
            sentWK = IMManager.shared.sendImageMessage(
                channelId: channelId, imageURL: path,
                width: upload.width, height: upload.height, channelType: channelType
            )
        case .video:
            let content = "\(thumbPath)|\(path)"
            messages[index].content = content
            sentWK = IMManager.shared.sendVideoMessage(
                channelId: channelId, thumbURL: thumbPath, videoURL: path,
                duration: upload.duration, channelType: channelType
            )
        default:
            return
        }
        messages[index].status = 1
        messages[index].clientMsgNo = sentWK?.clientMsgNo ?? ""
        confirmedLocalIDs.insert(messageID)
        pendingMedia.removeValue(forKey: messageID)
        pendingUploads.removeValue(forKey: messageID)
        tableView.reloadData()
        scrollToBottom()
    }

    /// 专用长超时会话上传聊天文件（对齐后端 /v1/file/upload，返回服务端相对路径）
    private func uploadChatFile(data: Data, fileName: String) async throws -> String {
        let ext = (fileName as NSString).pathExtension
        let suffix = ext.isEmpty ? "bin" : ext
        let rand = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8))
        let millis = Int64(Date().timeIntervalSince1970 * 1000)
        let filePath = "/\(channelType)/\(channelId)/\(millis)_\(rand).\(suffix)"
        let urlString = APIConfig.apiBaseURL + "/v1/file/upload?type=chat&path=" + filePath
        guard let url = URL(string: urlString) else { throw APIError.noData }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let token = UserDefaults.standard.string(forKey: "token") ?? ""
        if !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "token")
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (responseData, response) = try await uploadSession.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: responseData, encoding: .utf8) ?? ""
            print("[Chat] 上传失败 HTTP \(http.statusCode): \(body)")
            throw APIError.serverError(message: "上传失败(\(http.statusCode)) \(body)", code: http.statusCode)
        }
        if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
           let path = json["path"] as? String, !path.isEmpty {
            return path
        }
        throw APIError.noData
    }

    /// 与安卓完全一致：走后端 /v1/file/upload 中转上传，返回相对路径（/channelType/channelId/xxx.ext）
    /// 说明：COS 桶为私有读（匿名访问返回 403），直传得到的公网 URL 双方都无法打开，
    /// 因此聊天图片/视频统一走后端中转，安卓端收到的相对路径也能正常拼接展示。
    private func uploadMedia(data: Data, fileName: String, contentType: String) async throws -> String {
        return try await uploadChatFile(data: data, fileName: fileName)
    }

    private func sendFileMessage(url: URL) {
        let fileName = url.lastPathComponent
        Task {
            do {
                // 读取文件数据与大小
                let accessing = url.startAccessingSecurityScopedResource()
                let fileData = try Data(contentsOf: url)
                if accessing { url.stopAccessingSecurityScopedResource() }
                let fileSize = Int64(fileData.count)
                guard fileSize <= 100 * 1024 * 1024 else {
                    DispatchQueue.main.async { AppUtility.showToast("文件超过 100MB，无法发送") }
                    return
                }

                // 对齐 Android：走服务器中转上传通道（长超时会话）
                let path = try await self.uploadChatFile(data: fileData, fileName: fileName)
                let sentWK = IMManager.shared.sendFileMessage(
                    channelId: self.channelId,
                    fileName: fileName,
                    fileSize: fileSize,
                    fileURL: path,
                    channelType: self.channelType
                )
                let content = "\(fileName)|\(fileSize)|\(path)"
                let msg = Message(
                    messageID: UUID().uuidString,
                    channelID: self.channelId,
                    channelType: self.channelType,
                    fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
                    content: content,
                    type: .file,
                    timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                    status: 0, // 发送中
                    clientMsgNo: sentWK?.clientMsgNo ?? ""
                )
                self.messages.append(msg)
                self.pendingAppearIDs.insert(msg.messageID)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            } catch {
                print("文件上传失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    AppUtility.showToast("文件上传失败")
                }
            }
        }
    }

    /// 防止定位在短时间内被重复触发（导航栏连续点击/页面未及时 pop）导致一次选点发出多条
    private var lastLocationSendTime: TimeInterval = 0
    private var lastLocationSendSignature: String = ""

    private func sendLocationMessage(_ location: PickedLocation) {
        // 同一次选点只允许发送一条：2 秒内相同坐标的重复调用直接忽略
        let signature = "\(location.name)|\(location.address)|\(location.latitude),\(location.longitude)"
        let now = Date().timeIntervalSince1970
        if signature == lastLocationSendSignature, now - lastLocationSendTime < 2 { return }
        lastLocationSendSignature = signature
        lastLocationSendTime = now

        // 通过SDK发送位置消息
        let sentWK = IMManager.shared.sendLocationMessage(
            channelId: channelId,
            name: location.name,
            address: location.address,
            latitude: location.latitude,
            longitude: location.longitude,
            channelType: channelType
        )
        let displayName = location.address.isEmpty ? location.name : "\(location.name)\n\(location.address)"
        let sdkMessageID = sentWK.map { String($0.messageId) } ?? ""
        // 发送结果直接回写状态（对齐其他消息类型），避免占位气泡一直停留在"发送中"
        let msg = Message(
            messageID: sdkMessageID.isEmpty ? UUID().uuidString : sdkMessageID,
            channelID: channelId,
            channelType: self.channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: "[位置] \(displayName)|\(location.latitude),\(location.longitude)",
            type: .location,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: sentWK == nil ? -1 : 1,
            clientMsgNo: sentWK?.clientMsgNo ?? ""
        )
        if sentWK == nil {
            AppUtility.showToast("位置发送失败")
        }
        if let idx = messages.lastIndex(where: { isSameMessage($0, msg) }) {
            messages[idx] = mergedMessage(messages[idx], msg)
        } else {
            messages.append(msg)
        }
        IMManager.shared.recordLastPreview(msg)
        pendingAppearIDs.insert(msg.messageID)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    // MARK: - 发送名片消息
    private func sendCardMessage(uid: String, name: String, avatar: String, vercode: String) {
        // 通过SDK发送名片消息
        let sentWK = IMManager.shared.sendCardMessage(
            channelId: channelId,
            uid: uid,
            name: name,
            avatar: avatar,
            vercode: vercode,
            channelType: channelType
        )
        let cardInfo = CardMessageInfo(uid: uid, name: name, avatar: avatar, vercode: vercode)
        let content = cardInfo.toString()
        let msg = Message(
            messageID: UUID().uuidString,
            channelID: channelId,
            channelType: self.channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: content,
            type: .card,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: sentWK == nil ? -1 : 1,
            clientMsgNo: sentWK?.clientMsgNo ?? ""
        )
        messages.append(msg)
        IMManager.shared.recordLastPreview(msg)
        pendingAppearIDs.insert(msg.messageID)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    // MARK: - 发送笔记消息
    private func sendNoteMessage(_ note: NoteEntity) {
        // 将笔记内容序列化为JSON字符串
        guard let noteData = try? JSONEncoder().encode(note),
              let noteString = String(data: noteData, encoding: .utf8) else {
            AppUtility.showToast("笔记格式错误")
            return
        }
        // 通过SDK发送笔记消息
        let sentWK = IMManager.shared.sendNoteMessage(
            channelId: channelId,
            noteJSON: noteString,
            channelType: channelType
        )
        // 发送结果立即回写状态：之前固定为"发送中"(0)，SDK 回执又无法按 UUID 匹配，
        // 导致笔记气泡一直转圈、看起来"发不出去"
        let sdkMessageID = sentWK.map { String($0.messageId) } ?? ""
        let msg = Message(
            messageID: sdkMessageID.isEmpty ? UUID().uuidString : sdkMessageID,
            channelID: channelId,
            channelType: self.channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: noteString,
            type: .note,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: sentWK == nil ? -1 : 1,
            clientMsgNo: sentWK?.clientMsgNo ?? ""
        )
        if sentWK == nil {
            AppUtility.showToast("笔记发送失败")
        }
        messages.append(msg)
        IMManager.shared.recordLastPreview(msg)
        pendingAppearIDs.insert(msg.messageID)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    // MARK: - 解析笔记消息
    private func parseNoteMessage(_ content: String) -> NoteEntity? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let data = trimmed.data(using: .utf8) else { return nil }
        let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        // 1. 安卓 WKNoteContent 原生线缆格式：noteId/noteTitle/noteContent/blockListJson(字符串)
        //    必须最先判断——NoteEntity 容错解码永不失败，先 decode 会把安卓格式误判成空笔记
        if let dict = dict, dict["noteTitle"] != nil || dict["blockListJson"] != nil || dict["noteId"] != nil {
            var note = NoteEntity()
            if let nid = dict["noteId"] as? String, !nid.isEmpty { note.id = nid }
            note.title = dict["noteTitle"] as? String ?? ""
            note.group = dict["noteGroup"] as? String ?? "普通笔记"
            var blocks: [NoteBlock] = []
            if let blJson = dict["blockListJson"] as? String, !blJson.isEmpty,
               let bd = blJson.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: bd) as? [[String: Any]] {
                for item in arr {
                    let t = (item["type"] as? NSNumber)?.intValue ?? 2
                    let content = item["content"] as? String ?? ""
                    switch t {
                    case 1:
                        blocks.append(NoteBlock(type: .title, content: content))
                    case 3:
                        let img = item["imagePath"] as? String ?? ""
                        blocks.append(NoteBlock(type: .image, imageURL: img.isEmpty ? nil : img))
                    case 4:
                        let video = item["videoPath"] as? String ?? ""
                        blocks.append(NoteBlock(type: .video, videoURL: video.isEmpty ? nil : video))
                    case 5:
                        let lat = (item["latitude"] as? NSNumber)?.doubleValue ?? 0
                        let lng = (item["longitude"] as? NSNumber)?.doubleValue ?? 0
                        let locName = item["locationName"] as? String ?? ""
                        let locAddr = item["locationAddress"] as? String ?? ""
                        let addr = locAddr.isEmpty ? locName : "\(locName) \(locAddr)"
                        blocks.append(NoteBlock(type: .location, content: locName,
                                                location: NoteLocation(latitude: lat, longitude: lng, address: addr)))
                    default:
                        blocks.append(NoteBlock(type: .text, content: content))
                    }
                }
            }
            if blocks.isEmpty, let nc = dict["noteContent"] as? String, !nc.isEmpty {
                blocks = [NoteBlock(type: .text, content: nc)]
            }
            note.blocks = blocks
            return note
        }
        // 2. iOS NoteEntity 整体 JSON
        if let note = try? JSONDecoder().decode(NoteEntity.self, from: data),
           !note.title.isEmpty || !note.blocks.isEmpty {
            return note
        }
        // 3. 安卓可能把笔记包在 {"note_json": "..."} 或 {"note": {...}} 里
        if let dict = dict {
            if let nested = dict["note_json"] as? String, !nested.isEmpty {
                return parseNoteMessage(nested)
            }
            if let nestedDict = dict["note"] as? [String: Any],
               let nd = try? JSONSerialization.data(withJSONObject: nestedDict),
               let ns = String(data: nd, encoding: .utf8) {
                return parseNoteMessage(ns)
            }
        }
        return nil
    }
}

// MARK: - PHPickerViewControllerDelegate（相册秒选）
extension ChatViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let self = self, let image = object as? UIImage else { return }
                guard let data = image.jpegData(compressionQuality: 0.6) else { return }
                Task { @MainActor in self.sendImageMessage(data: data) }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                guard let self = self, let url = url else { return }
                let tmpURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("chat_video_\(UUID().uuidString).mp4")
                try? FileManager.default.removeItem(at: tmpURL)
                try? FileManager.default.copyItem(at: url, to: tmpURL)
                Task { @MainActor in self.sendVideoMessage(url: tmpURL) }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate（仅相机）
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let mediaType = info[.mediaType] as? String {
            if mediaType == UTType.image.identifier {
                if let image = info[.originalImage] as? UIImage,
                   let data = image.jpegData(compressionQuality: 0.6) {
                    sendImageMessage(data: data)
                }
            } else if mediaType == UTType.movie.identifier {
                if let videoURL = info[.mediaURL] as? URL {
                    sendVideoMessage(url: videoURL)
                }
            }
        }
        let wasVideo = imagePicker?.cameraCaptureMode == .video
        imagePicker = nil
        if wasVideo { restoreAudioSessionIfNeeded() }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        let wasVideo = imagePicker?.cameraCaptureMode == .video
        imagePicker = nil
        if wasVideo { restoreAudioSessionIfNeeded() }
    }
}

// MARK: - UIDocumentPickerDelegate
extension ChatViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        sendFileMessage(url: url)
    }
}

// MARK: - 消息Cell
class TextMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let tailView = ChatBubbleTailView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        messageLabel.font = ScreenAdapter.font(16)
        messageLabel.numberOfLines = 0

        bubbleView.layer.cornerRadius = ThemeDimension.bubbleCornerRadius
        bubbleView.translatesAutoresizingMaskIntoConstraints = false

        // 气泡尾巴：默认隐藏，仅在连续同方向消息的末条显示
        tailView.isHidden = true
        tailView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubviews(tailView, bubbleView)
        bubbleView.addSubview(messageLabel)

        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ChatBubbleLayout.textPadTB)
            make.bottom.equalToSuperview().offset(-ChatBubbleLayout.textPadTB)
            make.leading.equalToSuperview().offset(ChatBubbleLayout.textPadLR)
            make.trailing.equalToSuperview().offset(-ChatBubbleLayout.textPadLR)
        }
    }

    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
        messageLabel.text = message.content

        let isFromMe = message.isFromMe
        let font = ScreenAdapter.font(16)
        let innerPad = ChatBubbleLayout.textPadLR * 2
        // 多行测量：按最大文本宽度换行计算实际所需宽度，避免单行测量导致气泡过宽或过窄
        let maxTextWidth = ChatBubbleLayout.maxWidth - innerPad
        let content = message.content.isEmpty ? " " : message.content
        let textRect = (content as NSString).boundingRect(
            with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let bubbleWidth = max(ceil(textRect.width) + innerPad, ScreenAdapter.scaleW(40))

        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        messageLabel.textColor = isFromMe ? .themeBubbleSendText : .themeBubbleReceiveText

        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: bubbleWidth,
            minHeight: ScreenAdapter.scaleH(38),
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar,
            status: message.isFromMe ? message.status : nil
        )
    }
}

// MARK: - 上传中占位气泡（本地缩略图 + 发送中/失败重发）
final class PendingMediaMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let thumbnailView = UIImageView()
    private let dimOverlay = UIView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let playIcon = UIImageView()
    private let tailView = ChatBubbleTailView()
    private var onRetry: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = ThemeDimension.bubbleCornerRadius
        bubbleView.clipsToBounds = true
        bubbleView.backgroundColor = .systemGray6

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.isUserInteractionEnabled = false

        dimOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimOverlay.isHidden = true

        spinner.color = .white
        spinner.hidesWhenStopped = true

        statusLabel.text = "发送失败\n点击重发"
        statusLabel.textColor = .white
        statusLabel.font = ScreenAdapter.font(11)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.isHidden = true

        playIcon.image = UIImage(systemName: "play.circle.fill")
        playIcon.tintColor = .white.withAlphaComponent(0.9)
        playIcon.contentMode = .center
        playIcon.isHidden = true

        bubbleView.addSubviews(thumbnailView, dimOverlay, playIcon, spinner, statusLabel)
        contentView.addSubviews(tailView, bubbleView)

        thumbnailView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        dimOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        playIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        statusLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(ScreenAdapter.scaleW(8))
        }

        // 失败时点击气泡重试
        bubbleView.isUserInteractionEnabled = true
        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bubbleTapped)))
    }

    @objc private func bubbleTapped() {
        onRetry?()
    }

    func configure(with message: Message, thumbnail: UIImage?, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false, onRetry: (() -> Void)?) {
        let isFromMe = message.isFromMe
        self.onRetry = onRetry
        thumbnailView.image = thumbnail ?? UIImage(systemName: message.type == .video ? "video" : "photo")

        let failed = message.status == -1
        dimOverlay.isHidden = !failed
        statusLabel.isHidden = !failed
        playIcon.isHidden = failed || message.type != .video
        if failed {
            spinner.stopAnimating()
        } else {
            spinner.startAnimating()
        }

        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: ScreenAdapter.scaleW(180),
            height: ScreenAdapter.scaleW(180),
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar,
            status: message.isFromMe ? message.status : nil
        )
    }
}
