//
//  ThemeComponents.swift
//  Milo
//
//  基础UI组件库 - 对齐安卓端自定义组件
//  包含：AvatarView, BadgeView, StateView, SkeletonView 等
//

import UIKit
import SnapKit
import Kingfisher

// MARK: - AvatarView 头像视图
/// 支持单头像、群组头像组合、边框、等级角标
class AvatarView: UIView {

    // MARK: - 子视图
    private let imageView = UIImageView()
    private let placeholderImageView = UIImageView()
    private var groupImageViews: [UIImageView] = []
    private let badgeLabel = UILabel()
    private let borderLayer = CAShapeLayer()

    // MARK: - 配置
    /// 头像样式
    enum AvatarStyle {
        case single       // 单人头
        case group(count: Int) // 群头像（2~4人）
    }

    var style: AvatarStyle = .single {
        didSet { updateStyle() }
    }

    /// 边框宽度
    var borderWidth: CGFloat = 0 {
        didSet { updateBorder() }
    }

    /// 边框颜色
    var borderColor: UIColor = .white {
        didSet { updateBorder() }
    }

    /// 角标数字（0 或 nil 则隐藏）
    var badgeValue: Int? = nil {
        didSet { updateBadge() }
    }

    /// 角标背景色
    var badgeBackgroundColor: UIColor = .themeError {
        didSet { badgeLabel.backgroundColor = badgeBackgroundColor }
    }

    /// 占位图
    var placeholderImage: UIImage? = UIImage(systemName: "person.circle.fill") {
        didSet { placeholderImageView.image = placeholderImage }
    }

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = true

        // 主头像
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .themeAvatarPlaceholderBg
        addSubview(imageView)

        // 占位图
        placeholderImageView.contentMode = .scaleAspectFit
        placeholderImageView.tintColor = .themeAvatarPlaceholderTint
        placeholderImageView.image = placeholderImage
        addSubview(placeholderImageView)

        // 角标
        badgeLabel.font = ThemeFont.tiny(10)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = badgeBackgroundColor
        badgeLabel.layer.masksToBounds = true
        badgeLabel.isHidden = true
        addSubview(badgeLabel)

        // 约束
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        placeholderImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        imageView.layer.cornerRadius = bounds.width / 2
        updateBorder()
        updateBadge()
    }

    // MARK: - 公开方法

    /// 设置头像 URL
    func setAvatar(url: URL?, placeholder: UIImage? = nil) {
        style = .single
        if let placeholder = placeholder {
            placeholderImageView.image = placeholder
        }

        guard let url = url else {
            imageView.image = nil
            placeholderImageView.isHidden = false
            return
        }

        placeholderImageView.isHidden = true
        imageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: [.transition(.fade(0.2)), .cacheOriginalImage]
        ) { [weak self] result in
            if case .failure = result {
                self?.placeholderImageView.isHidden = false
            }
        }
    }

    /// 设置群组头像（最多4个）
    func setGroupAvatars(urls: [URL?], maxCount: Int = 4) {
        let count = min(urls.count, maxCount)
        style = .group(count: count)

        for (index, url) in urls.prefix(maxCount).enumerated() {
            guard index < groupImageViews.count else { break }
            let imageView = groupImageViews[index]
            if let url = url {
                imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.fill"))
            } else {
                imageView.image = UIImage(systemName: "person.fill")
                imageView.tintColor = .systemGray4
            }
        }
    }

    // MARK: - 私有方法

    private func updateStyle() {
        // 清理旧的群头像
        groupImageViews.forEach { $0.removeFromSuperview() }
        groupImageViews.removeAll()

        switch style {
        case .single:
            imageView.isHidden = false
            placeholderImageView.isHidden = false

        case .group(let count):
            imageView.isHidden = true
            placeholderImageView.isHidden = true

            let cols = count <= 2 ? 2 : 2
            let rows = count <= 2 ? 1 : 2
            let gap: CGFloat = 2
            let itemSize = (bounds.width - gap) / CGFloat(cols)

            for i in 0..<count {
                let imgView = UIImageView()
                imgView.contentMode = .scaleAspectFill
                imgView.clipsToBounds = true
                imgView.backgroundColor = .themeAvatarPlaceholderBg
                imgView.image = UIImage(systemName: "person.fill")
                imgView.tintColor = .themeAvatarPlaceholderTint
                addSubview(imgView)
                groupImageViews.append(imgView)

                let row = i / cols
                let col = i % cols
                imgView.snp.makeConstraints { make in
                    make.width.height.equalTo(itemSize)
                    let leftOffset = CGFloat(col) * (itemSize + gap)
                    let topOffset = CGFloat(row) * (itemSize + gap)
                    make.left.equalToSuperview().offset(leftOffset)
                    make.top.equalToSuperview().offset(topOffset)
                }
            }
        }

        setNeedsLayout()
    }

    private func updateBorder() {
        guard borderWidth > 0 else {
            borderLayer.removeFromSuperlayer()
            return
        }

        borderLayer.path = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: bounds.width / 2
        ).cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.frame = bounds

        if borderLayer.superlayer == nil {
            layer.addSublayer(borderLayer)
        }
    }

    private func updateBadge() {
        guard let value = badgeValue, value > 0 else {
            badgeLabel.isHidden = true
            return
        }

        badgeLabel.isHidden = false
        let text = value > 99 ? "99+" : "\(value)"
        badgeLabel.text = text

        let size = (text as NSString).size(withAttributes: [.font: ThemeFont.tiny(10)])
        let badgeWidth = max(size.width + 8, 18)
        let badgeHeight: CGFloat = 18

        badgeLabel.frame = CGRect(
            x: bounds.width - badgeWidth + 4,
            y: -4,
            width: badgeWidth,
            height: badgeHeight
        )
        badgeLabel.layer.cornerRadius = badgeHeight / 2
    }
}

