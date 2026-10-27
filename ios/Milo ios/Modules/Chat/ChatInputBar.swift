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
    // 新增：收藏入口（ChatViewController 尚未实现，先提供默认空实现避免编译失败）
    func didTapFavorite()
    // 新增：群聊 @ 成员选择
    func didTapMentionButton()
    // 新增：发送语音（本地临时 .m4a 文件 URL + 时长秒）
    func didSendVoiceMessage(fileURL: URL, duration: TimeInterval)
}

extension ChatInputBarDelegate {
    func didTapFavorite() {}
    func didTapMentionButton() {}
    func didSendVoiceMessage(fileURL: URL, duration: TimeInterval) {}
}

class ChatInputBar: UIView {

    weak var delegate: ChatInputBarDelegate?

    /// 输入行胶囊玻璃容器（包含语音/输入框/发送/+）
    private let pillContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    /// 胶囊顶部 1px 发丝高光，营造玻璃厚度感
    private let pillHighlight = UIView()
    private let inputRow = UIView()
    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    /// 左侧语音/键盘切换按钮
    private let voiceButton = UIButton(type: .system)
    /// 按住说话按钮（语音模式下替换输入框位置）
    private let holdToTalkButton = UIButton(type: .system)
    private var textViewHeight: Constraint!
    /// 面板容器常驻（高度 0↔N），保证 inputBar 高度约束链完整
    private let panelContainer = UIView()
    private var panelContainerHeight: Constraint!
    private var morePanel: UIView?
    private var emojiPanel: EmojiPanelView?
    private var isMoreVisible = false
    private var isEmojiVisible = false

    // MARK: - 语音录音状态
    private var isVoiceMode = false
    private var isRecording = false
    private var isPressing = false
    private var isCancelZone = false
    private var currentDuration: TimeInterval = 0
    private var recorderOverlay: VoiceRecorderOverlay?

    /// 点击空白处收起键盘/面板
    private let backgroundTapGesture = UITapGestureRecognizer(target: nil, action: nil)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if isRecording {
            AudioRecorderManager.shared.cancelRecording()
            AudioRecorderManager.shared.onRecordingChanged = nil
            AudioRecorderManager.shared.onRecordingFinished = nil
        }
        backgroundTapGesture.view?.removeGestureRecognizer(backgroundTapGesture)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else {
            backgroundTapGesture.view?.removeGestureRecognizer(backgroundTapGesture)
            return
        }
        if backgroundTapGesture.view !== window {
            window.addGestureRecognizer(backgroundTapGesture)
        }
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
        let hPad = ScreenAdapter.scaleW(8)
        let vPad = ScreenAdapter.scaleH(6)

