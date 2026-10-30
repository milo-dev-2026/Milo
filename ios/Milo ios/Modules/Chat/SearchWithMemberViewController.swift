import UIKit
import SnapKit
import Kingfisher
import WuKongIMSDK

// MARK: - 按成员搜索（对标 Android SearchWithMemberActivity）
/// 群成员列表页：展示群成员（单聊展示对方与自己），点击成员进入该成员发送的消息列表。
class SearchWithMemberViewController: UIViewController {

    // MARK: - 属性
    private let channelId: String
    private let channelType: Int
    private var members: [SearchMemberEntry] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无成员"
        label.font = ScreenAdapter.font(15)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - 初始化
    init(channelId: String, channelType: Int) {
        self.channelId = channelId
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "成员"
        view.backgroundColor = .themeBg
        setupUI()
        loadMembers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI
    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchMemberCell.self, forCellReuseIdentifier: "SearchMemberCell")
        tableView.rowHeight = ScreenAdapter.scaleH(56)
        tableView.backgroundColor = .themeBg
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(68), bottom: 0, right: 0)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        activityIndicator.color = .themeTextSecondary
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
    }

    // MARK: - 数据加载
    private func loadMembers() {
        guard !channelId.isEmpty else {
            emptyLabel.isHidden = false
            return
        }

        if channelType == 2 {
            // 群聊：拉取群成员列表
            activityIndicator.startAnimating()
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let decoded: [GroupMember] = try await APIClient.shared.requestFlexible(
                        .getGroupMembers(groupId: self.channelId, page: 1, size: 1000, keyword: nil)
                    )
                    let list = decoded.filter { ($0.isDeleted ?? 0) == 0 }
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.members = list.map { member in
                            let nick = member.nickname ?? ""
                            return SearchMemberEntry(uid: member.uid, name: nick.isEmpty ? member.name : nick)
                        }
                        self.tableView.reloadData()
                        self.emptyLabel.isHidden = !self.members.isEmpty
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        AppUtility.showToast("加载成员失败")
                        self.emptyLabel.isHidden = !self.members.isEmpty
                    }
                }
            }
        } else {
            // 单聊：展示对方与自己
            var list: [SearchMemberEntry] = []
            let peerName = IMManager.shared.getChannelInfo(channelId: channelId, channelType: 1)?.name ?? ""
            list.append(SearchMemberEntry(uid: channelId, name: peerName.isEmpty ? channelId : peerName))
            let myUID = UserDefaults.standard.string(forKey: "uid") ?? ""
            if !myUID.isEmpty {
                let myName = IMManager.shared.getChannelInfo(channelId: myUID, channelType: 1)?.name ?? ""
                list.append(SearchMemberEntry(uid: myUID, name: myName.isEmpty ? "我" : myName))
            }
            members = list
            tableView.reloadData()
            emptyLabel.isHidden = !members.isEmpty
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SearchWithMemberViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchMemberCell", for: indexPath) as! SearchMemberCell
        cell.configure(member: members[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let member = members[indexPath.row]
        let vc = SearchMemberMessagesViewController(channelId: channelId, channelType: channelType, member: member)
navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 成员数据
fileprivate struct SearchMemberEntry {
    let uid: String
    let name: String
}

// MARK: - 成员 Cell（头像 + 昵称）
private class SearchMemberCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        accessoryType = .disclosureIndicator

        let avatarSize = ScreenAdapter.scaleW(40)
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .themeBgCard

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .themeTextPrimary

        contentView.addSubviews(avatarView, nameLabel)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.kf.cancelDownloadTask()
        avatarView.image = nil
    }

    func configure(member: SearchMemberEntry) {
        nameLabel.text = member.name
        AppUtility.loadChannelAvatar(channelId: member.uid, channelType: 1, name: member.name, into: avatarView)
    }
}

// MARK: - 成员消息数据
fileprivate struct SearchMemberMessage {
    let messageId: String
    let summary: String
    let timestamp: Int64 // 毫秒
    let messageSeq: UInt32
}

// MARK: - WKMessage 内容摘要
fileprivate func wkMessageSummary(_ msg: WKMessage) -> String {
    let contentType = Int(msg.content.realContentType)
    switch contentType {
    case 1:
        return (msg.content as? WKTextContent)?.content ?? ""
    case 2:
        return "[图片]"
    case 3:
        return "[语音]"
    case 4:
        return "[视频]"
    case 5:
        let name = (msg.content as? WKFileMessageContent)?.fileName ?? ""
        return name.isEmpty ? "[文件]" : "[文件] \(name)"
    case 6:
        return "[位置]"
    case 7:
        return "[名片]"
    case 100:
        return "[笔记]"
    default:
        return (msg.content as? WKTextContent)?.content ?? ""
    }
}

// MARK: - 历史消息时间格式化（毫秒时间戳 → 显示文本）
fileprivate func formatHistoryTime(_ timestampMs: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestampMs / 1000))
    let formatter = DateFormatter()
    if Calendar.current.isDateInToday(date) {
        formatter.dateFormat = "HH:mm"
    } else {
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
    }
    return formatter.string(from: date)
}

