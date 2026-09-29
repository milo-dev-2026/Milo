import UIKit
import SnapKit
import Kingfisher

// MARK: - GIF 消息内容模型
/// GIF 消息内容格式：JSON
/// { "url": "xxx.gif", "width": 200, "height": 200, "preview": "xxx.jpg" }
struct GIFMessageContent {

    var url: String
    var width: CGFloat
    var height: CGFloat
    var preview: String?

    /// 从消息内容解析 GIF 信息
    /// - 支持 JSON 格式
    /// - 兼容旧的纯 URL 格式（自动转成正方形）
    static func parse(from content: String) -> GIFMessageContent? {
        // 兼容纯 URL 格式
        if !content.hasPrefix("{") {
            return GIFMessageContent(
                url: content,
                width: 200,
                height: 200,
                preview: nil
            )
        }

        guard let data = content.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let url = dict["url"] as? String ?? ""
        guard !url.isEmpty else { return nil }

        let width = CGFloat((dict["width"] as? NSNumber)?.floatValue ?? 200)
        let height = CGFloat((dict["height"] as? NSNumber)?.floatValue ?? 200)
        let preview = dict["preview"] as? String

        return GIFMessageContent(url: url, width: width, height: height, preview: preview)
    }

    /// 解析预览图 URL
    func previewURL() -> URL? {
        return GIFMessageContent.resolveURL(preview ?? url)
    }

    /// 解析 GIF 原图 URL
    func gifURL() -> URL? {
        return GIFMessageContent.resolveURL(url)
    }

    /// 将字符串路径解析为完整 URL
    private static func resolveURL(_ path: String) -> URL? {
        if path.hasPrefix("http") {
            return URL(string: path)
        } else if path.hasPrefix("/") {
            return URL(string: APIConfig.apiBaseURL + path)
        } else {
            return URL(string: APIConfig.apiBaseURL + "/" + path)
        }
    }

    /// 计算等比缩放后的展示尺寸
    func displaySize(maxSide: CGFloat) -> CGSize {
        guard width > 0, height > 0 else { return CGSize(width: maxSide, height: maxSide) }
        let aspect = width / height
        if width >= height {
            let w = maxSide
            let h = w / aspect
            return CGSize(width: w, height: h)
        } else {
            let h = maxSide
            let w = h * aspect
            return CGSize(width: w, height: h)
        }
    }
}

