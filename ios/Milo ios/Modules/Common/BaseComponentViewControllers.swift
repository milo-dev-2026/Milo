import UIKit
import SnapKit
import AVFoundation
import WebKit

// MARK: - 搜索位置
class SearchLocationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var pois: [(name: String, address: String, lat: Double, lng: Double)] = []
    private let searchController = UISearchController(searchResultsController: nil)
    var onSelected: ((String, Double, Double) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad(); title = "搜索位置"; view.backgroundColor = .themeBackground
        searchController.searchResultsUpdater = self; searchController.searchBar.placeholder = "搜索地点"
        navigationItem.searchController = searchController
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SLCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func updateSearchResults(for searchController: UISearchController) {
        // 实际通过高德SDK搜索
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(pois.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SLCell", for: indexPath)
        if pois.isEmpty { cell.textLabel?.text = "输入地点关键词搜索"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let p = pois[indexPath.row]; cell.textLabel?.text = p.name; cell.detailTextLabel?.text = p.address; cell.imageView?.image = UIImage(systemName: "mappin.circle.fill"); cell.imageView?.tintColor = .themePrimary }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !pois.isEmpty else { return }
        let p = pois[indexPath.row]
        onSelected?(p.name, p.lat, p.lng)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - 位置详情
class LocationDetailViewController: UIViewController {
    private var name: String; private var address: String; private var lat: Double; private var lng: Double
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let mapView = UIView()
    private let sendButton = UIButton(type: .system)
    var onSend: (() -> Void)?

    init(name: String, address: String, lat: Double, lng: Double) {
        self.name = name; self.address = address; self.lat = lat; self.lng = lng
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "位置详情"; view.backgroundColor = .themeBackground
        mapView.backgroundColor = .systemGray5; mapView.layer.cornerRadius = 12
        nameLabel.text = name; nameLabel.font = ScreenAdapter.boldFont(18)
        addressLabel.text = address; addressLabel.font = ScreenAdapter.font(14); addressLabel.textColor = .secondaryLabel; addressLabel.numberOfLines = 0
        sendButton.setTitle("发送位置", for: .normal); sendButton.titleLabel?.font = ScreenAdapter.font(17)
        sendButton.backgroundColor = .themePrimary; sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = ScreenAdapter.scaleW(10); sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [mapView, nameLabel, addressLabel, sendButton]); stack.axis = .vertical; stack.spacing = 12
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.equalToSuperview().offset(16); make.trailing.equalToSuperview().offset(-16)
        }
        mapView.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(200)) }
        sendButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func send() { onSend?(); navigationController?.popViewController(animated: true) }
}

// MARK: - 群组通话
class GroupCallViewController: UIViewController {
    private var groupId: String
    private let containerView = UIView()
    private let hangupButton = UIButton(type: .system)
    private let muteButton = UIButton(type: .system)
    private let cameraButton = UIButton(type: .system)
    private var memberViews: [UIView] = []
    private var isMuted = false
    private var isCameraOn = false

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "群组通话"
        navigationItem.hidesBackButton = true

        containerView.backgroundColor = .darkGray
        containerView.clipsToBounds = true

        hangupButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        hangupButton.tintColor = .white
        hangupButton.backgroundColor = .systemRed
        hangupButton.layer.cornerRadius = ScreenAdapter.scaleW(30)
        hangupButton.addTarget(self, action: #selector(hangup), for: .touchUpInside)

        muteButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        muteButton.tintColor = .white
        muteButton.backgroundColor = UIColor(white: 0.2, alpha: 1)
        muteButton.layer.cornerRadius = ScreenAdapter.scaleW(24)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)

