import UIKit
import SnapKit
import Kingfisher

// MARK: - 搜索结果数据模型

/// 会话搜索结果
struct SearchConversationResult {
    let channelId: String
    let name: String
    let avatar: String?
    let channelType: Int
    let lastMessage: String?
    let timeString: String
}

/// 聊天记录搜索结果
struct SearchMessageResult {
    let messageId: String
    let channelId: String
    let channelName: String
    let fromName: String
    let avatar: String?
    let content: String
    let timeString: String
    let messageType: MessageType
}

/// 联系人搜索结果
struct SearchContactResult {
    let uid: String
    let name: String
    let avatar: String?
}

/// 文件搜索结果
struct SearchFileResult {
    let messageId: String
    let channelId: String
    let channelName: String
    let fileName: String
    let fromName: String
    let timeString: String
}

// MARK: - 搜索范围
enum SearchScope: Int, CaseIterable {
    case all = 0
    case conversations = 1
    case messages = 2
    case contacts = 3
    case files = 4

    var title: String {
        switch self {
        case .all: return AppStrings.Search.all
        case .conversations: return "会话"
        case .messages: return AppStrings.Search.chatHistory
        case .contacts: return AppStrings.Search.contacts
        case .files: return "文件"
        }
    }
}

// MARK: - 搜索结果分组页
/// 从会话列表顶部搜索栏触发的分组搜索结果页：
/// 会话 / 聊天记录 / 联系人 / 文件，每组前 3 条 + “查看更多”，黄色背景高亮，空状态。
class SearchResultViewController: UIViewController {

    // MARK: - UI
    private let searchBarContainer = UIView()
    private let searchIconView = UIImageView()
    private let searchTextField = UITextField()
    private let cancelButton = UIButton(type: .system)
    private let scopeScrollView = UIScrollView()
    private let scopeStackView = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyContainer = UIView()
    private let emptyIconView = UIImageView()
    private let emptyLabel = UILabel()

    @available(iOS 15.0, *)
    private var searchBarGlassView: LiquidGlassView?

    // MARK: - 数据
    private var keyword: String = ""
    private var currentScope: SearchScope = .all
    private var conversations: [SearchConversationResult] = []
    private var messages: [SearchMessageResult] = []
    private var contacts: [SearchContactResult] = []
    private var files: [SearchFileResult] = []
    private var searchDebounceTimer: Timer?
    private var hasAnimatedEntrance = false
    private let maxPreviewCount = 3

    /// 外部传入的本地会话，用于会话分组实时过滤
    var localConversations: [Conversation] = []

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themeBg
        setupSearchBar()
        setupScopeTabs()
        setupTableView()
        setupEmptyState()
        setupLayout()

        if !keyword.isEmpty {
            searchTextField.text = keyword
            performSearch()
        } else {
            updateEmptyState(hasResults: false, keyword: "")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAnimatedEntrance {
            hasAnimatedEntrance = true
            playEntranceAnimation()
        } else {
            searchTextField.becomeFirstResponder()
        }
    }

    deinit {
        searchDebounceTimer?.invalidate()
    }

    convenience init(keyword: String = "") {
        self.init()
        self.keyword = keyword
    }

    // MARK: - UI 搭建
    private func setupSearchBar() {
        if #available(iOS 15.0, *) {
            searchBarContainer.backgroundColor = .clear
            let glass = LiquidGlassView()
            glass.cornerRadius = 18
            glass.glassOpacity = 0.4
            glass.borderWidth = 0.5
            glass.borderColor = UIColor.white.withAlphaComponent(0.25)
            glass.highlightOpacity = 0.1
            glass.blurStyle = traitCollection.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
            searchBarGlassView = glass
            searchBarContainer.addSubview(glass)
            searchBarContainer.sendSubviewToBack(glass)
            glass.snp.makeConstraints { make in make.edges.equalToSuperview() }
        } else {
            searchBarContainer.backgroundColor = .themeBgSearchBar
        }
        searchBarContainer.layer.cornerRadius = 18
        searchBarContainer.clipsToBounds = true

        searchIconView.image = ThemeIcon.search.image
        searchIconView.tintColor = .themeTextSecondary
        searchIconView.contentMode = .scaleAspectFit

        searchTextField.placeholder = AppStrings.Search.searchPlaceholder
        searchTextField.font = ScreenAdapter.font(14)
        searchTextField.textColor = .themeTextPrimary
        searchTextField.tintColor = .themeColorPrimary
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        cancelButton.setTitle(AppStrings.Search.cancel, for: .normal)
        cancelButton.titleLabel?.font = ScreenAdapter.font(16)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        if AnimationIntegration.shared.config.enableButtonPressAnimation {
            cancelButton.addPressScaleEffect()
        }

