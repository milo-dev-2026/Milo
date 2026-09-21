import UIKit
import SnapKit
import Kingfisher
import AVKit
import MapKit

// MARK: - 笔记详情页
class NoteDetailViewController: UIViewController {
    
    private var note: NoteEntity
    var onEdit: ((NoteEntity) -> Void)?
    var onDelete: ((String) -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    
    init(note: NoteEntity) {
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 重新加载最新数据
        if let latest = NoteStorageManager.shared.getNote(by: note.id) {
            note = latest
            renderContent()
        }
    }
    
    private func setupUI() {
        title = "笔记详情"
        view.backgroundColor = .themeBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(editNote)
        )
        
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentStack.axis = .vertical
        contentStack.spacing = ScreenAdapter.scaleH(12)
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
            make.width.equalTo(scrollView.snp.width).offset(-32)
        }
        
        // 标题
        titleLabel.font = ScreenAdapter.boldFont(22)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)
        
        // 时间
        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .tertiaryLabel
        contentStack.addArrangedSubview(timeLabel)
        
        // 分隔线
        let separator = UIView()
        separator.backgroundColor = .systemGray5
        contentStack.addArrangedSubview(separator)
        separator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
        }
    }
    
    private func renderContent() {
        titleLabel.text = note.title.isEmpty ? "无标题" : note.title
        timeLabel.text = "更新于 \(note.timeString)"
        
        // 清除旧的内容块视图（保留标题、时间、分隔线）
        let firstThree = contentStack.arrangedSubviews.prefix(3)
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(timeLabel)
        
        let separator = UIView()
        separator.backgroundColor = .systemGray5
        contentStack.addArrangedSubview(separator)
        separator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
        }
        
        // 渲染内容块
        for block in note.blocks {
            let blockView = createBlockView(for: block)
            contentStack.addArrangedSubview(blockView)
        }
        
        // 底部留白
        let spacer = UIView()
        spacer.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(40))
        }
        contentStack.addArrangedSubview(spacer)
    }
    
    private func createBlockView(for block: NoteBlock) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = ScreenAdapter.scaleW(10)
        
        switch block.type {
        case .title:
            let label = UILabel()
            label.text = block.content
            label.font = ScreenAdapter.boldFont(18)
            label.textColor = .label
            label.numberOfLines = 0
            container.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14))
            }
            
        case .text:
            let label = UILabel()
            label.text = block.content
            label.font = ScreenAdapter.font(15)
            label.textColor = .label
            label.numberOfLines = 0
            container.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14))
            }
            
        case .image:
            let imgView = UIImageView()
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true
            imgView.layer.cornerRadius = ScreenAdapter.scaleW(8)
            imgView.backgroundColor = .systemGray6
            imgView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imgView.addGestureRecognizer(tap)
            
            if let urlStr = block.imageURL, !urlStr.isEmpty {
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
            } else {
                imgView.image = UIImage(systemName: "photo")
                imgView.tintColor = .systemGray3
            }
            
            container.addSubview(imgView)
            imgView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
                make.height.equalTo(ScreenAdapter.scaleH(220))
            }
            
        case .video:
            let videoContainer = UIView()
            videoContainer.backgroundColor = .black
            videoContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
            videoContainer.clipsToBounds = true
            videoContainer.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(videoTapped(_:)))
            videoContainer.addGestureRecognizer(tap)
            videoContainer.tag = note.blocks.firstIndex(where: { $0.id == block.id }) ?? 0
            
            let playIcon = UIImageView()
            playIcon.image = UIImage(systemName: "play.circle.fill")
            playIcon.tintColor = .white
            playIcon.contentMode = .scaleAspectFit
            videoContainer.addSubview(playIcon)
            playIcon.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(ScreenAdapter.scaleW(56))
            }
            
            let videoLabel = UILabel()
            videoLabel.text = "点击播放视频"
            videoLabel.textColor = .white
            videoLabel.font = ScreenAdapter.font(14)
            videoLabel.textAlignment = .center
            videoContainer.addSubview(videoLabel)
            videoLabel.snp.makeConstraints { make in
                make.top.equalTo(playIcon.snp.bottom).offset(ScreenAdapter.scaleH(8))
                make.centerX.equalToSuperview()
            }
            
            container.addSubview(videoContainer)
            videoContainer.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
                make.height.equalTo(ScreenAdapter.scaleH(180))
            }
            
        case .location:
            let locView = UIView()
            locView.backgroundColor = .systemGray6
            locView.layer.cornerRadius = ScreenAdapter.scaleW(8)
            locView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(locationTapped(_:)))
            locView.addGestureRecognizer(tap)
            locView.tag = note.blocks.firstIndex(where: { $0.id == block.id }) ?? 0
            
            let locIcon = UIImageView()
            locIcon.image = UIImage(systemName: "mappin.circle.fill")
            locIcon.tintColor = .themePrimary
            locIcon.contentMode = .scaleAspectFit
            locView.addSubview(locIcon)
            locIcon.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
                make.centerY.equalToSuperview()
                make.width.height.equalTo(ScreenAdapter.scaleW(32))
            }
            
            let addrLabel = UILabel()
            addrLabel.text = block.location?.address ?? "位置信息"
            addrLabel.font = ScreenAdapter.font(14)
            addrLabel.numberOfLines = 2
            addrLabel.textColor = .label
            locView.addSubview(addrLabel)
            addrLabel.snp.makeConstraints { make in
                make.leading.equalTo(locIcon.snp.trailing).offset(ScreenAdapter.scaleW(12))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
                make.centerY.equalToSuperview()
            }
            
            let arrow = UIImageView()
            arrow.image = UIImage(systemName: "chevron.right")
            arrow.tintColor = .systemGray3
            locView.addSubview(arrow)
            arrow.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
                make.centerY.equalToSuperview()
            }
            
            container.addSubview(locView)
            locView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
                make.height.equalTo(ScreenAdapter.scaleH(64))
            }
        }
        
        return container
    }
    
    @objc private func editNote() {
        let editor = NoteEditViewController(note: note)
        editor.onSave = { [weak self] updatedNote in
            self?.note = updatedNote
            self?.renderContent()
            self?.onEdit?(updatedNote)
        }
        editor.onDelete = { [weak self] id in
            self?.onDelete?(id)
            self?.navigationController?.popViewController(animated: true)
        }
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let imgView = gesture.view as? UIImageView,
              let image = imgView.image else { return }
        let previewVC = ImagePreviewViewController(image: image)
        previewVC.modalPresentationStyle = .fullScreen
        present(previewVC, animated: true)
    }
    
    @objc private func videoTapped(_ gesture: UITapGestureRecognizer) {
        let index = gesture.view?.tag ?? 0
        guard index < note.blocks.count else { return }
        let block = note.blocks[index]
        guard let videoURLStr = block.videoURL, !videoURLStr.isEmpty else { return }
        
        let url: URL?
        if videoURLStr.hasPrefix("http") {
            url = URL(string: videoURLStr)
        } else if videoURLStr.hasPrefix("/") {
            url = URL(string: APIConfig.apiBaseURL + videoURLStr)
        } else {
            url = URL(string: APIConfig.apiBaseURL + "/" + videoURLStr)
        }
        
        guard let url = url else { return }
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        present(playerVC, animated: true) {
            player.play()
        }
    }
    
    @objc private func locationTapped(_ gesture: UITapGestureRecognizer) {
        let index = gesture.view?.tag ?? 0
        guard index < note.blocks.count else { return }
        let block = note.blocks[index]
        guard let location = block.location else { return }
        
        let alert = UIAlertController(title: "打开位置", message: location.address, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "在地图中打开", style: .default) { _ in
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = location.address
            mapItem.openInMaps(launchOptions: nil)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - 图片预览控制器（本地图片）
class ImagePreviewViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var image: UIImage?
    
    init(image: UIImage?) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.delegate = self
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalToSuperview()
        }
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.width.height.equalTo(ScreenAdapter.scaleW(36))
        }
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
    
    @objc private func doubleTap(_ gr: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
        } else {
            scrollView.setZoomScale(2, animated: true)
        }
    }
}

extension ImagePreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
