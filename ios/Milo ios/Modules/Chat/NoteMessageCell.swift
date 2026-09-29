import UIKit
import SnapKit

// MARK: - 笔记消息Cell
class NoteMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let timeLabel = UILabel()
    private let avatarView = UIImageView()
    private var isFromMe = false

    // 笔记内容
    private let noteContainer = UIView()
    private let noteIconView = UIImageView()
    private let noteTitleLabel = UILabel()
    private let notePreviewLabel = UILabel()
    private let noteArrowView = UIImageView()

    // MARK: - 时间分隔头
    let timeHeaderLabel = UILabel()
    private var showsTimeHeader = false

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

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.textAlignment = .center

        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        bubbleView.clipsToBounds = true
        bubbleView.backgroundColor = .white

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

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

        // 时间分隔头
        timeHeaderLabel.font = ScreenAdapter.font(12)
        timeHeaderLabel.textColor = .tertiaryLabel
        timeHeaderLabel.textAlignment = .center
        timeHeaderLabel.isHidden = true
        timeHeaderLabel.alpha = 0

        noteContainer.addSubviews(noteIconView, noteTitleLabel, notePreviewLabel, noteArrowView)
        bubbleView.addSubview(noteContainer)
        contentView.addSubviews(timeHeaderLabel, avatarView, bubbleView, timeLabel)

        timeHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(0)
        }

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }

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

    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

        // 解析笔记消息内容
        if let data = message.content.data(using: .utf8),
           let note = try? JSONDecoder().decode(NoteEntity.self, from: data) {
            noteTitleLabel.text = note.title.isEmpty ? "无标题笔记" : note.title
            notePreviewLabel.text = note.previewText
        } else {
            noteTitleLabel.text = "笔记"
            notePreviewLabel.text = message.content
        }

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let bubbleWidth = ScreenAdapter.screenWidth * 0.72

        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = .themeBubbleOutgoing
            noteTitleLabel.textColor = .white
            notePreviewLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
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
            noteTitleLabel.textColor = .label
            notePreviewLabel.textColor = .secondaryLabel
            bubbleView.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }

        // 笔记容器布局
        noteContainer.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            make.height.equalTo(ScreenAdapter.scaleH(72))
        }
    }

    // MARK: - 时间分隔头配置

    func configureTimeHeader(text: String?, isNew: Bool = false) {
        let shouldShow = text != nil
        showsTimeHeader = shouldShow

        let vPad = ScreenAdapter.scaleH(12)

        if shouldShow {
            timeHeaderLabel.text = text
            timeHeaderLabel.isHidden = false
            timeHeaderLabel.snp.updateConstraints { make in
                make.height.equalTo(18)
            }
        } else {
            timeHeaderLabel.text = nil
            timeHeaderLabel.isHidden = true
            timeHeaderLabel.alpha = 0
            timeHeaderLabel.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }

        // 更新头像顶部约束
        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
                if shouldShow {
                    make.top.equalTo(timeHeaderLabel.snp.bottom).offset(vPad)
                } else {
                    make.top.equalToSuperview().offset(vPad)
                }
                make.width.height.equalTo(ScreenAdapter.scaleW(36))
            }
        } else {
            avatarView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
                if shouldShow {
                    make.top.equalTo(timeHeaderLabel.snp.bottom).offset(vPad)
                } else {
                    make.top.equalToSuperview().offset(vPad)
                }
                make.width.height.equalTo(ScreenAdapter.scaleW(36))
            }
        }

        // 新时间分隔头动画
        if shouldShow && isNew && AnimationIntegration.shared.config.enableListEntranceAnimation {
            timeHeaderLabel.alpha = 0
            timeHeaderLabel.transform = CGAffineTransform(translationX: 0, y: -5)
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: .curveEaseOut) {
                self.timeHeaderLabel.alpha = 1
                self.timeHeaderLabel.transform = .identity
            }
        } else if shouldShow {
            timeHeaderLabel.alpha = 1
            timeHeaderLabel.transform = .identity
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
