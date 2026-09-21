import UIKit
import SnapKit
import Kingfisher
import AVFoundation
import AVKit
import MapKit

// MARK: - 收藏详情页
class FavoriteDetailViewController: UIViewController {
    
    private let item: FavoriteItem
    var onDelete: ((String) -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentContainer = UIView()
    private let senderInfoView = UIView()
    private let avatarView = UIImageView()
    private let senderNameLabel = UILabel()
    private let timeLabel = UILabel()
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    init(item: FavoriteItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    private func setupUI() {
        title = "收藏详情"
        view.backgroundColor = .themeBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(showMoreOptions)
        )
        
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        // 发送者信息
        senderInfoView.backgroundColor = .systemBackground
        contentContainer.addSubview(senderInfoView)
        senderInfoView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(64))
        }
        
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(20)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5
        senderInfoView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
        
        senderNameLabel.font = ScreenAdapter.mediumFont(15)
        senderNameLabel.textColor = .label
        senderInfoView.addSubview(senderNameLabel)
        senderNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(avatarView).offset(ScreenAdapter.scaleH(2))
        }
        
        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .secondaryLabel
        senderInfoView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.bottom.equalTo(avatarView).offset(-ScreenAdapter.scaleH(2))
        }
        
        // 底部操作按钮
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = ScreenAdapter.scaleW(12)
        bottomStack.distribution = .fillEqually
        view.addSubview(bottomStack)
        bottomStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(16))
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }
        
        let forwardBtn = UIButton(type: .system)
        forwardBtn.setTitle("转发", for: .normal)
        forwardBtn.backgroundColor = .themePrimary
        forwardBtn.setTitleColor(.white, for: .normal)
        forwardBtn.titleLabel?.font = ScreenAdapter.mediumFont(15)
        forwardBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        forwardBtn.addTarget(self, action: #selector(forwardItem), for: .touchUpInside)
        bottomStack.addArrangedSubview(forwardBtn)
        
        let deleteBtn = UIButton(type: .system)
        deleteBtn.setTitle("删除", for: .normal)
        deleteBtn.backgroundColor = .systemRed
        deleteBtn.setTitleColor(.white, for: .normal)
        deleteBtn.titleLabel?.font = ScreenAdapter.mediumFont(15)
        deleteBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        deleteBtn.addTarget(self, action: #selector(deleteItem), for: .touchUpInside)
        bottomStack.addArrangedSubview(deleteBtn)
        
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ScreenAdapter.scaleH(80), right: 0)
    }
    
    private func setupContent() {
        senderNameLabel.text = item.fromUser?.name ?? "未知"
        timeLabel.text = item.timeString
        
        if let avatarStr = item.fromUser?.avatar, !avatarStr.isEmpty {
            let urlStr = avatarStr.hasPrefix("http") ? avatarStr : APIConfig.apiBaseURL + "/" + avatarStr
            if let url = URL(string: urlStr) {
                avatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
            }
        }
        
        // 根据类型设置内容
        switch item.type {
        case .text:
            setupTextContent()
        case .image:
            setupImageContent()
        case .voice:
            setupVoiceContent()
        case .video:
            setupVideoContent()
        case .file:
            setupFileContent()
        case .location:
            setupLocationContent()
        case .link:
            setupLinkContent()
        }
    }
    
    // MARK: - 文字内容
    private func setupTextContent() {
        let textView = UITextView()
        textView.text = item.content
        textView.font = ScreenAdapter.font(16)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        contentContainer.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalTo(senderInfoView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - 图片内容
    private func setupImageContent() {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.backgroundColor = .black
        imgView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imgView.addGestureRecognizer(tap)
        
        let urlStr = item.imageURL ?? item.content
        let url: URL?
        if urlStr.hasPrefix("http") {
            url = URL(string: urlStr)
        } else if urlStr.hasPrefix("/") {
            url = URL(string: APIConfig.apiBaseURL + urlStr)
        } else {
            url = URL(string: APIConfig.apiBaseURL + "/" + urlStr)
        }
        if let url = url {
            imgView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        }
        
        contentContainer.addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.top.equalTo(senderInfoView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.screenWidth)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - 语音内容
    private func setupVoiceContent() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        contentContainer.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(senderInfoView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(120))
            make.bottom.equalToSuperview()
        }
        
        let playBtn = UIButton(type: .system)
        playBtn.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playBtn.tintColor = .themePrimary
        playBtn.addTarget(self, action: #selector(playVoice), for: .touchUpInside)
        container.addSubview(playBtn)
        playBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.width.height.equalTo(ScreenAdapter.scaleW(48))
        }
        
        let durationLabel = UILabel()
        if let duration = item.voiceDuration {
            durationLabel.text = "\(Int(duration))\""
        } else {
            durationLabel.text = "0\""
        }
        durationLabel.font = ScreenAdapter.font(14)
        durationLabel.textColor = .secondaryLabel
        durationLabel.textAlignment = .center
        container.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(playBtn.snp.bottom).offset(ScreenAdapter.scaleH(8))
        }
    }
    
    // MARK: - 视频内容
    private func setupVideoContent() {
        let container = UIView()
        container.backgroundColor = .black
        contentContainer.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(senderInfoView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.screenWidth * 0.75)
            make.bottom.equalToSuperview()
        }
        
        let playBtn = UIButton(type: .system)
        playBtn.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playBtn.tintColor = .white
        playBtn.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        container.addSubview(playBtn)
        playBtn.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(64))
        }
        
        // 缩略图
        if let thumb = item.imageURL, !thumb.isEmpty {
            let thumbImg = UIImageView()
            thumbImg.contentMode = .scaleAspectFill
            thumbImg.clipsToBounds = true
            let url: URL?
            if thumb.hasPrefix("http") {
                url = URL(string: thumb)
            } else if thumb.hasPrefix("/") {
                url = URL(string: APIConfig.apiBaseURL + thumb)
            } else {
                url = URL(string: APIConfig.apiBaseURL + "/" + thumb)
            }
            if let url = url {
                thumbImg.kf.setImage(with: url)
            }
            container.insertSubview(thumbImg, at: 0)
            thumbImg.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    // MARK: - 文件内容
    private func setupFileContent() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        contentContainer.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(senderInfoView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        let fileCard = UIView()
        fileCard.backgroundColor = .systemGray6
        fileCard.layer.cornerRadius = ScreenAdapter.scaleW(12)
        container.addSubview(fileCard)
        fileCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(80))
        }
        
        let fileIcon = UIImageView()
        fileIcon.image = UIImage(systemName: "doc.text.fill")
        fileIcon.tintColor = .themePrimary
        fileIcon.contentMode = .scaleAspectFit
        fileCard.addSubview(fileIcon)
        fileIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
        
        let nameLabel = UILabel()
        nameLabel.text = item.fileName ?? "文件"
        nameLabel.font = ScreenAdapter.mediumFont(15)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        fileCard.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(fileIcon.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(18))
        }
        
        let sizeLabel = UILabel()
        if let size = item.fileSize {
            sizeLabel.text = formatFileSize(size)
        }
        sizeLabel.font = ScreenAdapter.font(13)
        sizeLabel.textColor = .secondaryLabel
        fileCard.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { make in
            make.leading.equalTo(fileIcon.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(6))
        }
        
        let downloadBtn = UIButton(type: .system)
        downloadBtn.setTitle("下载", for: .normal)
        downloadBtn.backgroundColor = .themePrimary
        downloadBtn.setTitleColor(.white, for: .normal)
        downloadBtn.titleLabel?.font = ScreenAdapter.mediumFont(15)
        downloadBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        downloadBtn.addTarget(self, action: #selector(downloadFile), for: .touchUpInside)
        container.addSubview(downloadBtn)
        downloadBtn.snp.makeConstraints { make in
            make.top.equalTo(fileCard.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }
    }
    
    // MARK: - 位置内容
    private func setupLocationContent() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        contentContainer.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(senderInfoView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        guard let location = item.location else { return }
        
        // 地图视图
        let mapView = MKMapView()
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: false)
        mapView.isUserInteractionEnabled = false
        container.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(250))
        }
        
        // 地址信息
        let addrCard = UIView()
        addrCard.backgroundColor = .systemGray6
        addrCard.layer.cornerRadius = ScreenAdapter.scaleW(12)
        container.addSubview(addrCard)
        addrCard.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
        }
        
        let locIcon = UIImageView()
        locIcon.image = UIImage(systemName: "mappin.circle.fill")
        locIcon.tintColor = .themePrimary
        locIcon.contentMode = .scaleAspectFit
        addrCard.addSubview(locIcon)
        locIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }
        
        let addrLabel = UILabel()
        addrLabel.text = location.address
        addrLabel.font = ScreenAdapter.font(15)
        addrLabel.textColor = .label
        addrLabel.numberOfLines = 0
        addrCard.addSubview(addrLabel)
        addrLabel.snp.makeConstraints { make in
            make.leading.equalTo(locIcon.snp.trailing).offset(ScreenAdapter.scaleW(10))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(14))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
        
        let openBtn = UIButton(type: .system)
        openBtn.setTitle("在地图中打开", for: .normal)
        openBtn.backgroundColor = .themePrimary
        openBtn.setTitleColor(.white, for: .normal)
        openBtn.titleLabel?.font = ScreenAdapter.mediumFont(15)
        openBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        openBtn.addTarget(self, action: #selector(openInMaps), for: .touchUpInside)
        container.addSubview(openBtn)
        openBtn.snp.makeConstraints { make in
            make.top.equalTo(addrCard.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.height.equalTo(ScreenAdapter.scaleH(44))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(16))
        }
    }
    
    // MARK: - 链接内容
    private func setupLinkContent() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        contentContainer.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(senderInfoView.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        let linkCard = UIView()
        linkCard.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        linkCard.layer.cornerRadius = ScreenAdapter.scaleW(12)
        linkCard.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(openLink))
        linkCard.addGestureRecognizer(tap)
        container.addSubview(linkCard)
        linkCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
        }
        
        let linkIcon = UIImageView()
        linkIcon.image = UIImage(systemName: "link.circle.fill")
        linkIcon.tintColor = .systemBlue
        linkIcon.contentMode = .scaleAspectFit
        linkCard.addSubview(linkIcon)
        linkIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(14))
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }
        
        let linkLabel = UILabel()
        linkLabel.text = item.content
        linkLabel.font = ScreenAdapter.font(15)
        linkLabel.textColor = .systemBlue
        linkLabel.numberOfLines = 0
        linkCard.addSubview(linkLabel)
        linkLabel.snp.makeConstraints { make in
            make.leading.equalTo(linkIcon.snp.trailing).offset(ScreenAdapter.scaleW(10))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(14))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
    }
    
    // MARK: - 操作方法
    
    @objc private func showMoreOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "转发", style: .default) { [weak self] _ in
            self?.forwardItem()
        })
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteItem()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func forwardItem() {
        let alert = UIAlertController(title: "转发到", message: "请选择转发目标", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "输入对方ID"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "发送", style: .default) { [weak self] _ in
            guard let targetId = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !targetId.isEmpty else { return }
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(
                        .sendMessage(channelId: targetId, content: self?.item.content ?? "", type: self?.item.type.rawValue ?? 1)
                    )
                    DispatchQueue.main.async {
                        AppUtility.showToast("已转发")
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("转发失败")
                    }
                }
            }
        })
        present(alert, animated: true)
    }
    
    @objc private func deleteItem() {
        let alert = UIAlertController(title: "删除收藏", message: "确定删除该收藏？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            FavoriteStorageManager.shared.deleteFavorite(id: self.item.id)
            self.onDelete?(self.item.id)
            self.navigationController?.popViewController(animated: true)
            AppUtility.showToast("已删除")
        })
        present(alert, animated: true)
    }
    
    @objc private func imageTapped() {
        let urlStr = item.imageURL ?? item.content
        let url: URL?
        if urlStr.hasPrefix("http") {
            url = URL(string: urlStr)
        } else if urlStr.hasPrefix("/") {
            url = URL(string: APIConfig.apiBaseURL + urlStr)
        } else {
            url = URL(string: APIConfig.apiBaseURL + "/" + urlStr)
        }
        if let url = url {
            let previewVC = ImagePreviewViewController(url: url)
            previewVC.modalPresentationStyle = .fullScreen
            present(previewVC, animated: true)
        }
    }
    
    @objc private func playVoice() {
        guard let urlStr = item.voiceURL, !urlStr.isEmpty else {
            AppUtility.showToast("语音文件不可用")
            return
        }
        let url: URL?
        if urlStr.hasPrefix("http") {
            url = URL(string: urlStr)
        } else if urlStr.hasPrefix("/") {
            url = URL(string: APIConfig.apiBaseURL + urlStr)
        } else {
            url = URL(string: APIConfig.apiBaseURL + "/" + urlStr)
        }
        guard let url = url else { return }
        player = AVPlayer(url: url)
        player?.play()
        AppUtility.showToast("正在播放")
    }
    
    @objc private func playVideo() {
        guard let urlStr = item.videoURL, !urlStr.isEmpty else {
            AppUtility.showToast("视频文件不可用")
            return
        }
        let url: URL?
        if urlStr.hasPrefix("http") {
            url = URL(string: urlStr)
        } else if urlStr.hasPrefix("/") {
            url = URL(string: APIConfig.apiBaseURL + urlStr)
        } else {
            url = URL(string: APIConfig.apiBaseURL + "/" + urlStr)
        }
        guard let url = url else { return }
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        present(playerVC, animated: true) {
            player.play()
        }
    }
    
    @objc private func downloadFile() {
        AppUtility.showToast("开始下载")
    }
    
    @objc private func openInMaps() {
        guard let location = item.location else { return }
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.address
        mapItem.openInMaps(launchOptions: nil)
    }
    
    @objc private func openLink() {
        guard let url = URL(string: item.content) else {
            AppUtility.showToast("链接无效")
            return
        }
        UIApplication.shared.open(url)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else if size < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(size) / (1024 * 1024))
        } else {
            return String(format: "%.1f GB", Double(size) / (1024 * 1024 * 1024))
        }
    }
}
