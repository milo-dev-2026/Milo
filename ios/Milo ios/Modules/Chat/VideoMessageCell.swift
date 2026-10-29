import UIKit
import SnapKit
import AVKit
import Kingfisher

class VideoMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let thumbnailView = UIImageView()
    private let playIcon = UIImageView()
    private let tailView = ChatBubbleTailView()
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
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = ThemeDimension.bubbleCornerRadius
        bubbleView.clipsToBounds = true

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.backgroundColor = .black

        playIcon.image = UIImage(systemName: "play.circle.fill")
        playIcon.tintColor = .white.withAlphaComponent(0.8)
        playIcon.contentMode = .center

        bubbleView.addSubview(thumbnailView)
        bubbleView.addSubview(playIcon)
        contentView.addSubviews(tailView, bubbleView)

        thumbnailView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }
    }

    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
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

        let isFromMe = message.isFromMe
        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: ScreenAdapter.scaleW(180),
            height: ScreenAdapter.scaleW(220),
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar,
            status: message.isFromMe ? message.status : nil
        )
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
