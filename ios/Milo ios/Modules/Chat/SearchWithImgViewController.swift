import UIKit
import SnapKit
import Kingfisher
import WuKongIMSDK

// MARK: - 图片搜索页（对标 Android SearchWithImgActivity）
/// 从 IM SDK 加载频道历史消息，筛选图片类型消息，以 3 列网格展示缩略图。
/// 点击图片全屏预览（支持左右滑动切换），下拉加载更多历史消息。
class SearchWithImgViewController: UIViewController {

    // MARK: - 图片项
    private struct ImageItem {
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
        cv.backgroundColor = .themeBg
        cv.register(SearchWithImgCell.self, forCellWithReuseIdentifier: "SearchWithImgCell")
        cv.dataSource = self
        cv.delegate = self
        cv.alwaysBounceVertical = true
        return cv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无图片"
        label.font = ScreenAdapter.font(15)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - 初始化
    init(channelId: String, channelType: Int) {
        self.channelId = channelId
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "图片"
        view.backgroundColor = .themeBg
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

        // 下拉加载更多历史消息
        refreshControl.addTarget(self, action: #selector(loadMore), for: .valueChanged)
        collectionView.refreshControl = refreshControl

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

    /// 筛选图片类型消息（realContentType == 2）并加入列表
    private func appendMessages(_ messages: [WKMessage]) {
        let imageMsgs = messages.filter { Int($0.content.realContentType) == 2 }
        let newItems: [ImageItem] = imageMsgs.compactMap { msg in
            guard let imageContent = msg.content as? WKImageMessageContent, !imageContent.url.isEmpty else { return nil }
            return ImageItem(
                url: imageContent.url,
                timestamp: Int64(msg.timestamp),
                messageSeq: msg.messageSeq
            )
        }
        items.append(contentsOf: newItems)
        // 按时间倒序（最新在前）
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

// MARK: - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout
extension SearchWithImgViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchWithImgCell", for: indexPath) as! SearchWithImgCell
        cell.configure(with: fullURL(for: items[indexPath.item].url))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 每行 3 张，间距 2
        let spacing = ScreenAdapter.scaleW(2)
        let side = floor((collectionView.bounds.width - spacing * 2) / 3)
        return CGSize(width: side, height: side)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 全屏预览，支持左右滑动切换
        let urls = items.compactMap { fullURL(for: $0.url) }
        guard !urls.isEmpty, indexPath.item < urls.count else { return }
        let browser = ImageHistoryBrowserViewController(urls: urls, initialIndex: indexPath.item)
        browser.modalPresentationStyle = .fullScreen
        present(browser, animated: true)
    }
}

// MARK: - 图片网格 Cell（Kingfisher 加载缩略图）
private class SearchWithImgCell: UICollectionViewCell {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .themeBgCard
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
        imageView.kf.setImage(with: url, placeholder: ThemeIcon.image.image)
    }
}
