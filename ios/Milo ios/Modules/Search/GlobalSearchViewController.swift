import UIKit
import SnapKit
import Kingfisher

// MARK: - 全局搜索结果项类型
enum GlobalSearchItemType {
    case sectionHeader(String)
    case spacer
    case channel(GlobalChannel)
    case message(GlobalMessage)
    case searchUserEntry(String)
}

// MARK: - 全局搜索数据模型
struct GlobalChannel {
    let channelId: String
    let name: String
    let avatar: String?
    let channelType: Int
}

struct GlobalMessage {
    let messageId: String
    let channelId: String
    let channelName: String
    let fromUID: String
    let fromName: String
    let avatar: String?
    let content: String
    let createdAt: String
    let orderSeq: Int
}

// MARK: - 全局搜索页
class GlobalSearchViewController: UIViewController {

    private let searchField = UITextField()
    private let cancelButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyLabel = UILabel()

    private var items: [GlobalSearchItemType] = []
    private var currentPage = 1
    private var currentKeyword = ""
    private var isSearching = false
    private var isLoadingMore = false
    private var hasMoreMessages = false
    private var searchDebounceTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全局搜索"
        view.backgroundColor = .themeBackground
        setupUI()
    }

    deinit {
        searchDebounceTimer?.invalidate()
    }

    // MARK: - UI
    private func setupUI() {
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .secondaryLabel
        searchIcon.contentMode = .scaleAspectFit

        searchField.placeholder = "搜索"
        searchField.font = ScreenAdapter.font(15)
        searchField.borderStyle = .none
        searchField.returnKeyType = .search
        searchField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        searchField.delegate = self

        let searchContainer = UIView()
        searchContainer.backgroundColor = .systemGray6
        searchContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(8))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(18))
        }
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(ScreenAdapter.scaleW(6))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(8))
            make.top.bottom.equalToSuperview()
        }

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = ScreenAdapter.font(16)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let searchBar = UIView()
        searchBar.addSubview(searchContainer)
        searchBar.addSubview(cancelButton)
        searchContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(36))
        }
        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(searchContainer.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GlobalSectionHeaderCell.self, forCellReuseIdentifier: "SectionHeader")
        tableView.register(GlobalChannelCell.self, forCellReuseIdentifier: "Channel")
        tableView.register(GlobalMessageCell.self, forCellReuseIdentifier: "Message")
        tableView.register(GlobalSearchUserCell.self, forCellReuseIdentifier: "SearchUser")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Spacer")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56

        emptyLabel.text = "输入关键词开始搜索"
        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        activityIndicator.color = .secondaryLabel

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }

        searchField.becomeFirstResponder()
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        searchField.resignFirstResponder()
        dismiss(animated: true)
    }

    @objc private func textChanged() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if keyword.isEmpty {
                self.items = []
                self.tableView.reloadData()
                self.emptyLabel.text = "输入关键词开始搜索"
                self.emptyLabel.isHidden = false
            } else {
                self.currentKeyword = keyword
                self.currentPage = 1
                self.search()
            }
        }
    }

    // MARK: - 搜索
    private func search() {
        guard !isSearching else { return }
        isSearching = true
        hasMoreMessages = false
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true

        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.globalSearch(keyword: currentKeyword, page: currentPage))
                DispatchQueue.main.async {
                    self.isSearching = false
                    self.activityIndicator.stopAnimating()
                    self.parseSearchResult(resp, isLoadMore: false)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSearching = false
                    self.activityIndicator.stopAnimating()
                    self.emptyLabel.text = "搜索失败，请重试"
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    private func loadMoreMessages() {
        guard !isLoadingMore, hasMoreMessages else { return }
        isLoadingMore = true
        currentPage += 1

        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.globalSearch(keyword: currentKeyword, page: currentPage))
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    self.parseSearchResult(resp, isLoadMore: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    self.currentPage -= 1
                }
            }
        }
    }

    private func parseSearchResult(_ resp: [String: Any], isLoadMore: Bool) {
        guard let data = resp["data"] as? [String: Any] else {
            if !isLoadMore {
                emptyLabel.text = "无搜索结果"
                emptyLabel.isHidden = false
                items = []
                tableView.reloadData()
            }
            return
        }

        if isLoadMore {
            if let messages = data["messages"] as? [[String: Any]] {
                let msgs = messages.map { parseMessage($0) }
                if !msgs.isEmpty {
                    for msg in msgs {
                        items.append(.message(msg))
                    }
                    hasMoreMessages = msgs.count >= 20
                } else {
                    hasMoreMessages = false
                }
                tableView.reloadData()
            }
            return
        }

        var newItems: [GlobalSearchItemType] = []

        let friends = (data["friends"] as? [[String: Any]])?.map { parseChannel($0, type: 1) } ?? []
        let groups = (data["groups"] as? [[String: Any]])?.map { parseChannel($0, type: 2) } ?? []
        let messages = (data["messages"] as? [[String: Any]])?.map { parseMessage($0) } ?? []

        if !friends.isEmpty {
            newItems.append(.sectionHeader("好友"))
            for f in friends { newItems.append(.channel(f)) }
            newItems.append(.spacer)
        }

        if !groups.isEmpty {
            newItems.append(.sectionHeader("群聊"))
            for g in groups { newItems.append(.channel(g)) }
            newItems.append(.spacer)
        }

        newItems.append(.searchUserEntry(currentKeyword))
        newItems.append(.spacer)

        if !messages.isEmpty {
            newItems.append(.sectionHeader("聊天记录"))
            for m in messages { newItems.append(.message(m)) }
            hasMoreMessages = messages.count >= 20
        }

        items = newItems
        tableView.reloadData()

        if items.isEmpty {
            emptyLabel.text = "无搜索结果"
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
        }
    }

    private func parseChannel(_ dict: [String: Any], type: Int) -> GlobalChannel {
        GlobalChannel(
            channelId: dict["channel_id"] as? String ?? "",
            name: dict["name"] as? String ?? "",
            avatar: dict["avatar"] as? String,
            channelType: dict["channel_type"] as? Int ?? type
        )
    }

    private func parseMessage(_ dict: [String: Any]) -> GlobalMessage {
        GlobalMessage(
            messageId: dict["message_id"] as? String ?? "",
            channelId: dict["channel_id"] as? String ?? "",
            channelName: dict["channel_name"] as? String ?? "",
            fromUID: dict["from_uid"] as? String ?? "",
            fromName: dict["from_name"] as? String ?? "",
            avatar: dict["avatar"] as? String,
            content: dict["content"] as? String ?? "",
            createdAt: dict["created_at"] as? String ?? "",
            orderSeq: dict["order_seq"] as? Int ?? 0
        )
    }
}