        cameraButton.setImage(UIImage(systemName: "video.slash.fill"), for: .normal)
        cameraButton.tintColor = .white
        cameraButton.backgroundColor = UIColor(white: 0.2, alpha: 1)
        cameraButton.layer.cornerRadius = ScreenAdapter.scaleW(24)
        cameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)

        let controlStack = UIStackView(arrangedSubviews: [muteButton, hangupButton, cameraButton])
        controlStack.axis = .horizontal
        controlStack.spacing = ScreenAdapter.scaleW(40)
        controlStack.distribution = .fillEqually

        view.addSubview(containerView)
        view.addSubview(controlStack)

        containerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(controlStack.snp.top).offset(-ScreenAdapter.scaleH(40))
        }

        controlStack.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(30))
            make.centerX.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleW(60))
        }

        hangupButton.snp.makeConstraints { make in make.width.height.equalTo(ScreenAdapter.scaleW(60)) }
        muteButton.snp.makeConstraints { make in make.width.height.equalTo(ScreenAdapter.scaleW(48)) }
        cameraButton.snp.makeConstraints { make in make.width.height.equalTo(ScreenAdapter.scaleW(48)) }

        setupMemberLayout()
        enterTRTCRoom()
    }

    private func setupMemberLayout() {
        for v in memberViews { v.removeFromSuperview() }
        memberViews.removeAll()

        let cols: CGFloat = 2
        let gap: CGFloat = 4
        let w = (UIScreen.main.bounds.width - gap * (cols + 1)) / cols
        let h = w * 1.3

        for i in 0..<4 {
            let mv = UIView()
            mv.backgroundColor = .systemGray4
            mv.layer.cornerRadius = 8
            mv.layer.masksToBounds = true

            let avatar = UIImageView(image: UIImage(systemName: "person.fill"))
            avatar.tintColor = .systemGray2
            avatar.contentMode = .center
            mv.addSubview(avatar)
            avatar.snp.makeConstraints { make in make.center.equalToSuperview() }

            containerView.addSubview(mv)
            let row = CGFloat(Int(i) / Int(cols))
            let col = CGFloat(Int(i) % Int(cols))
            mv.snp.makeConstraints { make in
                make.width.equalTo(w)
                make.height.equalTo(h)
                make.leading.equalToSuperview().offset(col * (w + gap) + gap)
                make.top.equalToSuperview().offset(row * (h + gap) + gap)
            }
            memberViews.append(mv)
        }

        containerView.snp.makeConstraints { make in
            make.height.equalTo(h * 2 + gap * 3)
        }
    }

    private func enterTRTCRoom() {
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.getTRTCUserSig)
                if let data = resp["data"] as? [String: Any] {
                    let sdkAppId = data["sdk_app_id"] as? Int ?? 0
                    let userId = UserDefaults.standard.string(forKey: "uid") ?? ""
                    let userSig = data["user_sig"] as? String ?? ""
                    enterRoom(sdkAppId: UInt32(sdkAppId), userId: userId, userSig: userSig)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("无法加入通话，请重试")
                }
            }
        }
    }

    private func enterRoom(sdkAppId: UInt32, userId: String, userSig: String) {
        // TRTC SDK integration point
        // TRTCCloud.sharedInstance().enterRoom(roomId: UInt32(groupId) ?? 0, params: TRTCParams(...))
        // For now, log the parameters - actual TRTC entry depends on TXLiteAVSDK_TRTC integration
        print("TRTC enterRoom: sdkAppId=\(sdkAppId), userId=\(userId), roomId=\(groupId)")
    }

    @objc private func hangup() {
        // TRTCCloud.sharedInstance().exitRoom()
        dismiss(animated: true)
    }

    @objc private func toggleMute() {
        isMuted.toggle()
        let icon = isMuted ? "mic.slash.fill" : "mic.fill"
        muteButton.setImage(UIImage(systemName: icon), for: .normal)
        muteButton.backgroundColor = isMuted ? .systemRed : UIColor(white: 0.2, alpha: 1)
        // TRTCCloud.sharedInstance().muteLocalAudio(isMuted)
    }

    @objc private func toggleCamera() {
        isCameraOn.toggle()
        let icon = isCameraOn ? "video.fill" : "video.slash.fill"
        cameraButton.setImage(UIImage(systemName: icon), for: .normal)
        cameraButton.backgroundColor = isCameraOn ? .systemBlue : UIColor(white: 0.2, alpha: 1)
        // TRTCCloud.sharedInstance().muteLocalVideo(!isCameraOn)
    }
}

// MARK: - 扫码结果页
class ScanResultViewController: UIViewController {
    private var result: String

