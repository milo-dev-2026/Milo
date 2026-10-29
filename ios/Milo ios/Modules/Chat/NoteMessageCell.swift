import UIKit
import SnapKit

// MARK: - 笔记消息Cell
class NoteMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let tailView = ChatBubbleTailView()

    // 笔记内容
    private let noteContainer = UIView()
    private let noteIconView = UIImageView()
    private let noteTitleLabel = UILabel()
    private let notePreviewLabel = UILabel()
    private let noteArrowView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupPressGesture()
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
        bubbleView.backgroundColor = .white

        // 笔记卡片容器
        noteContainer.backgroundColor = .white
        noteContainer.layer.cornerRadius = ScreenAdapter.scaleW(10)

        // 笔记图标
        noteIconView.image = UIImage(systemName: "note.text")
        noteIconView.tintColor = .systemOrange
        noteIconView.contentMode = .scaleAspectFit

        // 笔记标题
        noteTitleLabel.font = ScreenAdapter.mediumFont(15)
        noteTitleLabel.textColor = .label
        noteTitleLabel.numberOfLines = 1

        // 笔记预览
        notePreviewLabel.font = ScreenAdapter.font(12)
        notePreviewLabel.textColor = .secondaryLabel
        notePreviewLabel.numberOfLines = 2

        // 箭头
        noteArrowView.image = UIImage(systemName: "chevron.right")
        noteArrowView.tintColor = .systemGray3
        noteArrowView.contentMode = .scaleAspectFit

        noteContainer.addSubviews(noteIconView, noteTitleLabel, notePreviewLabel, noteArrowView)
        bubbleView.addSubview(noteContainer)
        contentView.addSubviews(tailView, bubbleView)

        // 笔记内部布局
        noteIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }

        noteTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(noteIconView.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.top.equalTo(noteIconView)
            make.trailing.lessThanOrEqualTo(noteArrowView.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }

        notePreviewLabel.snp.makeConstraints { make in
            make.leading.equalTo(noteTitleLabel)
            make.top.equalTo(noteTitleLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.trailing.lessThanOrEqualTo(noteArrowView.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }

        noteArrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.equalTo(ScreenAdapter.scaleW(12))
        }
    }

    // MARK: - 按压缩放效果
    private func setupPressGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBubbleTap))
        bubbleView.addGestureRecognizer(tapGesture)
        bubbleView.isUserInteractionEnabled = true

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleBubbleLongPress))
        longPress.minimumPressDuration = 0
        longPress.cancelsTouchesInView = false
        longPress.delegate = self
        bubbleView.addGestureRecognizer(longPress)
    }

    @objc private func handleBubbleTap() {
        // 点击事件由 tableView didSelectRowAt 处理
    }

    @objc private func handleBubbleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }

        switch gesture.state {
        case .began:
            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.impactLight()
            }
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) {
                self.bubbleView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.15,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut) {
                self.bubbleView.transform = .identity
            }
        default:
            break
        }
    }

    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
        let isFromMe = message.isFromMe

        // 解析笔记消息内容
        if let data = message.content.data(using: .utf8),
           let note = try? JSONDecoder().decode(NoteEntity.self, from: data) {
            noteTitleLabel.text = note.title.isEmpty ? "无标题笔记" : note.title
            notePreviewLabel.text = note.previewText
        } else {
            noteTitleLabel.text = "笔记"
            notePreviewLabel.text = message.content
        }

        noteTitleLabel.textColor = isFromMe ? .themeBubbleSendText : .label
        notePreviewLabel.textColor = isFromMe ? UIColor.white.withAlphaComponent(0.8) : .secondaryLabel
        noteIconView.tintColor = isFromMe ? .white : .systemOrange
        noteArrowView.tintColor = isFromMe ? UIColor.white.withAlphaComponent(0.7) : .systemGray3
        noteContainer.backgroundColor = isFromMe ? UIColor.white.withAlphaComponent(0.16) : .white

        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: ScreenAdapter.screenWidth * 0.72,
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar,
            status: message.isFromMe ? message.status : nil
        )

        // 笔记容器布局
        noteContainer.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            make.height.equalTo(ScreenAdapter.scaleH(72))
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension NoteMessageCell {

    @objc override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
