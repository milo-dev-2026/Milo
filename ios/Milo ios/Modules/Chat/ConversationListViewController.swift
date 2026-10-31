import UIKit
import SnapKit
import Kingfisher

// MARK: - 会话列表
class ConversationListViewController: UIViewController {

    private let tableView = UITableView()
    private var conversations: [Conversation] = []
    /// 本地库读取中（防重入）
    private var isLoadingLocal = false
    /// 服务端列表请求中（防重复请求）
    private var isFetchingServer = false
    /// 服务端会话列表是否已成功展示过
    private var serverLoaded = false
    /// 防抖保存缓存（避免频道信息批量回填时频繁写盘）
    private var saveCacheWorkItem: DispatchWorkItem?

    // MARK: - 顶部标题栏
    private let titleBarView = UIView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .custom)

    // MARK: - 搜索栏
    private let searchBarContainer = UIView()
    private let searchIconView = UIImageView()
    private let searchTextField = UITextField()

    // MARK: - 弹窗菜单
    private var popupMenuView: PopupMenuView?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadNameCache()
        setupUI()
        loadData()
        setupIMObserver()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleSyncCompleted(_:)),
            name: NSNotification.Name("ConversationsSynced"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleConnectionStatusChanged(_:)),
            name: IMManager.connectionStatusChangedNotification, object: nil
        )
    }

    @objc private func handleSyncCompleted(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // 从聊天页/详情页返回时刷新一次，保证最后消息预览/时间与聊天内容一致
        refreshFromLocal()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // 离开时落盘一次（含刚回填的名称/头像），下次冷启动可直接秒显
        saveCache(conversations)
    }

    private func setupUI() {
        view.backgroundColor = .themeBg

        // MARK: - 顶部标题栏（小字体，inline 风格，位于安全区内不受灵动岛遮挡）
        titleBarView.backgroundColor = .themeBg
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        // 中间标题 "Milo"（含连接状态）
        titleLabel.font = ScreenAdapter.boldFont(17)
        titleLabel.textColor = .label
        titleBarView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        updateTitleStatus()

        // 右侧加号按钮
        let addConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: addConfig), for: .normal)
        addButton.tintColor = .label
        addButton.addTarget(self, action: #selector(showAddMenu), for: .touchUpInside)
        titleBarView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        // 右侧搜索按钮已移除（下方搜索栏已覆盖入口）

        // MARK: - 搜索栏（胶囊，系统填充色，现代 iOS 观感）
        searchBarContainer.backgroundColor = .secondarySystemFill
        searchBarContainer.layer.cornerRadius = 19
        searchBarContainer.clipsToBounds = true
        view.addSubview(searchBarContainer)
        searchBarContainer.snp.makeConstraints { make in
            make.top.equalTo(titleBarView.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(38)
        }

        // 搜索图标
        searchIconView.image = UIImage(systemName: "magnifyingglass",
                                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))
        searchIconView.tintColor = .secondaryLabel
        searchIconView.contentMode = .scaleAspectFit
        searchBarContainer.addSubview(searchIconView)
        searchIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // 搜索输入框（只读，点击跳转全局搜索页）
        searchTextField.placeholder = "搜索"
        searchTextField.font = ScreenAdapter.font(15)
        searchTextField.textColor = .label
        searchTextField.tintColor = .themePrimary
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchBarContainer.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.leading.equalTo(searchIconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }

        // MARK: - 列表区域
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: "ConversationCell")
        tableView.rowHeight = 74
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
        tableView.separatorColor = UIColor(white: 0, alpha: 0.06)
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .themeBg
        tableView.keyboardDismissMode = .interactive

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBarContainer.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - 按钮点击
    // 顶部右侧放大镜已移除；全局搜索入口保留下方搜索栏

    // MARK: - 连接状态标题
    @objc private func handleConnectionStatusChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateTitleStatus()
        }
    }

    private func updateTitleStatus() {
        let statusText = IMManager.shared.connectStatusText
        titleLabel.text = statusText.isEmpty ? "Milo" : "Milo(\(statusText))"
    }

    // MARK: - 加号弹窗菜单
    @objc private func showAddMenu() {
        if popupMenuView != nil {
            closePopupMenu()
            return
        }

        let menu = PopupMenuView(items: [
            ("person.2.fill", "发起群聊"),
            ("qrcode.viewfinder", "扫一扫"),
            ("person.badge.plus", "添加好友")
        ])
        menu.onSelect = { [weak self] index in
            self?.closePopupMenu()
            switch index {
            case 0: self?.startGroupChat()
            case 1: self?.startScan()
            case 2: self?.showAddFriend()
            default: break
            }
        }
        menu.onDismiss = { [weak self] in
            // 点击菜单外区域：动画关闭并移除，避免卡在上面
            self?.closePopupMenu()
        }

        view.addSubview(menu)
        let buttonFrame = addButton.convert(addButton.bounds, to: view)
        menu.snp.makeConstraints { make in
            make.top.equalTo(buttonFrame.maxY + 6)
            make.trailing.equalToSuperview().offset(-12)
            make.width.equalTo(160)
        }
        menu.alpha = 0
        UIView.animate(withDuration: 0.2) {
            menu.alpha = 1
        }
        popupMenuView = menu
    }

    private func closePopupMenu() {
        guard let menu = popupMenuView else { return }
        UIView.animate(withDuration: 0.2, animations: {
            menu.alpha = 0
        }) { _ in
            menu.removeFromSuperview()
            self.popupMenuView = nil
        }
    }

    private func startGroupChat() {
        let chooseVC = ChooseContactsViewController(maxSelection: 99)
        chooseVC.title = "选择联系人"
        chooseVC.onSelected = { [weak self] selected in
            self?.createGroup(selected: selected)
        }
        navigationController?.pushViewController(chooseVC, animated: true)
    }

    /// 创建群聊（对齐安卓：群名取前三位成员，成功后直接进入群聊）
    private func createGroup(selected: [(uid: String, name: String)]) {
        guard !selected.isEmpty else { return }
        let uids = selected.map { $0.uid }
        let names = selected.map { $0.name }
        let groupName = names.prefix(3).joined(separator: "、")
        AppUtility.showToast("正在创建群聊...")
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(
                    .createGroup(name: groupName, members: uids, memberNames: names)
                )
                // 兼容 {"group_no": "..."} 与 {"data": {"group_no": "..."}} 两种返回结构
                let payload = (response["data"] as? [String: Any]) ?? response
                var groupNo: String?
                if let s = payload["group_no"] as? String { groupNo = s }
                else if let i = payload["group_no"] as? Int { groupNo = String(i) }
                else if let s = payload["group_id"] as? String { groupNo = s }

                guard let gid = groupNo, !gid.isEmpty else {
                    DispatchQueue.main.async { AppUtility.showToast("创建群聊失败") }
                    return
                }
                DispatchQueue.main.async {
                    AppUtility.showToast("群聊创建成功")
                    // 通知会话列表刷新，新群立即出现在聊天页
                    NotificationCenter.default.post(name: NSNotification.Name("ConversationsSynced"), object: nil)
                    let chatVC = ChatViewController(channelId: gid, title: groupName, channelType: 2)
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("创建群聊失败")
                }
            }
        }
    }

    private func startScan() {
        let scanVC = ScanViewController()
        // 扫码页全屏：隐藏底部 TabBar（对齐安卓）
        scanVC.hidesBottomBarWhenPushed = true
        scanVC.onScanResult = { [weak self] result in
            self?.handleScanResult(result)
        }
        navigationController?.pushViewController(scanVC, animated: true)
    }

    private func handleScanResult(_ result: String) {
        let uid: String
        if result.hasPrefix("uid:") {
            uid = String(result.dropFirst(4))
        } else {
            uid = result
        }
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.applyFriend(uid: uid, remark: "", vercode: ""))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        AppUtility.showToast("好友申请已发送")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("发送申请失败")
                }
            }
        }
    }

    private func showAddFriend() {
        navigationController?.pushViewController(AddFriendViewController(), animated: true)
    }

    // MARK: - 会话置顶（本地持久化，对齐安卓右滑置顶）
    /// 按账号隔离的置顶存储键，重新登录后仍是同一 uid，可继续保留置顶
    private static func pinnedKey(for uid: String) -> String {
        return "pinned_channels_v2_\(uid)"
    }

    private var pinnedStorageKey: String {
        let uid = UserDefaults.standard.string(forKey: "uid") ?? "default"
        return ConversationListViewController.pinnedKey(for: uid)
    }

    /// 已删除会话（按账号隔离）：删除后本地库/服务端刷新都不再显示该会话
    private var deletedStorageKey: String {
        let uid = UserDefaults.standard.string(forKey: "uid") ?? "default"
        return "deleted_channels_v1_\(uid)"
    }

    private var deletedIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: deletedStorageKey) ?? [])
    }

    private func markDeleted(_ conversation: Conversation) {
        var ids = UserDefaults.standard.stringArray(forKey: deletedStorageKey) ?? []
        if !ids.contains(conversation.channelID) { ids.append(conversation.channelID) }
        UserDefaults.standard.set(ids, forKey: deletedStorageKey)
        UserDefaults.standard.synchronize()
    }

    /// 收到该会话新消息时自动移出删除名单（对齐微信行为：有新消息会话重新出现）
    private func unmarkDeleted(channelId: String) {
        var ids = UserDefaults.standard.stringArray(forKey: deletedStorageKey) ?? []
        if let idx = ids.firstIndex(of: channelId) {
            ids.remove(at: idx)
            UserDefaults.standard.set(ids, forKey: deletedStorageKey)
            UserDefaults.standard.synchronize()
        }
    }

    private func filterDeleted(_ list: [Conversation]) -> [Conversation] {
        let deleted = deletedIDs
        guard !deleted.isEmpty else { return list }
        return list.filter { !deleted.contains($0.channelID) }
    }

    private var pinnedIDs: Set<String> {
        migrateLegacyPinsIfNeeded()
        return Set(UserDefaults.standard.stringArray(forKey: pinnedStorageKey) ?? [])
    }

    /// 兼容旧版本的全局置顶键，首次升级时迁移到按账号键
    private func migrateLegacyPinsIfNeeded() {
        let legacyKey = "pinned_channels"
        guard UserDefaults.standard.stringArray(forKey: pinnedStorageKey) == nil,
              let legacy = UserDefaults.standard.stringArray(forKey: legacyKey), !legacy.isEmpty else { return }
        UserDefaults.standard.set(legacy, forKey: pinnedStorageKey)
    }

    private func isPinned(_ conversation: Conversation) -> Bool {
        pinnedIDs.contains(conversation.channelID)
    }

    private func togglePin(_ conversation: Conversation) {
        var ids = UserDefaults.standard.stringArray(forKey: pinnedStorageKey) ?? []
        if let idx = ids.firstIndex(of: conversation.channelID) {
            ids.remove(at: idx)
        } else {
            ids.append(conversation.channelID)
        }
        UserDefaults.standard.set(ids, forKey: pinnedStorageKey)
        UserDefaults.standard.synchronize()
    }

    /// 置顶会话排最前，其余按消息时间倒序（最新消息在最上面），与安卓一致
    private func sortedConversations(_ list: [Conversation]) -> [Conversation] {
        let pins = pinnedIDs
        return list.sorted { a, b in
            let ap = pins.contains(a.channelID)
            let bp = pins.contains(b.channelID)
            if ap != bp { return ap }
            // 优先按消息时间戳，新消息在最上面
            let at = a.lastMessageTimestamp ?? 0
            let bt = b.lastMessageTimestamp ?? 0
            if at != bt { return at > bt }
            return a.lastMsgSeq > b.lastMsgSeq
        }
    }

    private var cacheKey: String {
        let uid = UserDefaults.standard.string(forKey: "uid") ?? "default"
        return "conversations_cache_v1_\(uid)"
    }

    /// 频道名称/头像持久缓存：冷启动时先用它填名字，避免昵称显示成 uid 或群号（约30s后才恢复）
    private var channelNameCache: [String: [String: String]] = [:]

    private var nameCacheFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uid = UserDefaults.standard.string(forKey: "uid") ?? "default"
        return docs.appendingPathComponent("channel_names_\(uid).json")
    }

    private func loadNameCache() {
        guard let data = try? Data(contentsOf: nameCacheFileURL),
              let dict = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return }
        channelNameCache = dict
    }

    private func persistNameCache() {
        guard let data = try? JSONEncoder().encode(channelNameCache) else { return }
        try? data.write(to: nameCacheFileURL, options: .atomic)
    }

    /// 用持久缓存补齐缺失名称（key = "type_channelID"）
    private func applyNameCache(to list: [Conversation]) -> [Conversation] {
        guard !channelNameCache.isEmpty else { return list }
        return list.map { conv in
            guard conv.name.isEmpty || conv.name == conv.channelID else { return conv }
            let key = "\(conv.channelType)_\(conv.channelID)"
            guard let cached = channelNameCache[key], let n = cached["name"], !n.isEmpty else { return conv }
            var updated = conv
            updated.name = n
            if updated.avatar == nil, let a = cached["avatar"], !a.isEmpty {
                updated.avatar = a
            }
            return updated
        }
    }

    /// 会话列表落盘缓存文件路径（Documents 目录，比 UserDefaults 更可靠、可排查）
    private var cacheFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uid = UserDefaults.standard.string(forKey: "uid") ?? "default"
        return docs.appendingPathComponent("conv_cache_\(uid).json")
    }

    /// 会话列表落盘缓存：冷启动时先秒显，避免等 IM 连接/网络
    private func saveCache(_ list: [Conversation]) {
        guard !list.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(list)
            try data.write(to: cacheFileURL, options: .atomic)
            // 同时写一份到 UserDefaults 作为备份
            UserDefaults.standard.set(data, forKey: cacheKey)
            CrashLogger.shared.log("[ConvCache] saved \(list.count) conversations -> \(cacheFileURL.lastPathComponent)")
        } catch {
            CrashLogger.shared.log("[ConvCache] save failed: \(error)")
        }
    }

    /// 防抖保存（1 秒内多次调用只保存最后一次，用于频道信息批量回填场景）
    private func saveCacheDebounced() {
        saveCacheWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.saveCache(self.conversations)
        }
        saveCacheWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }

    private func loadCachedConversations() -> [Conversation] {
        // 优先读文件
        do {
            let data = try Data(contentsOf: cacheFileURL)
            if let list = try? JSONDecoder().decode([Conversation].self, from: data) {
                CrashLogger.shared.log("[ConvCache] loaded \(list.count) from file \(cacheFileURL.lastPathComponent)")
                return applyNameCache(to: list)
            }
            CrashLogger.shared.log("[ConvCache] file decode failed (data \(data.count) bytes)")
        } catch {
            CrashLogger.shared.log("[ConvCache] file read failed: \(error)")
        }
        // 降级读 UserDefaults
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let list = try? JSONDecoder().decode([Conversation].self, from: data) {
            CrashLogger.shared.log("[ConvCache] loaded \(list.count) from UserDefaults")
            return applyNameCache(to: list)
        }
        CrashLogger.shared.log("[ConvCache] no cache available")
        return []
    }

    private func loadData() {
        CrashLogger.shared.log("[ConvList] loadData start, conversations.count=\(conversations.count)")
        // 1. 立即渲染磁盘缓存（同步、纯内存，冷启动第一帧就能看到会话，不等连接）
        if conversations.isEmpty {
            let cached = loadCachedConversations()
            if !cached.isEmpty {
                conversations = sortedConversations(cached)
                tableView.reloadData()
            }
        }

        // 2. 后台读 IM SDK 本地数据库（SQLite 查询不放主线程，避免白屏）
        refreshFromLocal()

        // 3. 最后异步拉取服务端会话列表补齐/刷新（不阻塞界面）
        fetchFromServer()
    }

    /// 后台读取 SDK 本地会话库并刷新列表（不发网络）
    private func refreshFromLocal() {
        guard !isLoadingLocal else { return }
        isLoadingLocal = true
        let existingSnapshot = conversations
        let serverLoadedSnapshot = serverLoaded
        DispatchQueue.global(qos: .userInitiated).async {
            let local = IMManager.shared.getLocalConversationModels()
            CrashLogger.shared.log("[ConvCache] SDK local conversations = \(local.count)")
            DispatchQueue.main.async {
                self.isLoadingLocal = false
                guard !local.isEmpty else { return }
                var merged = self.filterDeleted(self.mergeNames(local, with: existingSnapshot))
                if serverLoadedSnapshot {
                    // 服务端列表更全时不要用本地较少的会话覆盖，但必须把本地最新的最后一条消息/名称回填，
                    // 否则昵称下方的预览会一直停留在旧消息（对齐安卓实时更新）
                    merged = self.conversations.map { conv in
                        guard let l = local.first(where: {
                            $0.channelID == conv.channelID && $0.channelType == conv.channelType
                        }) else { return conv }
                        var c = conv
                        if (l.lastMessageTimestamp ?? 0) > (conv.lastMessageTimestamp ?? 0) {
                            c.lastMessage = l.lastMessage
                            c.lastMessageType = l.lastMessageType
                            c.lastMessageTimestamp = l.lastMessageTimestamp
                        }
                        if c.name.isEmpty || c.name == c.channelID {
                            if !l.name.isEmpty { c.name = l.name }
                            if c.avatar == nil { c.avatar = l.avatar }
                        }
                        return c
                    }
                    // 本地存在但服务端未返回的会话（如刚产生的笔记/邀请会话）补齐进来
                    for l in local where !merged.contains(where: {
                        $0.channelID == l.channelID && $0.channelType == l.channelType
                    }) {
                        merged.append(l)
                    }
                }
                merged = self.applyPreviewOverrides(self.filterDeleted(merged))
                self.conversations = self.sortedConversations(merged)
                self.tableView.reloadData()
                self.saveCache(self.conversations)
            }
        }
    }

    /// 异步请求服务端会话列表（补齐本地缺失的会话/名称）
    private func fetchFromServer() {
        guard !isFetchingServer else { return }
        isFetchingServer = true
        let existingSnapshot = conversations
        Task {
            do {
                let syncResp: WKSyncChat = try await APIClient.shared.requestFlexible(.syncConversations)
                let wkConversations = syncResp.conversations ?? []
                // 置顶优先，其余按 lastMsgSeq 降序（其次按时间戳），与Android会话顺序一致
                var serverList = self.sortedConversations(
                    self.applyPreviewOverrides(self.filterDeleted(self.mergeNames(wkConversations.map { Conversation(from: $0) }, with: existingSnapshot)))
                )
                // 服务端列表未返回、但本地已存在且未被删除的会话补齐（避免会话丢失）
                for conv in existingSnapshot where !serverList.contains(where: {
                    $0.channelID == conv.channelID && $0.channelType == conv.channelType
                }) {
                    if !self.deletedIDs.contains(conv.channelID) { serverList.append(conv) }
                }
                serverList = self.sortedConversations(serverList)
                let finalList = serverList
                DispatchQueue.main.async {
                    self.isFetchingServer = false
                    self.serverLoaded = true
                    self.conversations = finalList
                    self.tableView.reloadData()
                    self.saveCache(finalList)
                }
                self.fetchChannelInfoForConversations()
            } catch {
                print("[ConvList] 加载失败: \(error)")
                DispatchQueue.main.async {
                    self.isFetchingServer = false
                }
            }
        }
    }

    /// 用已有名称/头像补齐缺失字段，避免刷新时名字闪空
    private func mergeNames(_ incoming: [Conversation], with existing: [Conversation]) -> [Conversation] {
        var nameMap: [String: (name: String, avatar: String?)] = [:]
        for c in existing where !c.name.isEmpty {
            nameMap[c.channelID] = (c.name, c.avatar)
        }
        // 持久名称缓存兜底（App 重启后仍能立刻显示正确昵称）
        for (key, value) in channelNameCache {
            guard let n = value["name"], !n.isEmpty else { continue }
            guard let idPart = key.split(separator: "_", maxSplits: 1).last else { continue }
            let channelID = String(idPart)
            if nameMap[channelID] == nil {
                nameMap[channelID] = (n, value["avatar"])
            }
        }
        guard !nameMap.isEmpty else { return incoming }
        return incoming.map { conv in
            guard conv.name.isEmpty || conv.name == conv.channelID,
                  let cached = nameMap[conv.channelID] else { return conv }
            var updated = conv
            updated.name = cached.name
            if updated.avatar == nil { updated.avatar = cached.avatar }
            return updated
        }
    }

    private func fetchChannelInfoForConversations() {
        // 拷贝快照，避免并发修改导致索引错乱
        let snapshot = conversations
        // 本地已有名称/头像的会话不再请求，减少首屏并发请求（提速）
        let needFetch = snapshot.filter { $0.name.isEmpty || $0.name == $0.channelID }
        for conv in needFetch {
            Task {
                do {
                    let channelInfo: ChannelInfo = try await APIClient.shared.requestFlexible(
                        .getChannelInfo(channelId: conv.channelID, channelType: conv.channelType)
                    )
                    DispatchQueue.main.async {
                        // 通过 channelID 定位，避免索引竞态导致名字/头像错配
                        guard let idx = self.conversations.firstIndex(where: {
                            $0.channelID == conv.channelID && $0.channelType == conv.channelType
                        }) else { return }
                        self.conversations[idx].name = channelInfo.displayName
                        self.conversations[idx].avatar = channelInfo.logo ?? channelInfo.avatar
                        // 写入持久名称缓存，下次冷启动直接可用（丢弃空名/等于channelID的无效名）
                        let displayName = channelInfo.displayName
                        if !displayName.isEmpty && displayName != conv.channelID {
                            let key = "\(conv.channelType)_\(conv.channelID)"
                            self.channelNameCache[key] = [
                                "name": displayName,
                                "avatar": channelInfo.logo ?? channelInfo.avatar ?? ""
                            ]
                            self.persistNameCache()
                        }
                        // 只刷新可见行，避免整表抖动
                        if self.tableView.indexPathsForVisibleRows?.contains(IndexPath(row: idx, section: 0)) == true {
                            self.tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
                        }
                        // 名称回填后防抖落盘，保证缓存里有正确昵称
                        self.saveCacheDebounced()
                    }
                } catch { }
            }
        }
    }

    private func setupIMObserver() {
        // 新消息：只从本地库刷新，不发网络请求（避免每条消息都触发一次服务端同步）
        // 注意：使用 NotificationCenter 而非 onMessageReceived 闭包——后者会被 ChatViewController 覆盖，
        // 且聊天页销毁后 weak self 失效，导致会话列表不再刷新
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIMMessageReceived(_:)),
            name: IMManager.messageReceivedNotification,
            object: nil
        )
        // 自己发送的消息：SDK 发送结果回写时同步更新预览（会话库 lastMessage 有延迟）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMessageStatusUpdate(_:)),
            name: IMManager.messageStatusUpdateNotification,
            object: nil
        )
    }

    @objc private func handleIMMessageReceived(_ notification: Notification) {
        guard let message = notification.object as? Message else { return }
        // 收到该会话的新消息时移出删除名单（对齐微信：有新消息会话重新出现）
        if !message.isFromMe {
            unmarkDeleted(channelId: message.channelID)
        }
        DispatchQueue.main.async {
            self.applyLastMessage(message)
            self.refreshFromLocal()
        }
    }

    @objc private func handleMessageStatusUpdate(_ notification: Notification) {
        guard let message = notification.object as? Message, message.isFromMe else { return }
        DispatchQueue.main.async {
            self.applyLastMessage(message)
        }
    }

    /// SDK 会话库 lastMessage 更新有延迟：用刚收到/刚发出的消息直接补丁会话预览，
    /// 保证列表昵称下方显示的是最新一条消息（与安卓一致）
    private struct PreviewOverride {
        let content: String
        let type: Int
        let timestamp: Int64
    }

    private var previewOverrides: [String: PreviewOverride] = [:]

    private func previewKey(channelID: String, channelType: Int) -> String {
        return "\(channelType)_\(channelID)"
    }

    private func applyLastMessage(_ message: Message) {
        guard !message.content.isEmpty else { return }
        guard !deletedIDs.contains(message.channelID) else { return }
        // 历史消息迟到时不覆盖更新的预览
        if let idx = conversations.firstIndex(where: {
            $0.channelID == message.channelID && $0.channelType == message.channelType
        }), let ts = conversations[idx].lastMessageTimestamp, message.timestamp < ts {
            return
        }
        let key = previewKey(channelID: message.channelID, channelType: message.channelType)
        if let old = previewOverrides[key], message.timestamp < old.timestamp { return }
        previewOverrides[key] = PreviewOverride(content: message.content,
                                                type: message.type.rawValue,
                                                timestamp: message.timestamp)

        guard let idx = conversations.firstIndex(where: {
            $0.channelID == message.channelID && $0.channelType == message.channelType
        }) else {
            // 会话尚未出现在列表（新会话）：交给本地库刷新补入
            refreshFromLocal()
            return
        }
        conversations[idx].lastMessage = message.content
        conversations[idx].lastMessageType = message.type.rawValue
        conversations[idx].lastMessageTimestamp = message.timestamp
        conversations = sortedConversations(conversations)
        tableView.reloadData()
        saveCacheDebounced()
    }

    /// 本地库/服务端返回的旧预览用待覆盖值补齐（仅当新消息时间更晚时）
    private func applyPreviewOverrides(_ list: [Conversation]) -> [Conversation] {
        guard !previewOverrides.isEmpty else { return list }
        return list.map { conv in
            let key = previewKey(channelID: conv.channelID, channelType: conv.channelType)
            guard let ov = previewOverrides[key] else { return conv }
            if (conv.lastMessageTimestamp ?? 0) < ov.timestamp {
                var c = conv
                c.lastMessage = ov.content
                c.lastMessageType = ov.type
                c.lastMessageTimestamp = ov.timestamp
                return c
            }
            return conv
        }
    }

    // MARK: - 搜索
    // 搜索栏已改为跳转全局搜索页入口（见 UITextFieldDelegate）
}