// MARK: - UITableViewDataSource & Delegate
extension GlobalSearchViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]

        switch item {
        case .sectionHeader(let title):
            let cell = tableView.dequeueReusableCell(withIdentifier: "SectionHeader", for: indexPath) as! GlobalSectionHeaderCell
            cell.configure(title: title)
            return cell

        case .spacer:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Spacer", for: indexPath)
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.textLabel?.text = ""
            return cell

        case .channel(let channel):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Channel", for: indexPath) as! GlobalChannelCell
            cell.configure(channel: channel, keyword: currentKeyword)
            return cell

        case .message(let msg):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Message", for: indexPath) as! GlobalMessageCell
            cell.configure(msg: msg, keyword: currentKeyword)
            return cell

        case .searchUserEntry(let keyword):
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUser", for: indexPath) as! GlobalSearchUserCell
            cell.configure(keyword: keyword)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch items[indexPath.row] {
        case .spacer: return ScreenAdapter.scaleH(10)
        case .sectionHeader: return ScreenAdapter.scaleH(32)
        case .searchUserEntry: return ScreenAdapter.scaleH(48)
        case .channel: return ScreenAdapter.scaleH(56)
        case .message: return ScreenAdapter.scaleH(72)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]

        switch item {
        case .channel(let channel):
            let vc = ChatViewController(channelId: channel.channelId, title: channel.name)
            navigationController?.pushViewController(vc, animated: true)

        case .message(let msg):
            let vc = ChatViewController(channelId: msg.channelId, title: msg.channelName)
            navigationController?.pushViewController(vc, animated: true)

        case .searchUserEntry:
            let vc = SearchUserViewController()
            vc.searchKeyword = currentKeyword
            navigationController?.pushViewController(vc, animated: true)

        default:
            break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.height

        if offsetY > contentHeight - screenHeight - 100 {
            if hasMoreMessages && !isLoadingMore && !isSearching {
                loadMoreMessages()
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension GlobalSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Section Header Cell
private class GlobalSectionHeaderCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        label.font = ScreenAdapter.mediumFont(14)
        label.textColor = .secondaryLabel
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
        }
        backgroundColor = .systemGray6
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String) {
        label.text = title
    }
}

// MARK: - Channel Cell (好友/群聊)
private class GlobalChannelCell: UITableViewCell {
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(20)
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .systemGray5
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray3

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(channel: GlobalChannel, keyword: String) {
        nameLabel.attributedText = highlightKeyword(channel.name, keyword: keyword)

        if let avatarStr = channel.avatar, !avatarStr.isEmpty {
            let urlStr = avatarStr.hasPrefix("http") ? avatarStr : APIConfig.apiBaseURL + "/" + avatarStr
            if let url = URL(string: urlStr) {
                avatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
            }
        } else {
            let iconName = channel.channelType == 2 ? "person.3.fill" : "person.circle.fill"
            avatarView.image = UIImage(systemName: iconName)
            avatarView.tintColor = .systemGray3
        }
    }
}

// MARK: - Message Cell (聊天记录)
private class GlobalMessageCell: UITableViewCell {
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let contentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(20)
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .systemGray5
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray3

        nameLabel.font = ScreenAdapter.mediumFont(15)
        nameLabel.textColor = .label

        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .right

        contentLabel.font = ScreenAdapter.font(14)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 1

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(contentLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(8))
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(avatarView)
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalTo(nameLabel)
        }
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(8))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(msg: GlobalMessage, keyword: String) {
        nameLabel.text = msg.fromName.isEmpty ? msg.channelName : msg.fromName
        timeLabel.text = msg.createdAt
        contentLabel.attributedText = highlightKeyword(msg.content, keyword: keyword)

        if let avatarStr = msg.avatar, !avatarStr.isEmpty {
            let urlStr = avatarStr.hasPrefix("http") ? avatarStr : APIConfig.apiBaseURL + "/" + avatarStr
            if let url = URL(string: urlStr) {
                avatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
            }
        }
    }
}

