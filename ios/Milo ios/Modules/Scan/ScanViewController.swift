import UIKit
import AVFoundation
import SnapKit
import PhotosUI

// MARK: - 扫描页
class ScanViewController: UIViewController {

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let scanView = ScanOverlayView()
    private var metadataOutput: AVCaptureMetadataOutput!

    /// 闪光灯状态
    private var isTorchOn = false
    /// 闪光灯按钮引用（切换时更新颜色反馈）
    private weak var torchButton: UIButton?

    var onScanResult: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 透明导航栏：去掉顶部分隔白线，融入相机画面
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        appearance.backgroundImage = UIImage()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        title = "扫一扫"

        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 离开时关闭闪光灯并恢复全局导航栏样式
        setTorch(on: false)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .themePrimary

        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            AppUtility.showToast("无法访问相机")
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        let scanSize = min(ScreenAdapter.screenWidth, ScreenAdapter.screenHeight) * 0.65

        view.addSubview(scanView)
        scanView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(scanSize)
        }

        let hintLabel = UILabel()
        hintLabel.text = "将二维码放入框内扫描"
        hintLabel.textColor = .white
        hintLabel.font = ScreenAdapter.font(14)
        hintLabel.textAlignment = .center
        view.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(scanView.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.centerX.equalToSuperview()
        }

        setupBottomBar()
    }

    // MARK: - 底部功能栏（闪光灯 / 相册 / 我的二维码，对齐安卓）
    private func setupBottomBar() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(40))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(44))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(44))
            make.height.equalTo(ScreenAdapter.scaleH(76))
        }

        stack.addArrangedSubview(makeBottomButton(icon: "bolt.fill", title: "闪光灯", action: #selector(toggleTorch)))
        stack.addArrangedSubview(makeBottomButton(icon: "photo", title: "相册", action: #selector(openAlbum)))
        stack.addArrangedSubview(makeBottomButton(icon: "qrcode", title: "我的二维码", action: #selector(showMyQRCode)))
    }

    private func makeBottomButton(icon: String, title: String, action: Selector) -> UIView {
        let container = UIView()

        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        button.layer.cornerRadius = ScreenAdapter.scaleW(26)
        button.clipsToBounds = true
        button.addTarget(self, action: action, for: .touchUpInside)
        container.addSubview(button)
        button.snp.makeConstraints { make in
            // 容器宽度跟随按钮，保证按钮完全落在父视图 bounds 内可点击
            make.top.leading.trailing.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(52))
        }
        if icon == "bolt.fill" { torchButton = button }

        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = ScreenAdapter.font(12)
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(ScreenAdapter.scaleH(6))
            make.centerX.bottom.equalToSuperview()
        }

        return container
    }

    // MARK: - 闪光灯
    @objc private func toggleTorch() {
        setTorch(on: !isTorchOn)
    }

    private func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            AppUtility.showToast("设备不支持闪光灯")
            return
        }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            isTorchOn = on
            // 开启后按钮变黄，给用户明确反馈
            torchButton?.tintColor = on ? .systemYellow : .white
        } catch {
            print("[Scan] 闪光灯切换失败: \(error)")
        }
    }

    // MARK: - 相册识别二维码（PHPicker 无权限弹窗、秒开）
    @objc private func openAlbum() {
        // 先停掉相机采集，避免弹出相册时摄像头仍在跑导致卡顿
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.stopRunning()
            }
        }
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func detectQRCode(in image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]
        return features?.first?.messageString
    }

    // MARK: - 我的二维码
    @objc private func showMyQRCode() {
        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
        guard !uid.isEmpty else {
            AppUtility.showToast("未获取到用户信息")
            return
        }
        let vc = MyQRCodeViewController(uid: uid)
        present(vc, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ScanViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        if let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let result = obj.stringValue {
            captureSession.stopRunning()
            AppUtility.lightFeedback()
            onScanResult?(result)
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate（相册选图识别二维码）
extension ScanViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self = self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                if let result = self.detectQRCode(in: image) {
                    self.captureSession.stopRunning()
                    AppUtility.lightFeedback()
                    self.onScanResult?(result)
                    self.navigationController?.popViewController(animated: true)
                } else {
                    AppUtility.showToast("未识别到二维码")
                }
            }
        }
    }
}

