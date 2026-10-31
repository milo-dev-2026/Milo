import UIKit
import SnapKit
import Kingfisher

// MARK: - 聊天图片尺寸缓存
/// 图片气泡按原始宽高比展示（不再固定正方形）。尺寸首次读到后缓存，供复用与翻页时直接命中
final class ChatImageSizeCache {

    static let shared = ChatImageSizeCache()
    /// 图片尺寸解析完成通知（userInfo: ["url": String]），聊天页收到后刷新对应行
    static let didResolveNotification = Notification.Name("ChatImageSizeCacheDidResolve")

    private let defaultsKey = "chat_image_size_cache_v1"
    private let maxEntries = 300
    private var memory: [String: CGSize] = [:]
    private var resolving: Set<String> = []

    private init() {
        guard let store = UserDefaults.standard.dictionary(forKey: defaultsKey) else { return }
        for (key, value) in store {
            guard let arr = value as? [NSNumber], arr.count == 2 else { continue }
            memory[key] = CGSize(width: arr[0].doubleValue, height: arr[1].doubleValue)
        }
    }

    func size(for url: URL) -> CGSize? {
        return memory[url.absoluteString]
    }

    func store(_ size: CGSize, for url: URL) {
        guard size.width > 1, size.height > 1 else { return }
        let key = url.absoluteString
        memory[key] = size
        if memory.count > maxEntries {
            memory = Dictionary(uniqueKeysWithValues: Array(Array(memory).suffix(maxEntries)))
        }
        var store = UserDefaults.standard.dictionary(forKey: defaultsKey) ?? [:]
        store[key] = [Double(size.width), Double(size.height)]
        UserDefaults.standard.set(store, forKey: defaultsKey)
    }

    /// 异步解析尺寸（命中缓存/磁盘时很快），仅首次解析成功后回调
    func resolve(url: URL, completion: @escaping (CGSize) -> Void) {
        if let size = size(for: url) {
            completion(size)
            return
        }
        let key = url.absoluteString
        guard !resolving.contains(key) else { return }
        resolving.insert(key)
        KingfisherManager.shared.retrieveImage(with: url, options: []) { [weak self] result in
            guard let self = self else { return }
            self.resolving.remove(key)
            guard case .success(let value) = result else { return }
            let size = value.image.size
            guard size.width > 1, size.height > 1 else { return }
            self.store(size, for: url)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: ChatImageSizeCache.didResolveNotification,
                                                object: nil,
                                                userInfo: ["url": key])
                completion(size)
            }
        }
    }
}

class ImageMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let imageView_ = UIImageView()
    private let tailView = ChatBubbleTailView()
    private var currentURLString: String = ""
    /// 当前展示高度（用于尺寸解析完成后判断是否需要重排）
    private var currentHeight: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
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

        imageView_.contentMode = .scaleAspectFill
        imageView_.clipsToBounds = true
        imageView_.backgroundColor = .systemGray6

        bubbleView.addSubview(imageView_)
        contentView.addSubviews(tailView, bubbleView)

        imageView_.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
        let content = message.content
        let imgURL: URL? = APIConfig.chatMediaURL(content)
        currentURLString = imgURL?.absoluteString ?? ""

        if let url = imgURL {
            imageView_.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        } else {
            imageView_.image = UIImage(systemName: "photo")
        }

        // 按原始宽高比取展示尺寸（对齐安卓/微信：大图优先，非正方形）
        let targetWidth = min(ScreenAdapter.scaleW(230), ScreenAdapter.screenWidth * 0.62)
        var ratio: CGFloat = 4.0 / 3.0
        if let url = imgURL, let size = ChatImageSizeCache.shared.size(for: url) {
            ratio = size.height / max(size.width, 1)
        }
        let maxHeight = ScreenAdapter.scaleH(320)
        let minHeight = ScreenAdapter.scaleH(90)
        let displayHeight = min(max(targetWidth * ratio, minHeight), maxHeight)
        currentHeight = displayHeight

        // 尺寸未知时异步解析（取自图片原始像素），解析成功后刷新该行
        if let url = imgURL, ChatImageSizeCache.shared.size(for: url) == nil {
            ChatImageSizeCache.shared.resolve(url: url) { [weak self] _ in
                guard let self = self, self.currentURLString == url.absoluteString else { return }
                self.reloadSelfRow()
            }
        }

        let isFromMe = message.isFromMe
        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: targetWidth,
            height: displayHeight,
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar,
            status: message.isFromMe ? message.status : nil
        )
    }

    /// 尺寸解析完成后让聊天页重算本行高度
    private func reloadSelfRow() {
        guard let tableView = superview as? UITableView,
              let indexPath = tableView.indexPath(for: self) else { return }
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}
