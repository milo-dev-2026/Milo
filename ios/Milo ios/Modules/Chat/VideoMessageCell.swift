import UIKit
import SnapKit
import AVKit
import Kingfisher

class VideoMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let thumbnailView = UIImageView()
    private let playIcon = UIImageView()
    private let timeLabel = UILabel()
    private let avatarView = UIImageView()
    private var isFromMe = false
    private var videoURL: URL?

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

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel

        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        bubbleView.clipsToBounds = true

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.backgroundColor = .black

        playIcon.image = UIImage(systemName: "play.circle.fill")
        playIcon.tintColor = .white.withAlphaComponent(0.8)
        playIcon.contentMode = .center

        bubbleView.addSubview(thumbnailView)
        bubbleView.addSubview(playIcon)
        contentView.addSubviews(avatarView, bubbleView, timeLabel)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }

        thumbnailView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }
    }

    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

        let parts = message.content.split(separator: "|")
        let thumbPath: String
        let videoPath: String

        if parts.count >= 2 {
            thumbPath = String(parts[0])
            videoPath = String(parts[1])
        } else {
            thumbPath = message.content
            videoPath = message.content
        }

        let thumbURL: URL?
        if thumbPath.hasPrefix("http") {
            thumbURL = URL(string: thumbPath)
        } else {
            thumbURL = URL(string: APIConfig.apiBaseURL + "/" + thumbPath)
        }

        if videoPath.hasPrefix("http") {
            videoURL = URL(string: videoPath)
        } else {
            videoURL = URL(string: APIConfig.apiBaseURL + "/" + videoPath)
        }

        if let url = thumbURL {
            thumbnailView.kf.setImage(with: url, placeholder: UIImage(systemName: "video"))
        } else {
            thumbnailView.image = UIImage(systemName: "video")
        }

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let imgSize = ScreenAdapter.scaleW(160)

        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.height.equalTo(imgSize)
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
            bubbleView.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(bubbleGap)
                make.top.equalTo(avatarView)
                make.width.height.equalTo(imgSize)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }
    }

    func playVideo(from vc: UIViewController) {
        guard let url = videoURL else { return }
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        vc.present(playerVC, animated: true) {
            player.play()
        }
    }
}
