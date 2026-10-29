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
import WuKongIMSDK

// MARK: - 聊天页
class ChatViewController: UIViewController {

    let channelId: String
    private let titleText: String
    private let channelType: Int // 1: 单聊, 2: 群聊

    private let tableView = UITableView()
    private let inputBar = ChatInputBar()
    private var messages: [Message] = []
    private var imagePicker: UIImagePickerController?

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
    /// 最近一次在线状态文案，供「正在输入」切换后还原
    private var lastOnlineStatusText: String?

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
        // 更新消息状态（SDK返回的消息有正确的messageID，通过匹配来更新）
        if let index = messages.firstIndex(where: { $0.messageID == msg.messageID }) {
            messages[index].status = msg.status
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private func handleIncomingMessage(_ msg: Message) {
        guard msg.channelID == channelId else { return }
        if messages.contains(where: { $0.messageID == msg.messageID }) { return }
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
        tableView.register(PendingMediaMessageCell.self, forCellReuseIdentifier: "PendingMediaMessageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        // 自适应行高：气泡高度随内容撑开
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = ScreenAdapter.scaleH(64)

        // 长按菜单使用 iOS 原生 ContextMenu（气泡弹出 + 菜单），见 UITableViewDelegate 扩展

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
        // 从聊天背景设置页返回时刷新背景
        applyChatBackground()
        refreshCachedOnlineStatus()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 离开聊天页时恢复导航栏默认外观，避免影响其它页面
        restoreNavBarAppearance()
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
        titleView.addSubview(onlineStatusLabel)

        let hasStatus = channelType == 1
        if hasStatus {
            // 单聊：昵称+在线状态两行整体与头像垂直居中（总高约 34pt）
            navTitleLabel.snp.makeConstraints { make in
                make.leading.equalTo(navAvatar.snp.trailing).offset(ScreenAdapter.scaleW(8))
                make.trailing.lessThanOrEqualToSuperview()
                make.top.equalTo(navAvatar.snp.top).offset(-ScreenAdapter.scaleH(2))
            }
            onlineStatusLabel.snp.makeConstraints { make in
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
                    // 用真实昵称刷新标题头像占位图
                    AppUtility.loadChannelAvatar(channelId: self.channelId, channelType: self.channelType, name: channelInfo.displayName, into: navAvatar)
                    self.updateOnlineStatus(
                        online: (channelInfo.online ?? 0) == 1,
                        lastOffline: channelInfo.last_offline
                    )
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshCachedOnlineStatus()
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
            navigationItem.rightBarButtonItems = [moreBtn, callBtn]
        } else {
            navigationItem.rightBarButtonItem = moreBtn
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

    /// 右上角"三个横杠"：单聊进入聊天信息页，群聊进入群设置页
    @objc private func showMoreOptions() {
        if channelType == 2 {
            openGroupDetail()
        } else {
            openChatPersonal()
        }
    }

    // MARK: - 点击气泡头像
    @objc private func handleAvatarTapped(_ note: Notification) {
        guard let info = note.userInfo,
              let tappedId = info["channelId"] as? String else { return }
        let tappedType = (info["channelType"] as? Int) ?? 1
        let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""

        if tappedType == 2 {
            // 群头像 → 群资料页
            openGroupDetail()
            return
        }
        // 自己的头像 → 我的主页
        if tappedId == myUid {
            openChatPersonal()
            return
        }
        // 他人头像 → 个人主页（统一走联系人详情页）
        let vc = ContactDetailViewController(uid: tappedId, source: channelType == 2 ? "来自群聊" : "来自聊天")
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 单聊语音通话
    @objc private func startVoiceCall() {
        guard channelType == 1 else { return }
        // 与安卓一致：本地生成 UserSig，不依赖后端接口
        guard TRTCConfig.sdkAppID > 0, !TRTCConfig.userSig.isEmpty else {
            AppUtility.showToast("TRTC未配置，请联系管理员")
            return
        }
        let callVC = TRTCCallViewController(channelId: channelId)
        callVC.modalPresentationStyle = .fullScreen
        present(callVC, animated: true)
    }

    // MARK: - 单聊在线状态（数据缺失时不显示，不伪造）
    private func updateOnlineStatus(online: Bool, lastOffline: Int?) {
        guard channelType == 1 else {
            onlineStatusLabel.isHidden = true
            lastOnlineStatusText = nil
            return
        }
        if online {
            lastOnlineStatusText = "在线"
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

    /// 合并服务端消息与本地消息（保留发送中/失败占位），按 seq + 时间排序
    /// - Parameter merge: 为 true 时保留已有本地消息（服务端只返回部分消息也不丢内容）
    private func applyLoadedMessages(_ loaded: [Message], scroll: Bool, finish: Bool, merge: Bool = false) {
        var result = loaded.filter { !($0.type == .text && $0.content.isEmpty) }
        let base = merge ? messages : []
        for local in base {
            // 同方向同类型同内容 60 秒内视为同一条（本地 ID 与服务端 ID 不同）
            let duplicated = result.contains { r in
                r.messageID == local.messageID ||
                (r.isFromMe == local.isFromMe && r.type == local.type &&
                 r.content == local.content && abs(r.timestamp - local.timestamp) < 60_000)
            }
            if !duplicated { result.append(local) }
        }
        for local in messages where (local.status == 0 || local.status == -1) {
            if !result.contains(where: { $0.messageID == local.messageID }) {
                result.append(local)
            }
        }
        result.sort { lhs, rhs in
            let lSeq = lhs.messageSeq == 0 ? Int.max : lhs.messageSeq
            let rSeq = rhs.messageSeq == 0 ? Int.max : rhs.messageSeq
            if lSeq != rSeq { return lSeq < rSeq }
            return lhs.timestamp < rhs.timestamp
        }
        messages = result
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
                    .syncChannelMessages(channelId: channelId, channelType: self.channelType, startMessageSeq: 0, limit: 50)
                )
                DispatchQueue.main.async {
                    if let msgs = response.messages {
                        print("[Chat] 加载到 \(msgs.count) 条服务端消息")
                        // merge: 服务端只返回部分消息时保留本地已有内容，避免"加载不完整"
                        self.applyLoadedMessages(msgs.map { Message(from: $0) }, scroll: self.messages.isEmpty, finish: true, merge: true)
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
        case .system:
            // 系统/群事件消息：居中灰色圆角条，无头像，{0}/{1} 占位符在解析时替换为昵称
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
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
            // 解析笔记消息内容并展示详情
            if let note = parseNoteMessage(message.content) {
                let detailVC = NoteDetailViewController(note: note)
                navigationController?.pushViewController(detailVC, animated: true)
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
    private func markMessagesAsRead() {
        Task {
            for message in messages where !message.isFromMe && message.status == 0 {
                do {
                    _ = try await APIClient.shared.requestRaw(.deleteMessage(messageId: message.messageID))
                } catch { }
            }
        }
    }

    private func recallMessage(_ message: Message) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.deleteMessage(messageId: message.messageID))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        if let idx = self.messages.firstIndex(where: { $0.messageID == message.messageID }) {
                            self.messages[idx].content = "此消息已撤回"
                            self.tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
                        }
                        AppUtility.showToast("已撤回")
                    }
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
        let sentOK = IMManager.shared.sendTextMessage(channelId: channelId, content: text, channelType: channelType)
        let msg = Message(
            messageID: UUID().uuidString,
            channelID: channelId,
            channelType: self.channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: text,
            type: .text,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: sentOK ? 1 : -1
        )
        messages.append(msg)
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
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            presentCamera()
        } else {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.presentCamera()
                    } else {
                        AppUtility.showToast("请在设置中允许访问相机")
                    }
                }
            }
        }
    }

    func didTapLocationButton() {
        let vc = LocationPickerViewController()
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
        navigationController?.pushViewController(FavoriteViewController(), animated: true)
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
        let msg = Message(
            messageID: messageID,
            channelID: channelId,
            channelType: channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: "local:\(messageID)",
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
                        self.messages[index].content = path
                        self.messages[index].status = 1
                        self.confirmedLocalIDs.insert(messageID)
                        self.tableView.reloadData()
                    }
                    IMManager.shared.sendVoiceMessage(
                        channelId: self.channelId,
                        voiceURL: path,
                        duration: max(1, Int(duration)),
                        channelType: self.channelType
                    )
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

    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        picker.videoMaximumDuration = 60
        picker.delegate = self
        imagePicker = picker
        present(picker, animated: true)
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
        switch upload.type {
        case .image:
            messages[index].content = path
            IMManager.shared.sendImageMessage(
                channelId: channelId, imageURL: path,
                width: upload.width, height: upload.height, channelType: channelType
            )
        case .video:
            let content = "\(thumbPath)|\(path)"
            messages[index].content = content
            IMManager.shared.sendVideoMessage(
                channelId: channelId, thumbURL: thumbPath, videoURL: path,
                duration: upload.duration, channelType: channelType
            )
        default:
            return
        }
        messages[index].status = 1
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
                IMManager.shared.sendFileMessage(
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
                    status: 0 // 发送中
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

    private func sendLocationMessage(_ location: PickedLocation) {
        // 通过SDK发送位置消息
        IMManager.shared.sendLocationMessage(
            channelId: channelId,
            name: location.name,
            latitude: location.latitude,
            longitude: location.longitude,
            channelType: channelType
        )
        let content = "\(location.name)|\(location.latitude),\(location.longitude)"
        let msg = Message(
            messageID: UUID().uuidString,
            channelID: channelId,
            channelType: self.channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: "[位置] \(location.name)",
            type: .location,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: 0 // 发送中
        )
        messages.append(msg)
        pendingAppearIDs.insert(msg.messageID)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    // MARK: - 发送名片消息
    private func sendCardMessage(uid: String, name: String, avatar: String, vercode: String) {
        // 通过SDK发送名片消息
        IMManager.shared.sendCardMessage(
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
            status: 0 // 发送中
        )
        messages.append(msg)
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
        IMManager.shared.sendNoteMessage(
            channelId: channelId,
            noteJSON: noteString,
            channelType: channelType
        )
        let msg = Message(
            messageID: UUID().uuidString,
            channelID: channelId,
            channelType: self.channelType,
            fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
            content: noteString,
            type: .note,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: 0 // 发送中
        )
        messages.append(msg)
        pendingAppearIDs.insert(msg.messageID)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    // MARK: - 解析笔记消息
    private func parseNoteMessage(_ content: String) -> NoteEntity? {
        guard let data = content.data(using: .utf8),
              let note = try? JSONDecoder().decode(NoteEntity.self, from: data) else {
            return nil
        }
        return note
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
        imagePicker = nil
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        imagePicker = nil
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
