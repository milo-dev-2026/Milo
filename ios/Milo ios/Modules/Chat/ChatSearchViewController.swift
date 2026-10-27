import UIKit
import SnapKit
import Kingfisher
import WuKongIMSDK

// MARK: - 查找聊天记录（对标 Android MessageRecordActivity）
/// 会话内搜索页：顶部 UISearchBar + 横向搜索类型菜单（全部/图片/文件/链接/语音/视频）+ 结果列表。
/// 通过 APIRouter.globalSearch 联网搜索，点击结果跳转到聊天页面。
class ChatSearchViewController: UIViewController {

    // MARK: - 搜索类型
    private enum SearchType: Int, CaseIterable {
        case all = 0
        case image
        case file
        case link
        case voice
        case video

        var title: String {
            switch self {
            case .all: return "全部"
            case .image: return "图片"
            case .file: return "文件"
            case .link: return "链接"
            case .voice: return "语音"
            case .video: return "视频"
            }
        }
    }

    // MARK: - 搜索结果项
    fileprivate struct ChatSearchResult {
        let messageId: String
        let fromUID: String
        let fromName: String
        let content: String
        let type: Int
        let timeString: String

        /// 列表展示用内容摘要（按消息类型加前缀）
        var summary: String {
            switch type {
            case 2: return "[图片]"
            case 3: return "[语音]"
            case 4: return "[视频]"
            case 5:
                let name = content.split(separator: "|").first.map(String.init) ?? content
                return name.isEmpty ? "[文件]" : "[文件] \(name)"
            case 6: return "[位置]"
            case 7: return "[名片]"
            case 100: return "[笔记]"
            default: return content
            }
        }
    }

    // MARK: - 属性
    private let channelId: String
    private let channelType: Int
    private var channelTitle: String = "聊天"

    private let searchBar = UISearchBar()
    private let typeScrollView = UIScrollView()
    private let typeStackView = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyLabel = UILabel()

    private var currentType: SearchType = .all
    private var results: [ChatSearchResult] = []
    private var keyword: String = ""
    private var page = 1
    private let pageSize = 20
    private var hasMore = false
    private var isLoading = false
    private var searchTimer: Timer?