        searchBarContainer.addSubviews(searchIconView, searchTextField)
        view.addSubviews(searchBarContainer, cancelButton)
    }

    private func setupScopeTabs() {
        scopeScrollView.showsHorizontalScrollIndicator = false
        scopeScrollView.alwaysBounceHorizontal = false
        scopeStackView.axis = .horizontal
        scopeStackView.alignment = .center
        scopeStackView.spacing = 8
        scopeStackView.distribution = .fill
        scopeScrollView.addSubview(scopeStackView)
        view.addSubview(scopeScrollView)

        for scope in SearchScope.allCases {
            let btn = makeScopeButton(scope)
            scopeStackView.addArrangedSubview(btn)
        }
        updateScopeSelection()
    }

    private func makeScopeButton(_ scope: SearchScope) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(scope.title, for: .normal)
        btn.titleLabel?.font = ScreenAdapter.mediumFont(13)
        btn.layer.cornerRadius = 14
        btn.layer.masksToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        btn.tag = scope.rawValue
        btn.addTarget(self, action: #selector(scopeTapped(_:)), for: .touchUpInside)
        if AnimationIntegration.shared.config.enableButtonPressAnimation {
            btn.addPressScaleEffect()
        }
        return btn
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchResultGroupHeaderCell.self, forCellReuseIdentifier: "GroupHeader")
        tableView.register(SearchResultConversationCell.self, forCellReuseIdentifier: "Conversation")
        tableView.register(SearchResultMessageCell.self, forCellReuseIdentifier: "Message")
        tableView.register(SearchResultContactCell.self, forCellReuseIdentifier: "Contact")
        tableView.register(SearchResultFileCell.self, forCellReuseIdentifier: "File")
        tableView.register(SearchResultMoreCell.self, forCellReuseIdentifier: "More")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.backgroundColor = .themeBg
        tableView.keyboardDismissMode = .interactive
        view.addSubview(tableView)

        activityIndicator.color = .themeTextSecondary
        view.addSubview(activityIndicator)
    }

    private func setupEmptyState() {
        emptyIconView.image = ThemeIcon.search.image
        emptyIconView.tintColor = .themeTextHint
        emptyIconView.contentMode = .scaleAspectFit

        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .themeTextSecondary
        emptyLabel.textAlignment = .center

        emptyContainer.addSubviews(emptyIconView, emptyLabel)
        emptyContainer.isHidden = true
        view.addSubview(emptyContainer)
    }

    private func setupLayout() {
        searchBarContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(36)
        }
        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(searchBarContainer.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(searchBarContainer)
        }
        searchIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        searchTextField.snp.makeConstraints { make in
            make.leading.equalTo(searchIconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }

        scopeScrollView.snp.makeConstraints { make in
            make.top.equalTo(searchBarContainer.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
        scopeStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(scopeScrollView.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
        emptyContainer.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.width.equalTo(200)
        }
        emptyIconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(48)
        }
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyIconView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - 范围切换
    @objc private func scopeTapped(_ sender: UIButton) {
        guard let scope = SearchScope(rawValue: sender.tag), scope != currentScope else { return }
        currentScope = scope
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
        updateScopeSelection()
        tableView.reloadData()
        refreshEmptyState()
    }

    private func updateScopeSelection() {
        for view in scopeStackView.arrangedSubviews {
            guard let btn = view as? UIButton, let scope = SearchScope(rawValue: btn.tag) else { continue }
            let selected = scope == currentScope
            btn.setTitleColor(selected ? .white : .themeTextPrimary, for: .normal)
            btn.backgroundColor = selected ? .themeColorPrimary : .themeBgCard
        }
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
        searchTextField.resignFirstResponder()
        dismiss(animated: true)
    }

    @objc private func textChanged() {
        let text = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.keyword = text
            if text.isEmpty {
                self.clearResults()
            } else {
                self.performSearch()
            }
        }
    }

    // MARK: - 搜索
    private func performSearch() {
        guard !keyword.isEmpty else { return }
        activityIndicator.startAnimating()
        emptyContainer.isHidden = true

        // 先做本地会话过滤（会话分组实时响应）
        let localConvMatches = localConversations.filter { conv in
            let nameMatch = conv.name.lowercased().contains(keyword.lowercased())
            let msgMatch = (conv.lastMessage ?? "").lowercased().contains(keyword.lowercased())
            return nameMatch || msgMatch
        }
        conversations = localConvMatches.map { conv in
            SearchConversationResult(
                channelId: conv.channelID,
                name: conv.name,
                avatar: conv.avatar,
                channelType: conv.channelType,
                lastMessage: conv.lastMessage,
                timeString: conv.timeString
            )
        }

        // 联网搜索聊天记录 / 联系人 / 文件
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.globalSearch(keyword: keyword, page: 1))
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.parseRemote(resp)
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    // 网络失败时用本地 + 模拟数据兜底
                    self.applySimulatedData()
                }
            }
        }
    }

    private func parseRemote(_ resp: [String: Any]) {
        guard let data = resp["data"] as? [String: Any] else {
            applySimulatedData()
            return
        }

        // 聊天记录
        let remoteMsgs = (data["messages"] as? [[String: Any]]) ?? []
        messages = remoteMsgs.map { dict in
            let content = dict["content"] as? String ?? ""
            let typeRaw = dict["type"] as? Int ?? 1
            return SearchMessageResult(
                messageId: dict["message_id"] as? String ?? "",
                channelId: dict["channel_id"] as? String ?? "",
                channelName: dict["channel_name"] as? String ?? "",
                fromName: dict["from_name"] as? String ?? "",
                avatar: dict["avatar"] as? String,
                content: content,
                timeString: dict["created_at"] as? String ?? "",
                messageType: MessageType(rawValue: typeRaw) ?? .text
            )
        }

        // 联系人（好友）
        let remoteFriends = (data["friends"] as? [[String: Any]]) ?? []
        contacts = remoteFriends.map { dict in
            SearchContactResult(
                uid: dict["channel_id"] as? String ?? "",
                name: dict["name"] as? String ?? "",
                avatar: dict["avatar"] as? String
            )
        }

        // 补充会话分组（远端群聊）
        if conversations.isEmpty {
            let remoteGroups = (data["groups"] as? [[String: Any]]) ?? []
            conversations = remoteGroups.map { dict in
                SearchConversationResult(
                    channelId: dict["channel_id"] as? String ?? "",
                    name: dict["name"] as? String ?? "",
                    avatar: dict["avatar"] as? String,
                    channelType: 2,
                    lastMessage: nil,
                    timeString: ""
                )
            }
        }

        // 文件：从聊天记录中筛选文件类型
        files = messages.filter { $0.messageType == .file }.map { msg in
            let fileName = msg.content.split(separator: "|").first.map(String.init) ?? msg.content
            return SearchFileResult(
                messageId: msg.messageId,
                channelId: msg.channelId,
                channelName: msg.channelName,
                fileName: fileName,
                fromName: msg.fromName,
                timeString: msg.timeString
            )
        }

        // 本地/远端均无结果时，用模拟数据兜底以展示 UI
        if conversations.isEmpty && messages.isEmpty && contacts.isEmpty && files.isEmpty {
            applySimulatedData()
            return
        }

        tableView.reloadData()
        refreshEmptyState()
    }

    /// 模拟数据兜底（任务要求：搜索功能可以先模拟数据）
    private func applySimulatedData() {
        let k = keyword
        if conversations.isEmpty {
            conversations = [
                SearchConversationResult(channelId: "sim_conv_1", name: "\(k)的会话", avatar: nil, channelType: 1, lastMessage: "关于\(k)的讨论", timeString: "10:24"),
                SearchConversationResult(channelId: "sim_conv_2", name: "项目\(k)群", avatar: nil, channelType: 2, lastMessage: "[\(k)] 设计稿已更新", timeString: "昨天")
            ]
        }
        if messages.isEmpty {
            messages = [
                SearchMessageResult(messageId: "sim_msg_1", channelId: "sim_conv_1", channelName: "\(k)的会话", fromName: "阿明", avatar: nil, content: "今天分享一份\(k)相关资料", timeString: "10:20", messageType: .text),
                SearchMessageResult(messageId: "sim_msg_2", channelId: "sim_conv_2", channelName: "项目\(k)群", fromName: "小琳", avatar: nil, content: "[图片] \(k).png", timeString: "09:15", messageType: .image),
                SearchMessageResult(messageId: "sim_msg_3", channelId: "sim_conv_1", channelName: "\(k)的会话", fromName: "阿明", avatar: nil, content: "\(k)-需求文档.pdf|102400", timeString: "昨天", messageType: .file)
            ]
        }
        if contacts.isEmpty {
            contacts = [
                SearchContactResult(uid: "sim_uid_1", name: "\(k)老师", avatar: nil),
                SearchContactResult(uid: "sim_uid_2", name: "李\(k)", avatar: nil)
            ]
        }
        if files.isEmpty {
            files = [
                SearchFileResult(messageId: "sim_file_1", channelId: "sim_conv_1", channelName: "\(k)的会话", fileName: "\(k)-需求文档.pdf", fromName: "阿明", timeString: "昨天"),
                SearchFileResult(messageId: "sim_file_2", channelId: "sim_conv_2", channelName: "项目\(k)群", fileName: "\(k)设计稿.zip", fromName: "小琳", timeString: "09:15")
            ]
        }
        tableView.reloadData()
        refreshEmptyState()
    }

    private func clearResults() {
        conversations = []
        messages = []
        contacts = []
        files = []
        tableView.reloadData()
        updateEmptyState(hasResults: false, keyword: "")
    }

    // MARK: - 空状态
    private func refreshEmptyState() {
        let hasResults = !conversations.isEmpty || !messages.isEmpty || !contacts.isEmpty || !files.isEmpty
        updateEmptyState(hasResults: hasResults, keyword: keyword)
    }

    private func updateEmptyState(hasResults: Bool, keyword: String) {
        if hasResults {
            emptyContainer.isHidden = true
            return
        }
        emptyContainer.isHidden = false
        if keyword.isEmpty {
            emptyLabel.text = "输入关键词开始搜索"
        } else {
            emptyLabel.text = AppStrings.Search.noResults
        }
    }

    // MARK: - 入场动画
    private func playEntranceAnimation() {
        let config = AnimationIntegration.shared.config
        guard config.enablePageTransition else {
            searchTextField.becomeFirstResponder()
            return
        }
        searchBarContainer.alpha = 0
        searchBarContainer.transform = CGAffineTransform(translationX: 0, y: -16).scaledBy(x: 0.96, y: 0.96)
        UIView.animate(withDuration: AnimationDuration.normal,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            self.searchBarContainer.alpha = 1
            self.searchBarContainer.transform = .identity
        } completion: { _ in
            self.searchTextField.becomeFirstResponder()
            if config.enableHapticFeedback {
                HapticManager.shared.selectionChanged()
            }
        }
        if config.enableListEntranceAnimation {
            tableView.alpha = 0
            tableView.transform = CGAffineTransform(translationX: 0, y: 16)
            UIView.animate(withDuration: AnimationDuration.slow,
                           delay: 0.15,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut) {
                self.tableView.alpha = 1
                self.tableView.transform = .identity
            }
        }
        if config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
    }

    // MARK: - 分组数据
    private struct SearchResultGroup {
        let scope: SearchScope
        let headerTitle: String
        var items: [Any]
    }

    private var visibleGroups: [SearchResultGroup] {
        var groups: [SearchResultGroup] = []
        let shouldShow: (SearchScope) -> Bool = { scope in
            return self.currentScope == .all || self.currentScope == scope
        }
        if shouldShow(.conversations) && !conversations.isEmpty {
            groups.append(SearchResultGroup(scope: .conversations, headerTitle: "会话", items: Array(conversations.prefix(maxPreviewCount))))
        }
        if shouldShow(.messages) && !messages.isEmpty {
            groups.append(SearchResultGroup(scope: .messages, headerTitle: AppStrings.Search.chatHistory, items: Array(messages.prefix(maxPreviewCount))))
        }
        if shouldShow(.contacts) && !contacts.isEmpty {
            groups.append(SearchResultGroup(scope: .contacts, headerTitle: AppStrings.Search.contacts, items: Array(contacts.prefix(maxPreviewCount))))
        }
        if shouldShow(.files) && !files.isEmpty {
            groups.append(SearchResultGroup(scope: .files, headerTitle: "文件", items: Array(files.prefix(maxPreviewCount))))
        }
        return groups
    }

    private func totalCount(for scope: SearchScope) -> Int {
        switch scope {
        case .conversations: return conversations.count
        case .messages: return messages.count
        case .contacts: return contacts.count
        case .files: return files.count
        default: return 0
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SearchResultViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return visibleGroups.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = visibleGroups[section]
        var count = group.items.count
        // 当前范围非“全部”时展示全部，不需要“查看更多”
        if currentScope == .all && totalCount(for: group.scope) > maxPreviewCount {
            count += 1
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = visibleGroups[indexPath.section]
        let isMoreRow = currentScope == .all && indexPath.row == group.items.count && totalCount(for: group.scope) > maxPreviewCount

        if isMoreRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: "More", for: indexPath) as! SearchResultMoreCell
            cell.configure(title: "查看更多\(group.headerTitle)（\(totalCount(for: group.scope))）")
            return cell
        }

        switch group.scope {
        case .conversations:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Conversation", for: indexPath) as! SearchResultConversationCell
            cell.configure(item: group.items[indexPath.row] as! SearchConversationResult, keyword: keyword)
            return cell
        case .messages:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Message", for: indexPath) as! SearchResultMessageCell
            cell.configure(item: group.items[indexPath.row] as! SearchMessageResult, keyword: keyword)
            return cell
        case .contacts:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Contact", for: indexPath) as! SearchResultContactCell
            cell.configure(item: group.items[indexPath.row] as! SearchContactResult, keyword: keyword)
            return cell
        case .files:
            let cell = tableView.dequeueReusableCell(withIdentifier: "File", for: indexPath) as! SearchResultFileCell
            cell.configure(item: group.items[indexPath.row] as! SearchFileResult, keyword: keyword)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = visibleGroups[section]
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupHeader") as! SearchResultGroupHeaderCell
        cell.configure(title: group.headerTitle)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ScreenAdapter.scaleH(32)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
        let group = visibleGroups[indexPath.section]
        let isMoreRow = currentScope == .all && indexPath.row == group.items.count && totalCount(for: group.scope) > maxPreviewCount
        if isMoreRow {
            // 切换到对应范围，展开全部
            currentScope = group.scope
            updateScopeSelection()
            tableView.reloadData()
            return
        }
        switch group.scope {
        case .conversations:
            let item = group.items[indexPath.row] as! SearchConversationResult
            navigateToChat(channelId: item.channelId, title: item.name, channelType: item.channelType)
        case .messages:
            let item = group.items[indexPath.row] as! SearchMessageResult
            navigateToChat(channelId: item.channelId, title: item.channelName, channelType: 1)
        case .contacts:
            let item = group.items[indexPath.row] as! SearchContactResult
            navigationController?.pushViewController(ContactDetailViewController(uid: item.uid), animated: true)
        case .files:
            let item = group.items[indexPath.row] as! SearchFileResult
            navigateToChat(channelId: item.channelId, title: item.channelName, channelType: 1)
        default:
            break
        }
    }

    private func navigateToChat(channelId: String, title: String, channelType: Int) {
        let vc = ChatViewController(channelId: channelId, title: title, channelType: channelType)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension SearchResultViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 分组头 Cell
private class SearchResultGroupHeaderCell: UITableViewCell {
    private let label = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        label.font = ScreenAdapter.mediumFont(13)
        label.textColor = .themeTextSecondary
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(title: String) { label.text = title }
}

// MARK: - “查看更多” Cell
private class SearchResultMoreCell: UITableViewCell {
    private let label = UILabel()
    private let arrow = UIImageView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        label.font = ScreenAdapter.font(14)
        label.textColor = .themeColorPrimary
        arrow.image = ThemeIcon.forward.image
        arrow.tintColor = .themeColorPrimary
        arrow.contentMode = .scaleAspectFit
        contentView.addSubviews(label, arrow)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        arrow.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(title: String) { label.text = title }
}

// MARK: - 会话结果 Cell
private class SearchResultConversationCell: UITableViewCell {
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 8
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .themeBgCard
        avatarView.image = ThemeIcon.contacts.image
        avatarView.tintColor = .themeTextHint
        nameLabel.font = ScreenAdapter.mediumFont(16)
        nameLabel.textColor = .themeTextPrimary
        lastMessageLabel.font = ScreenAdapter.font(13)
        lastMessageLabel.textColor = .themeTextSecondary
        lastMessageLabel.numberOfLines = 1
        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .themeTextTertiary
        timeLabel.textAlignment = .right
        contentView.addSubviews(avatarView, nameLabel, lastMessageLabel, timeLabel)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalTo(avatarView).offset(2)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
        }
        lastMessageLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalTo(avatarView).offset(-2)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: SearchConversationResult, keyword: String) {
        nameLabel.attributedText = highlightKeywordYellow(item.name, keyword: keyword)
        lastMessageLabel.attributedText = highlightKeywordYellow(item.lastMessage ?? "", keyword: keyword)
        timeLabel.text = item.timeString
        AppUtility.loadAvatar(nil, into: avatarView)
        if let avatar = item.avatar, !avatar.isEmpty {
            let urlStr = avatar.hasPrefix("http") ? avatar : APIConfig.apiBaseURL + "/" + avatar
            if let url = URL(string: urlStr) {
                avatarView.kf.setImage(with: url, placeholder: ThemeIcon.contacts.image)
            }
        } else {
            avatarView.image = item.channelType == 2 ? ThemeIcon.group.image : ThemeIcon.contacts.image
            avatarView.tintColor = .themeTextHint
        }
    }
}