// MARK: - Search User Entry Cell
private class GlobalSearchUserCell: UITableViewCell {
    private let iconView = UIImageView()
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        iconView.image = UIImage(systemName: "magnifyingglass")
        iconView.tintColor = .themePrimary
        iconView.contentMode = .scaleAspectFit

        label.font = ScreenAdapter.font(16)
        label.textColor = .themePrimary

        contentView.addSubview(iconView)
        contentView.addSubview(label)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(22))
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(keyword: String) {
        label.text = "查找用户"
    }
}

// MARK: - 关键词高亮
func highlightKeyword(_ text: String, keyword: String) -> NSAttributedString {
    let attr = NSMutableAttributedString(string: text)
    attr.addAttribute(.font, value: ScreenAdapter.font(16), range: NSRange(location: 0, length: attr.length))
    attr.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: attr.length))

    if keyword.isEmpty { return attr }

    let lowerText = text.lowercased()
    let lowerKeyword = keyword.lowercased()
    var searchRange = lowerText.startIndex..<lowerText.endIndex

    while let range = lowerText.range(of: lowerKeyword, options: [], range: searchRange) {
        let nsRange = NSRange(range, in: text)
        attr.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: nsRange)
        searchRange = range.upperBound..<lowerText.endIndex
    }

    return attr
}