        backgroundTapGesture.cancelsTouchesInView = false
        backgroundTapGesture.addTarget(self, action: #selector(handleBackgroundTap(_:)))

        // 输入行容器：面板展开时位于其下方，保证面板在 inputBar bounds 内可点击
        addSubview(inputRow)
        inputRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        // 胶囊玻璃容器：圆角 + 内描边，透出背后聊天内容
        pillContainer.layer.cornerRadius = ScreenAdapter.scaleW(20)
        pillContainer.layer.borderWidth = 0.5
        pillContainer.layer.borderColor = UIColor.themeSeparator.cgColor
        pillContainer.clipsToBounds = true
        inputRow.addSubview(pillContainer)
        pillContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(6))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(6))
            make.leading.equalToSuperview().offset(hPad)
            make.trailing.equalToSuperview().offset(-hPad)
        }
        let pill = pillContainer.contentView

        textView.font = ScreenAdapter.font(15)
        textView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)

        sendButton.setTitle("发送", for: .normal)
        sendButton.setTitleColor(.themePrimary, for: .normal)
        sendButton.titleLabel?.font = ScreenAdapter.mediumFont(15)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)

        moreButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        moreButton.tintColor = .themePrimary
        moreButton.addTarget(self, action: #selector(toggleMorePanel), for: .touchUpInside)

        voiceButton.setImage(UIImage(systemName: "mic"), for: .normal)
        voiceButton.tintColor = .themePrimary
        voiceButton.addTarget(self, action: #selector(toggleVoiceMode), for: .touchUpInside)

        holdToTalkButton.setTitle("按住 说话", for: .normal)
        holdToTalkButton.setTitleColor(.label, for: .normal)
        holdToTalkButton.titleLabel?.font = ScreenAdapter.mediumFont(15)
        holdToTalkButton.backgroundColor = .clear
        holdToTalkButton.layer.cornerRadius = ScreenAdapter.scaleW(8)
        holdToTalkButton.isHidden = true
        let talkGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTalkPress(_:)))
        talkGesture.minimumPressDuration = 0.15
        holdToTalkButton.addGestureRecognizer(talkGesture)

        // 输入控件全部放进胶囊玻璃容器
        pill.addSubviews(voiceButton, textView, holdToTalkButton, sendButton, moreButton)

        // 顶部发丝高光：横向内缩，避让胶囊圆角
        pillHighlight.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        pillHighlight.isUserInteractionEnabled = false
        pillContainer.contentView.addSubview(pillHighlight)
        pillHighlight.snp.makeConstraints { make in
            make.top.equalTo(pill)
            make.leading.equalTo(pill).offset(ScreenAdapter.scaleW(20))
            make.trailing.equalTo(pill).offset(-ScreenAdapter.scaleW(20))
            make.height.equalTo(1)
        }

        // 图标按钮按压回弹
        installPressAnimation(on: sendButton)
        installPressAnimation(on: moreButton)
        installPressAnimation(on: voiceButton)

        moreButton.snp.makeConstraints { make in
            make.trailing.equalTo(pill).offset(-hPad)
            make.centerY.equalTo(textView)
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }

        sendButton.snp.makeConstraints { make in
            make.trailing.equalTo(moreButton.snp.leading).offset(-hPad)
            make.centerY.equalTo(textView)
            make.width.equalTo(ScreenAdapter.scaleW(44))
            make.height.equalTo(ScreenAdapter.scaleH(36))
        }

        voiceButton.snp.makeConstraints { make in
            make.leading.equalTo(pill).offset(hPad)
            make.centerY.equalTo(textView)
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }

        textView.snp.makeConstraints { make in
            make.leading.equalTo(voiceButton.snp.trailing).offset(hPad)
            make.top.equalTo(pill).offset(vPad)
            make.bottom.equalTo(pill).offset(-vPad)
            self.textViewHeight = make.height.equalTo(minH).constraint
            make.trailing.equalTo(sendButton.snp.leading).offset(-hPad)
        }

        holdToTalkButton.snp.makeConstraints { make in
            make.edges.equalTo(textView)
        }

        // 面板容器：固定在输入行下方、inputBar 内部，高度 0↔N 动画
        panelContainer.clipsToBounds = true
        addSubview(panelContainer)
        panelContainer.snp.makeConstraints { make in
            make.top.equalTo(inputRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            self.panelContainerHeight = make.height.equalTo(0).constraint
        }
    }

    @objc private func send() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        delegate?.didSendTextMessage(text)
        textView.text = ""
        textViewDidChange(textView)
    }

    // MARK: - 按键按压回弹

    /// 按下缩到 0.96，抬起用 spring 回弹到 1.0
    private func installPressAnimation(on button: UIButton) {
        button.addTarget(self, action: #selector(pressDown(_:)), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(pressUp(_:)),
                         for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }

    @objc private func pressDown(_ sender: UIButton) {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }
        UIView.animate(withDuration: 0.12,
                       delay: 0,
                       options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }

    @objc private func pressUp(_ sender: UIButton) {
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }
        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.55,
                       initialSpringVelocity: 0.6,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            sender.transform = .identity
        }
    }

    @objc private func toggleMorePanel() {
        textView.resignFirstResponder()
        if isMoreVisible {
            collapsePanel()
        } else {
            showMorePanel()
        }
        delegate?.didTapMoreButton()
    }

    @objc private func toggleEmojiPanel() {
        textView.resignFirstResponder()
        if isEmojiVisible {
            collapsePanel()
        } else {
            showEmojiPanel()
        }
    }

    // MARK: - 语音/键盘切换

    @objc private func toggleVoiceMode() {
        if isRecording {
            finishRecording(cancelled: true)
        }
        isVoiceMode.toggle()
        collapsePanel()

        if isVoiceMode {
            textView.resignFirstResponder()
            textView.isHidden = true
            holdToTalkButton.isHidden = false
            voiceButton.setImage(UIImage(systemName: "keyboard"), for: .normal)
            textViewHeight.update(offset: ScreenAdapter.scaleH(36))
        } else {
            textView.isHidden = false
            holdToTalkButton.isHidden = true
            voiceButton.setImage(UIImage(systemName: "mic"), for: .normal)
            textView.becomeFirstResponder()
        }
        superview?.layoutIfNeeded()
    }

    // MARK: - 录音交互

    @objc private func handleTalkPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            isPressing = true
            isCancelZone = false
            requestPermissionAndStartRecording()
        case .changed:
            guard isRecording else { return }
            let point = gesture.location(in: holdToTalkButton)
            let inCancelZone = point.y < -ScreenAdapter.scaleH(40)
            if inCancelZone != isCancelZone {
                isCancelZone = inCancelZone
                recorderOverlay?.updateCancelState(isInCancelZone: inCancelZone)
            }
        case .ended:
            isPressing = false
            finishRecording(cancelled: isCancelZone)
            isCancelZone = false
        case .cancelled, .failed:
            isPressing = false
            finishRecording(cancelled: true)
            isCancelZone = false
        @unknown default:
            break
        }
    }

    private func requestPermissionAndStartRecording() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let granted = await AudioRecorderManager.shared.requestPermissionIfNeeded()
            guard self.isPressing else { return }
            guard granted else {
                self.isPressing = false
                AppUtility.showToast("请在设置中允许使用麦克风")
                return
            }
            self.startVoiceRecording()
        }
    }

    private func startVoiceRecording() {
        guard !isRecording else { return }
        isRecording = true
        currentDuration = 0
        isCancelZone = false
        collapsePanel()

        let overlay = VoiceRecorderOverlay(frame: .zero)
        let host: UIView? = self.window ?? self.superview
        if let host = host {
            overlay.show(in: host)
            recorderOverlay = overlay
        }

        AudioRecorderManager.shared.onRecordingChanged = { [weak self] duration in
            guard let self = self, self.isRecording else { return }
            self.currentDuration = TimeInterval(duration)
            self.recorderOverlay?.updateDuration(self.currentDuration)
            // 录音时长上限 60 秒
            if self.currentDuration >= 60 {
                self.finishRecording(cancelled: false)
            }
        }

        AudioRecorderManager.shared.onRecordingFinished = { [weak self] data, duration in
            guard let self = self else { return }
            self.isRecording = false
            self.isPressing = false
            self.hideRecorderOverlay()
            AudioRecorderManager.shared.onRecordingChanged = nil
            AudioRecorderManager.shared.onRecordingFinished = nil

            let fileName = "voice_\(UUID().uuidString).m4a"
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            do {
                try data.write(to: url)
                self.delegate?.didSendVoiceMessage(fileURL: url, duration: TimeInterval(duration))
            } catch {
                AppUtility.showToast("语音发送失败")
            }
        }

        AudioRecorderManager.shared.startRecording()
    }

    private func finishRecording(cancelled: Bool) {
        guard isRecording else { return }
        isRecording = false
        AudioRecorderManager.shared.onRecordingChanged = nil

        if cancelled {
            AudioRecorderManager.shared.onRecordingFinished = nil
            AudioRecorderManager.shared.cancelRecording()
            hideRecorderOverlay()
            return
        }

        // 最短 1 秒（与 AudioRecorderManager 的丢弃阈值一致）
        if currentDuration < 1.0 {
            AudioRecorderManager.shared.onRecordingFinished = nil
            AudioRecorderManager.shared.cancelRecording()
            hideRecorderOverlay()
            AppUtility.showToast("说话时间太短")
            return
        }

        // stopRecording 会触发 onRecordingFinished 回调
        hideRecorderOverlay()
        AudioRecorderManager.shared.stopRecording()
    }

    private func hideRecorderOverlay() {
        recorderOverlay?.hide()
        recorderOverlay = nil
    }

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        guard !bounds.contains(point) else { return }
        textView.resignFirstResponder()
        if isMoreVisible || isEmojiVisible {
            collapsePanel()
        }
    }

    // MARK: - 对外文本操作

    /// 在光标处插入文本（如 @ 提及）
    func insertText(_ text: String) {
        if isVoiceMode {
            isVoiceMode = false
            textView.isHidden = false
            holdToTalkButton.isHidden = true
            voiceButton.setImage(UIImage(systemName: "mic"), for: .normal)
        }
        let current = textView.text ?? ""
        textView.text = current + text
        textViewDidChange(textView)
        textView.becomeFirstResponder()
        let end = textView.endOfDocument
        textView.selectedTextRange = textView.textRange(from: end, to: end)
    }

    /// 收起面板（容器高度归 0，输入栏恢复单行）
    private func collapsePanel() {
        isMoreVisible = false
        isEmojiVisible = false
        UIView.animate(withDuration: 0.25) {
            self.panelContainerHeight?.update(offset: 0)
            self.superview?.layoutIfNeeded()
        }
    }

    private func showEmojiPanel() {
        if emojiPanel == nil {
            let panel = EmojiPanelView()
            panel.delegate = self
            panelContainer.addSubview(panel)
            panel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            emojiPanel = panel
        }
        morePanel?.isHidden = true
        emojiPanel?.isHidden = false
        isMoreVisible = false
        isEmojiVisible = true
        superview?.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.panelContainerHeight?.update(offset: ScreenAdapter.scaleH(220))
            self.superview?.layoutIfNeeded()
        }
    }

    func hideEmojiPanel() {
        guard isEmojiVisible else { return }
        collapsePanel()
    }

    private func showMorePanel() {
        if morePanel == nil {
            let scrollView = UIScrollView()
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.alwaysBounceHorizontal = true
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.contentInset = UIEdgeInsets(top: 0,
                                                   left: ScreenAdapter.scaleW(16),
                                                   bottom: 0,
                                                   right: ScreenAdapter.scaleW(16))

            let stack = UIStackView()
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = ScreenAdapter.scaleW(12)

            let items: [(icon: String, title: String, action: Selector)] = [
                ("face.smiling", "表情", #selector(toggleEmojiPanel)),
                ("photo.on.rectangle", "图片", #selector(didTapPhoto)),
                ("note.text", "笔记", #selector(didTapNote)),
                ("star", "收藏", #selector(didTapFavorite)),
                ("camera", "相机", #selector(didTapCamera)),
                ("location", "定位", #selector(didTapLocation)),
                ("at", "群聊@", #selector(didTapMention))
            ]
            for item in items {
                stack.addArrangedSubview(makeToolButton(icon: item.icon, title: item.title, action: item.action))
            }

            scrollView.addSubview(stack)
            panelContainer.addSubview(scrollView)

            scrollView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
                make.height.equalTo(ScreenAdapter.scaleH(96))
            }
            stack.snp.makeConstraints { make in
                make.top.bottom.equalTo(scrollView.contentLayoutGuide)
                make.leading.trailing.equalTo(scrollView.contentLayoutGuide)
                make.height.equalTo(ScreenAdapter.scaleH(96))
            }
            morePanel = scrollView
        }
        emojiPanel?.isHidden = true
        morePanel?.isHidden = false
        isEmojiVisible = false
        isMoreVisible = true
        superview?.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.panelContainerHeight?.update(offset: ScreenAdapter.scaleH(180))
            self.superview?.layoutIfNeeded()
        }
    }

    /// 工具按钮：内部垂直 stack（图标 28x28 + 文字 11pt），整体 64x72，不依赖 insets
    private func makeToolButton(icon: String, title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(self, action: action, for: .touchUpInside)

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .themePrimary
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }

        let label = UILabel()
        label.text = title
        label.font = ScreenAdapter.font(11)
        label.textColor = .label
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = ScreenAdapter.scaleH(6)
        stack.isUserInteractionEnabled = false
        button.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        button.snp.makeConstraints { make in
            make.width.equalTo(ScreenAdapter.scaleW(64))
            make.height.equalTo(ScreenAdapter.scaleH(72))
        }
        return button
    }

    func hideMorePanel() {
        guard isMoreVisible else { return }
        collapsePanel()
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

    @objc private func didTapFavorite() {
        hideMorePanel()
        delegate?.didTapFavorite()
    }

    @objc private func didTapMention() {
        hideMorePanel()
        delegate?.didTapMentionButton()
    }
}

extension ChatInputBar: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        // 键盘弹出时收起面板（键盘替代面板位置）
        if isMoreVisible || isEmojiVisible {
            collapsePanel()
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        let minH = ScreenAdapter.scaleH(36)
        // 最多 5 行，超出后内部滚动
        let lineHeight = textView.font?.lineHeight ?? ScreenAdapter.font(15).lineHeight
        let maxH = ceil(lineHeight * 5 + textView.textContainerInset.top + textView.textContainerInset.bottom + 2)
        let size = CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude)
        let fitSize = textView.sizeThatFits(size)
        let height = min(max(fitSize.height, minH), maxH)
        textView.isScrollEnabled = fitSize.height > maxH
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
