//
//  ThemeScrollAnimations.swift
//  Milo
//
//  滚动动效增强
//  包含：视差滚动、集合视图动画、下拉刷新、上拉加载
//

import UIKit

// MARK: - 视差滚动头图效果
final class ParallaxHeaderView: UIView {

    // MARK: - 配置
    var parallaxFactor: CGFloat = 0.5       // 视差系数 (0~1)
    var minHeight: CGFloat = 88             // 最小高度（导航栏高度）
    var maxHeight: CGFloat = 250            // 最大高度（初始头图高度）

    // MARK: - 子视图
    private let imageView = UIImageView()
    private let overlayView = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .system)

    // MARK: - 回调
    var onBackTapped: (() -> Void)?

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
        clipsToBounds = false

        // 背景图
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .themeColorPrimary.withAlphaComponent(0.3)
        addSubview(imageView)

        // 遮罩层
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(overlayView)

        // 返回按钮
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        backButton.layer.cornerRadius = 18
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        addSubview(backButton)

        // 标题
        titleLabel.font = ThemeFont.title2(18)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        addSubview(titleLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let height = bounds.height
        imageView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: height)
        overlayView.frame = imageView.frame

        backButton.frame = CGRect(x: 12, y: safeAreaInsets.top + 6, width: 36, height: 36)

        titleLabel.frame = CGRect(x: 60, y: safeAreaInsets.top + 10,
                                  width: bounds.width - 120, height: 30)
    }

    // MARK: - 公开方法

    /// 设置头图
    func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    /// 设置标题
    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    /// 根据滚动偏移更新视差效果
    func update(with scrollOffset: CGFloat) {
        let offset = scrollOffset < 0 ? scrollOffset : 0
        let height = maxHeight - offset

        // 更新高度
        var frame = self.frame
        frame.size.height = max(minHeight, height)
        frame.origin.y = offset < 0 ? offset : 0
        self.frame = frame

        // 计算进度 (0 = 展开状态, 1 = 收起状态)
        let progress = min(max((scrollOffset - 0) / (maxHeight - minHeight), 0), 1)

        // 标题淡入
        titleLabel.alpha = progress
        titleLabel.transform = CGAffineTransform(translationX: 0, y: (1 - progress) * 10)

        // 遮罩透明度变化
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3 + progress * 0.4)

        // 背景图视差移动
        if scrollOffset < 0 {
            // 下拉放大
            let scale = 1 + (-scrollOffset / maxHeight) * 0.5
            imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        } else {
            imageView.transform = .identity
        }
    }

    @objc private func backTapped() {
        onBackTapped?()
    }
}

// MARK: - 集合视图动画扩展
extension UICollectionView {

    /// 瀑布流入场动画（克制版：缩放0.9+位移10pt，弹性更内敛）
    func animateWaterfallIn(duration: TimeInterval = AnimationDuration.slow, delayPerItem: TimeInterval = 0.03) {
        let visibleItems = indexPathsForVisibleItems.sorted { $0.item < $1.item }
        for (index, indexPath) in visibleItems.enumerated() {
            guard let cell = cellForItem(at: indexPath) else { continue }

            cell.alpha = 0
            cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).translatedBy(x: 0, y: 10)

            UIView.animate(withDuration: duration,
                           delay: delayPerItem * Double(index),
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.4,
                           options: .curveEaseOut) {
                cell.alpha = 1
                cell.transform = .identity
            }
        }
    }

    /// 网格入场动画（交错淡入）
    func animateGridIn(duration: TimeInterval = AnimationDuration.normal, staggerDelay: TimeInterval = 0.03) {
        let visibleItems = indexPathsForVisibleItems.sorted { $0.item < $1.item }
        for (index, indexPath) in visibleItems.enumerated() {
            guard let cell = cellForItem(at: indexPath) else { continue }

            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 15)

            UIView.animate(withDuration: duration,
                           delay: staggerDelay * Double(index),
                           options: .curveEaseOut) {
                cell.alpha = 1
                cell.transform = .identity
            }
        }
    }
}

// MARK: - 自定义下拉刷新控件
final class PullToRefreshControl: UIView {

    // MARK: - 状态
    enum RefreshState {
        case idle       // 闲置
        case pulling    // 下拉中
        case refreshing // 刷新中
        case ending     // 结束中
    }

    private(set) var state: RefreshState = .idle
    var onRefresh: (() -> Void)?

    // MARK: - UI
    private let indicatorView = RefreshIndicatorView()
    private let statusLabel = UILabel()
    private let arrowImageView = UIImageView()

    private var scrollView: UIScrollView?
    private var originalTopInset: CGFloat = 0
    private let triggerHeight: CGFloat = 60

