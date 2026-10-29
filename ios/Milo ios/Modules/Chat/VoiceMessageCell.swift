import UIKit
import SnapKit
import Kingfisher

class VoiceMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let durationLabel = UILabel()
    private let voiceIcon = UIImageView()
    private let tailView = ChatBubbleTailView()
    private var voiceURL: URL?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = ThemeDimension.bubbleCornerRadius

        voiceIcon.image = UIImage(systemName: "speaker.wave.2.fill")
        voiceIcon.tintColor = .themePrimary
        voiceIcon.contentMode = .scaleAspectFit

        durationLabel.font = ScreenAdapter.font(14)
        durationLabel.textColor = .label

        bubbleView.addSubview(voiceIcon)
        bubbleView.addSubview(durationLabel)
        contentView.addSubviews(tailView, bubbleView)

        voiceIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }

        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(voiceIcon.snp.trailing).offset(ScreenAdapter.scaleW(6))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
        }
    }

    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
        let parts = message.content.split(separator: "|")
        let duration: String
        let path: String
        var seconds: Double = 0

        if parts.count >= 2 {
            seconds = Double(parts[0]) ?? 0
            duration = String(parts[0]) + "\""
            path = String(parts[1])
        } else {
            duration = "0\""
            path = message.content
        }
        durationLabel.text = duration

        // 本地文件路径（刚录完待上传的自己的语音）直接用 file://，否则走服务器地址
        if path.hasPrefix("/"), FileManager.default.fileExists(atPath: path) {
            voiceURL = URL(fileURLWithPath: path)
        } else {
            voiceURL = APIConfig.chatMediaURL(path)
        }

        let isFromMe = message.isFromMe
        // 时长越长气泡越宽（与 iMessage 语音条一致）：70pt 起步，每秒 +4pt，上限 190pt
        let bubbleWidth = ScreenAdapter.scaleW(70 + min(seconds, 30) * 4)
        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        durationLabel.textColor = isFromMe ? .themeBubbleSendText : .themeBubbleReceiveText
        voiceIcon.tintColor = isFromMe ? .white : .themePrimary

        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: bubbleWidth,
            height: ScreenAdapter.scaleH(38),
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar,
            status: message.isFromMe ? message.status : nil
        )
    }

    func playVoice() {
        guard let url = voiceURL else { return }
        let baseTint: UIColor = voiceIcon.tintColor
        if url.isFileURL {
            AudioRecorderManager.shared.playAudio(url: url)
        } else {
            // 远程语音：先下载到本地缓存再播放（AVAudioPlayer 不支持 http 流）
            AudioRecorderManager.shared.playRemoteAudio(url, onDownloadStart: { [weak self] in
                // 下载中：图标降为半透明提示
                self?.voiceIcon.alpha = 0.4
            })
        }
        voiceIcon.tintColor = .systemGreen
        AudioRecorderManager.shared.onPlayFinished = { [weak self] in
            self?.voiceIcon.tintColor = baseTint
            self?.voiceIcon.alpha = 1.0
        }
    }
}