// MARK: - BadgeView 角标视图
/// 未读数 / 红点 角标
class BadgeView: UIView {

    enum BadgeType {
        case dot              // 小红点
        case number(Int)      // 数字
        case text(String)     // 文字（如 NEW）
    }

    private let label = UILabel()

    var type: BadgeType = .dot {
        didSet { updateType() }
    }

    var badgeColor: UIColor = .themeError {
        didSet { backgroundColor = badgeColor }
    }

    var textColor: UIColor = .white {
        didSet { label.textColor = textColor }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = badgeColor
        layer.masksToBounds = true

        label.font = ThemeFont.tiny(10)
        label.textColor = textColor
        label.textAlignment = .center
        addSubview(label)

        updateType()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        label.frame = bounds
    }

    private func updateType() {
        switch type {
        case .dot:
            label.isHidden = true
            // 小红点固定大小
        case .number(let value):
            label.isHidden = false
            if value > 99 {
                label.text = "99+"
            } else if value <= 0 {
                isHidden = true
                return
            } else {
                label.text = "\(value)"
            }
            isHidden = false
        case .text(let text):
            label.isHidden = false
            label.text = text
            isHidden = false
        }

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    override var intrinsicContentSize: CGSize {
        switch type {
        case .dot:
            return CGSize(width: 8, height: 8)
        case .number(let value):
            let text = value > 99 ? "99+" : "\(value)"
            let size = (text as NSString).size(withAttributes: [.font: ThemeFont.tiny(10)])
            let width = max(size.width + 8, 18)
            return CGSize(width: width, height: 18)
        case .text(let text):
            let size = (text as NSString).size(withAttributes: [.font: ThemeFont.tiny(10)])
            let width = max(size.width + 8, 18)
            return CGSize(width: width, height: 18)
        }
    }
}

// MARK: - StateView 多状态布局视图
/// 加载 / 空 / 错误 / 内容 四种状态
class StateView: UIView {

    enum State {
        case content        // 显示内容
        case loading        // 加载中
        case empty(title: String?, message: String?, icon: UIImage?)  // 空状态
        case error(title: String?, message: String?, retryTitle: String?) // 错误状态
    }

    // MARK: - 子视图
    private let contentView = UIView()
    private let loadingContainer = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let emptyContainer = UIView()
    private let emptyIconView = UIImageView()
    private let emptyTitleLabel = UILabel()
    private let emptyMessageLabel = UILabel()
    private let errorContainer = UIView()
    private let errorIconView = UIImageView()
    private let errorTitleLabel = UILabel()
    private let errorMessageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    // MARK: - 属性
    var currentState: State = .content {
        didSet { updateState() }
    }

