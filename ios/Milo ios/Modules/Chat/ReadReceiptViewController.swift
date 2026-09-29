//
//  ReadReceiptViewController.swift
//  Milo
//
//  群聊消息已读/未读详情页
//  类似微信的消息回执列表，显示已读和未读成员
//

import UIKit
import SnapKit
import Kingfisher

// MARK: - 已读回执数据模型
struct ReadReceipt {
    let uid: String
    let name: String
    let avatar: String?
    let isRead: Bool
    let readTime: Int64?

    var avatarURL: URL? {
        guard let avatar = avatar, !avatar.isEmpty else { return nil }
        if avatar.hasPrefix("http") {
            return URL(string: avatar)
        }
        return URL(string: APIConfig.apiBaseURL + "/" + avatar)
    }

    var readTimeString: String {
        guard let time = readTime, time > 0 else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(time / 1000))
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨天 HH:mm".replacingOccurrences(of: "HH:mm", with: {
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                return f.string(from: date)
            }())
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: date)
    }
}

// MARK: - 已读回执列表页
class ReadReceiptViewController: UIViewController {

    // MARK: - 属性
    private let messageID: String
    private let groupID: String
    private var readList: [ReadReceipt] = []
    private var unreadList: [ReadReceipt] = []

    private var currentTab: Int = 0 // 0: 已读, 1: 未读

    // MARK: - UI 组件
    private let segmentControl: UISegmentedControl = {
        let items = [AppStrings.Common.all, AppStrings.Common.all]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = .clear
        return sc
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let bottomStatsView = UIView()
    private let statsLabel = UILabel()

    // MARK: - 初始化
    init(messageID: String, groupID: String) {
        self.messageID = messageID
        self.groupID = groupID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMockData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI 设置
    private func setupUI() {
        title = "消息回执"
        view.backgroundColor = .themeBg

        // 导航栏返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        // 分段控件作为 titleView
        setupSegmentControl()
        navigationItem.titleView = segmentControl

        // 列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ReadReceiptCell.self, forCellReuseIdentifier: "ReadReceiptCell")
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 64, bottom: 0, right: 0)
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 56
        view.addSubview(tableView)

        // 底部统计栏
        setupBottomStatsView()

        // 布局
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomStatsView.snp.top)
        }

        bottomStatsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(44)
        }
    }

    private func setupSegmentControl() {
        // 更新分段标题（带人数）
        updateSegmentTitles()
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        // 样式调整
        if #available(iOS 13.0, *) {
            segmentControl.selectedSegmentTintColor = .themeColorPrimary
            segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.themeTextSecondary], for: .normal)
        }
    }

    private func setupBottomStatsView() {
        bottomStatsView.backgroundColor = .themeBgWhite
        bottomStatsView.layer.borderWidth = 0.5
        bottomStatsView.layer.borderColor = UIColor.themeSeparatorLight.cgColor

        statsLabel.font = ScreenAdapter.font(13)
        statsLabel.textColor = .themeTextTertiary
        statsLabel.textAlignment = .center
        bottomStatsView.addSubview(statsLabel)

        statsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        updateStatsText()
    }

    private func updateSegmentTitles() {
        let readTitle = "已读 (\(readList.count))"
        let unreadTitle = "未读 (\(unreadList.count))"
        segmentControl.setTitle(readTitle, forSegmentAt: 0)
        segmentControl.setTitle(unreadTitle, forSegmentAt: 1)
    }

    private func updateStatsText() {
        let text = "已读 \(readList.count) 人，未读 \(unreadList.count) 人"
        statsLabel.text = text
    }

    // MARK: - 数据加载（模拟数据）
    private func loadMockData() {
        // 模拟已读成员
        let readNames = ["张三", "李四", "王五", "赵六", "钱七", "孙八"]
        readList = readNames.enumerated().map { index, name in
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000) - Int64(index * 300000)
            return ReadReceipt(
                uid: "read_\(index)",
                name: name,
                avatar: nil,
                isRead: true,
                readTime: timestamp
            )
        }

        // 模拟未读成员
        let unreadNames = ["周九", "吴十", "郑十一", "王十二"]
        unreadList = unreadNames.enumerated().map { index, name in
            return ReadReceipt(
                uid: "unread_\(index)",
                name: name,
                avatar: nil,
                isRead: false,
                readTime: nil
            )
        }

        updateSegmentTitles()
        updateStatsText()
        tableView.reloadData()
    }

    // MARK: - 事件处理
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        currentTab = sender.selectedSegmentIndex
        tableView.reloadData()

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ReadReceiptViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let list = currentTab == 0 ? readList : unreadList
        return list.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadReceiptCell", for: indexPath) as! ReadReceiptCell
        let list = currentTab == 0 ? readList : unreadList
        let receipt = list[indexPath.row]
        cell.configure(with: receipt)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 可以跳转到成员详情页
    }
}

// MARK: - 已读回执 Cell
class ReadReceiptCell: UITableViewCell {

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.backgroundColor = .systemGray5
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = .systemGray4
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = ScreenAdapter.font(16)
        label.textColor = .themeTextPrimary
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = ScreenAdapter.font(13)
        label.textColor = .themeTextTertiary
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
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite

        contentView.addSubviews(avatarImageView, nameLabel, statusLabel)

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(statusLabel.snp.leading).offset(-8)
        }

        statusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with receipt: ReadReceipt) {
        nameLabel.text = receipt.name

        if receipt.isRead {
            statusLabel.text = receipt.readTimeString
            statusLabel.textColor = .themeTextTertiary
        } else {
            statusLabel.text = "未读"
            statusLabel.textColor = .themeTextHint
        }

        // 加载头像
        if let url = receipt.avatarURL {
            avatarImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemGray4
        }
    }
}
