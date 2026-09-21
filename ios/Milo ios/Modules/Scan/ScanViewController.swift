import UIKit
import AVFoundation
import SnapKit

// MARK: - 扫描页
class ScanViewController: UIViewController {

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let scanView = ScanOverlayView()
    private var metadataOutput: AVCaptureMetadataOutput!

    var onScanResult: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
            make.bottom.equalTo(scanView.snp.top).offset(-ScreenAdapter.scaleH(16))
            make.centerX.equalToSuperview()
        }
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