// MARK: - UITableViewDataSource
extension ConversationListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        let conversation = conversations[indexPath.row]
        cell.configure(with: conversation)
        // 置顶会话浅灰底（对齐微信/安卓）
        let pinned = isPinned(conversation)
        cell.contentView.backgroundColor = pinned ? UIColor(white: 0.95, alpha: 1.0) : .white
        cell.backgroundColor = cell.contentView.backgroundColor
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ConversationListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        let chatVC = ChatViewController(channelId: conversation.channelID, title: conversation.name, channelType: conversation.channelType)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let conversation = conversations[indexPath.row]
        let pinned = isPinned(conversation)

        let pinAction = UIContextualAction(style: .normal, title: pinned ? "取消置顶" : "置顶") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.togglePin(conversation)
            self.conversations = self.sortedConversations(self.conversations)
            tableView.reloadData()
            completion(true)
        }
        pinAction.backgroundColor = .themePrimary

        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { _, _, completion in
            self.markDeleted(conversation)
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            // 同步刷新缓存，避免冷启动又出现
            self.saveCache(self.conversations)
            completion(true)
        }
        let muteAction = UIContextualAction(style: .normal, title: "免打扰") { _, _, completion in
            AppUtility.showToast("已设为免打扰")
            completion(true)
        }
        muteAction.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [deleteAction, muteAction, pinAction])
    }
}