// MARK: - 我的二维码弹层
class MyQRCodeViewController: UIViewController {

    private let uid: String

    init(uid: String) {
        self.uid = uid
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(ScreenAdapter.scaleW(280))
        }

        // 头像 + 昵称
        let avatarView = UIImageView()
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(6)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        let name = UserDefaults.standard.string(forKey: "name") ?? uid
        AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: name, into: avatarView)
        card.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = ScreenAdapter.mediumFont(17)
        nameLabel.textColor = .label
        card.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.centerY.equalTo(avatarView)
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(20))
        }

        // 二维码（与安卓/服务端格式一致：/v1/qrcode/<Milo号>，无 Milo 号时兼容旧格式 uid:xxx）
        let shortNo = UserDefaults.standard.string(forKey: "short_no") ?? ""
        let qrContent = shortNo.isEmpty ? "uid:\(uid)" : "\(APIConfig.apiBaseURL)/v1/qrcode/\(shortNo)"
        let qrImageView = UIImageView()
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.image = Self.makeQRCode(from: qrContent, size: 512)
        card.addSubview(qrImageView)
        qrImageView.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(220))
        }

        let hintLabel = UILabel()
        hintLabel.text = "扫一扫上面的二维码，加我好友"
        hintLabel.font = ScreenAdapter.font(13)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center
        card.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(qrImageView.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(24))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissSelf(_ gesture: UITapGestureRecognizer) {
        dismiss(animated: true)
    }

    /// 生成二维码图片
    static func makeQRCode(from string: String, size: CGFloat) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return UIImage(ciImage: scaled)
    }
}

// MARK: - 二维码识别与入群（扫一扫 / 相册识别 / 长按识图共用）
enum GroupQRCodeHelper {

    /// 十六进制校验
    private static func isHex(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789abcdefABCDEF").inverted) == nil
    }

