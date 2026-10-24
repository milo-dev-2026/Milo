import UIKit
import SnapKit
import Kingfisher

// MARK: - 我的头像（对照 Android MyHeadPortraitActivity）
class MyHeadPortraitViewController: UIViewController {

    // MARK: - UI 元素
    private let scrollView = UIScrollView()
    private let avatarImageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadAvatar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyDarkNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.restoreDefaultNavigationBar()
    }

    // MARK: - 导航栏（黑色背景、白色文字、白色返回按钮）
    private func setupNavigationBar() {
        title = "头像"
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(showMoreActions)
        )
        moreButton.tintColor = .white
        navigationItem.rightBarButtonItem = moreButton
    }

    private func applyDarkNavigationBar() {
        guard let navBar = navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: ScreenAdapter.mediumFont(17)
        ]
        navBar.standardAppearance = appearance
        navBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navBar.scrollEdgeAppearance = appearance
        }
        navBar.tintColor = .white
    }

    // MARK: - 布局
    private func setupUI() {
        view.backgroundColor = .black

        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.isUserInteractionEnabled = true
        scrollView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(view)
        }

        // 双击缩放
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        // 长按弹出菜单（与 Android 一致）
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        scrollView.addGestureRecognizer(longPress)

        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - 加载头像（与 Android 一致：/v1/users/{uid}/avatar）
    private func loadAvatar() {
        let defaults = UserDefaults.standard
        let uid = defaults.string(forKey: "uid") ?? ""
        let name = defaults.string(forKey: "name") ?? ""
        guard !uid.isEmpty, let url = AppUtility.avatarURL(forChannelId: uid, channelType: 1) else {
            avatarImageView.image = AppUtility.defaultAvatarImage(name: name, size: 200)
            return
        }
        activityIndicator.startAnimating()
        let placeholder = AppUtility.defaultAvatarImage(name: name, size: 200)
        avatarImageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [.transition(.fade(0.2)), .cacheOriginalImage]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if case .failure = result {
                    self?.avatarImageView.image = placeholder
                }
            }
        }
    }

    // MARK: - 底部菜单
    @objc private func showMoreActions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "更换头像", style: .default) { [weak self] _ in
            self?.pickAvatar()
        })
        alert.addAction(UIAlertAction(title: "保存图片", style: .default) { [weak self] _ in
            self?.saveImage()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        showMoreActions()
    }

    // MARK: - 双击缩放
    @objc private func handleDoubleTap() {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            scrollView.setZoomScale(2.0, animated: true)
        }
    }

    // MARK: - 选择头像
    private func pickAvatar() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    // MARK: - 上传头像
    private func uploadAvatar(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.6) else {
            AppUtility.showToast("图片处理失败")
            return
        }
        activityIndicator.startAnimating()
        Task {
            do {
                // 1. 上传图片文件
                let fileName = "avatar_\(Int(Date().timeIntervalSince1970)).jpg"
                let path = try await APIClient.shared.upload(data: data, fileName: fileName)
                guard !path.isEmpty else { throw APIError.noData }
                // 2. 更新用户头像字段
                _ = try await APIClient.shared.requestRaw(.updateUserInfo(name: nil, avatar: path))
                // 3. 更新本地缓存并通知
                UserDefaults.standard.set(path, forKey: "avatar")
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.avatarImageView.image = image
                    // 清除头像缓存，使其他页面加载最新头像
                    let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
                    if !uid.isEmpty, let url = AppUtility.avatarURL(forChannelId: uid, channelType: 1) {
                        KingfisherManager.shared.cache.removeImage(forKey: url.absoluteString)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("UserInfoUpdated"), object: nil)
                    AppUtility.showToast("头像已更新")
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    AppUtility.showToast("头像上传失败，请重试")
                }
            }
        }
    }

    // MARK: - 保存图片到相册
    @objc private func saveImage() {
        guard let image = avatarImageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            AppUtility.showToast("保存失败，请检查相册权限")
        } else {
            AppUtility.showToast("已保存到相册")
        }
    }
}

// MARK: - UIScrollViewDelegate
extension MyHeadPortraitViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return avatarImageView
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MyHeadPortraitViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            uploadAvatar(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