    init(result: String) { self.result = result; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "扫描结果"; view.backgroundColor = .themeBackground
        let icon = UIImageView(image: UIImage(systemName: "qrcode.viewfinder")); icon.tintColor = .themePrimary; icon.contentMode = .scaleAspectFit
        let contentLabel = UILabel()
        contentLabel.text = result; contentLabel.font = ScreenAdapter.font(16); contentLabel.numberOfLines = 0; contentLabel.textAlignment = .center
        let copyButton = UIButton(type: .system); copyButton.setTitle("复制内容", for: .normal); copyButton.titleLabel?.font = ScreenAdapter.font(16)
        copyButton.addTarget(self, action: #selector(copyContent), for: .touchUpInside)
        let openButton = UIButton(type: .system); openButton.setTitle("打开链接", for: .normal); openButton.titleLabel?.font = ScreenAdapter.font(16)
        openButton.addTarget(self, action: #selector(open), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [icon, contentLabel, copyButton, openButton]); stack.axis = .vertical; stack.spacing = 16; stack.alignment = .center
        view.addSubview(stack); stack.snp.makeConstraints { make in make.center.equalToSuperview(); make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24) }
        icon.snp.makeConstraints { make in make.width.height.equalTo(ScreenAdapter.scaleW(80)) }
    }
    @objc private func copyContent() { UIPasteboard.general.string = result; AppUtility.showToast("已复制") }
    @objc private func open() {
        if let url = URL(string: result), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else { AppUtility.showToast("无效链接") }
    }
}

// MARK: - 视频播放器
class VideoPlayerViewController: UIViewController {
    private var videoUrl: URL
    private let player: AVPlayer
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var playButton: UIButton!
    private var isPlaying = false

    init(videoUrl: URL) { self.videoUrl = videoUrl; self.player = AVPlayer(url: videoUrl); super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .black; title = "视频播放"
        playerLayer.videoGravity = .resizeAspect; view.layer.addSublayer(playerLayer)
        playButton = UIButton(type: .system); playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = .white; playButton.contentMode = .scaleAspectFit
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        view.addSubview(playButton); playButton.snp.makeConstraints { make in make.center.equalToSuperview(); make.width.height.equalTo(ScreenAdapter.scaleW(60)) }
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(close)); doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); playerLayer.frame = view.bounds }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); player.play(); isPlaying = true; playButton.isHidden = true }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); player.pause() }
    @objc private func togglePlay() {
        if isPlaying { player.pause(); playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal); playButton.isHidden = false } else { player.play(); playButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal); playButton.isHidden = true }
        isPlaying.toggle()
    }
    @objc private func close() { navigationController?.popViewController(animated: true) }
}

// MARK: - WebView
class WKWebViewViewController: UIViewController, WKNavigationDelegate {
    private var url: URL
    private var webView: WKWebView!
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    init(url: URL) { self.url = url; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView = WKWebView(); webView.navigationDelegate = self
        view.addSubview(webView); view.addSubview(activityIndicator)
        webView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        activityIndicator.snp.makeConstraints { make in make.center.equalToSuperview() }
        activityIndicator.startAnimating()
        webView.load(URLRequest(url: url))
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { activityIndicator.stopAnimating() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { activityIndicator.stopAnimating(); AppUtility.showToast("加载失败") }
}

// MARK: - 图片裁剪
class CropImageViewController: UIViewController {
    private var image: UIImage
    private let imageView = UIImageView()
    private let scrollView = UIScrollView()
    private let cropButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    var onCropped: ((UIImage) -> Void)?

    init(image: UIImage) { self.image = image; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .black; title = "裁剪图片"
        imageView.image = image; imageView.contentMode = .scaleAspectFit
        scrollView.minimumZoomScale = 1; scrollView.maximumZoomScale = 4; scrollView.delegate = self
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        cropButton.setTitle("裁剪", for: .normal); cropButton.titleLabel?.font = ScreenAdapter.font(16)
        cropButton.backgroundColor = .themePrimary; cropButton.setTitleColor(.white, for: .normal)
        cropButton.layer.cornerRadius = 8; cropButton.addTarget(self, action: #selector(crop), for: .touchUpInside)
        view.addSubview(cropButton)
        scrollView.snp.makeConstraints { make in make.top.leading.trailing.equalToSuperview(); make.bottom.equalToSuperview().offset(-80) }
        imageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        cropButton.snp.makeConstraints { make in make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16); make.centerX.equalToSuperview(); make.width.equalTo(ScreenAdapter.scaleW(120)); make.height.equalTo(ScreenAdapter.scaleH(40)) }
    }
    @objc private func crop() {
        let renderer = UIGraphicsImageRenderer(size: scrollView.bounds.size)
        let img = renderer.image { _ in self.scrollView.drawHierarchy(in: self.scrollView.bounds, afterScreenUpdates: true) }
        onCropped?(img)
        navigationController?.popViewController(animated: true)
    }
}
extension CropImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return imageView }
}
