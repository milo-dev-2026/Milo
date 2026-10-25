//
//  FileHelperViewController.swift
//  Milo
//
//  文件传输助手（对齐 Android WKFileHelperActivity）
//  功能：文件传输记录列表（本地持久化）、发送文件/图片到文件传输助手频道、打开/分享文件
//

import UIKit
import SnapKit

// MARK: - 文件传输记录模型
/// 传输状态
enum FileTransferStatus: Int, Codable {
    case sending = 0    // 发送中
    case sent = 1       // 已发送
    case received = 2   // 已接收

    var displayText: String {
        switch self {
        case .sending: return "发送中"
        case .sent: return "已发送"
        case .received: return "已接收"
        }
    }
}

/// 文件传输记录
struct FileTransferRecord: Codable {
    let id: String
    var fileName: String
    var fileSize: Int64
    var timestamp: Int64          // 毫秒时间戳
    var status: FileTransferStatus
    var localPath: String?        // 本地文件路径（拍照/相册/文件选择后）
    var remoteURL: String?        // 上传后的远端地址
}

// MARK: - 文件传输助手控制器
class FileHelperViewController: UIViewController {

    /// 页面模式：文件传输助手 / 系统通知（复用同一页面）
    enum Mode {
        case fileHelper
        case systemNotice
    }

    // MARK: - 常量
    /// 文件传输助手频道（固定 channelId，对齐后端/Android 虚拟账号）
    private var channelId: String {
        return mode == .fileHelper ? "system_file_helper" : "system_notice"
    }
    private let channelType = 1
    private let storageKey = "file_helper_records"
    /// 系统通知复用系统消息本地存储（SystemTeamViewController 使用同一 Key）
    private let noticeStorageKey = "system_team_messages"

    // MARK: - 数据
    private let mode: Mode

    // MARK: - UI 组件
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    // MARK: - 数据
    private var records: [FileTransferRecord] = []
    private var notices: [SystemNotice] = []
    private var imagePicker: UIImagePickerController?

    // MARK: - 初始化
    init(mode: Mode = .fileHelper) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if mode == .fileHelper {
            loadRecords()
        } else {
            loadNotices()
        }
        ensureLocalConversation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    /// 保证本地会话记录存在（会话列表由会话模块统一展示）
    private func ensureLocalConversation() {
        if IMManager.shared.getConversation(channelId: channelId, channelType: channelType) == nil {
            IMManager.shared.recoveryConversation(channelId: channelId, channelType: channelType)
        }
    }