// MARK: - 聊天记录结果 Cell
private class SearchResultMessageCell: UITableViewCell {
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let contentLabel = UILabel()
    private let typeIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .themeBgCard
        avatarView.image = ThemeIcon.contacts.image
        avatarView.tintColor = .themeTextHint
        nameLabel.font = ScreenAdapter.mediumFont(15)
        nameLabel.textColor = .themeTextPrimary
        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .themeTextTertiary
        timeLabel.textAlignment = .right
        contentLabel.font = ScreenAdapter.font(14)
        contentLabel.textColor = .themeTextSecondary
        contentLabel.numberOfLines = 1
        typeIcon.tintColor = .themeTextTertiary
        typeIcon.contentMode = .scaleAspectFit
        contentView.addSubviews(avatarView, nameLabel, timeLabel, typeIcon, contentLabel)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(8)
            make.width.height.equalTo(40)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalTo(avatarView)
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(nameLabel)
        }
        typeIcon.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-8)
            make.width.height.equalTo(14)
        }
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(typeIcon.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(typeIcon)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: SearchMessageResult, keyword: String) {
        nameLabel.text = item.fromName.isEmpty ? item.channelName : item.fromName
        timeLabel.text = item.timeString
        let icon: ThemeIcon
        var displayText = item.content
        switch item.messageType {
        case .image:
            icon = .image
            displayText = "[图片] \(item.content)"
        case .video:
            icon = .video
            displayText = "[视频]"
        case .voice:
            icon = .voice
            displayText = "[语音]"
        case .file:
            icon = .file
            displayText = "[文件] \(item.content.split(separator: "|").first.map(String.init) ?? item.content)"
        case .location:
            icon = .location
            displayText = "[位置]"
        case .card:
            icon = .card
            displayText = "[名片]"
        default:
            icon = .text
        }
        typeIcon.image = icon.image
        contentLabel.attributedText = highlightKeywordYellow(displayText, keyword: keyword)

        if let avatar = item.avatar, !avatar.isEmpty {
            let urlStr = avatar.hasPrefix("http") ? avatar : APIConfig.apiBaseURL + "/" + avatar
            if let url = URL(string: urlStr) {
                avatarView.kf.setImage(with: url, placeholder: ThemeIcon.contacts.image)
            }
        }
    }
}

