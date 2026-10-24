//
//  SystemTeamViewController.swift
//  Milo
//
//  系统消息（对齐 Android WKSystemTeamActivity）
//  功能：系统通知消息列表（公告/安全/更新/活动）、未读标记、标记全部已读、消息详情
//

import UIKit
import SnapKit

// MARK: - 系统消息模型
/// 消息类型
enum SystemNoticeType: Int, Codable {
    case announcement = 0   // 系统公告
    case security = 1       // 安全提醒
    case update = 2         // 功能更新
    case activity = 3       // 活动通知

    var displayName: String {
        switch self {
        case .announcement: return "系统公告"
        case .security: return "安全提醒"
        case .update: return "功能更新"
        case .activity: return "活动通知"
        }
    }

    var iconName: String {
        switch self {
        case .announcement: return "megaphone.fill"
        case .security: return "shield.fill"
        case .update: return "arrow.triangle.2.circlepath"
        case .activity: return "party.popper.fill"
        }
    }

    var iconColor: UIColor {
        switch self {
        case .announcement: return .systemBlue
        case .security: return .systemRed
        case .update: return .systemGreen
        case .activity: return .systemOrange
        }
    }
}

/// 系统通知消息
struct SystemNotice: Codable {
    let id: String
    var type: SystemNoticeType
    var title: String
    var content: String
    var timestamp: Int64      // 毫秒时间戳
    var isRead: Bool
}

// MARK: - 系统消息控制器
class SystemTeamViewController: UIViewController {

    // MARK: - 常量
    private let storageKey = "system_team_messages"

    // MARK: - UI 组件
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    // MARK: - 数据
    private var notices: [SystemNotice] = []

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadNotices()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI 设置
    private func setupUI() {
        title = "系统消息"
        view.backgroundColor = .themeBackground

        // 返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        // 右上角"全部已读"
        let readAllBtn = UIBarButtonItem(
            title: "全部已读",
            style: .plain,
            target: self,
            action: #selector(markAllReadTapped)
        )
        readAllBtn.tintColor = .themePrimary
        navigationItem.rightBarButtonItem = readAllBtn

        // 列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SystemNoticeCell.self, forCellReuseIdentifier: "SystemNoticeCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = ScreenAdapter.scaleH(72)
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(76), bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 空列表
        emptyLabel.text = "暂无系统消息"
        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .themeTextSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - 数据加载 / 持久化
    private func loadNotices() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let list = try? JSONDecoder().decode([SystemNotice].self, from: data) {
            notices = list.sorted { $0.timestamp > $1.timestamp }
        } else {
            // 首次进入，生成演示数据
            notices = makeDefaultNotices()
            saveNotices()
        }
        updateEmptyState()
        tableView.reloadData()
    }

    private func saveNotices() {
        if let data = try? JSONEncoder().encode(notices) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !notices.isEmpty
    }

    /// 默认演示数据
    private func makeDefaultNotices() -> [SystemNotice] {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return [
            SystemNotice(
                id: UUID().uuidString,
                type: .announcement,
                title: "欢迎使用 Milo",
                content: "感谢您使用 Milo 即时通讯。如有任何问题，请通过设置-帮助与反馈联系我们。",
                timestamp: now - 3600_000,
                isRead: false
            ),
            SystemNotice(
                id: UUID().uuidString,
                type: .security,
                title: "账号安全提醒",
                content: "检测到您的账号在新设备上登录。如非本人操作，请立即修改密码并开启二次验证。",
                timestamp: now - 7200_000,
                isRead: false
            ),
            SystemNotice(
                id: UUID().uuidString,
                type: .update,
                title: "新版本发布",
                content: "Milo V1.2.0 已发布，新增贴纸商店、消息翻译、群接龙等功能，欢迎体验。",
                timestamp: now - 86400_000,
                isRead: true
            ),
            SystemNotice(
                id: UUID().uuidString,
                type: .activity,
                title: "五一活动上线",
                content: "五一劳动节专属活动已开启，邀请好友注册即可领取限定头像框，快来参与吧！",
                timestamp: now - 172800_000,
                isRead: true
            )
        ]
    }

    // MARK: - 按钮事件
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 标记全部已读
    @objc private func markAllReadTapped() {
        guard notices.contains(where: { !$0.isRead }) else {
            AppUtility.showToast("没有未读消息")
            return
        }
        for index in notices.indices {
            notices[index].isRead = true
        }
        saveNotices()
        tableView.reloadData()
        AppUtility.showToast("已全部标记为已读")
    }

    /// 显示消息详情
    private func showDetail(_ notice: SystemNotice) {
        // 标记已读
        if !notice.isRead,
           let index = notices.firstIndex(where: { $0.id == notice.id }) {
            notices[index].isRead = true
            saveNotices()
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }

        let alert = UIAlertController(
            title: notice.title,
            message: notice.content,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppStrings.Common.gotIt, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SystemTeamViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SystemNoticeCell", for: indexPath) as! SystemNoticeCell
        cell.configure(with: notices[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showDetail(notices[indexPath.row])
    }
}

// MARK: - 系统消息 Cell
class SystemNoticeCell: UITableViewCell {

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadDot = UIView()
    private let typeTagLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite

        // 图标容器
        iconContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        iconContainer.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImageView)

        // 标题
        titleLabel.font = ScreenAdapter.mediumFont(16)
        titleLabel.textColor = .label

        // 类型标签
        typeTagLabel.font = ScreenAdapter.font(10)
        typeTagLabel.textAlignment = .center
        typeTagLabel.layer.cornerRadius = ScreenAdapter.scaleW(3)
        typeTagLabel.clipsToBounds = true

        // 内容摘要
        contentLabel.font = ScreenAdapter.font(13)
        contentLabel.textColor = .themeTextSecondary
        contentLabel.numberOfLines = 2

        // 时间
        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .themeTextTertiary
        timeLabel.textAlignment = .right

        // 未读红点
        unreadDot.backgroundColor = .systemRed
        unreadDot.layer.cornerRadius = ScreenAdapter.scaleW(4)
        unreadDot.isHidden = true

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, typeTagLabel])
        titleStack.axis = .horizontal
        titleStack.spacing = ScreenAdapter.scaleW(6)
        titleStack.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [titleStack, contentLabel])
        textStack.axis = .vertical
        textStack.spacing = ScreenAdapter.scaleH(4)

        contentView.addSubviews(iconContainer, textStack, timeLabel, unreadDot)

        let iconSize = ScreenAdapter.scaleW(44)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.width.height.equalTo(iconSize)
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(22))
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(iconContainer)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(12))
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainer)
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
        }

        unreadDot.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(12))
            make.width.height.equalTo(ScreenAdapter.scaleW(8))
        }
    }

    // MARK: - 配置
    func configure(with notice: SystemNotice) {
        titleLabel.text = notice.title
        contentLabel.text = notice.content
        timeLabel.text = AppUtility.formatTimestamp(notice.timestamp)

        // 类型标签
        typeTagLabel.text = " \(notice.type.displayName) "
        typeTagLabel.textColor = notice.type.iconColor
        typeTagLabel.backgroundColor = notice.type.iconColor.withAlphaComponent(0.12)

        // 图标
        iconImageView.image = UIImage(systemName: notice.type.iconName)
        iconImageView.tintColor = notice.type.iconColor
        iconContainer.backgroundColor = notice.type.iconColor.withAlphaComponent(0.12)

        // 未读标记
        unreadDot.isHidden = notice.isRead
        titleLabel.textColor = notice.isRead ? .themeTextSecondary : .label
    }
}
