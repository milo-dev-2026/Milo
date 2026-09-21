import UIKit
import SnapKit
import Kingfisher
import Photos

class ImagePreviewViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let imageURL: URL?
    private let image: UIImage?
    private let closeButton = UIButton(type: .system)
    private let bottomBar = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    var onForward: ((URL?) -> Void)?

    init(url: URL?) {
        self.imageURL = url
        self.image = nil
        super.init(nibName: nil, bundle: nil)
    }

    init(image: UIImage?) {
        self.image = image
        self.imageURL = nil
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .black

        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.delegate = self

        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        scrollView.addGestureRecognizer(longPress)

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.layer.cornerRadius = ScreenAdapter.scaleW(20)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeButton.addTarget(self, action: #selector(dismissPreview), for: .touchUpInside)

        activityIndicator.color = .white
        activityIndicator.startAnimating()

        setupBottomBar()

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(closeButton)
        view.addSubview(bottomBar)
        view.addSubview(activityIndicator)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(view)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }

        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(60) + view.safeAreaInsets.bottom)
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        if let image = image {
            imageView.image = image
            activityIndicator.stopAnimating()
        } else if let url = imageURL {
            imageView.kf.setImage(with: url) { [weak self] result in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    switch result {
                    case .success(let value):
                        self?.activityIndicator.stopAnimating()
                        _ = value.image
                    case .failure:
                        self?.showErrorPlaceholder()
                    }
                }
            }
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        let saveButton = createBottomButton(icon: "square.and.arrow.down", title: "保存")
        saveButton.addTarget(self, action: #selector(saveImage), for: .touchUpInside)

        let forwardButton = createBottomButton(icon: "arrowshape.turn.up.right", title: "转发")
        forwardButton.addTarget(self, action: #selector(forwardImage), for: .touchUpInside)

        let editButton = createBottomButton(icon: "pencil", title: "编辑")
        editButton.addTarget(self, action: #selector(editImage), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [saveButton, forwardButton, editButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        bottomBar.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }
    }

    private func createBottomButton(icon: String, title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: icon), for: .normal)
        btn.tintColor = .white
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = ScreenAdapter.font(12)
        btn.titleEdgeInsets = UIEdgeInsets(top: 20, left: -20, bottom: 0, right: 0)
        btn.imageEdgeInsets = UIEdgeInsets(top: -12, left: 0, bottom: 0, right: 0)
        return btn
    }

    private func showErrorPlaceholder() {
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray
    }

    @objc private func dismissPreview() {
        dismiss(animated: true)
    }

    @objc private func handleDoubleTap() {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            scrollView.setZoomScale(2.0, animated: true)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "保存到相册", style: .default) { _ in
            self.saveImage()
        })
        alert.addAction(UIAlertAction(title: "转发", style: .default) { _ in
            self.forwardImage()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    @objc private func saveImage() {
        guard let image = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let _ = error {
            AppUtility.showToast("保存失败，请检查相册权限")
        } else {
            AppUtility.showToast("已保存到相册")
        }
    }

    @objc private func forwardImage() {
        onForward?(imageURL)
    }

    @objc private func editImage() {
        guard imageView.image != nil else { return }
        let cropVC = CropImageViewController(image: imageView.image!)
        cropVC.modalPresentationStyle = .fullScreen
        cropVC.onCropped = { [weak self] croppedImage in
            self?.imageView.image = croppedImage
            self?.dismiss(animated: true)
        }
        present(cropVC, animated: true)
    }
}

extension ImagePreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
