import UIKit
import SnapKit
import Kingfisher
import WuKongIMSDK

// MARK: - 图片消息历史页（对标 Android ImageMessageHistoryActivity）
class ImageMessageHistoryViewController: UIViewController {

    // MARK: - 数据模型
    private struct ImageItem {
        let messageId: String
        let url: String
        let timestamp: Int64 // 秒
        let messageSeq: UInt32
    }

    // MARK: - 属性
    private let channelId: String
    private let channelType: Int
    private var items: [ImageItem] = []
    private var oldestSeq: UInt32 = 0
    private var isLoading = false
    private var hasMore = true

    private let refreshControl = UIRefreshControl()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = ScreenAdapter.scaleW(2)
        layout.minimumInteritemSpacing = ScreenAdapter.scaleW(2)
        layout.sectionInset = .zero
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .themeBackground
        cv.register(ImageHistoryCell.self, forCellWithReuseIdentifier: "ImageHistoryCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无图片"
        label.font = ScreenAdapter.font(15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - 初始化
    init(channelId: String, channelType: Int = 1) {
        self.channelId = channelId
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        self.init(channelId: "", channelType: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "图片历史"
        view.backgroundColor = .themeBackground
        setupUI()
        loadInitial()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI
    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        refreshControl.addTarget(self, action: #selector(loadMore), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - 数据加载
    private func loadInitial() {
        guard !channelId.isEmpty else {
            emptyLabel.isHidden = false
            return
        }
        isLoading = true
        IMManager.shared.pullLastMessages(channelId: channelId, channelType: channelType, limit: 100) { [weak self] messages, error in
            guard let self = self else { return }
            self.isLoading = false
            guard error == nil, let messages = messages, !messages.isEmpty else {
                self.emptyLabel.isHidden = !self.items.isEmpty
                return
            }
            self.appendMessages(messages)
            self.emptyLabel.isHidden = !self.items.isEmpty
        }
    }

    @objc private func loadMore() {
        guard !channelId.isEmpty, hasMore, !isLoading, oldestSeq > 0 else {
            refreshControl.endRefreshing()
            return
        }
        isLoading = true
        IMManager.shared.pullDownMessages(channelId: channelId, channelType: channelType, startOrderSeq: oldestSeq, limit: 100) { [weak self] messages, error in
            guard let self = self else { return }
            self.isLoading = false
            self.refreshControl.endRefreshing()
            guard error == nil, let messages = messages, !messages.isEmpty else {
                self.hasMore = false
                return
            }
            self.appendMessages(messages)
        }
    }

    private func appendMessages(_ messages: [WKMessage]) {
        let imageMsgs = messages.filter { Int($0.content.realContentType) == 2 }
        let newItems: [ImageItem] = imageMsgs.compactMap { msg in
            guard let imageContent = msg.content as? WKImageMessageContent, !imageContent.url.isEmpty else { return nil }
            return ImageItem(
                messageId: String(msg.messageId),
                url: imageContent.url,
                timestamp: Int64(msg.timestamp),
                messageSeq: msg.messageSeq
            )
        }
        items.append(contentsOf: newItems)
        // 按时间倒序
        items.sort { $0.timestamp > $1.timestamp }
        if let minSeq = messages.map({ $0.messageSeq }).min(), minSeq > 0 {
            oldestSeq = minSeq
        }
        collectionView.reloadData()
    }

    private func fullURL(for path: String) -> URL? {
        if path.hasPrefix("http") {
            return URL(string: path)
        } else if path.hasPrefix("/") {
            return URL(string: APIConfig.apiBaseURL + path)
        }
        return URL(string: APIConfig.apiBaseURL + "/" + path)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension ImageMessageHistoryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageHistoryCell", for: indexPath) as! ImageHistoryCell
        cell.configure(with: fullURL(for: items[indexPath.item].url))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing = ScreenAdapter.scaleW(2)
        let side = floor((collectionView.bounds.width - spacing * 2) / 3)
        return CGSize(width: side, height: side)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let urls = items.compactMap { fullURL(for: $0.url) }
        let browser = ImageHistoryBrowserViewController(urls: urls, initialIndex: indexPath.item)
        browser.modalPresentationStyle = .fullScreen
        present(browser, animated: true)
    }
}

// MARK: - 图片网格 Cell
class ImageHistoryCell: UICollectionViewCell {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }

    func configure(with url: URL?) {
        imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
    }
}

// MARK: - 全屏图片浏览器（支持左右滑动切换）
class ImageHistoryBrowserViewController: UIViewController {

    private let urls: [URL]
    private var currentIndex: Int

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .black
        cv.register(ImageHistoryBrowserCell.self, forCellWithReuseIdentifier: "ImageHistoryBrowserCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = ScreenAdapter.font(14)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        label.layer.cornerRadius = ScreenAdapter.scaleW(12)
        label.layer.masksToBounds = true
        return label
    }()

    init(urls: [URL], initialIndex: Int) {
        self.urls = urls
        self.currentIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(pageLabel)
        pageLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-ScreenAdapter.scaleH(16))
            make.centerX.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(28))
            make.width.greaterThanOrEqualTo(ScreenAdapter.scaleW(64))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissBrowser))
        view.addGestureRecognizer(tap)
        tap.require(toFail: collectionView.panGestureRecognizer)

        updatePageLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = collectionView.bounds.size
        }
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        // 仅在首次布局时滚动到初始位置
        if !didScrollToInitial {
            didScrollToInitial = true
            let indexPath = IndexPath(item: currentIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }

    private var didScrollToInitial = false

    private func updatePageLabel() {
        pageLabel.text = "  \(currentIndex + 1) / \(urls.count)  "
    }

    @objc private func dismissBrowser() {
        dismiss(animated: true)
    }
}

extension ImageHistoryBrowserViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageHistoryBrowserCell", for: indexPath) as! ImageHistoryBrowserCell
        cell.configure(with: urls[indexPath.item])
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        if page != currentIndex, page >= 0, page < urls.count {
            currentIndex = page
            updatePageLabel()
        }
    }
}

// MARK: - 浏览器单页 Cell（支持双击缩放）
class ImageHistoryBrowserCell: UICollectionViewCell, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let indicator = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        imageView.contentMode = .scaleAspectFit

        indicator.color = .white
        indicator.hidesWhenStopped = true

        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        contentView.addSubview(indicator)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(scrollView)
        }
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        scrollView.setZoomScale(1.0, animated: false)
    }

    func configure(with url: URL) {
        indicator.startAnimating()
        imageView.kf.setImage(with: url) { [weak self] result in
            self?.indicator.stopAnimating()
            if case .failure = result {
                self?.imageView.image = UIImage(systemName: "photo")
                self?.imageView.tintColor = .systemGray
            }
        }
    }

    @objc private func handleDoubleTap() {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            scrollView.setZoomScale(2.0, animated: true)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
