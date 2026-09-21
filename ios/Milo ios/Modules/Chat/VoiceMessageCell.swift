import UIKit
import SnapKit
import Kingfisher

class VoiceMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let durationLabel = UILabel()
    private let voiceIcon = UIImageView()
    private let timeLabel = UILabel()
    private let avatarView = UIImageView()
    private var isFromMe = false
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

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubblePad = ScreenAdapter.scaleW(10)

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel

        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        bubbleView.backgroundColor = .white

        voiceIcon.image = UIImage(systemName: "speaker.wave.2.fill")
        voiceIcon.tintColor = .themePrimary
        voiceIcon.contentMode = .scaleAspectFit

        durationLabel.font = ScreenAdapter.font(14)
        durationLabel.textColor = .label

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        bubbleView.addSubview(voiceIcon)
        bubbleView.addSubview(durationLabel)
        contentView.addSubviews(avatarView, bubbleView, timeLabel)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }

        voiceIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(bubblePad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }

        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(voiceIcon.snp.trailing).offset(ScreenAdapter.scaleW(6))
            make.trailing.equalToSuperview().offset(-bubblePad)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

        let parts = message.content.split(separator: "|")
        let duration: String
        let path: String

        if parts.count >= 2 {
            duration = String(parts[0]) + "\""
            path = String(parts[1])
        } else {
            duration = "0\""
            path = message.content
        }
        durationLabel.text = duration

        if path.hasPrefix("http") {
            voiceURL = URL(string: path)
        } else if path.hasPrefix("/") {
            voiceURL = URL(string: APIConfig.apiBaseURL + path)
        } else {
            voiceURL = URL(string: APIConfig.apiBaseURL + "/" + path)
        }

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let bubbleWidth = ScreenAdapter.scaleW(100)

        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = .themeBubbleOutgoing
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
                make.height.equalTo(ScreenAdapter.scaleH(36))
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
            bubbleView.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
                make.height.equalTo(ScreenAdapter.scaleH(36))
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }
    }

    func playVoice() {
        guard let url = voiceURL else { return }
        AudioRecorderManager.shared.playAudio(url: url)
        voiceIcon.tintColor = .systemGreen
        AudioRecorderManager.shared.onPlayFinished = { [weak self] in
            self?.voiceIcon.tintColor = .themePrimary
        }
    }
}