// MARK: - 联系人结果 Cell
private class SearchResultContactCell: UITableViewCell {
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .themeBgCard
        avatarView.image = ThemeIcon.contacts.image
        avatarView.tintColor = .themeTextHint
        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .themeTextPrimary
        contentView.addSubviews(avatarView, nameLabel)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: SearchContactResult, keyword: String) {
        nameLabel.attributedText = highlightKeywordYellow(item.name, keyword: keyword)
        if let avatar = item.avatar, !avatar.isEmpty {
            let urlStr = avatar.hasPrefix("http") ? avatar : APIConfig.apiBaseURL + "/" + avatar
            if let url = URL(string: urlStr) {
                avatarView.kf.setImage(with: url, placeholder: ThemeIcon.contacts.image)
            }
        } else {
            avatarView.image = ThemeIcon.contacts.image
            avatarView.tintColor = .themeTextHint
        }
    }
}

// MARK: - 文件结果 Cell
private class SearchResultFileCell: UITableViewCell {
    private let fileIcon = UIImageView()
    private let fileNameLabel = UILabel()
    private let metaLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        fileIcon.contentMode = .scaleAspectFit
        fileIcon.tintColor = .themeColorPrimary
        fileNameLabel.font = ScreenAdapter.font(15)
        fileNameLabel.textColor = .themeTextPrimary
        fileNameLabel.numberOfLines = 1
        metaLabel.font = ScreenAdapter.font(12)
        metaLabel.textColor = .themeTextTertiary
        contentView.addSubviews(fileIcon, fileNameLabel, metaLabel)
        fileIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        fileNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(fileIcon.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(10)
        }
        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(fileNameLabel)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: SearchFileResult, keyword: String) {
        fileNameLabel.attributedText = highlightKeywordYellow(item.fileName, keyword: keyword)
        metaLabel.text = "\(item.fromName) · \(item.channelName) · \(item.timeString)"
        let ext = (item.fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf":
            fileIcon.image = ThemeIcon.file.image
            fileIcon.tintColor = .systemRed
        case "zip", "rar", "7z":
            fileIcon.image = ThemeIcon.file.image
            fileIcon.tintColor = .systemOrange
        case "mp4", "mov", "avi":
            fileIcon.image = ThemeIcon.video.image
        case "mp3", "wav", "m4a":
            fileIcon.image = ThemeIcon.voice.image
        default:
            fileIcon.image = ThemeIcon.file.image
        }
    }
}