    // MARK: - UI 设置
    private func setupUI() {
        title = mode == .fileHelper ? "文件传输助手" : "系统通知"
        view.backgroundColor = .themeBackground

        // 导航栏返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        // 右上角 "+" 按钮（仅文件传输助手）
        if mode == .fileHelper {
            let addBtn = UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                style: .plain,
                target: self,
                action: #selector(addTapped)
            )
            addBtn.tintColor = .label
            navigationItem.rightBarButtonItem = addBtn
        }
        // 列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FileTransferCell.self, forCellReuseIdentifier: "FileTransferCell")
        tableView.register(SystemNoticeMessageCell.self, forCellReuseIdentifier: "SystemNoticeMessageCell")
        tableView.rowHeight = mode == .fileHelper ? ScreenAdapter.scaleH(72) : UITableView.automaticDimension
        tableView.estimatedRowHeight = ScreenAdapter.scaleH(72)
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(76), bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 空列表提示
        emptyLabel.text = mode == .fileHelper ? "暂无文件传输记录" : "暂无系统消息"
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
    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([FileTransferRecord].self, from: data) else {
            records = []
            updateEmptyState()
            return
        }
        // 按时间倒序
        records = list.sorted { $0.timestamp > $1.timestamp }
        updateEmptyState()
        tableView.reloadData()
    }

    private func loadNotices() {
        if let data = UserDefaults.standard.data(forKey: noticeStorageKey),
           let list = try? JSONDecoder().decode([SystemNotice].self, from: data) {
            notices = list.sorted { $0.timestamp > $1.timestamp }
        } else {
            notices = []
        }
        updateEmptyState()
        tableView.reloadData()
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func updateEmptyState() {
        let isEmpty = mode == .fileHelper ? records.isEmpty : notices.isEmpty
        emptyLabel.isHidden = !isEmpty
    }

    // MARK: - 按钮事件
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 右上角 "+"：弹出 拍照 / 相册 / 文件 选择
    @objc private func addTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "拍照", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        alert.addAction(UIAlertAction(title: "相册", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        alert.addAction(UIAlertAction(title: "文件", style: .default) { [weak self] _ in
            self?.presentFilePicker()
        })
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))

        // iPad 适配
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(alert, animated: true)
    }

    // MARK: - 拍照 / 相册 / 文件
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            AppUtility.showToast("相机不可用")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image"]
        picker.delegate = self
        imagePicker = picker
        present(picker, animated: true)
    }

    private func presentPhotoPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.delegate = self
        imagePicker = picker
        present(picker, animated: true)
    }

    private func presentFilePicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - 发送到文件传输助手频道
    /// 发送图片消息并记录
    private func sendImage(_ image: UIImage, localURL: URL?) {
        // 先插入一条"发送中"记录
        var record = FileTransferRecord(
            id: UUID().uuidString,
            fileName: localURL?.lastPathComponent ?? "照片.jpg",
            fileSize: Int64(image.jpegData(compressionQuality: 0.8)?.count ?? 0),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: .sending,
            localPath: localURL?.path,
            remoteURL: nil
        )
        insertRecord(record)

        COSUploadManager.shared.uploadImage(image,
            progress: { _ in },
            completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let cdnURL):
                    IMManager.shared.sendImageMessage(
                        channelId: self.channelId,
                        imageURL: cdnURL,
                        width: image.size.width,
                        height: image.size.height,
                        channelType: self.channelType
                    )
                    record.status = .sent
                    record.remoteURL = cdnURL
                    self.updateRecord(record)
                case .failure:
                    AppUtility.showToast("图片上传失败")
                    self.removeRecord(id: record.id)
                }
            }
        )
    }

    /// 发送文件消息并记录
    private func sendFile(_ url: URL) {
        let fileName = url.lastPathComponent
        let fileSize: Int64
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            fileSize = Int64(resources.fileSize ?? 0)
        } catch {
            fileSize = 0
        }

        var record = FileTransferRecord(
            id: UUID().uuidString,
            fileName: fileName,
            fileSize: fileSize,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            status: .sending,
            localPath: url.path,
            remoteURL: nil
        )
        insertRecord(record)

        COSUploadManager.shared.uploadFile(fileURL: url,
            fileName: fileName,
            contentType: "application/octet-stream",
            progress: { _ in },
            completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let cdnURL):
                    IMManager.shared.sendFileMessage(
                        channelId: self.channelId,
                        fileName: fileName,
                        fileSize: fileSize,
                        fileURL: cdnURL,
                        channelType: self.channelType
                    )
                    record.status = .sent
                    record.remoteURL = cdnURL
                    self.updateRecord(record)
                case .failure:
                    AppUtility.showToast("文件上传失败")
                    self.removeRecord(id: record.id)
                }
            }
        )
    }

    // MARK: - 记录操作
    private func insertRecord(_ record: FileTransferRecord) {
        records.insert(record, at: 0)
        saveRecords()
        updateEmptyState()
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }

    private func updateRecord(_ record: FileTransferRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        saveRecords()
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }

    private func removeRecord(id: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records.remove(at: index)
        saveRecords()
        updateEmptyState()
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    // MARK: - 打开 / 分享
    private func openOrShare(_ record: FileTransferRecord) {
        // 优先本地文件
        if let path = record.localPath, FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            presentActivity(with: url)
            return
        }
        // 其次远端地址
        if let remote = record.remoteURL, let url = URL(string: remote) {
            let alert = UIAlertController(title: record.fileName, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "打开链接", style: .default) { _ in
                UIApplication.shared.open(url)
            })
            alert.addAction(UIAlertAction(title: "分享链接", style: .default) { [weak self] _ in
                self?.presentActivity(with: url)
            })
            alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
            present(alert, animated: true)
            return
        }
        AppUtility.showToast("文件不可用")
    }

    private func presentActivity(with item: Any) {
        let activity = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(activity, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension FileHelperViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mode == .fileHelper ? records.count : notices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if mode == .fileHelper {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FileTransferCell", for: indexPath) as! FileTransferCell
            cell.configure(with: records[indexPath.row])
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "SystemNoticeMessageCell", for: indexPath) as! SystemNoticeMessageCell
        cell.configure(with: notices[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard mode == .fileHelper else {
            showNoticeDetail(notices[indexPath.row])
            return
        }
        openOrShare(records[indexPath.row])
    }

    /// 系统通知只读展示
    private func showNoticeDetail(_ notice: SystemNotice) {
        let alert = UIAlertController(title: notice.title, message: notice.content, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension FileHelperViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        // 保存到临时目录，作为本地路径
        let localURL = saveImageToTemp(image)
        sendImage(image, localURL: localURL)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func saveImageToTemp(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let fileName = "IMG_\(Int(Date().timeIntervalSince1970)).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension FileHelperViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        // 拷贝到临时目录，确保持久可访问
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: tmpURL.path) {
                try FileManager.default.removeItem(at: tmpURL)
            }
            try FileManager.default.copyItem(at: url, to: tmpURL)
            sendFile(tmpURL)
        } catch {
            AppUtility.showToast("文件读取失败")
        }
    }
}

// MARK: - 文件传输记录 Cell
class FileTransferCell: UITableViewCell {

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let sizeLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusLabel = UILabel()

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

        // 文件图标容器
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .themePrimary
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        sizeLabel.font = ScreenAdapter.font(12)
        sizeLabel.textColor = .themeTextSecondary

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .themeTextTertiary
        timeLabel.textAlignment = .right

        statusLabel.font = ScreenAdapter.font(11)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = ScreenAdapter.scaleW(4)
        statusLabel.clipsToBounds = true

        let textStack = UIStackView(arrangedSubviews: [nameLabel, sizeLabel])
        textStack.axis = .vertical
        textStack.spacing = ScreenAdapter.scaleH(4)

        let rightStack = UIStackView(arrangedSubviews: [timeLabel, statusLabel])
        rightStack.axis = .vertical
        rightStack.spacing = ScreenAdapter.scaleH(4)
        rightStack.alignment = .trailing

        contentView.addSubviews(iconContainer, textStack, rightStack)
        iconContainer.addSubview(iconImageView)

        let iconSize = ScreenAdapter.scaleW(40)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }
        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(rightStack.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }

        rightStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - 配置
    func configure(with record: FileTransferRecord) {
        nameLabel.text = record.fileName
        sizeLabel.text = formatFileSize(record.fileSize)
        timeLabel.text = AppUtility.formatTimestamp(record.timestamp)
        statusLabel.text = record.status.displayText

        // 状态颜色
        switch record.status {
        case .sending:
            statusLabel.textColor = .white
            statusLabel.backgroundColor = .systemOrange
        case .sent:
            statusLabel.textColor = .white
            statusLabel.backgroundColor = .themePrimary
        case .received:
            statusLabel.textColor = .white
            statusLabel.backgroundColor = .systemGreen
        }

        // 文件图标
        let ext = (record.fileName as NSString).pathExtension.lowercased()
        let iconName: String
        let iconColor: UIColor
        switch ext {
        case "pdf":
            iconName = "doc.richtext.fill"; iconColor = .systemRed
        case "doc", "docx":
            iconName = "doc.text.fill"; iconColor = .themePrimary
        case "xls", "xlsx":
            iconName = "chart.bar.doc.horizontal.fill"; iconColor = .systemGreen
        case "ppt", "pptx":
            iconName = "slider.horizontal.3"; iconColor = .systemOrange
        case "zip", "rar", "7z":
            iconName = "doc.zipper"; iconColor = .systemPurple
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            iconName = "photo.fill"; iconColor = .systemBlue
        case "mp4", "mov", "avi", "mkv":
            iconName = "video.fill"; iconColor = .systemPurple
        case "mp3", "wav", "aac", "m4a":
            iconName = "music.note"; iconColor = .systemPink
        default:
            iconName = "doc.fill"; iconColor = .themePrimary
        }
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = iconColor
    }

    // MARK: - 格式化
    private func formatFileSize(_ size: Int64) -> String {
        if size < 1024 { return "\(size) B" }
        let kb = Double(size) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }
}

// MARK: - 系统通知消息 Cell（只读展示）
class SystemNoticeMessageCell: UITableViewCell {

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let timeLabel = UILabel()

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

        iconContainer.layer.cornerRadius = 10
        iconContainer.clipsToBounds = true
        iconContainer.backgroundColor = .themeColorPrimaryLight
        iconImageView.image = UIImage(systemName: "bell.badge.fill")
        iconImageView.tintColor = .themeColorPrimary
        iconImageView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImageView)

        titleLabel.font = ScreenAdapter.font(16)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        contentLabel.font = ScreenAdapter.font(13)
        contentLabel.textColor = .themeTextSecondary
        contentLabel.numberOfLines = 2

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .themeTextTertiary
        timeLabel.textAlignment = .right

        let textStack = UIStackView(arrangedSubviews: [titleLabel, contentLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        contentView.addSubviews(iconContainer, textStack, timeLabel)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalTo(textStack.snp.top)
        }
    }

    func configure(with notice: SystemNotice) {
        titleLabel.text = notice.title
        contentLabel.text = notice.content
        timeLabel.text = AppUtility.formatTimestamp(notice.timestamp)
    }
}
