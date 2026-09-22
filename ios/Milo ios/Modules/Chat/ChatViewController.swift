import UIKit
import SnapKit
import Kingfisher
import Photos
import MAMapKit
import AMapLocationKit
import AMapSearchKit
import UniformTypeIdentifiers
import AVKit

// MARK: - 聊天页
class ChatViewController: UIViewController {

    let channelId: String
    private let titleText: String
    private let channelType: Int // 1: 单聊, 2: 群聊

    private let tableView = UITableView()
    private let inputBar = ChatInputBar()
    private var messages: [Message] = []
    private var imagePicker: UIImagePickerController?
    private var typingTimer: Timer?
    private var isTyping = false

    init(channelId: String, title: String, channelType: Int = 1) {
        self.channelId = channelId
        self.titleText = title
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavBar()
        loadMessages()
        setupKeyboardObserver()

        IMManager.shared.onMessageReceived = { [weak self] msg in
            self?.handleIncomingMessage(msg)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMessageNotification(_:)),
            name: IMManager.messageReceivedNotification,
            object: nil
        )
    }

    @objc private func handleMessageNotification(_ notification: Notification) {
        guard let msg = notification.object as? Message else { return }
        handleIncomingMessage(msg)
    }

    private func handleIncomingMessage(_ msg: Message) {
        guard msg.channelID == channelId else { return }
        if messages.contains(where: { $0.messageID == msg.messageID }) { return }
        messages.append(msg)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }

    private func setupUI() {
        title = titleText
        view.backgroundColor = .themeChatBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TextMessageCell.self, forCellReuseIdentifier: "TextMessageCell")
        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: "ImageMessageCell")
        tableView.register(VoiceMessageCell.self, forCellReuseIdentifier: "VoiceMessageCell")
        tableView.register(VideoMessageCell.self, forCellReuseIdentifier: "VideoMessageCell")
        tableView.register(FileMessageCell.self, forCellReuseIdentifier: "FileMessageCell")
        tableView.register(LocationMessageCell.self, forCellReuseIdentifier: "LocationMessageCell")
        tableView.register(CardMessageCell.self, forCellReuseIdentifier: "CardMessageCell")
        tableView.register(NoteMessageCell.self, forCellReuseIdentifier: "NoteMessageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        inputBar.delegate = self

        view.addSubviews(tableView, inputBar)

        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top)
        }

        inputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func setupNavBar() {
        // 群聊时显示 "+" 按钮，单聊时不显示通话入口
        if channelType == 2 {
            let moreBtn = UIBarButtonItem(
                image: UIImage(systemName: "plus.circle"),
                style: .plain,
                target: self,
                action: #selector(showGroupMoreOptions)
            )
            moreBtn.tintColor = .themePrimary
            navigationItem.rightBarButtonItem = moreBtn
        }
    }

    @objc private func showGroupMoreOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "语音通话", style: .default) { [weak self] _ in
            self?.startGroupVoiceCall()
        })

        alert.addAction(UIAlertAction(title: "群聊详情", style: .default) { [weak self] _ in
            self?.openGroupDetail()
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        // iPad 适配
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }

    private func startGroupVoiceCall() {
        let vc = ChooseVideoCallMembersViewController(groupId: channelId, groupType: channelType)
        vc.onSelected = { [weak self] (uids: [String]) in
            guard let self = self else { return }
            // 发起语音通话
            let callVC = TRTCCallViewController(channelId: self.channelId)
            callVC.modalPresentationStyle = .fullScreen
            self.present(callVC, animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openGroupDetail() {
        let vc = GroupDetailViewController(groupId: channelId)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func loadMessages() {
        Task {
            do {
                let response: WKMessageSyncResponse = try await APIClient.shared.requestFlexible(
                    .syncChannelMessages(channelId: channelId, channelType: self.channelType, startMessageSeq: 0, limit: 50)
                )
                if let msgs = response.messages {
                    messages = msgs.map { Message(from: $0) }.sorted { $0.timestamp < $1.timestamp }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.scrollToBottom()
                    }
                }
            } catch {
                AppUtility.showToast("加载消息失败")
            }
        }
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }

    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let height = frame.height
            UIView.animate(withDuration: 0.25) {
                self.inputBar.snp.updateConstraints { make in
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-height)
                }
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.25) {
            self.inputBar.snp.updateConstraints { make in
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        switch message.type {
        case .image:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageMessageCell", for: indexPath) as! ImageMessageCell
            cell.configure(with: message)
            return cell
        case .voice:
            let cell = tableView.dequeueReusableCell(withIdentifier: "VoiceMessageCell", for: indexPath) as! VoiceMessageCell
            cell.configure(with: message)
            return cell
        case .video:
            let cell = tableView.dequeueReusableCell(withIdentifier: "VideoMessageCell", for: indexPath) as! VideoMessageCell
            cell.configure(with: message)
            return cell
        case .file:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FileMessageCell", for: indexPath) as! FileMessageCell
            cell.configure(with: message)
            return cell
        case .location:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocationMessageCell", for: indexPath) as! LocationMessageCell
            cell.configure(with: message)
            return cell
        case .card:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CardMessageCell", for: indexPath) as! CardMessageCell
            cell.configure(with: message)
            return cell
        case .note:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoteMessageCell", for: indexPath) as! NoteMessageCell
            cell.configure(with: message)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextMessageCell", for: indexPath) as! TextMessageCell
            cell.configure(with: message)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = messages[indexPath.row]
        switch message.type {
        case .image:
            let content = message.content
            let imgURL: URL?
            if content.hasPrefix("http") {
                imgURL = URL(string: content)
            } else if content.hasPrefix("/") {
                imgURL = URL(string: APIConfig.apiBaseURL + content)
            } else {
                imgURL = URL(string: APIConfig.apiBaseURL + "/" + content)
            }
            let previewVC = ImagePreviewViewController(url: imgURL)
            previewVC.modalPresentationStyle = .fullScreen
            present(previewVC, animated: true)
        case .voice:
            if let cell = tableView.cellForRow(at: indexPath) as? VoiceMessageCell {
                cell.playVoice()
            }
        case .video:
            if let cell = tableView.cellForRow(at: indexPath) as? VideoMessageCell {
                cell.playVideo(from: self)
            }
        case .location:
            if let cell = tableView.cellForRow(at: indexPath) as? LocationMessageCell {
                cell.openLocationMap(from: self)
            }
        case .card:
            if let cardInfo = CardMessageInfo.parse(from: message.content) {
                let detailVC = ContactDetailViewController(uid: cardInfo.uid)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        case .note:
            // 解析笔记消息内容并展示详情
            if let note = parseNoteMessage(message.content) {
                let detailVC = NoteDetailViewController(note: note)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        default:
            break
        }
    }

    // MARK: - 已读回执
    private func markMessagesAsRead() {
        Task {
            for message in messages where !message.isFromMe && message.status == 0 {
                do {
                    _ = try await APIClient.shared.requestRaw(.deleteMessage(messageId: message.messageID))
                } catch { }
            }
        }
    }

    // MARK: - 正在输入提示
    private func updateTypingStatus(isTyping: Bool) {
        if isTyping {
            guard !self.isTyping else { return }
            self.isTyping = true
            title = "\(titleText) 正在输入..."
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                self?.resetTypingStatus()
            }
        } else {
            resetTypingStatus()
        }
    }

    private func resetTypingStatus() {
        guard isTyping else { return }
        isTyping = false
        title = titleText
        typingTimer?.invalidate()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        let message = messages[indexPath.row]

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if message.isFromMe {
            alert.addAction(UIAlertAction(title: "撤回", style: .default) { [weak self] _ in
                self?.recallMessage(message)
            })
        }
        alert.addAction(UIAlertAction(title: "复制", style: .default) { _ in
            UIPasteboard.general.string = message.content
            AppUtility.showToast("已复制")
        })
        alert.addAction(UIAlertAction(title: "收藏", style: .default) { [weak self] _ in
            self?.favoriteMessage(message)
        })
        alert.addAction(UIAlertAction(title: "回复表情", style: .default) { [weak self] _ in
            guard let self = self else { return }
            MessageReactionView.showReactionPicker(for: message.messageID, from: self.tableView) { emoji in
                self.sendReaction(message: message, emoji: emoji)
            }
        })
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteMessage(message)
        })
        alert.addAction(UIAlertAction(title: "转发", style: .default) { [weak self] _ in
            self?.forwardMessage(message)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func recallMessage(_ message: Message) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.deleteMessage(messageId: message.messageID))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        if let idx = self.messages.firstIndex(where: { $0.messageID == message.messageID }) {
                            self.messages[idx].content = "此消息已撤回"
                            self.tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
                        }
                        AppUtility.showToast("已撤回")
                    }
                }
            } catch {
                AppUtility.showToast("撤回失败")
            }
        }
    }

    private func deleteMessage(_ message: Message) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.deleteMessage(messageId: message.messageID))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        if let idx = self.messages.firstIndex(where: { $0.messageID == message.messageID }) {
                            self.messages.remove(at: idx)
                            self.tableView.deleteRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
                        }
                    }
                }
            } catch {
                AppUtility.showToast("删除失败")
            }
        }
    }

    private func forwardMessage(_ message: Message) {
        let alert = UIAlertController(title: "转发到", message: "请选择转发目标", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "输入对方ID"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "发送", style: .default) { [weak self] _ in
            guard let targetId = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !targetId.isEmpty else { return }
            Task {
                do {
                    let response = try await APIClient.shared.requestRaw(.sendMessage(channelId: targetId, content: message.content, type: message.type.rawValue, channelType: 1))
                    if response["status"] as? Int == 200 {
                        DispatchQueue.main.async {
                            AppUtility.showToast("已转发")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("转发失败")
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func favoriteMessage(_ message: Message) {
        // 使用本地存储收藏
        let favItem = FavoriteStorageManager.shared.createFavorite(from: message, senderName: titleText)
        FavoriteStorageManager.shared.addFavorite(favItem)
        AppUtility.showToast("已收藏")
        
        // 同时尝试同步到服务器（失败不影响本地）
        Task {
            do {
                let typeVal: Int
                switch message.type {
                case .text: typeVal = 1
                case .image: typeVal = 2
                case .voice: typeVal = 3
                case .video: typeVal = 4
                case .file: typeVal = 5
                case .location: typeVal = 6
                case .card: typeVal = 7
                case .note: typeVal = 100
                default: typeVal = 1
                }
                _ = try await APIClient.shared.requestRaw(.addFavorite(type: typeVal, content: message.content, extra: nil))
            } catch {
                // 静默失败，本地已保存
            }
        }
    }

    private func sendReaction(message: Message, emoji: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.reactMessage(
                    messageId: message.messageID,
                    channelId: channelId,
                    channelType: self.channelType,
                    emoji: emoji
                ))
                DispatchQueue.main.async {
                    AppUtility.showToast("表情已发送")
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }
}

// MARK: - ChatInputBarDelegate
extension ChatViewController: ChatInputBarDelegate {

    func didSendTextMessage(_ text: String) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(
                    .sendTextMessage(channelId: channelId, content: text, channelType: channelType)
                )
                let msg = Message(
                    messageID: UUID().uuidString,
                    channelID: channelId,
                    channelType: self.channelType,
                    fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
                    content: text,
                    type: .text,
                    timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                    status: 1
                )
                messages.append(msg)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            } catch {
                AppUtility.showToast("发送失败")
            }
        }
    }

    func didTapMoreButton() {
        view.endEditing(true)
    }

    func didStartTyping() {
        updateTypingStatus(isTyping: true)
    }

    func didStopTyping() {
        updateTypingStatus(isTyping: false)
    }

    func didInsertEmoji(_ emoji: String) {
    }

    func didTapPhotoButton() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            presentPhotoPicker()
        } else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.presentPhotoPicker()
                    } else {
                        AppUtility.showToast("请在设置中允许访问相册")
                    }
                }
            }
        }
    }

    func didTapCameraButton() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            AppUtility.showToast("相机不可用")
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            presentCamera()
        } else {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.presentCamera()
                    } else {
                        AppUtility.showToast("请在设置中允许访问相机")
                    }
                }
            }
        }
    }

    func didTapLocationButton() {
        let vc = LocationPickerViewController()
        vc.onLocationSelected = { [weak self] location in
            self?.sendLocationMessage(location)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    func didTapFileButton() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func didTapNoteButton() {
        let noteSelectVC = NoteSelectViewController()
        noteSelectVC.onNoteSelected = { [weak self] note in
            self?.sendNoteMessage(note)
        }
        let nav = UINavigationController(rootViewController: noteSelectVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    func didTapCardButton() {
        let chooseVC = ChooseContactsViewController(maxSelection: 1) { [weak self] selected in
            guard let contact = selected.first else { return }
            self?.sendCardMessage(uid: contact.uid, name: contact.name, avatar: "", vercode: contact.uid)
        }
        navigationController?.pushViewController(chooseVC, animated: true)
    }

    private func presentPhotoPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.image.identifier]
        picker.delegate = self
        imagePicker = picker
        present(picker, animated: true)
    }

    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        picker.videoMaximumDuration = 60
        picker.delegate = self
        imagePicker = picker
        present(picker, animated: true)
    }

    private func sendImageMessage(data: Data) {
        guard let image = UIImage(data: data) else {
            AppUtility.showToast("图片数据无效")
            return
        }
        COSUploadManager.shared.uploadImage(image,
            progress: { progressValue in
                print("图片上传进度: \(String(format: "%.1f%%", progressValue * 100))")
            },
            completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let cdnURL):
                    Task {
                        do {
                            let response = try await APIClient.shared.requestRaw(
                                .sendMessage(channelId: self.channelId, content: cdnURL, type: 2, channelType: self.channelType)
                            )
                            if response["status"] as? Int == 200 {
                                let msg = Message(
                                    messageID: UUID().uuidString,
                                    channelID: self.channelId,
                                    channelType: self.channelType,
                                    fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
                                    content: cdnURL,
                                    type: .image,
                                    timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                                    status: 1
                                )
                                self.messages.append(msg)
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    self.scrollToBottom()
                                }
                            }
                        } catch {
                            AppUtility.showToast("发送图片失败")
                        }
                    }
                case .failure(let error):
                    print("图片上传失败: \(error.localizedDescription)")
                    AppUtility.showToast("图片上传失败")
                }
            }
        )
    }

    private func sendVideoMessage(url: URL) {
        // 先上传视频
        COSUploadManager.shared.uploadVideo(url,
            progress: { progressValue in
                print("视频上传进度: \(String(format: "%.1f%%", progressValue * 100))")
            },
            completion: { [weak self] videoResult in
                guard let self = self else { return }
                switch videoResult {
                case .success(let videoCDNURL):
                    // 再上传缩略图（使用系统图标作为占位）
                    let thumbImage = UIImage(systemName: "video")!
                    COSUploadManager.shared.uploadImage(thumbImage,
                        progress: { progressValue in
                            print("视频缩略图上传进度: \(String(format: "%.1f%%", progressValue * 100))")
                        },
                        completion: { [weak self] thumbResult in
                            guard let self = self else { return }
                            switch thumbResult {
                            case .success(let thumbCDNURL):
                                let content = "\(thumbCDNURL)|\(videoCDNURL)"
                                Task {
                                    do {
                                        let response = try await APIClient.shared.requestRaw(
                                            .sendMessage(channelId: self.channelId, content: content, type: 4, channelType: self.channelType)
                                        )
                                        if response["status"] as? Int == 200 {
                                            let msg = Message(
                                                messageID: UUID().uuidString,
                                                channelID: self.channelId,
                                                channelType: self.channelType,
                                                fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
                                                content: content,
                                                type: .video,
                                                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                                                status: 1
                                            )
                                            self.messages.append(msg)
                                            DispatchQueue.main.async {
                                                self.tableView.reloadData()
                                                self.scrollToBottom()
                                            }
                                        }
                                    } catch {
                                        AppUtility.showToast("发送视频失败")
                                    }
                                }
                            case .failure(let error):
                                print("缩略图上传失败: \(error.localizedDescription)")
                                AppUtility.showToast("缩略图上传失败")
                            }
                        }
                    )
                case .failure(let error):
                    print("视频上传失败: \(error.localizedDescription)")
                    AppUtility.showToast("视频上传失败")
                }
            }
        )
    }

    private func sendFileMessage(url: URL) {
        let fileName = url.lastPathComponent

        COSUploadManager.shared.uploadFile(fileURL: url,
            fileName: fileName,
            contentType: "application/octet-stream",
            progress: { progressValue in
                print("文件上传进度: \(String(format: "%.1f%%", progressValue * 100))")
            },
            completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let cdnURL):
                    // 读取文件大小
                    let fileSize: Int
                    do {
                        let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                        fileSize = resources.fileSize ?? 0
                    } catch {
                        fileSize = 0
                    }
                    // content 格式: fileName|fileSize|cdnURL
                    let content = "\(fileName)|\(fileSize)|\(cdnURL)"
                    Task {
                        do {
                            let response = try await APIClient.shared.requestRaw(
                                .sendMessage(channelId: self.channelId, content: content, type: 5, channelType: self.channelType)
                            )
                            if response["status"] as? Int == 200 {
                                let msg = Message(
                                    messageID: UUID().uuidString,
                                    channelID: self.channelId,
                                    channelType: self.channelType,
                                    fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
                                    content: content,
                                    type: .file,
                                    timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                                    status: 1
                                )
                                self.messages.append(msg)
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    self.scrollToBottom()
                                }
                            }
                        } catch {
                            AppUtility.showToast("发送文件失败")
                        }
                    }
                case .failure(let error):
                    print("文件上传失败: \(error.localizedDescription)")
                    AppUtility.showToast("文件上传失败")
                }
            }
        )
    }

    private func sendLocationMessage(_ location: PickedLocation) {
        let content = "\(location.name)|\(location.latitude),\(location.longitude)"
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.sendMessage(channelId: channelId, content: content, type: 6, channelType: channelType))
                if response["status"] as? Int == 200 {
                    let msg = Message(
                        messageID: UUID().uuidString,
                        channelID: channelId,
                        channelType: self.channelType,
                        fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
                        content: "[位置] \(location.name)",
                        type: .location,
                        timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                        status: 1
                    )
                    messages.append(msg)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.scrollToBottom()
                    }
                }
            } catch {
                AppUtility.showToast("发送位置失败")
            }
        }
    }
    
    // MARK: - 发送名片消息
    private func sendCardMessage(uid: String, name: String, avatar: String, vercode: String) {
        let cardInfo = CardMessageInfo(uid: uid, name: name, avatar: avatar, vercode: vercode)
        let content = cardInfo.toString()
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.sendMessage(channelId: channelId, content: content, type: 7, channelType: channelType))
                if response["status"] as? Int == 200 {
                    let msg = Message(
                        messageID: UUID().uuidString,
                        channelID: channelId,
                        channelType: self.channelType,
                        fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
                        content: content,
                        type: .card,
                        timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                        status: 1
                    )
                    messages.append(msg)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.scrollToBottom()
                    }
                }
            } catch {
                AppUtility.showToast("发送名片失败")
            }
        }
    }
    
    // MARK: - 发送笔记消息
    private func sendNoteMessage(_ note: NoteEntity) {
        // 将笔记内容序列化为JSON字符串
        guard let noteData = try? JSONEncoder().encode(note),
              let noteString = String(data: noteData, encoding: .utf8) else {
            AppUtility.showToast("笔记格式错误")
            return
        }
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.sendMessage(channelId: channelId, content: noteString, type: 100, channelType: channelType))
                if response["status"] as? Int == 200 {
                    let msg = Message(
                        messageID: UUID().uuidString,
                        channelID: channelId,
                        channelType: self.channelType,
                        fromUID: UserDefaults.standard.string(forKey: "uid") ?? "",
                        content: noteString,
                        type: .note,
                        timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                        status: 1
                    )
                    messages.append(msg)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.scrollToBottom()
                    }
                }
            } catch {
                AppUtility.showToast("发送笔记失败")
            }
        }
    }
    
    // MARK: - 解析笔记消息
    private func parseNoteMessage(_ content: String) -> NoteEntity? {
        guard let data = content.data(using: .utf8),
              let note = try? JSONDecoder().decode(NoteEntity.self, from: data) else {
            return nil
        }
        return note
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let mediaType = info[.mediaType] as? String {
            if mediaType == UTType.image.identifier {
                if let image = info[.originalImage] as? UIImage,
                   let data = image.jpegData(compressionQuality: 0.6) {
                    sendImageMessage(data: data)
                }
            } else if mediaType == UTType.movie.identifier {
                if let videoURL = info[.mediaURL] as? URL {
                    sendVideoMessage(url: videoURL)
                }
            }
        }
        imagePicker = nil
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        imagePicker = nil
    }
}