    // MARK: - 初始化
    init(channelId: String, channelType: Int) {
        self.channelId = channelId
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        searchTimer?.invalidate()
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "查找聊天记录"
        view.backgroundColor = .themeBg
        channelTitle = IMManager.shared.getChannelInfo(channelId: channelId, channelType: channelType)?.name ?? "聊天"
        setupSearchBar()
        setupTypeMenu()
        setupTableView()
        setupLayout()
        refreshEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI
    private func setupSearchBar() {
        searchBar.placeholder = "搜索聊天记录"
        searchBar.searchBarStyle = .minimal
        searchBar.returnKeyType = .search
        searchBar.delegate = self
        searchBar.tintColor = .themeColorPrimary
        view.addSubview(searchBar)
    }

    private func setupTypeMenu() {
        typeScrollView.showsHorizontalScrollIndicator = false
        typeScrollView.alwaysBounceHorizontal = true

        typeStackView.axis = .horizontal
        typeStackView.alignment = .center
        typeStackView.spacing = ScreenAdapter.scaleW(8)
        typeStackView.distribution = .fill
        typeScrollView.addSubview(typeStackView)
        view.addSubview(typeScrollView)

        for type in SearchType.allCases {
            let btn = UIButton(type: .system)
            btn.setTitle(type.title, for: .normal)
            btn.titleLabel?.font = ScreenAdapter.mediumFont(13)
            btn.layer.cornerRadius = ScreenAdapter.scaleW(14)
            btn.layer.masksToBounds = true
            btn.contentEdgeInsets = UIEdgeInsets(
                top: ScreenAdapter.scaleH(6),
                left: ScreenAdapter.scaleW(14),
                bottom: ScreenAdapter.scaleH(6),
                right: ScreenAdapter.scaleW(14)
            )
            btn.tag = type.rawValue
            btn.addTarget(self, action: #selector(typeTapped(_:)), for: .touchUpInside)
            typeStackView.addArrangedSubview(btn)
        }
        updateTypeSelection()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatSearchResultCell.self, forCellReuseIdentifier: "ChatSearchResultCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = ScreenAdapter.scaleH(64)
        tableView.backgroundColor = .themeBg
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(68), bottom: 0, right: 0)
        view.addSubview(tableView)

        activityIndicator.color = .themeTextSecondary
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .themeTextSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
    }

    private func setupLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        typeScrollView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }
        typeStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(typeScrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.leading.greaterThanOrEqualToSuperview().offset(ScreenAdapter.scaleW(32))
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(32))
        }
    }

    // MARK: - 类型切换
    @objc private func typeTapped(_ sender: UIButton) {
        guard let type = SearchType(rawValue: sender.tag), type != currentType else { return }
        currentType = type
        updateTypeSelection()
        performSearch(reset: true)
    }

    private func updateTypeSelection() {
        for sub in typeStackView.arrangedSubviews {
            guard let btn = sub as? UIButton, let type = SearchType(rawValue: btn.tag) else { continue }
            let selected = type == currentType
            btn.setTitleColor(selected ? .white : .themeTextPrimary, for: .normal)
            btn.backgroundColor = selected ? .themeColorPrimary : .themeBgCard
        }
    }

    private func matchesType(_ item: ChatSearchResult) -> Bool {
        switch currentType {
        case .all:
            return true
        case .image:
            return item.type == 2
        case .voice:
            return item.type == 3
        case .video:
            return item.type == 4
        case .file:
            return item.type == 5
        case .link:
            let lower = item.content.lowercased()
            return item.type == 1 && (lower.contains("http://") || lower.contains("https://"))
        }
    }

    // MARK: - 搜索
    private func performSearch(reset: Bool) {
        let kw = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !kw.isEmpty else {
            results = []
            hasMore = false
            tableView.reloadData()
            refreshEmptyState()
            return
        }
        guard !isLoading else { return }
        if reset {
            page = 1
            hasMore = false
        }
        isLoading = true
        emptyLabel.isHidden = true
        activityIndicator.startAnimating()
        let requestPage = page

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let resp = try await APIClient.shared.requestRaw(.globalSearch(keyword: kw, page: requestPage))
                let parsed = self.parseResults(resp)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.activityIndicator.stopAnimating()
                    if requestPage == 1 {
                        self.results = parsed
                    } else {
                        let existing = Set(self.results.map { $0.messageId })
                        self.results.append(contentsOf: parsed.filter { !existing.contains($0.messageId) })
                    }
                    self.hasMore = parsed.count >= self.pageSize
                    if self.hasMore {
                        self.page = requestPage + 1
                    }
                    self.tableView.reloadData()
                    self.refreshEmptyState()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.activityIndicator.stopAnimating()
                    AppUtility.showToast("搜索失败")
                    self.refreshEmptyState()
                }
            }
        }
    }

    /// 解析 globalSearch 响应，仅保留本会话消息并按所选类型过滤
    private func parseResults(_ resp: [String: Any]) -> [ChatSearchResult] {
        guard let data = resp["data"] as? [String: Any],
              let messages = data["messages"] as? [[String: Any]] else {
            return []
        }
        var list: [ChatSearchResult] = []
        for dict in messages {
            // 服务端返回的消息含内嵌 channel 对象（对齐安卓 GlobalMessage）
            let channel = dict["channel"] as? [String: Any] ?? [:]
            let cid = channel["channel_id"] as? String ?? ""
            guard cid == channelId else { continue }

            let type = (dict["type"] as? NSNumber)?.intValue ?? 1
            let content = dict["content"] as? String ?? ""

            let messageId: String
            if let s = dict["message_id"] as? String {
                messageId = s
            } else if let n = dict["message_id"] as? NSNumber {
                messageId = n.stringValue
            } else if let n = dict["message_seq"] as? NSNumber {
                messageId = n.stringValue
            } else {
                messageId = ""
            }

            var timeString = dict["created_at"] as? String ?? ""
            if timeString.isEmpty, let ts = (dict["timestamp"] as? NSNumber)?.int64Value {
                let ms = ts > 10_000_000_000 ? ts : ts * 1000
                timeString = AppUtility.formatTimestamp(ms)
            }

            let item = ChatSearchResult(
                messageId: messageId,
                fromUID: dict["from_uid"] as? String ?? "",
                fromName: dict["from_name"] as? String ?? "",
                content: content,
                type: type,
                timeString: timeString
            )
            guard matchesType(item) else { continue }
            list.append(item)
        }
        return list
    }

    // MARK: - 空状态
    private func refreshEmptyState() {
        if !results.isEmpty {
            emptyLabel.isHidden = true
            return
        }
        emptyLabel.isHidden = false
        emptyLabel.text = keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "输入关键词搜索聊天记录"
            : "未找到相关聊天记录"
    }

    // MARK: - 跳转聊天页
    private func navigateToChat() {
        let chatVC = ChatViewController(channelId: channelId, title: channelTitle, channelType: channelType)
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension ChatSearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.keyword = searchText
            self.performSearch(reset: true)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchTimer?.invalidate()
        keyword = searchBar.text ?? ""
        performSearch(reset: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ChatSearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatSearchResultCell", for: indexPath) as! ChatSearchResultCell
        cell.configure(item: results[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 滚动到底部自动加载更多
        guard indexPath.row == results.count - 1, hasMore, !isLoading,
              !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        performSearch(reset: false)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigateToChat()
    }
}

// MARK: - 搜索结果 Cell（发送者头像 + 昵称 + 内容摘要 + 时间）
private class ChatSearchResultCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let contentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite

        let avatarSize = ScreenAdapter.scaleW(40)
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .themeBgCard

        nameLabel.font = ScreenAdapter.mediumFont(15)
        nameLabel.textColor = .themeTextPrimary

        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .themeTextTertiary
        timeLabel.textAlignment = .right

        contentLabel.font = ScreenAdapter.font(14)
        contentLabel.textColor = .themeTextSecondary
        contentLabel.numberOfLines = 2

        contentView.addSubviews(avatarView, nameLabel, timeLabel, contentLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.width.height.equalTo(avatarSize)
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(10))
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(avatarView)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalTo(nameLabel)
        }
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(10))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: ChatSearchViewController.ChatSearchResult) {
        let displayName = item.fromName.isEmpty ? item.fromUID : item.fromName
        nameLabel.text = displayName
        contentLabel.text = item.summary
        timeLabel.text = item.timeString
        AppUtility.loadChannelAvatar(channelId: item.fromUID, channelType: 1, name: displayName, into: avatarView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.kf.cancelDownloadTask()
        avatarView.image = nil
    }
}