    var onRetry: (() -> Void)?

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        // 内容视图
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 加载中
        loadingContainer.backgroundColor = .clear
        loadingContainer.isHidden = true
        addSubview(loadingContainer)
        loadingContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingContainer.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 空状态
        emptyContainer.backgroundColor = .clear
        emptyContainer.isHidden = true
        addSubview(emptyContainer)
        emptyContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyIconView.contentMode = .scaleAspectFit
        emptyIconView.tintColor = .themeTextHint
        emptyContainer.addSubview(emptyIconView)
        emptyIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.width.height.equalTo(80)
        }

        emptyTitleLabel.font = ThemeFont.title3(16)
        emptyTitleLabel.textColor = .themeTextPrimary
        emptyTitleLabel.textAlignment = .center
        emptyContainer.addSubview(emptyTitleLabel)
        emptyTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyIconView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(32)
        }

        emptyMessageLabel.font = ThemeFont.bodySmall(14)
        emptyMessageLabel.textColor = .themeTextSecondary
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.numberOfLines = 0
        emptyContainer.addSubview(emptyMessageLabel)
        emptyMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyTitleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(32)
        }

        // 错误状态
        errorContainer.backgroundColor = .clear
        errorContainer.isHidden = true
        addSubview(errorContainer)
        errorContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        errorIconView.contentMode = .scaleAspectFit
        errorIconView.tintColor = .themeError
        errorContainer.addSubview(errorIconView)
        errorIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.width.height.equalTo(80)
        }

        errorTitleLabel.font = ThemeFont.title3(16)
        errorTitleLabel.textColor = .themeTextPrimary
        errorTitleLabel.textAlignment = .center
        errorContainer.addSubview(errorTitleLabel)
        errorTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(errorIconView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(32)
        }

        errorMessageLabel.font = ThemeFont.bodySmall(14)
        errorMessageLabel.textColor = .themeTextSecondary
        errorMessageLabel.textAlignment = .center
        errorMessageLabel.numberOfLines = 0
        errorContainer.addSubview(errorMessageLabel)
        errorMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(errorTitleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(32)
        }

        retryButton.configureAsThemeButton(title: "重新加载", fontSize: 14)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        errorContainer.addSubview(retryButton)
        retryButton.snp.makeConstraints { make in
            make.top.equalTo(errorMessageLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(36)
        }
    }

    // MARK: - 公开方法

    /// 设置内容视图
    func setContentView(_ view: UIView) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 显示内容
    func showContent() {
        currentState = .content
    }

    /// 显示加载中
    func showLoading() {
        currentState = .loading
        activityIndicator.startAnimating()
    }

    /// 显示空状态
    func showEmpty(title: String? = nil, message: String? = nil, icon: UIImage? = nil) {
        currentState = .empty(title: title, message: message, icon: icon)
    }

    /// 显示错误状态
    func showError(title: String? = "加载失败", message: String? = nil, retryTitle: String? = "重新加载") {
        currentState = .error(title: title, message: message, retryTitle: retryTitle)
    }

    // MARK: - 私有方法

    private func updateState() {
        switch currentState {
        case .content:
            contentView.isHidden = false
            loadingContainer.isHidden = true
            emptyContainer.isHidden = true
            errorContainer.isHidden = true
            activityIndicator.stopAnimating()

        case .loading:
            contentView.isHidden = true
            loadingContainer.isHidden = false
            emptyContainer.isHidden = true
            errorContainer.isHidden = true
            activityIndicator.startAnimating()

        case .empty(let title, let message, let icon):
            contentView.isHidden = true
            loadingContainer.isHidden = true
            emptyContainer.isHidden = false
            errorContainer.isHidden = true
            activityIndicator.stopAnimating()

            emptyTitleLabel.text = title
            emptyTitleLabel.isHidden = title == nil
            emptyMessageLabel.text = message
            emptyMessageLabel.isHidden = message == nil
            emptyIconView.image = icon ?? UIImage(systemName: "tray")
            emptyIconView.isHidden = icon == nil && emptyIconView.image == nil
        }
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}

// MARK: - SkeletonView 骨架屏视图
/// 骨架屏加载动画
class SkeletonView: UIView {

    // MARK: - 骨架元素
    struct SkeletonItem {
        var frame: CGRect
        var cornerRadius: CGFloat = 4
    }

    private let gradientLayer = CAGradientLayer()
    private let maskLayer = CAShapeLayer()
    private var skeletonItems: [SkeletonItem] = []

