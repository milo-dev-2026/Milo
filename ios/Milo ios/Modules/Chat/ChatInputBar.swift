import UIKit
import SnapKit

// MARK: - 聊天输入栏
protocol ChatInputBarDelegate: AnyObject {
    func didSendTextMessage(_ text: String)
    func didTapMoreButton()
    func didTapPhotoButton()
    func didTapCameraButton()
    func didTapLocationButton()
    func didTapFileButton()
    func didTapNoteButton()
    func didTapCardButton()
    func didStartTyping()
    func didStopTyping()
    func didInsertEmoji(_ emoji: String)
}

class ChatInputBar: UIView {

    weak var delegate: ChatInputBarDelegate?

    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let emojiButton = UIButton(type: .system)
    private var textViewHeight: Constraint!
    private var morePanel: UIView?
    private var morePanelHeight: Constraint?
    private var emojiPanel: EmojiPanelView?
    private var emojiPanelHeight: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        // 毛玻璃背景
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let minH = ScreenAdapter.scaleH(36)
        let maxH = ScreenAdapter.scaleH(100)
        let hPad = ScreenAdapter.scaleW(8)
        let vPad = ScreenAdapter.scaleH(6)

        let topBorder = UIView()
        topBorder.backgroundColor = .themeSeparator
        addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        textView.font = ScreenAdapter.font(15)
        textView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.themeSeparator.cgColor
        textView.backgroundColor = .systemBackground
        textView.delegate = self
        textView.isScrollEnabled = false