// MARK: - GIF 动图消息 Cell
class GIFMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let imageView_ = UIImageView()
    private let timeLabel = UILabel()
    private let avatarView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var isFromMe = false

    // MARK: - 圆形进度环
    private let progressRingView = UIView()
    private let progressRingLayer = CAShapeLayer()
    private let progressTrackLayer = CAShapeLayer()
    private var progressTimer: Timer?
    private var simulatedProgress: Float = 0

    // MARK: - 加载失败状态
    private let retryImageView = UIImageView()
    private var isLoadFailed = false
    var onRetry: (() -> Void)?

    // MARK: - GIF 标识
    private let gifBadgeView = UIView()
    private let gifBadgeLabel = UILabel()

    // MARK: - GIF 模拟播放（静态图 + 闪烁的 GIF 标签）
    /// 当前为模拟实现：使用静态预览图 + "GIF" 标签表示。
    /// 接入真实 GIF 库（FLAnimatedImage / CGAnimatedImage）后替换 playGIF / stopGIF 即可。
    private var isPlaying = false
    private static let gifBlinkAnimationKey = "gifBadgeBlink"

    // MARK: - 群聊已读状态
    private let readCountLabel = UILabel()
    var onReadReceiptTapped: (() -> Void)?

    // MARK: - 时间分隔头
    let timeHeaderLabel = UILabel()
    private var showsTimeHeader = false

    // 对外暴露 imageView 与 bubbleView，便于 Hero 转场与定位
    var heroImageView: UIImageView { imageView_ }
    var bubbleViewFrame: CGRect { return bubbleView.frame }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupPressGesture()
        setupProgressRing()
        setupRetryView()
        setupGIFBadge()
        setupReadCountLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 复用时停止 GIF 播放，避免内存泄漏
        stopGIF()
        stopSimulatedProgress()
    }

    private func setupUI() {
        selectionStyle = .none

        let avatarSize = ScreenAdapter.scaleW(36)
        let vPad = ScreenAdapter.scaleH(12)

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
        imageView_.isUserInteractionEnabled = true

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemGray2
        loadingIndicator.isHidden = true // 使用进度环替代

        // 时间分隔头
        timeHeaderLabel.font = ScreenAdapter.font(12)
        timeHeaderLabel.textColor = .tertiaryLabel
        timeHeaderLabel.textAlignment = .center
        timeHeaderLabel.isHidden = true
        timeHeaderLabel.alpha = 0

        bubbleView.addSubview(imageView_)
        bubbleView.addSubview(loadingIndicator)
        bubbleView.addSubview(progressRingView)
        bubbleView.addSubview(retryImageView)
        bubbleView.addSubview(gifBadgeView)
        contentView.addSubviews(timeHeaderLabel, avatarView, bubbleView, timeLabel, readCountLabel)

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

        imageView_.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        progressRingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(36)
        }

        retryImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(36)
        }

        gifBadgeView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
        }

        readCountLabel.snp.makeConstraints { make in
            make.width.height.equalTo(0)
        }
    }

    // MARK: - GIF 标识设置
    private func setupGIFBadge() {
        gifBadgeView.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        gifBadgeView.layer.cornerRadius = ScreenAdapter.scaleW(3)
        gifBadgeView.layer.masksToBounds = true

        gifBadgeLabel.text = AppStrings.Chat.gifBadge
        gifBadgeLabel.font = ScreenAdapter.boldFont(10)
        gifBadgeLabel.textColor = .white
        gifBadgeLabel.textAlignment = .center

        gifBadgeView.addSubview(gifBadgeLabel)
        gifBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4))
        }
    }

    // MARK: - 群聊已读状态
    private func setupReadCountLabel() {
        readCountLabel.font = ScreenAdapter.font(10)
        readCountLabel.textColor = .tertiaryLabel
        readCountLabel.text = ""
        readCountLabel.isHidden = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleReadReceiptTap))
        readCountLabel.addGestureRecognizer(tap)
        readCountLabel.isUserInteractionEnabled = true
    }

    @objc private func handleReadReceiptTap() {
        guard AnimationIntegration.shared.config.enableHapticFeedback else {
            onReadReceiptTapped?()
            return
        }
        HapticManager.shared.impactLight()
        onReadReceiptTapped?()
    }

    // MARK: - 圆形进度环设置
    private func setupProgressRing() {
        let ringSize: CGFloat = 36
        let lineWidth: CGFloat = 3
        let center = CGPoint(x: ringSize / 2, y: ringSize / 2)
        let radius = (ringSize - lineWidth) / 2

        // 背景轨道
        progressTrackLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: CGFloat.pi * 1.5,
            clockwise: true
        ).cgPath
        progressTrackLayer.fillColor = UIColor.clear.cgColor
        progressTrackLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
        progressTrackLayer.lineWidth = lineWidth
        progressTrackLayer.lineCap = .round
        progressRingView.layer.addSublayer(progressTrackLayer)

        // 进度环
        progressRingLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: CGFloat.pi * 1.5,
            clockwise: true
        ).cgPath
        progressRingLayer.fillColor = UIColor.clear.cgColor
        progressRingLayer.strokeColor = UIColor.white.cgColor
        progressRingLayer.lineWidth = lineWidth
        progressRingLayer.lineCap = .round
        progressRingLayer.strokeEnd = 0
        progressRingView.layer.addSublayer(progressRingLayer)

        progressRingView.isHidden = true
    }

    // MARK: - 重试图标设置
    private func setupRetryView() {
        retryImageView.image = UIImage(systemName: "arrow.clockwise")
        retryImageView.tintColor = .white
        retryImageView.contentMode = .scaleAspectFit
        retryImageView.isHidden = true
        retryImageView.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRetryTap))
        retryImageView.addGestureRecognizer(tapGesture)

        // 图片点击手势（用于重试）
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        imageView_.addGestureRecognizer(imageTap)
    }

    @objc private func handleImageTap() {
        if isLoadFailed {
            handleRetryTap()
        }
    }

    @objc private func handleRetryTap() {
        guard isLoadFailed else { return }
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }
        onRetry?()
    }

    // MARK: - 进度更新
    func setDownloadProgress(_ progress: Float) {
        guard !isLoadFailed else { return }
        progressRingView.isHidden = false
        progressRingView.alpha = 1

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressRingLayer.strokeEnd
        animation.toValue = progress
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressRingLayer.add(animation, forKey: "progress")

        if progress >= 1.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.hideProgressRing()
            }
        }
    }

    private func hideProgressRing() {
        UIView.animate(withDuration: 0.2, animations: {
            self.progressRingView.alpha = 0
        }) { _ in
            self.progressRingView.isHidden = true
            self.progressRingView.alpha = 1
            self.progressRingLayer.strokeEnd = 0
        }
    }

    // MARK: - 模拟进度
    private func startSimulatedProgress() {
        stopSimulatedProgress()
        simulatedProgress = 0
        progressRingLayer.strokeEnd = 0
        progressRingView.isHidden = false
        progressRingView.alpha = 1

        if AnimationIntegration.shared.config.enableListEntranceAnimation {
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.simulatedProgress < 0.85 {
                    self.simulatedProgress += 0.04
                    self.progressRingLayer.strokeEnd = CGFloat(self.simulatedProgress)
                }
            }
        }
    }

    private func stopSimulatedProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func completeSimulatedProgress() {
        stopSimulatedProgress()
        if AnimationIntegration.shared.config.enableListEntranceAnimation {
            setDownloadProgress(1.0)
        } else {
            progressRingLayer.strokeEnd = 1.0
            hideProgressRing()
        }
    }

    // MARK: - 加载失败状态
    private func showLoadFailedState() {
        isLoadFailed = true
        stopSimulatedProgress()

        // 隐藏进度环
        progressRingView.isHidden = true

        // 显示重试图标
        retryImageView.isHidden = false
        retryImageView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.retryImageView.alpha = 1
        }

        // 红色边框
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = UIColor.systemRed.cgColor

        // 抖动动画
        if AnimationIntegration.shared.config.enableListEntranceAnimation {
            let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
            shake.values = [-4, 4, -4, 4, -2, 2, 0]
            shake.duration = 0.4
            shake.timingFunction = CAMediaTimingFunction(name: .easeOut)
            bubbleView.layer.add(shake, forKey: "shake")
        }
    }

    private func resetLoadState() {
        isLoadFailed = false
        retryImageView.isHidden = true
        retryImageView.alpha = 1
        bubbleView.layer.borderWidth = 0
        bubbleView.layer.borderColor = nil
        bubbleView.layer.removeAnimation(forKey: "shake")
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

    // MARK: - GIF 播放控制
    /// cell 可见时调用，启动 GIF "播放" 效果（当前为标签闪烁模拟）
    func playGIF() {
        guard !isLoadFailed else { return }
        guard !isPlaying else { return }
        isPlaying = true

        // 模拟播放：GIF 标签闪烁，提示这是一个动图
        guard AnimationIntegration.shared.config.enableButtonPressAnimation else { return }
        let blink = CABasicAnimation(keyPath: "opacity")
        blink.fromValue = 1.0
        blink.toValue = 0.45
        blink.duration = 0.8
        blink.autoreverses = true
        blink.repeatCount = .infinity
        blink.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gifBadgeView.layer.add(blink, forKey: GIFMessageCell.gifBlinkAnimationKey)
    }

    /// cell 不可见/复用时调用，停止 GIF "播放"
    func stopGIF() {
        guard isPlaying else { return }
        isPlaying = false
        gifBadgeView.layer.removeAnimation(forKey: GIFMessageCell.gifBlinkAnimationKey)
    }

    // MARK: - 配置消息
    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let maxSide = ScreenAdapter.scaleW(160)

        guard let gifContent = GIFMessageContent.parse(from: message.content) else {
            // 内容解析失败，显示占位
            imageView_.image = UIImage(systemName: "photo")
            imageView_.alpha = 1
            resetLoadState()
            progressRingView.isHidden = true
            stopSimulatedProgress()
            return
        }

        let displaySize = gifContent.displaySize(maxSide: maxSide)

        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(displaySize.width)
                make.height.equalTo(displaySize.height)
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
                make.width.equalTo(displaySize.width)
                make.height.equalTo(displaySize.height)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }

        // 加载预览图（优先使用 preview 字段，回退到 GIF URL）
        let previewURL = gifContent.previewURL()
        if let url = previewURL {
            // 重置加载状态
            resetLoadState()
            // 开始模拟进度
            startSimulatedProgress()
            imageView_.alpha = 0

            let enableAnim = AnimationIntegration.shared.config.enableListEntranceAnimation

            imageView_.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: enableAnim ? [.transition(.fade(0.3))] : []
            ) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.completeSimulatedProgress()
                        if enableAnim {
                            // 入场动画：淡入 + 缩放
                            self.imageView_.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                                self.imageView_.alpha = 1
                                self.imageView_.transform = .identity
                            }
                        } else {
                            self.imageView_.alpha = 1
                        }
                    case .failure:
                        self.showLoadFailedState()
                        self.imageView_.alpha = 0.3
                    }
                }
            }
        } else {
            imageView_.image = UIImage(systemName: "photo")
            imageView_.alpha = 1
            resetLoadState()
            progressRingView.isHidden = true
            stopSimulatedProgress()
        }
    }

    // MARK: - 群聊已读状态
    func configureGroupReadStatus(isGroup: Bool, readCount: Int) {
        if isGroup && isFromMe && readCount > 0 {
            readCountLabel.isHidden = false
            readCountLabel.text = "\(readCount)人未读"
            readCountLabel.snp.remakeConstraints { make in
                if isFromMe {
                    make.trailing.equalTo(bubbleView.snp.leading).offset(-ScreenAdapter.scaleW(4))
                } else {
                    make.leading.equalTo(bubbleView.snp.trailing).offset(ScreenAdapter.scaleW(4))
                }
                make.bottom.equalTo(bubbleView.snp.bottom).offset(-ScreenAdapter.scaleH(2))
            }
        } else {
            readCountLabel.isHidden = true
            readCountLabel.text = ""
            readCountLabel.snp.remakeConstraints { make in
                make.width.height.equalTo(0)
            }
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
extension GIFMessageCell {

    @objc override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
