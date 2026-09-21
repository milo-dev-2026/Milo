import UIKit
import SnapKit

class FileMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let fileIcon = UIImageView()
    private let nameLabel = UILabel()
    private let sizeLabel = UILabel()
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

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel

        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        bubbleView.backgroundColor = .white

        fileIcon.image = UIImage(systemName: "doc.fill")
        fileIcon.tintColor = .systemBlue
        fileIcon.contentMode = .scaleAspectFit

        nameLabel.font = ScreenAdapter.font(15)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        sizeLabel.font = ScreenAdapter.font(12)
        sizeLabel.textColor = .secondaryLabel

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, sizeLabel])
        infoStack.axis = .vertical
        infoStack.spacing = ScreenAdapter.scaleH(2)

        bubbleView.addSubview(fileIcon)
        bubbleView.addSubview(infoStack)
        contentView.addSubviews(avatarView, bubbleView, timeLabel)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }

        fileIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(bubblePad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(32))
        }

        infoStack.snp.makeConstraints { make in
            make.leading.equalTo(fileIcon.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.trailing.equalToSuperview().offset(-bubblePad)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

        let parts = message.content.split(separator: "|", maxParts: 2)
        let fileName: String
        let fileSize: String

        if parts.count >= 2 {
            fileName = String(parts[0])
            let bytes = Int(parts[1]) ?? 0
            if bytes > 1024 * 1024 {
                fileSize = String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
            } else if bytes > 1024 {
                fileSize = String(format: "%.1f KB", Double(bytes) / 1024)
            } else {
                fileSize = "\(bytes) B"
            }
        } else {
            fileName = message.content
            fileSize = ""
        }
        nameLabel.text = fileName
        sizeLabel.text = fileSize

        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf":
            fileIcon.tintColor = .systemRed
            fileIcon.image = UIImage(systemName: "doc.richtext.fill")
        case "doc", "docx":
            fileIcon.tintColor = .systemBlue
            fileIcon.image = UIImage(systemName: "doc.text.fill")
        case "xls", "xlsx":
            fileIcon.tintColor = .systemGreen
            fileIcon.image = UIImage(systemName: "chart.bar.doc.horizontal.fill")
        case "ppt", "pptx":
            fileIcon.tintColor = .systemOrange
            fileIcon.image = UIImage(systemName: "slider.horizontal.3")
        case "zip", "rar", "7z":
            fileIcon.tintColor = .systemPurple
            fileIcon.image = UIImage(systemName: "doc.zipper")
        default:
            fileIcon.tintColor = .systemBlue
            fileIcon.image = UIImage(systemName: "doc.fill")
        }

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let bubbleWidth = ScreenAdapter.scaleW(220)
        let bubbleHeight = ScreenAdapter.scaleH(56)

        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
                make.height.equalTo(bubbleHeight)
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
                make.width.equalTo(bubbleWidth)
                make.height.equalTo(bubbleHeight)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }
    }
}
