import UIKit
import SnapKit
import Kingfisher

class ImageMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let imageView_ = UIImageView()
    private let tailView = ChatBubbleTailView()

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

        imageView_.contentMode = .scaleAspectFill
        imageView_.clipsToBounds = true
        imageView_.backgroundColor = .systemGray6

        bubbleView.addSubview(imageView_)
        contentView.addSubviews(tailView, bubbleView)

        imageView_.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
        let content = message.content
        let imgURL: URL?
        if content.hasPrefix("http") {
            imgURL = URL(string: content)
        } else if content.hasPrefix("/") {
            imgURL = URL(string: APIConfig.apiBaseURL + content)
        } else {
            imgURL = URL(string: APIConfig.apiBaseURL + "/" + content)
        }

        if let url = imgURL {
            imageView_.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        } else {
            imageView_.image = UIImage(systemName: "photo")
        }

        let isFromMe = message.isFromMe
        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: ScreenAdapter.scaleW(180),
            height: ScreenAdapter.scaleW(180),
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar,
            status: message.isFromMe ? message.status : nil
        )
    }
}