// MARK: - UITextFieldDelegate
extension ConversationListViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // 搜索栏作为入口：点击跳转全局搜索页
        let searchVC = SearchAllViewController()
        navigationController?.pushViewController(searchVC, animated: true)
        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 弹窗菜单视图
class PopupMenuView: UIView {

    private let backgroundView = UIView()
    private let stackView = UIStackView()
    /// 全屏点击遮罩：点击菜单以外任何位置都能关闭菜单
    private weak var dismissOverlay: UIView?
    var onSelect: ((Int) -> Void)?
    var onDismiss: (() -> Void)?

    init(items: [(icon: String, title: String)]) {
        super.init(frame: .zero)
        setupUI(items: items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(items: [(icon: String, title: String)]) {
        backgroundColor = .clear
        layer.cornerRadius = 12
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.15

        // 背景
        backgroundView.backgroundColor = UIColor.systemBackground
        backgroundView.layer.cornerRadius = 12
        backgroundView.clipsToBounds = true
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        for (index, item) in items.enumerated() {
            let btn = UIButton(type: .system)
            btn.tag = index
            let iconImg = UIImage(systemName: item.icon)
            btn.setImage(iconImg, for: .normal)
            btn.setTitle("  \(item.title)", for: .normal)
            btn.titleLabel?.font = ScreenAdapter.font(15)
            btn.tintColor = .label
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            btn.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(btn)
            btn.snp.makeConstraints { make in
                make.height.equalTo(48)
            }

            // 分割线
            if index < items.count - 1 {
                let line = UIView()
                line.backgroundColor = UIColor(white: 0, alpha: 0.08)
                btn.addSubview(line)
                line.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.trailing.bottom.equalToSuperview()
                    make.height.equalTo(0.5)
                }
            }
        }

        snp.makeConstraints { make in
            make.height.equalTo(CGFloat(items.count) * 48)
        }
    }

    @objc private func itemTapped(_ sender: UIButton) {
        onSelect?(sender.tag)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil, dismissOverlay == nil else { return }
        // 铺一层全屏透明遮罩在菜单下方，任何位置的点击都能关闭菜单（列表/按钮也会被拦截）
        let overlay = UIView()
        overlay.backgroundColor = .clear
        superview?.insertSubview(overlay, belowSubview: self)
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(overlayTapped)))
        dismissOverlay = overlay
    }

    @objc private func overlayTapped() {
        onDismiss?()
    }

    override func removeFromSuperview() {
        dismissOverlay?.removeFromSuperview()
        dismissOverlay = nil
        super.removeFromSuperview()
    }
}

