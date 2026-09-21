import UIKit
import SnapKit
import Photos

protocol MultiImagePickerDelegate: AnyObject {
    func didSelectImages(_ images: [UIImage])
}

class MultiImagePickerController: UIViewController {

    weak var delegate: MultiImagePickerDelegate?
    private let collectionView: UICollectionView
    private var assets: [PHAsset] = []
    private var selectedAssets: Set<Int> = []
    private var imageManager = PHCachingImageManager.default()

    private let bottomBar = UIView()
    private let previewButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let maxCount = 9

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 6) / 4, height: (UIScreen.main.bounds.width - 6) / 4)
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkPermission()
    }

    private func setupUI() {
        title = "选择图片"
        view.backgroundColor = .systemBackground

        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        collectionView.register(MultiImageCell.self, forCellWithReuseIdentifier: "MICell")

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(view.bounds.height - ScreenAdapter.scaleH(60))
        }

        bottomBar.backgroundColor = .systemBackground

        previewButton.setTitle("预览", for: .normal)
        previewButton.titleLabel?.font = ScreenAdapter.font(15)
        previewButton.addTarget(self, action: #selector(preview), for: .touchUpInside)

        sendButton.setTitle("发送(\(selectedAssets.count)/\(maxCount))", for: .normal)
        sendButton.titleLabel?.font = ScreenAdapter.font(15)
        sendButton.backgroundColor = .themePrimary
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = ScreenAdapter.scaleW(6)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)

        let bottomStack = UIStackView(arrangedSubviews: [previewButton, sendButton])
        bottomStack.axis = .horizontal
        bottomStack.spacing = ScreenAdapter.scaleW(16)

        bottomBar.addSubview(bottomStack)
        view.addSubview(bottomBar)

        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ScreenAdapter.safeAreaBottom + ScreenAdapter.scaleH(50))
        }

        bottomStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(8))
            make.height.equalTo(ScreenAdapter.scaleH(36))
        }
    }

    private func checkPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            loadAssets()
        } else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.loadAssets()
                    } else {
                        AppUtility.showToast("请允许访问相册")
                        self?.dismiss(animated: true)
                    }
                }
            }
        }
    }

    private func loadAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        fetchResult.enumerateObjects { asset, _, _ in
            self.assets.append(asset)
        }
        collectionView.reloadData()
    }

    private func updateSendButton() {
        sendButton.setTitle("发送(\(selectedAssets.count)/\(maxCount))", for: .normal)
    }

    @objc private func preview() {
        guard !selectedAssets.isEmpty else {
            AppUtility.showToast("请选择图片")
            return
        }
        let urls = selectedAssets.compactMap { assets[$0] }
        if let firstAsset = urls.first {
            let img = imageManager.requestImageDataAndOrientation(for: firstAsset) { _, _, _, _ in }
            let previewVC = ImagePreviewViewController(url: nil)
            present(previewVC, animated: true)
        }
    }

    @objc private func send() {
        var images: [UIImage] = []
        for idx in selectedAssets.sorted() {
            let asset = assets[idx]
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { image, _ in
                if let img = image {
                    images.append(img)
                }
            }
        }
        delegate?.didSelectImages(images)
        dismiss(animated: true)
    }
}

extension MultiImagePickerController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MICell", for: indexPath) as! MultiImageCell
        let asset = assets[indexPath.item]

        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .opportunistic
        imageManager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                cell.imageView.image = image
            }
        }

        cell.isSelected = selectedAssets.contains(indexPath.item)
        cell.selectedIndex = selectedAssets.contains(indexPath.item) ? selectedAssets.sorted().firstIndex(of: indexPath.item).map { $0 + 1 } : nil
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedAssets.count >= maxCount {
            AppUtility.showToast("最多选择\(maxCount)张")
            collectionView.deselectItem(at: indexPath, animated: false)
            return
        }
        selectedAssets.insert(indexPath.item)
        updateSendButton()
        collectionView.reloadItems(at: [indexPath])
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedAssets.remove(indexPath.item)
        updateSendButton()
        collectionView.reloadSections(IndexSet(integer: 0))
    }
}

class MultiImageCell: UICollectionViewCell {

    let imageView = UIImageView()
    private let badgeView = UIView()
    private let badgeLabel = UILabel()

    var selectedIndex: Int? {
        didSet {
            if let idx = selectedIndex {
                badgeView.backgroundColor = .themePrimary
                badgeLabel.text = "\(idx)"
                badgeView.isHidden = false
            } else {
                badgeView.isHidden = true
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            imageView.alpha = isSelected ? 0.7 : 1.0
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        badgeView.layer.cornerRadius = ScreenAdapter.scaleW(10)
        badgeView.layer.borderWidth = 1.5
        badgeView.layer.borderColor = UIColor.white.cgColor
        badgeView.isHidden = true

        badgeLabel.font = ScreenAdapter.font(12)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center

        badgeView.addSubview(badgeLabel)
        contentView.addSubview(badgeView)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        badgeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }

        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