        sendButton.setTitle("发送", for: .normal)
        sendButton.setTitleColor(.themePrimary, for: .normal)
        sendButton.titleLabel?.font = ScreenAdapter.mediumFont(15)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)

        moreButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        moreButton.tintColor = .themePrimary
        moreButton.addTarget(self, action: #selector(toggleMorePanel), for: .touchUpInside)

        emojiButton.setImage(UIImage(systemName: "face.smiling"), for: .normal)
        emojiButton.tintColor = .themePrimary
        emojiButton.addTarget(self, action: #selector(toggleEmojiPanel), for: .touchUpInside)

        addSubviews(emojiButton, textView, sendButton, moreButton)

        emojiButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }

        textView.snp.makeConstraints { make in
            make.leading.equalTo(emojiButton.snp.trailing).offset(hPad)
            make.top.equalToSuperview().offset(vPad)
            self.textViewHeight = make.height.equalTo(minH).constraint
            make.trailing.equalTo(sendButton.snp.leading).offset(-hPad)
        }

        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-hPad)
            make.centerY.equalTo(textView)
            make.width.equalTo(ScreenAdapter.scaleW(44))
        }

        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-hPad)
            make.top.equalTo(textView.snp.bottom).offset(vPad)
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }
    }

    @objc private func send() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        delegate?.didSendTextMessage(text)
        textView.text = ""
        textViewDidChange(textView)
    }

    @objc private func toggleMorePanel() {
        hideEmojiPanel()
        if morePanel != nil {
            hideMorePanel()
        } else {
            showMorePanel()
        }
        delegate?.didTapMoreButton()
    }

    @objc private func toggleEmojiPanel() {
        textView.resignFirstResponder()
        if morePanel != nil { hideMorePanel() }
        if emojiPanel != nil {
            hideEmojiPanel()
        } else {
            showEmojiPanel()
        }
    }

    private func showEmojiPanel() {
        let panel = EmojiPanelView()
        panel.delegate = self
        addSubview(panel)

        panel.snp.makeConstraints { make in
            make.top.equalTo(moreButton.snp.bottom).offset(ScreenAdapter.scaleH(6))
            make.leading.trailing.bottom.equalToSuperview()
            self.emojiPanelHeight = make.height.equalTo(0).constraint
        }

        emojiPanel = panel
        superview?.layoutIfNeeded()

        let panelHeight = ScreenAdapter.scaleH(220)
        UIView.animate(withDuration: 0.25) {
            self.emojiPanelHeight?.update(offset: panelHeight)
            self.superview?.layoutIfNeeded()
        }
    }

    func hideEmojiPanel() {
        guard let panel = emojiPanel else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.emojiPanelHeight?.update(offset: 0)
            self.superview?.layoutIfNeeded()
        }) { _ in
            panel.removeFromSuperview()
            self.emojiPanel = nil
            self.emojiPanelHeight = nil
        }
    }

    private func showMorePanel() {
        let panel = UIView()
        panel.backgroundColor = .clear
        addSubview(panel)

        let panelHeight = ScreenAdapter.scaleH(180)
        let columns: [(icon: String, title: String, action: Selector)] = [
            ("photo.on.rectangle", "相册", #selector(didTapPhoto)),
            ("camera", "拍摄", #selector(didTapCamera)),
            ("location", "位置", #selector(didTapLocation)),
            ("folder", "文件", #selector(didTapFile)),
            ("note.text", "笔记", #selector(didTapNote)),
            ("person.text.rectangle", "名片", #selector(didTapCard))
        ]

        var prevButton: UIButton?
        for item in columns {
            let btn = UIButton(type: .system)
            let iconSize = ScreenAdapter.scaleW(32)
            btn.setImage(UIImage(systemName: item.icon), for: .normal)
            btn.tintColor = .themePrimary
            btn.setTitle(item.title, for: .normal)
            btn.setTitleColor(.label, for: .normal)
            btn.titleLabel?.font = ScreenAdapter.font(11)
            btn.titleEdgeInsets = UIEdgeInsets(top: iconSize + 4, left: 0, bottom: 0, right: 0)
            btn.imageEdgeInsets = UIEdgeInsets(top: -14, left: 0, bottom: 0, right: 0)
            btn.addTarget(self, action: item.action, for: .touchUpInside)
            panel.addSubview(btn)

            btn.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
                if let prev = prevButton {
                    make.leading.equalTo(prev.snp.trailing).offset(ScreenAdapter.scaleW(16))
                } else {
                    make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
                }
                make.width.equalTo(ScreenAdapter.scaleW(64))
                make.height.equalTo(ScreenAdapter.scaleH(64))
            }
            prevButton = btn
        }

        panel.snp.makeConstraints { make in
            make.top.equalTo(moreButton.snp.bottom).offset(vPad)
            make.leading.trailing.bottom.equalToSuperview()
            self.morePanelHeight = make.height.equalTo(0).constraint
        }

        morePanel = panel
        superview?.layoutIfNeeded()

        UIView.animate(withDuration: 0.25) {
            self.morePanelHeight?.update(offset: panelHeight)
            self.superview?.layoutIfNeeded()
        }
    }

    func hideMorePanel() {
        guard let panel = morePanel else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.morePanelHeight?.update(offset: 0)
            self.superview?.layoutIfNeeded()
        }) { _ in
            panel.removeFromSuperview()
            self.morePanel = nil
            self.morePanelHeight = nil
        }
    }

    @objc private func didTapPhoto() {
        hideMorePanel()
        delegate?.didTapPhotoButton()
    }

    @objc private func didTapCamera() {
        hideMorePanel()
        delegate?.didTapCameraButton()
    }

    @objc private func didTapLocation() {
        hideMorePanel()
        delegate?.didTapLocationButton()
    }

    @objc private func didTapFile() {
        hideMorePanel()
        delegate?.didTapFileButton()
    }
    
    @objc private func didTapNote() {
        hideMorePanel()
        delegate?.didTapNoteButton()
    }
    
    @objc private func didTapCard() {
        hideMorePanel()
        delegate?.didTapCardButton()
    }

    private var vPad: CGFloat {
        return ScreenAdapter.scaleH(6)
    }
}

extension ChatInputBar: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        let minH = ScreenAdapter.scaleH(36)
        let maxH = ScreenAdapter.scaleH(100)
        let size = CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude)
        let fitSize = textView.sizeThatFits(size)
        let height = min(max(fitSize.height, minH), maxH)
        textViewHeight.update(offset: height)
        superview?.layoutIfNeeded()

        if textView.text?.isEmpty == true {
            delegate?.didStopTyping()
        } else {
            delegate?.didStartTyping()
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.didStopTyping()
    }
}

// MARK: - EmojiPanelDelegate
extension ChatInputBar: EmojiPanelDelegate {

    func didSelectEmoji(_ emoji: String) {
        textView.insertText(emoji)
        textViewDidChange(textView)
        delegate?.didInsertEmoji(emoji)
    }

    func didTapDelete() {
        if textView.text?.isEmpty == false {
            textView.deleteBackward()
            textViewDidChange(textView)
        }
    }
}