// MARK: - 聊天记录搜索页（会话内）
/// 在聊天页面内搜索本会话聊天记录：文字 / 图片缩略图 / 文件名，
/// 点击结果通过 onLocate 回调跳转到对应消息位置。
class ChatHistorySearchViewController: UIViewController {

    private let searchBarContainer = UIView()
    private let searchIconView = UIImageView()
    private let searchTextField = UITextField()
    private let cancelButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyContainer = UIView()
    private let emptyIconView = UIImageView()
    private let emptyLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    @available(iOS 15.0, *)
    private var searchBarGlassView: LiquidGlassView?

    private let channelId: String
    private let channelType: Int
    private let channelTitle: String
    private var messages: [Message]
    private var results: [Message] = []
    private var keyword: String = ""
    private var searchDebounceTimer: Timer?

    /// 选中某条结果后回调（messageId），由 ChatViewController 跳转定位
    var onLocate: ((String) -> Void)?

    init(channelId: String, channelType: Int, title: String, messages: [Message]) {
        self.channelId = channelId
        self.channelType = channelType
        self.channelTitle = title
        self.messages = messages
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "查找聊天记录"
        view.backgroundColor = .themeBg
        setupSearchBar()
        setupTableView()
        setupEmptyState()
        setupLayout()
        updateEmptyState(hasResults: false, keyword: "")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.becomeFirstResponder()
    }

