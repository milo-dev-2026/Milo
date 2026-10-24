import UIKit
import SnapKit
import Kingfisher
import WuKongIMSDK

// MARK: - 按日期搜索（对标 Android SearchWithDateActivity）
/// 日期选择页：顶部日历选择器，选择日期后展示该日期的所有消息（按时间升序），下拉加载更多历史消息。
class SearchWithDateViewController: UIViewController {

    // MARK: - 属性
    private let channelId: String
    private let channelType: Int
    private var allMessages: [SearchDateMessage] = []
    private var filteredMessages: [SearchDateMessage] = []
    private var selectedDate: Date = Date()
    private var oldestSeq: UInt32 = 0
    private var isLoading = false
    private var hasMore = true

    private let datePicker = UIDatePicker()
    private let dateCaptionLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "该日期没有消息记录"
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
        title = "日期"
        view.backgroundColor = .themeBg
        setupUI()
        loadInitial()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI
    private func setupUI() {
        // 日历/日期选择器
        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        }
        datePicker.maximumDate = Date()
        datePicker.locale = Locale(identifier: "zh_CN")
        datePicker.tintColor = .themeColorPrimary
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        view.addSubview(datePicker)

        // 当前选中日期说明
        dateCaptionLabel.font = ScreenAdapter.mediumFont(14)
        dateCaptionLabel.textColor = .themeTextSecondary
        dateCaptionLabel.textAlignment = .center
        view.addSubview(dateCaptionLabel)

        // 消息列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchDateMessageCell.self, forCellReuseIdentifier: "SearchDateMessageCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = ScreenAdapter.scaleH(56)
        tableView.backgroundColor = .themeBg
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(16), bottom: 0, right: 0)
        tableView.alwaysBounceVertical = true
        view.addSubview(tableView)

        refreshControl.addTarget(self, action: #selector(loadMore), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(emptyLabel)

        datePicker.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(8))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
        }
        dateCaptionLabel.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(20))
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(dateCaptionLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }

        updateDateCaption()
    }

    // MARK: - 日期选择
    @objc private func dateChanged() {
        selectedDate = datePicker.date
        updateDateCaption()
        reloadFiltered()
    }

    private func updateDateCaption() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        dateCaptionLabel.text = "\(formatter.string(from: selectedDate)) 的消息"
    }

    // MARK: - 数据加载
    private func loadInitial() {
        guard !channelId.isEmpty else {
            emptyLabel.isHidden = false
            return
        }
        isLoading = true
        IMManager.shared.pullLastMessages(channelId: channelId, channelType: channelType, limit: 100) { [weak self] wkMessages, _ in
            guard let self = self else { return }
            self.isLoading = false
            self.appendMessages(wkMessages ?? [])
            self.reloadFiltered()
        }
    }

    @objc private func loadMore() {
        guard !channelId.isEmpty, hasMore, !isLoading, oldestSeq > 0 else {
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
            self.reloadFiltered()
        }
    }

    /// 合并历史消息（去重）
    private func appendMessages(_ wkMessages: [WKMessage]) {
        let newItems = wkMessages.map { msg in
            SearchDateMessage(
                messageId: String(msg.messageId),
                summary: wkMessageSummary(msg),
                timestamp: Int64(msg.timestamp) * 1000,
                messageSeq: msg.messageSeq
            )
        }
        allMessages.append(contentsOf: newItems)
        var seen = Set<String>()
        allMessages = allMessages.filter { seen.insert($0.messageId).inserted }
        if let minSeq = wkMessages.map({ $0.messageSeq }).min(), minSeq > 0 {
            oldestSeq = minSeq
        }
    }

    /// 按选中日期过滤，并按时间升序排列
    private func reloadFiltered() {
        let calendar = Calendar.current
        let selected = selectedDate
        filteredMessages = allMessages.filter { item in
            let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp / 1000))
            return calendar.isDate(date, inSameDayAs: selected)
        }
        filteredMessages.sort { $0.timestamp < $1.timestamp }
        tableView.reloadData()
        emptyLabel.isHidden = !filteredMessages.isEmpty
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SearchWithDateViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchDateMessageCell", for: indexPath) as! SearchDateMessageCell
        cell.configure(message: filteredMessages[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - 日期消息数据
fileprivate struct SearchDateMessage {
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

// MARK: - 日期消息 Cell（内容摘要 + 时间）
private class SearchDateMessageCell: UITableViewCell {

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
            make.width.greaterThanOrEqualTo(ScreenAdapter.scaleW(40))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: SearchDateMessage) {
        contentLabel.text = message.summary
        let date = Date(timeIntervalSince1970: TimeInterval(message.timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: date)
    }
}