    var isAnimating: Bool = false {
        didSet {
            if isAnimating {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .themeSkeletonBg

        // 渐变层
        gradientLayer.colors = [
            UIColor.themeSkeletonBg.cgColor,
            UIColor.themeSkeletonShimmer.cgColor,
            UIColor.themeSkeletonBg.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.mask = maskLayer
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateMaskPath()
    }

    // MARK: - 公开方法

    /// 设置骨架项
    func setSkeletonItems(_ items: [SkeletonItem]) {
        skeletonItems = items
        updateMaskPath()
    }

    /// 从视图生成骨架（自动识别子视图）
    func generateSkeleton(from view: UIView) {
        var items: [SkeletonItem] = []
        for subview in view.subviews {
            if subview is UILabel || subview is UIImageView || subview is UIButton {
                let frame = convert(subview.frame, from: subview.superview)
                let radius: CGFloat
                if subview is UILabel {
                    radius = 4
                } else if subview.layer.cornerRadius > 0 {
                    radius = subview.layer.cornerRadius
                } else {
                    radius = 4
                }
                items.append(SkeletonItem(frame: frame, cornerRadius: radius))
            }
        }
        setSkeletonItems(items)
    }

    // MARK: - 私有方法

    private func updateMaskPath() {
        let path = UIBezierPath()
        for item in skeletonItems {
            let rectPath = UIBezierPath(
                roundedRect: item.frame,
                cornerRadius: item.cornerRadius
            )
            path.append(rectPath)
        }
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.black.cgColor
    }

    private func startAnimation() {
        isHidden = false

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        gradientLayer.add(animation, forKey: "skeletonShimmer")
    }

    private func stopAnimation() {
        gradientLayer.removeAnimation(forKey: "skeletonShimmer")
        isHidden = true
    }
}

// MARK: - MarqueeLabel 跑马灯标签
/// 文字横向滚动跑马灯效果
class MarqueeLabel: UIView {

    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private var scrollView = UIScrollView()

    var text: String? {
        didSet { updateText() }
    }

    var font: UIFont = ThemeFont.body(14) {
        didSet {
            firstLabel.font = font
            secondLabel.font = font
            updateText()
        }
    }

    var textColor: UIColor = .themeTextPrimary {
        didSet {
            firstLabel.textColor = textColor
            secondLabel.textColor = textColor
        }
    }

    var scrollSpeed: CGFloat = 30 // 每秒移动的点数
    var gap: CGFloat = 30 // 两个标签之间的间距

    private var displayLink: CADisplayLink?
    private var isScrolling = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        clipsToBounds = true

        scrollView.isScrollEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        firstLabel.font = font
        firstLabel.textColor = textColor
        scrollView.addSubview(firstLabel)

        secondLabel.font = font
        secondLabel.textColor = textColor
        scrollView.addSubview(secondLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        updateText()
    }

    private func updateText() {
        guard let text = text else {
            firstLabel.text = nil
            secondLabel.text = nil
            stopScrolling()
            return
        }

        firstLabel.text = text
        secondLabel.text = text

        let textSize = (text as NSString).size(withAttributes: [.font: font])
        let textWidth = textSize.width

        // 如果文字宽度小于视图宽度，不滚动
        if textWidth <= bounds.width {
            scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height)
            firstLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            firstLabel.textAlignment = .left
            secondLabel.isHidden = true
            stopScrolling()
            return
        }

        secondLabel.isHidden = false
        firstLabel.textAlignment = .left
        secondLabel.textAlignment = .left

        firstLabel.frame = CGRect(x: 0, y: 0, width: textWidth, height: bounds.height)
        secondLabel.frame = CGRect(x: textWidth + gap, y: 0, width: textWidth, height: bounds.height)
        scrollView.contentSize = CGSize(width: textWidth * 2 + gap, height: bounds.height)

        startScrolling()
    }

    private func startScrolling() {
        guard !isScrolling else { return }
        isScrolling = true

        displayLink = CADisplayLink(target: self, selector: #selector(scrollStep))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopScrolling() {
        isScrolling = false
        displayLink?.invalidate()
        displayLink = nil
        scrollView.contentOffset = .zero
    }

    @objc private func scrollStep() {
        guard let displayLink = displayLink else { return }

        let delta = scrollSpeed * CGFloat(displayLink.duration)
        var offset = scrollView.contentOffset.x + delta

        let textWidth = firstLabel.bounds.width
        if offset >= textWidth + gap {
            offset -= textWidth + gap
        }

        scrollView.contentOffset = CGPoint(x: offset, y: 0)
    }

    deinit {
        stopScrolling()
    }
}