    deinit {
        searchDebounceTimer?.invalidate()
    }

    // MARK: - UI
    private func setupSearchBar() {
        if #available(iOS 15.0, *) {
            searchBarContainer.backgroundColor = .clear
            let glass = LiquidGlassView()
            glass.cornerRadius = 18
            glass.glassOpacity = 0.4
            glass.borderWidth = 0.5
            glass.borderColor = UIColor.white.withAlphaComponent(0.25)
            glass.highlightOpacity = 0.1
            glass.blurStyle = traitCollection.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
            searchBarGlassView = glass
            searchBarContainer.addSubview(glass)
            searchBarContainer.sendSubviewToBack(glass)
            glass.snp.makeConstraints { make in make.edges.equalToSuperview() }
        } else {
            searchBarContainer.backgroundColor = .themeBgSearchBar
        }
        searchBarContainer.layer.cornerRadius = 18
        searchBarContainer.clipsToBounds = true

        searchIconView.image = ThemeIcon.search.image
        searchIconView.tintColor = .themeTextSecondary
        searchIconView.contentMode = .scaleAspectFit

        searchTextField.placeholder = "搜索\"\(channelTitle)\"的聊天记录"
        searchTextField.font = ScreenAdapter.font(14)
        searchTextField.textColor = .themeTextPrimary
        searchTextField.tintColor = .themeColorPrimary
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        cancelButton.setTitle(AppStrings.Search.cancel, for: .normal)
        cancelButton.titleLabel?.font = ScreenAdapter.font(16)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        if AnimationIntegration.shared.config.enableButtonPressAnimation {
            cancelButton.addPressScaleEffect()
        }