// MARK: - 成员消息列表页
/// 展示指定成员在该会话中发送的所有消息（内容摘要 + 时间），下拉加载更多历史消息。
private class SearchMemberMessagesViewController: UIViewController {

    private let channelId: String
    private let channelType: Int
    private let member: SearchMemberEntry
    private var messages: [SearchMemberMessage] = []
    private var oldestSeq: UInt32 = 0
    private var isLoading = false
    private var hasMore = true

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无消息记录"
        label.font = ScreenAdapter.font(15)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    init(channelId: String, channelType: Int, member: SearchMemberEntry) {
        self.channelId = channelId
        self.channelType = channelType
        self.member = member
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = member.name
        view.backgroundColor = .themeBg
        setupUI()
        loadInitial()
    }

    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchMemberMessageCell.self, forCellReuseIdentifier: "SearchMemberMessageCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = ScreenAdapter.scaleH(56)
        tableView.backgroundColor = .themeBg
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(16), bottom: 0, right: 0)
        tableView.alwaysBounceVertical = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        refreshControl.addTarget(self, action: #selector(loadMore), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
    }

    // MARK: - 数据加载
    private func loadInitial() {
        isLoading = true
        IMManager.shared.pullLastMessages(channelId: channelId, channelType: channelType, limit: 100) { [weak self] wkMessages, _ in
            guard let self = self else { return }
            self.isLoading = false
            self.appendMessages(wkMessages ?? [])
            self.emptyLabel.isHidden = !self.messages.isEmpty
        }
    }

    @objc private func loadMore() {
        guard hasMore, !isLoading, oldestSeq > 0 else {
            refreshControl.endRefreshing()
            return
        }
        isLoading = true
        IMManager.shared.pullDownMessages(channelId: channelId, channelType: channelType, startOrderSeq: oldestSeq, limit: 100) { [weak self] wkMessages, _ in
            guard let self = self else { return }
            self.isLoading = false
            self.refreshControl.endRefreshing()
            guard let wkMessages = wkMessages, !wkMessages.isEmpty else {
                self.hasMore = false
                return
            }
            self.appendMessages(wkMessages)
        }
    }

    /// 筛选该成员发送的消息，合并去重后按时间升序
    private func appendMessages(_ wkMessages: [WKMessage]) {
        let filtered = wkMessages.filter { ($0.fromUid ?? "") == member.uid }
        let newItems = filtered.map { msg in
            SearchMemberMessage(
                messageId: String(msg.messageId),
                summary: wkMessageSummary(msg),
                timestamp: Int64(msg.timestamp) * 1000,
                messageSeq: msg.messageSeq
            )
        }
        messages.append(contentsOf: newItems)
        var seen = Set<String>()
        messages = messages.filter { seen.insert($0.messageId).inserted }
        messages.sort { $0.timestamp < $1.timestamp }
        if let minSeq = wkMessages.map({ $0.messageSeq }).min(), minSeq > 0 {
            oldestSeq = minSeq
        }
        tableView.reloadData()
    }
}

// MARK: - 成员消息列表 DataSource & Delegate
extension SearchMemberMessagesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchMemberMessageCell", for: indexPath) as! SearchMemberMessageCell
        cell.configure(message: messages[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - 成员消息 Cell（内容摘要 + 时间）
private class SearchMemberMessageCell: UITableViewCell {

    private let contentLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        selectionStyle = .none

        contentLabel.font = ScreenAdapter.font(15)
        contentLabel.textColor = .themeTextPrimary
        contentLabel.numberOfLines = 2

        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .themeTextTertiary
        timeLabel.textAlignment = .right

        contentView.addSubviews(contentLabel, timeLabel)
        contentLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(10))
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.top.equalTo(contentLabel)
            make.width.greaterThanOrEqualTo(ScreenAdapter.scaleW(48))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: SearchMemberMessage) {
        contentLabel.text = message.summary
        timeLabel.text = formatHistoryTime(message.timestamp)
    }
}