// MARK: - 会话Cell
class ConversationCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameRow = UIStackView()
    private let nameLabel = UILabel()
    private let officialBadge = UIImageView()
    private let robotBadge = UIImageView()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadBadge = UIView()
    private let unreadLabel = UILabel()
    private let muteIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let avatarSize: CGFloat = 52
        let hPad: CGFloat = 16

        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite

        // 头像
        avatarView.layer.cornerRadius = 14
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        // 名字（缩小两个号，对齐安卓会话列表观感）
        nameLabel.font = ScreenAdapter.mediumFont(15)
        nameLabel.textColor = .label
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // 名称行：名称 + 官方/机器人徽标（仅在特殊会话展示，可复用不重建）
        officialBadge.image = nil
        officialBadge.contentMode = .scaleAspectFit
        officialBadge.setContentHuggingPriority(.required, for: .horizontal)
        officialBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        officialBadge.isHidden = true

        robotBadge.image = nil
        robotBadge.contentMode = .scaleAspectFit
        robotBadge.setContentHuggingPriority(.required, for: .horizontal)
        robotBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        robotBadge.isHidden = true

        nameRow.axis = .horizontal
        nameRow.alignment = .center
        nameRow.spacing = 4
        nameRow.addArrangedSubview(nameLabel)
        nameRow.addArrangedSubview(officialBadge)
        nameRow.addArrangedSubview(robotBadge)

        // 最后一条消息
        lastMessageLabel.font = ScreenAdapter.font(14)
        lastMessageLabel.textColor = .secondaryLabel
        lastMessageLabel.numberOfLines = 1

        // 时间
        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.textAlignment = .right

        // 未读红点
        unreadBadge.backgroundColor = .systemRed
        unreadBadge.layer.cornerRadius = 9
        unreadBadge.clipsToBounds = true
        unreadBadge.isHidden = true

        unreadLabel.font = ScreenAdapter.font(10)
        unreadLabel.textColor = .white
        unreadLabel.textAlignment = .center

        // 免打扰图标
        muteIcon.image = UIImage(systemName: "bell.slash.fill")
        muteIcon.tintColor = .systemGray3
        muteIcon.contentMode = .scaleAspectFit
        muteIcon.isHidden = true

        contentView.addSubviews(avatarView, nameRow, lastMessageLabel, timeLabel, unreadBadge, muteIcon)
        unreadBadge.addSubview(unreadLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameRow.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(hPad)
            make.top.equalTo(avatarView.snp.top).offset(2)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
        }

        lastMessageLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameRow)
            make.bottom.equalTo(avatarView.snp.bottom).offset(-2)
            make.trailing.lessThanOrEqualTo(unreadBadge.snp.leading).offset(-8)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.top).offset(4)
            make.trailing.equalToSuperview().offset(-hPad)
        }

        unreadBadge.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView.snp.bottom).offset(-2)
            make.trailing.equalToSuperview().offset(-hPad)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(18)
        }

        unreadLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(6)
            make.trailing.equalToSuperview().offset(-6)
        }

        muteIcon.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView.snp.bottom).offset(-2)
            make.trailing.equalToSuperview().offset(-hPad)
            make.width.height.equalTo(14)
        }
    }

    /// 系统账号 / 官方会话：Android WKSystemAccount（fileHelper、u_10000）及官方、机器人命名规则
    private static let officialChannelIDs: Set<String> = [
        "system_file_helper", "filehelper", "system_notice", "system_team", "u_10000"
    ]

    static func isOfficialConversation(_ conversation: Conversation) -> Bool {
        if officialChannelIDs.contains(conversation.channelID.lowercased()) {
            return true
        }
        let name = conversation.name
        let lower = name.lowercased()
        return name.contains("官方") || name.contains("机器人")
            || name.contains("系统通知") || name.contains("文件传输助手")
            || lower.contains("official") || lower.contains("robot")
    }

    /// 系统账号专属头像与默认昵称（对齐安卓：文件传输助手=绿色文件夹，系统账号=Milo Logo，系统团队=双人图标）
    private static let systemAccountMap: [String: (icon: String, bgHex: String, name: String)] = [
        "system_file_helper": ("folder.fill", "4CAF50", "文件传输助手"),
        "filehelper": ("folder.fill", "4CAF50", "文件传输助手"),
        "system_notice": ("milo_logo", "", "系统账号"),
        "u_10000": ("milo_logo", "", "系统账号"),
        "system_team": ("person.2.fill", "7F92D6", "系统团队")
    ]

    /// 按 channelId 或昵称解析系统账号（防止后端返回的 ID 大小写/命名不同导致显示错误头像）
    static func systemAccount(for channelId: String, name: String) -> (icon: String, bgHex: String, name: String)? {
        if let conf = systemAccountMap[channelId.lowercased()] {
            return conf
        }
        if name.contains("文件传输助手") {
            return ("folder.fill", "4CAF50", "文件传输助手")
        }
        if name.contains("系统通知") || name.contains("系统账号") {
            return ("milo_logo", "", "系统账号")
        }
        return nil
    }

    static func makeIconAvatar(icon: String, bgHex: String, size: CGFloat = 96) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            UIColor.hex(bgHex).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            let config = UIImage.SymbolConfiguration(pointSize: size * 0.45, weight: .medium)
            if let symbol = UIImage(systemName: icon, withConfiguration: config) {
                let rect = CGRect(x: (size - symbol.size.width) / 2, y: (size - symbol.size.height) / 2,
                                  width: symbol.size.width, height: symbol.size.height)
                symbol.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: rect)
            }
        }
    }

    /// 文字徽标图片（官方=红框红字，机器人=蓝框蓝字），对齐安卓样式
    static func makeTextBadge(_ text: String, colorHex: String, fontSize: CGFloat = 10) -> UIImage {
        let color = UIColor.hex(colorHex)
        let font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let hPad: CGFloat = 4, vPad: CGFloat = 2
        let size = CGSize(width: ceil(textSize.width) + hPad * 2, height: ceil(textSize.height) + vPad * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 3)
            color.setStroke()
            path.lineWidth = 1
            path.stroke()
            (text as NSString).draw(at: CGPoint(x: hPad, y: vPad), withAttributes: attrs)
        }
    }

    func configure(with conversation: Conversation) {
        // 系统账号：专属图标头像 + 默认昵称 + 官方徽标（ID 与昵称双重匹配，避免落到后端默认头像）
        let systemConf = ConversationCell.systemAccount(for: conversation.channelID, name: conversation.name)
        // 名称兜底：群聊未拉到名称时显示"群聊"，单聊显示"用户"，避免直接暴露群号/uid（看起来像乱码）
        let fallbackName = conversation.isGroup ? "群聊" : "用户"
        let displayName = conversation.name.isEmpty ? (systemConf?.name ?? fallbackName) : conversation.name
        nameLabel.text = displayName
        lastMessageLabel.text = conversation.lastMessageDisplay
        timeLabel.text = conversation.timeString

        // 系统账号：名称黑色（不染色），后面带「官方」红框 + 「机器人」蓝框徽标（对齐安卓）
        let isSystemAccount = (systemConf != nil)
        nameLabel.textColor = .label
        nameLabel.attributedText = nil
        nameLabel.text = displayName
        if isSystemAccount {
            officialBadge.image = ConversationCell.makeTextBadge("官方", colorHex: "F53F3F")
            officialBadge.isHidden = false
            robotBadge.image = ConversationCell.makeTextBadge("机器人", colorHex: "165DFF")
            robotBadge.isHidden = false
        } else {
            officialBadge.isHidden = true
            robotBadge.isHidden = true
        }

        // 特殊用户（红色昵称 + 西安/押金商家徽标）与特殊群聊（红棕色昵称），对齐安卓
        if !isSystemAccount {
            if conversation.channelType == 1,
               SpecialUserUtils.isSpecialUser(uid: conversation.channelID, shortNo: "", name: displayName) {
                nameLabel.attributedText = SpecialUserUtils.attributedName(displayName,
                                                                            font: nameLabel.font,
                                                                            color: SpecialUserUtils.specialUserNameColor)
            } else if conversation.channelType == 2 && SpecialUserUtils.isSpecialGroup(name: displayName) {
                nameLabel.attributedText = NSAttributedString(
                    string: displayName,
                    attributes: [.font: nameLabel.font, .foregroundColor: SpecialUserUtils.specialGroupNameColor]
                )
            }
        }

        if let conf = systemConf {
            if conf.icon == "milo_logo" {
                // 系统账号头像与通讯录一致：Milo Logo
                avatarView.image = UIImage(named: "LoginLogo") ?? ConversationCell.makeIconAvatar(icon: "bell.fill", bgHex: "FFA940")
            } else {
                avatarView.image = ConversationCell.makeIconAvatar(icon: conf.icon, bgHex: conf.bgHex)
            }
        } else {
            // 与Android一致：通过 /v1/users/{uid}/avatar 或 /v1/groups/{gid}/avatar 加载
            AppUtility.loadChannelAvatar(
                channelId: conversation.channelID,
                channelType: conversation.channelType,
                name: displayName,
                into: avatarView
            )
        }

        if conversation.unreadCount > 0 {
            unreadBadge.isHidden = false
            muteIcon.isHidden = true
            unreadLabel.text = conversation.unreadCount > 99 ? "99+" : "\(conversation.unreadCount)"
        } else {
            unreadBadge.isHidden = true
            // TODO: 根据免打扰状态显示
            muteIcon.isHidden = true
        }
    }
}