        searchBarContainer.addSubviews(searchIconView, searchTextField)
        view.addSubviews(searchBarContainer, cancelButton)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatHistorySearchCell.self, forCellReuseIdentifier: "HistoryCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.backgroundColor = .themeBg
        tableView.keyboardDismissMode = .interactive
        view.addSubview(tableView)

        activityIndicator.color = .themeTextSecondary
        view.addSubview(activityIndicator)
    }

    private func setupEmptyState() {
        emptyIconView.image = ThemeIcon.search.image
        emptyIconView.tintColor = .themeTextHint
        emptyIconView.contentMode = .scaleAspectFit
        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .themeTextSecondary
        emptyLabel.textAlignment = .center
        emptyContainer.addSubviews(emptyIconView, emptyLabel)
        emptyContainer.isHidden = true
        view.addSubview(emptyContainer)
    }

    private func setupLayout() {
        searchBarContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(36)
        }
        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(searchBarContainer.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(searchBarContainer)
        }
        searchIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        searchTextField.snp.makeConstraints { make in
            make.leading.equalTo(searchIconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBarContainer.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
        emptyContainer.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.width.equalTo(200)
        }
        emptyIconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(48)
        }
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyIconView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
        searchTextField.resignFirstResponder()
        dismiss(animated: true)
    }

    @objc private func textChanged() {
        let text = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.keyword = text
            self?.performSearch()
        }
    }

    // MARK: - 搜索
    private func performSearch() {
        guard !keyword.isEmpty else {
            results = []
            tableView.reloadData()
            updateEmptyState(hasResults: false, keyword: "")
            return
        }
        activityIndicator.startAnimating()
        emptyContainer.isHidden = true

        // 本地消息匹配
        let local = messages.filter { msg in
            matches(message: msg, keyword: keyword)
        }
        results = local

        // 本地不足时尝试联网拉取更多消息再过滤
        if results.count < 20 {
            IMManager.shared.pullLastMessages(channelId: channelId, channelType: channelType, limit: 100) { [weak self] wkMessages, _ in
                guard let self = self else { return }
                let remote = (wkMessages ?? []).map { Message(from: $0 as! WKMessageData) }
                // 合并去重
                var seen = Set(self.results.map { $0.messageID })
                for m in remote {
                    if seen.contains(m.messageID) { continue }
                    if self.matches(message: m, keyword: self.keyword) {
                        self.results.append(m)
                        seen.insert(m.messageID)
                    }
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.tableView.reloadData()
                    self.updateEmptyState(hasResults: !self.results.isEmpty, keyword: self.keyword)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
                self.updateEmptyState(hasResults: !self.results.isEmpty, keyword: self.keyword)
            }
        }
    }

    private func matches(message: Message, keyword: String) -> Bool {
        let k = keyword.lowercased()
        switch message.type {
        case .text, .note:
            return message.content.lowercased().contains(k)
        case .file:
            let fileName = message.content.split(separator: "|").first.map(String.init) ?? message.content
            return fileName.lowercased().contains(k)
        case .image, .video:
            // 媒体以类型标记参与搜索（便于按类型定位）
            return k.contains("图片") || k.contains("视频") || message.content.lowercased().contains(k)
        default:
            return message.content.lowercased().contains(k)
        }
    }

    private func updateEmptyState(hasResults: Bool, keyword: String) {
        if hasResults {
            emptyContainer.isHidden = true
            return
        }
        emptyContainer.isHidden = false
        emptyLabel.text = keyword.isEmpty ? "输入关键词搜索聊天记录" : AppStrings.Search.noResults
    }
}