// MARK: - UIDocumentPickerDelegate
extension ChatViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        sendFileMessage(url: url)
    }
}

// MARK: - 消息Cell
class TextMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let avatarView = UIImageView()
    private var isFromMe = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubblePad = ScreenAdapter.scaleW(10)
        let bubbleInner = ScreenAdapter.scaleW(12)

        messageLabel.font = ScreenAdapter.font(15)
        messageLabel.numberOfLines = 0

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.textAlignment = .center

        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        contentView.addSubviews(avatarView, bubbleView, timeLabel)
        bubbleView.addSubview(messageLabel)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(bubblePad)
            make.bottom.equalToSuperview().offset(-bubblePad)
            make.leading.equalToSuperview().offset(bubbleInner)
            make.trailing.equalToSuperview().offset(-bubbleInner)
        }
    }

    func configure(with message: Message) {
        isFromMe = message.isFromMe
        messageLabel.text = message.content
        timeLabel.text = message.timeString

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let maxWidth = ScreenAdapter.screenWidth * 0.6
        let font = ScreenAdapter.font(15)
        let size = message.content.size(withAttributes: [.font: font])
        let bubbleWidth = min(size.width + ScreenAdapter.scaleW(24), maxWidth)

        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = .themeBubbleOutgoing
            messageLabel.textColor = .label
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
            }
            timeLabel.snp.remakeConstraints { make in
                make.trailing.equalTo(bubbleView.snp.trailing)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        } else {
            avatarView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = .themeBubbleIncoming
            messageLabel.textColor = .label
            bubbleView.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }
    }
}