    /// 提取服务端二维码短码
    /// 安卓端群二维码来自后端 /v1/groups/<群号>/qrcode，内容为 http(s)://host/v1/qrcode/g<群号>；
    /// 个人二维码为 http(s)://host/v1/qrcode/<Milo号>。两端统一交给后端解析，避免格式猜不一致。
    private static func serverCode(from payload: String) -> String? {
        let text = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if let url = URL(string: text), url.path.contains("/v1/qrcode/") {
            let code = (url.path as NSString).lastPathComponent
            return code.isEmpty ? nil : code
        }
        // 裸短码：g + 32位群号，或 10 位 Milo 号
        if text.count == 33, text.hasPrefix("g"), isHex(String(text.dropFirst())) {
            return text
        }
        if text.count == 10, text.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
            return text
        }
        return nil
    }

    /// 本地解析群号（g + 32 位十六进制，兼容直接编码群号的二维码）
    static func groupNo(from payload: String) -> String? {
        guard let code = serverCode(from: payload) else { return nil }
        if code.count == 33, code.hasPrefix("g") { return String(code.dropFirst()) }
        if code.count == 32, isHex(code) { return code }
        return nil
    }

    /// 统一入口：识别二维码内容并执行对应操作（返回 true 表示已接管）
    @discardableResult
    static func handle(payload: String, from presenter: UIViewController) -> Bool {
        let text = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }

        // 1. 群二维码：本地能解析的直接处理，响应最快
        if let groupNo = groupNo(from: text), groupNo.count == 32 {
            join(groupNo: groupNo, from: presenter)
            return true
        }
        // 2. 其它 /v1/qrcode/ 短码（个人二维码、旧版邀请码）交给后端解析，与安卓走同一条链路
        if let code = serverCode(from: text) {
            resolve(code: code, from: presenter)
            return true
        }
        // 3. 兼容 iOS 旧版个人二维码 uid:xxx
        if text.hasPrefix("uid:") {
            let uid = String(text.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !uid.isEmpty { applyFriend(uid: uid, from: presenter) }
            return true
        }
        return false
    }

    /// 调用后端 /v1/qrcode/<code> 解析（对齐安卓 ScanUtils）
    private static func resolve(code: String, from presenter: UIViewController) {
        guard let url = URL(string: "\(APIConfig.apiBaseURL)/v1/qrcode/\(code)") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { AppUtility.showToast("二维码无效或已过期") }
                return
            }
            let type = json["type"] as? String ?? ""
            let dataDict = json["data"] as? [String: Any]
            DispatchQueue.main.async {
                switch type {
                case "group":
                    if let gid = dataDict?["group_no"] as? String, !gid.isEmpty {
                        join(groupNo: gid, from: presenter)
                    } else {
                        AppUtility.showToast("群二维码无效")
                    }
                case "userInfo":
                    if let uid = dataDict?["uid"] as? String, !uid.isEmpty {
                        applyFriend(uid: uid, from: presenter)
                    } else {
                        AppUtility.showToast("二维码无效")
                    }
                default:
                    AppUtility.showToast(json["msg"] as? String ?? "二维码无效或已过期")
                }
            }
        }.resume()
    }

    /// 发送好友申请（对齐扫码加好友流程）
    private static func applyFriend(uid: String, from presenter: UIViewController) {
        let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
        guard !myUid.isEmpty else {
            AppUtility.showToast("请先登录")
            return
        }
        guard uid != myUid else {
            AppUtility.showToast("不能添加自己为好友")
            return
        }
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.applyFriend(uid: uid, remark: "", vercode: ""))
                let ok = (response["status"] as? Int) == 200
                DispatchQueue.main.async {
                    AppUtility.showToast(ok ? "好友申请已发送" : (response["msg"] as? String ?? "发送申请失败"))
                }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("发送申请失败") }
            }
        }
    }

    /// 弹确认框，确认后以自己 uid 申请加入群聊
    static func join(groupNo: String, from presenter: UIViewController) {
        let alert = UIAlertController(title: "加入群聊", message: "是否加入该群聊？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "加入", style: .default) { _ in
            let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
            guard !myUid.isEmpty else {
                AppUtility.showToast("请先登录")
                return
            }
            AppUtility.showToast("正在申请加入…")
            Task {
                do {
                    let resp = try await APIClient.shared.requestRaw(
                        .applyJoinGroup(groupId: groupNo, remark: "申请加入群聊")
                    )
                    let status = resp["status"] as? Int ?? 0
                    // invite: 0=直接加入，1=已提交申请等待群主/管理员审核
                    let invite = (resp["data"] as? [String: Any])?["invite"] as? Int ?? 1
                    DispatchQueue.main.async {
                        if status == 200 {
                            AppUtility.showToast(invite == 0 ? "已加入群聊" : "已发送进群申请，等待管理员审核")
                            NotificationCenter.default.post(name: NSNotification.Name("ConversationsSynced"), object: nil)
                        } else {
                            AppUtility.showToast(resp["msg"] as? String ?? "加入群聊失败")
                        }
                    }
                } catch {
                    DispatchQueue.main.async { AppUtility.showToast("加入群聊失败") }
                }
            }
        })
        presenter.present(alert, animated: true)
    }
}

// MARK: - 扫描动画视图
class ScanOverlayView: UIView {

    private let scanLine = UIView()
    private var displayLink: CADisplayLink!
    private var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    private func setupUI() {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1

        scanLine.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.8)
        addSubview(scanLine)

        displayLink = CADisplayLink(target: self, selector: #selector(updateScanLine))
        displayLink.add(to: .main, forMode: .default)
    }

    @objc private func updateScanLine() {
        progress += 0.01
        if progress > 1 {
            progress = 0
        }
        scanLine.frame = CGRect(x: 0, y: bounds.height * progress, width: bounds.width, height: 2)
    }
}
