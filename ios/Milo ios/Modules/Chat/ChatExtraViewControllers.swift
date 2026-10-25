import UIKit
import SnapKit
import AVFoundation

class RecordingViewController: UIViewController {

    private let cancelButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let waveformView = UIView()
    private let timerLabel = UILabel()
    private let hintLabel = UILabel()
    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var recordDuration: TimeInterval = 0

    var onFinished: ((URL, TimeInterval) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "录音"
        view.backgroundColor = .themeBackground
        setupUI()
        requestPermissionAndStart()
    }

    private func setupUI() {
        hintLabel.text = "正在录音..."
        hintLabel.font = ScreenAdapter.font(16)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center

        timerLabel.font = ScreenAdapter.boldFont(32)
        timerLabel.textAlignment = .center
        timerLabel.text = "00:00"

        waveformView.backgroundColor = .systemGray6
        waveformView.layer.cornerRadius = ScreenAdapter.scaleW(8)

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = ScreenAdapter.font(16)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        sendButton.setTitle("发送", for: .normal)
        sendButton.titleLabel?.font = ScreenAdapter.font(16)
        sendButton.backgroundColor = .themePrimary
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = ScreenAdapter.scaleW(8)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [hintLabel, timerLabel, waveformView, cancelButton, sendButton])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(16)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(40))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(40))
        }
        waveformView.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(100)) }
        sendButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(44)) }
    }

    private func requestPermissionAndStart() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard granted else { AppUtility.showToast("需要麦克风权限"); return }
                    self?.startRecording()
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard granted else { AppUtility.showToast("需要麦克风权限"); return }
                    self?.startRecording()
                }
            }
        }
    }

    private func startRecording() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try? AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        recorder?.record()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMeter()
        }
    }

    private func updateMeter() {
        recorder?.updateMeters()
        recordDuration += 0.1
        let min = Int(recordDuration) / 60
        let sec = Int(recordDuration) % 60
        timerLabel.text = String(format: "%02d:%02d", min, sec)
    }

    @objc private func cancel() {
        recorder?.stop()
        meterTimer?.invalidate()
        dismiss(animated: true)
    }

    @objc private func send() {
        recorder?.stop()
        meterTimer?.invalidate()
        if let url = recorder?.url {
            onFinished?(url, recordDuration)
        }
        dismiss(animated: true)
    }
}

extension RecordingViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        meterTimer?.invalidate()
    }
}

class ChooseChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var conversations: [(channelId: String, channelType: Int, name: String, avatar: String)] = []
    var onSelected: ((String, String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择聊天"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChooseChatCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        loadData()
    }

    private func loadData() {
        Task {
            do {
                let syncResp: WKSyncChat = try await APIClient.shared.requestFlexible(.syncConversations)
                let wkConvs = syncResp.conversations ?? []
                conversations = wkConvs.map { (channelId: $0.channel_id ?? "", channelType: $0.channel_type ?? 0, name: "", avatar: "") }
                DispatchQueue.main.async { self.tableView.reloadData() }
                for (index, conv) in conversations.enumerated() {
                    Task {
                        do {
                            let channelInfo: ChannelInfo = try await APIClient.shared.requestFlexible(
                                .getChannelInfo(channelId: conv.channelId, channelType: wkConvs[index].channel_type ?? 0)
                            )
                            DispatchQueue.main.async {
                                if index < self.conversations.count {
                                    self.conversations[index].name = channelInfo.displayName
                                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                }
                            }
                        } catch { }
                    }
                }
            } catch { }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { conversations.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseChatCell", for: indexPath)
        let conv = conversations[indexPath.row]
        cell.textLabel?.text = conv.name
        AppUtility.loadChannelAvatar(channelId: conv.channelId, channelType: conv.channelType, name: conv.name, into: cell.imageView!)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conv = conversations[indexPath.row]
        onSelected?(conv.channelId, conv.name)
        navigationController?.popViewController(animated: true)
    }
}


class ChatFileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var files: [(name: String, size: String, type: String, date: String, url: String)] = []
    private var channelId: String = ""
    private var channelType: Int = 1

    convenience init(channelId: String, channelType: Int) {
        self.init()
        self.channelId = channelId
        self.channelType = channelType
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "聊天文件"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        loadData()
    }

    private func loadData() {
        // 从 IM SDK 获取频道历史消息，筛选文件类型
        Task {
            do {
                let messages = try await withCheckedThrowingContinuation { continuation in
                    IMManager.shared.pullLastMessages(channelId: channelId, channelType: channelType, limit: 200) { msgs, error in
                        if let error = error { continuation.resume(throwing: error) }
                        else { continuation.resume(returning: msgs ?? []) }
                    }
                }
                var list: [(name: String, size: String, type: String, date: String, url: String)] = []
                for msg in messages {
                    if msg.content is WKFileMessageContent {
                        let content = (msg.content as? WKFileMessageContent)?.fileName ?? ""
                        let fileName = content.isEmpty ? "未知文件" : content
                        let fileSize = "\((msg.content as? WKFileMessageContent)?.fileSize ?? 0)"
                        let fileUrl = (msg.content as? WKFileMessageContent)?.url ?? ""
                        let date = AppUtility.formatTimestamp(msg.timestamp)
                        let ext = (fileName as NSString).pathExtension.lowercased()
                        list.append((name: fileName, size: fileSize, type: ext, date: date, url: fileUrl))
                    }
                }
                DispatchQueue.main.async {
                    self.files = list
                    self.tableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    self.files = []
                    self.tableView.reloadData()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(files.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        if files.isEmpty {
            cell.textLabel?.text = "暂无文件"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
        } else {
            let f = files[indexPath.row]
            cell.textLabel?.text = f.name; cell.detailTextLabel?.text = "\(f.size)  \(f.date)"
            cell.imageView?.image = UIImage(systemName: "doc.fill"); cell.imageView?.tintColor = .themePrimary
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !files.isEmpty else { return }
        let f = files[indexPath.row]
        if let url = URL(string: f.url), !f.url.isEmpty {
            UIApplication.shared.open(url)
        } else {
            AppUtility.showToast("文件不可用")
        }
    }
}

class ChooseFileViewController: UIViewController, UIDocumentPickerDelegate {
    var onSelected: ((URL) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择文件"
        view.backgroundColor = .themeBackground
        DispatchQueue.main.async { self.presentPicker() }
    }

    private func presentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .archive, .image, .data])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first { onSelected?(url) }
        dismiss(animated: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true)
    }
}

class PreviewChatBgViewController: UIViewController {
    private var bgColor: UIColor

    init(bgColor: UIColor) { self.bgColor = bgColor; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "背景预览"
        view.backgroundColor = bgColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "设为背景", style: .done, target: self, action: #selector(setBg))
    }

    @objc private func setBg() {
        UserDefaults.standard.set(bgColor.toHex(), forKey: "chat_bg_color")
        AppUtility.showToast("已设置聊天背景")
        navigationController?.popViewController(animated: true)
    }
}

extension UIColor {
    func toHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    convenience init?(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        self.init(red: CGFloat((int >> 16) & 0xFF) / 255, green: CGFloat((int >> 8) & 0xFF) / 255, blue: CGFloat(int & 0xFF) / 255, alpha: 1)
    }
}