    // MARK: - 配置
    var pullText = "下拉可以刷新"
    var releaseText = "释放立即刷新"
    var refreshingText = "正在刷新..."

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

        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-50)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        statusLabel.font = ThemeFont.caption(13)
        statusLabel.textColor = .themeTextSecondary
        statusLabel.text = pullText
        addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.left.equalTo(indicatorView.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }

        arrowImageView.image = UIImage(systemName: "arrow.down")
        arrowImageView.tintColor = .themeColorPrimary
        arrowImageView.contentMode = .scaleAspectFit
        addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.centerX.equalTo(indicatorView)
            make.centerY.equalTo(indicatorView)
            make.width.height.equalTo(16)
        }
    }

    // MARK: - 关联 ScrollView
    func attach(to scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.originalTopInset = scrollView.contentInset.top
        scrollView.addSubview(self)
        scrollView.sendSubviewToBack(self)

        // KVO 监听滚动
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
    }

    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            handleScroll()
        }
    }

    private func handleScroll() {
        guard let scrollView = scrollView else { return }

        let offsetY = scrollView.contentOffset.y + originalTopInset
        let pullDistance = -offsetY

        // 更新位置
        self.frame = CGRect(x: 0, y: -triggerHeight,
                            width: scrollView.bounds.width, height: triggerHeight)

        switch state {
        case .idle:
            if scrollView.isDragging && pullDistance > 0 {
                state = .pulling
                updatePullProgress(pullDistance / triggerHeight)
            }

        case .pulling:
            let progress = min(pullDistance / triggerHeight, 1.0)
            updatePullProgress(progress)

            if !scrollView.isDragging && pullDistance >= triggerHeight {
                beginRefreshing()
            } else if scrollView.isDragging && pullDistance <= 0 {
                state = .idle
                resetState()
            }

        case .refreshing, .ending:
            break
        }
    }

    private func updatePullProgress(_ progress: CGFloat) {
        indicatorView.updateProgress(progress)
        arrowImageView.isHidden = progress >= 1.0

        if progress >= 1.0 {
            statusLabel.text = releaseText
            // 箭头旋转
            UIView.animate(withDuration: 0.2) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
            }
        } else {
            statusLabel.text = pullText
            UIView.animate(withDuration: 0.2) {
                self.arrowImageView.transform = .identity
            }
        }
    }

    /// 开始刷新
    func beginRefreshing() {
        guard state != .refreshing else { return }
        state = .refreshing

        statusLabel.text = refreshingText
        arrowImageView.isHidden = true
        indicatorView.startAnimating()

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [weak self] in
            guard let self = self, let scrollView = self.scrollView else { return }
            scrollView.contentInset.top = self.originalTopInset + self.triggerHeight
        }

        onRefresh?()
    }

    /// 结束刷新
    func endRefreshing() {
        guard state == .refreshing else { return }
        state = .ending

        indicatorView.stopAnimating()

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
            guard let self = self, let scrollView = self.scrollView else { return }
            scrollView.contentInset.top = self.originalTopInset
        } completion: { [weak self] _ in
            self?.state = .idle
            self?.resetState()
        }
    }

    private func resetState() {
        statusLabel.text = pullText
        arrowImageView.isHidden = false
        arrowImageView.transform = .identity
        indicatorView.stopAnimating()
    }
}

// MARK: - 上拉加载更多控件
final class LoadMoreFooterView: UIView {

    enum LoadState {
        case idle       // 闲置
        case loading    // 加载中
        case noMore     // 没有更多
        case failed     // 加载失败
    }

    private(set) var state: LoadState = .idle
    var onLoadMore: (() -> Void)?

    private let indicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        indicator.hidesWhenStopped = true
        indicator.color = .themeColorPrimary
        addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-60)
            make.centerY.equalToSuperview()
        }

        statusLabel.font = ThemeFont.caption(13)
        statusLabel.textColor = .themeTextSecondary
        statusLabel.text = "上拉加载更多"
        statusLabel.textAlignment = .center
        addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        retryButton.setTitle("加载失败，点击重试", for: .normal)
        retryButton.titleLabel?.font = ThemeFont.caption(13)
        retryButton.setTitleColor(.themeColorPrimary, for: .normal)
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        addSubview(retryButton)
        retryButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    /// 设置状态
    func setState(_ state: LoadState) {
        self.state = state

        switch state {
        case .idle:
            statusLabel.isHidden = false
            statusLabel.text = "上拉加载更多"
            indicator.stopAnimating()
            retryButton.isHidden = true

        case .loading:
            statusLabel.isHidden = false
            statusLabel.text = "加载中..."
            indicator.startAnimating()
            retryButton.isHidden = true
            onLoadMore?()

        case .noMore:
            statusLabel.isHidden = false
            statusLabel.text = "没有更多了"
            indicator.stopAnimating()
            retryButton.isHidden = true

        case .failed:
            statusLabel.isHidden = true
            indicator.stopAnimating()
            retryButton.isHidden = false
        }
    }

    @objc private func retryTapped() {
        setState(.loading)
    }
}

// MARK: - 渐变导航栏效果
final class TransparentNavigationBar {

    /// 配置导航栏透明度渐变效果
    static func setupGradient(for navigationBar: UINavigationBar,
                              with scrollView: UIScrollView,
                              threshold: CGFloat = 200) {
        let offsetY = scrollView.contentOffset.y + scrollView.contentInset.top
        let progress = min(max(offsetY / threshold, 0), 1)

        if let appearance = navigationBar.standardAppearance as? UINavigationBarAppearance {
            appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
            appearance.backgroundColor = UIColor.themeBgWhite.withAlphaComponent(progress)
        }
    }
}

// MARK: - 滚动渐变头部（简易版）
extension UIViewController {

    /// 添加滚动渐变导航效果
    func addScrollGradientNavigation(scrollView: UIScrollView, threshold: CGFloat = 100) {
        let offsetY = scrollView.contentOffset.y
        let progress = min(max(offsetY / threshold, 0), 1)

        // 导航栏透明度
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.backgroundColor = .themeBgWhite.withAlphaComponent(progress)
        navigationController?.navigationBar.shadowImage = progress > 0.9 ? UIImage() : UIImage()
    }
}
