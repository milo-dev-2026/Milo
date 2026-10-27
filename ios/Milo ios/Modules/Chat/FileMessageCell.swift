import UIKit
import SnapKit

class FileMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let fileIcon = UIImageView()
    private let nameLabel = UILabel()
    private let sizeLabel = UILabel()
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

        let bubblePad = ScreenAdapter.scaleW(12)

        bubbleView.layer.cornerRadius = ThemeDimension.bubbleCornerRadius

        fileIcon.image = UIImage(systemName: "doc.fill")
        fileIcon.tintColor = .themePrimary
        fileIcon.contentMode = .scaleAspectFit

        nameLabel.font = ScreenAdapter.font(15)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        sizeLabel.font = ScreenAdapter.font(12)
        sizeLabel.textColor = .secondaryLabel

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, sizeLabel])
        infoStack.axis = .vertical
        infoStack.spacing = ScreenAdapter.scaleH(2)

        bubbleView.addSubview(fileIcon)
        bubbleView.addSubview(infoStack)
        contentView.addSubviews(tailView, bubbleView)

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

    func configure(with message: Message, showTail: Bool = false) {
        let parts = message.content.split(separator: "|")
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
            fileIcon.tintColor = .themePrimary
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
            fileIcon.tintColor = .themePrimary
            fileIcon.image = UIImage(systemName: "doc.fill")
        }

        let isFromMe = message.isFromMe
        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        nameLabel.textColor = isFromMe ? .themeBubbleSendText : .themeBubbleReceiveText
        sizeLabel.textColor = isFromMe ? UIColor.white.withAlphaComponent(0.8) : .secondaryLabel
        if isFromMe { fileIcon.tintColor = .white }

        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: ScreenAdapter.scaleW(240),
            height: ScreenAdapter.scaleH(56),
            showTail: showTail,
            fillColor: fillColor
        )
    }
}
