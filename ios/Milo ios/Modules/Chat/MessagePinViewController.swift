import UIKit
import SnapKit
import Kingfisher

// MARK: - 置顶消息页（对标 Android MessagePinActivity）
class MessagePinViewController: UIViewController {

    // MARK: - 数据模型
    private struct PinnedMessage {
        let messageId: String
        let content: String
        let senderUid: String
        let senderName: String
        let timestamp: Int64 // 毫秒

        var timeString: String {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
            let formatter = DateFormatter()
            if Calendar.current.isDateInToday(date) {
                formatter.dateFormat = "HH:mm"
            } else if Calendar.current.isDateInYesterday(date) {
                formatter.dateFormat = "'昨天' HH:mm"
            } else {
                formatter.dateFormat = "MM-dd HH:mm"
            }
            return formatter.string(from: date)
        }
    }

    // MARK: - 属性
    private let channelId: String
    private let channelType: Int
    private var pinnedMessages: [PinnedMessage] = []

    private var storageKey: String {
        return "pinned_messages_\(channelType)_\(channelId)"
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无置顶消息"
        label.font = ScreenAdapter.font(15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - 初始化
    init(channelId: String, channelType: Int = 1) {
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
        title = "置顶消息"
        view.backgroundColor = .themeBackground
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI
    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessagePinCell.self, forCellReuseIdentifier: "MessagePinCell")
        tableView.rowHeight = ScreenAdapter.scaleH(64)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - 数据
    private func loadData() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] {
            pinnedMessages = saved.map {
                PinnedMessage(
                    messageId: $0["message_id"] as? String ?? "",
                    content: $0["content"] as? String ?? "",
                    senderUid: $0["sender_uid"] as? String ?? "",
                    senderName: $0["sender_name"] as? String ?? "",
                    timestamp: $0["timestamp"] as? Int64 ?? 0
                )
            }
        }
        // 按置顶时间倒序
        pinnedMessages.sort { $0.timestamp > $1.timestamp }
        emptyLabel.isHidden = !pinnedMessages.isEmpty
        tableView.reloadData()
    }

    private func persist() {
        let arr: [[String: Any]] = pinnedMessages.map {
            [
                "message_id": $0.messageId,
                "content": $0.content,
                "sender_uid": $0.senderUid,
                "sender_name": $0.senderName,
                "timestamp": $0.timestamp
            ]
        }
        UserDefaults.standard.set(arr, forKey: storageKey)
    }

    // MARK: - 取消置顶（调用接口/本地存储）
    private func unpinMessage(at index: Int) {
        pinnedMessages.remove(at: index)
        persist()
        emptyLabel.isHidden = !pinnedMessages.isEmpty
        tableView.reloadData()
        AppUtility.showToast("已取消置顶")
    }

    // MARK: - 跳转定位到聊天消息
    private func jumpToMessage(_ message: PinnedMessage) {
        // 若导航栈中已有该会话的聊天页则直接返回定位，否则新建聊天页
        if let nav = navigationController,
           let chatVC = nav.viewControllers.first(where: {
               ($0 as? ChatViewController)?.channelId == channelId
           }) {
            nav.popToViewController(chatVC, animated: true)
        } else {
            let chatVC = ChatViewController(channelId: channelId, title: "", channelType: channelType)
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension MessagePinViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pinnedMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessagePinCell", for: indexPath) as! MessagePinCell
        let msg = pinnedMessages[indexPath.row]
        cell.configure(senderUid: msg.senderUid, senderName: msg.senderName, content: msg.content, time: msg.timeString)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        jumpToMessage(pinnedMessages[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let unpin = UIContextualAction(style: .destructive, title: "取消置顶") { [weak self] _, _, completion in
            self?.unpinMessage(at: indexPath.row)
            completion(true)
        }
        unpin.image = UIImage(systemName: "pin.slash")
        return UISwipeActionsConfiguration(actions: [unpin])
    }
}

// MARK: - 置顶消息 Cell（头像 + 昵称 + 内容摘要 + 置顶时间）
class MessagePinCell: UITableViewCell {

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = ScreenAdapter.scaleW(20)
        iv.backgroundColor = .systemGray5
        return iv
    }()

    private let pinIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "pin.fill"))
        iv.tintColor = .themePrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = ScreenAdapter.font(15)
        label.textColor = .label
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = ScreenAdapter.font(13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = ScreenAdapter.font(12)
        label.textColor = .tertiaryLabel
        label.textAlignment = .right
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubviews(avatarImageView, pinIcon, nameLabel, contentLabel, timeLabel)

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }

        pinIcon.snp.makeConstraints { make in
            make.trailing.equalTo(avatarImageView).offset(ScreenAdapter.scaleW(2))
            make.bottom.equalTo(avatarImageView).offset(ScreenAdapter.scaleW(2))
            make.width.height.equalTo(ScreenAdapter.scaleW(14))
        }

        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.top.equalTo(avatarImageView)
            make.width.greaterThanOrEqualTo(ScreenAdapter.scaleW(60))
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(avatarImageView)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }

        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(8))
        }
    }

    func configure(senderUid: String, senderName: String, content: String, time: String) {
        nameLabel.text = senderName.isEmpty ? senderUid : senderName
        contentLabel.text = content
        timeLabel.text = time
        AppUtility.loadChannelAvatar(channelId: senderUid, channelType: 1, name: nameLabel.text ?? "", into: avatarImageView)
        if senderName.isEmpty {
            AppUtility.displayName(for: senderUid) { [weak self] name in
                self?.nameLabel.text = name
            }
        }
    }
}
