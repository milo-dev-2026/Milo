import UIKit
import SnapKit
import Kingfisher

class ImageMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let imageView_ = UIImageView()
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
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.textAlignment = .center

        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        bubbleView.clipsToBounds = true

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        imageView_.contentMode = .scaleAspectFill
        imageView_.clipsToBounds = true
        imageView_.backgroundColor = .systemGray6

        bubbleView.addSubview(imageView_)
        contentView.addSubviews(avatarView, bubbleView, timeLabel)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }

        imageView_.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let imgSize = ScreenAdapter.scaleW(160)

        let content = message.content
        let imgURL: URL?
        if content.hasPrefix("http") {
            imgURL = URL(string: content)
        } else if content.hasPrefix("/") {
            imgURL = URL(string: APIConfig.apiBaseURL + content)
        } else {
            imgURL = URL(string: APIConfig.apiBaseURL + "/" + content)
        }

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

        if let url = imgURL {
            imageView_.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        } else {
            imageView_.image = UIImage(systemName: "photo")
        }
    }
}