// MARK: - 聊天记录搜索 DataSource & Delegate
extension ChatHistorySearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(results.count, 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! ChatHistorySearchCell
        cell.configure(message: results[indexPath.row], keyword: keyword)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
        let messageId = results[indexPath.row].messageID
        onLocate?(messageId)
        dismiss(animated: true)
    }
}

extension ChatHistorySearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 聊天记录搜索结果 Cell
private class ChatHistorySearchCell: UITableViewCell {
    private let typeIcon = UIImageView()
    private let thumbView = UIImageView()
    private let contentLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        typeIcon.contentMode = .scaleAspectFit
        typeIcon.tintColor = .themeTextTertiary
        thumbView.contentMode = .scaleAspectFill
        thumbView.clipsToBounds = true
        thumbView.layer.cornerRadius = 6
        thumbView.backgroundColor = .themeBgCard
        thumbView.isHidden = true
        contentLabel.font = ScreenAdapter.font(15)
        contentLabel.textColor = .themeTextPrimary
        contentLabel.numberOfLines = 2
        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .themeTextTertiary
        timeLabel.textAlignment = .right
        contentView.addSubviews(typeIcon, thumbView, contentLabel, timeLabel)
        typeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }
        thumbView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(typeIcon.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(10)
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(message: Message, keyword: String) {
        timeLabel.text = message.timeString
        thumbView.isHidden = true
        typeIcon.isHidden = false
        switch message.type {
        case .text, .note:
            typeIcon.image = ThemeIcon.text.image
            contentLabel.attributedText = highlightKeywordYellow(message.content, keyword: keyword)
        case .image:
            typeIcon.isHidden = true
            thumbView.isHidden = false
            contentLabel.text = "[图片]"
            let urlStr: String
            if message.content.hasPrefix("http") {
                urlStr = message.content
            } else if message.content.hasPrefix("/") {
                urlStr = APIConfig.apiBaseURL + message.content
            } else {
                urlStr = APIConfig.apiBaseURL + "/" + message.content
            }
            if let url = URL(string: urlStr) {
                thumbView.kf.setImage(with: url, placeholder: ThemeIcon.image.image)
            } else {
                thumbView.image = ThemeIcon.image.image
            }
        case .video:
            typeIcon.image = ThemeIcon.video.image
            contentLabel.text = "[视频]"
        case .file:
            typeIcon.image = ThemeIcon.file.image
            let fileName = message.content.split(separator: "|").first.map(String.init) ?? message.content
            contentLabel.attributedText = highlightKeywordYellow("[文件] \(fileName)", keyword: keyword)
        case .voice:
            typeIcon.image = ThemeIcon.voice.image
            contentLabel.text = "[语音]"
        case .location:
            typeIcon.image = ThemeIcon.location.image
            contentLabel.text = "[位置]"
        case .card:
            typeIcon.image = ThemeIcon.card.image
            contentLabel.text = "[名片]"
        default:
            typeIcon.image = ThemeIcon.text.image
            contentLabel.attributedText = highlightKeywordYellow(message.content, keyword: keyword)
        }
        // 动态约束：缩略图模式下内容左对齐到缩略图
        contentLabel.snp.remakeConstraints { make in
            make.leading.equalTo(thumbView.isHidden ? typeIcon.snp.trailing : thumbView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
}

// MARK: - 关键词高亮（黄色背景）
/// 搜索结果关键词高亮：匹配片段使用黄色背景 + 深色文字，对齐设计稿要求。
func highlightKeywordYellow(_ text: String, keyword: String) -> NSAttributedString {
    let attr = NSMutableAttributedString(string: text)
    attr.addAttribute(.font, value: ScreenAdapter.font(15), range: NSRange(location: 0, length: attr.length))
    attr.addAttribute(.foregroundColor, value: UIColor.themeTextPrimary, range: NSRange(location: 0, length: attr.length))

    if keyword.isEmpty { return attr }

    let lowerText = text.lowercased()
    let lowerKeyword = keyword.lowercased()
    var searchRange = lowerText.startIndex..<lowerText.endIndex
    let highlightColor = UIColor(red: 1.0, green: 0.93, blue: 0.4, alpha: 1.0)
    let highlightTextColor = UIColor(red: 0.2, green: 0.13, blue: 0.0, alpha: 1.0)

    while let range = lowerText.range(of: lowerKeyword, options: [], range: searchRange) {
        let nsRange = NSRange(range, in: text)
        attr.addAttribute(.backgroundColor, value: highlightColor, range: nsRange)
        attr.addAttribute(.foregroundColor, value: highlightTextColor, range: nsRange)
        searchRange = range.upperBound..<lowerText.endIndex
    }
    return attr
}
