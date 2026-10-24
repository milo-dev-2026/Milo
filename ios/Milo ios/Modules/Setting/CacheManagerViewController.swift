import UIKit
import SnapKit
import Kingfisher

class CacheManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private enum CacheCategory: Int, CaseIterable {
        case image, video, voice, file, other

        var title: String {
            switch self {
            case .image: return "图片缓存"
            case .video: return "视频缓存"
            case .voice: return "语音缓存"
            case .file: return "文件缓存"
            case .other: return "其他缓存"
            }
        }

        var icon: String {
            switch self {
            case .image: return "photo"
            case .video: return "video"
            case .voice: return "mic"
            case .file: return "doc"
            case .other: return "folder"
            }
        }

        var directoryName: String? {
            switch self {
            case .image: return "image"
            case .video: return "video"
            case .voice: return "voice"
            case .file: return "file"
            case .other: return nil
            }
        }
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let clearAllButton = UIButton(type: .system)
    private let totalSizeLabel = UILabel()

    private var categorySizes: [CacheCategory: UInt64] = [:]
    private var totalSize: UInt64 = 0

    private var cachesURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private var tmpURL: URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCacheSizes()
    }

    private func setupUI() {
        title = "缓存管理"
        view.backgroundColor = .themeBackground

        // 顶部总缓存大小
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenAdapter.screenWidth, height: ScreenAdapter.scaleH(130)))
        headerView.backgroundColor = .clear

        let totalTitleLabel = UILabel()
        totalTitleLabel.text = "总缓存大小"
        totalTitleLabel.font = ScreenAdapter.font(14)
        totalTitleLabel.textColor = .secondaryLabel
        totalTitleLabel.textAlignment = .center
        headerView.addSubview(totalTitleLabel)
        totalTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
        }

        totalSizeLabel.text = "计算中..."
        totalSizeLabel.font = ScreenAdapter.boldFont(32)
        totalSizeLabel.textColor = .label
        totalSizeLabel.textAlignment = .center
        headerView.addSubview(totalSizeLabel)
        totalSizeLabel.snp.makeConstraints { make in
            make.top.equalTo(totalTitleLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.centerX.equalToSuperview()
        }

        tableView.tableHeaderView = headerView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = ScreenAdapter.scaleH(52)
        view.addSubview(tableView)

        // 底部红色按钮
        clearAllButton.setTitle("清空全部缓存", for: .normal)
        clearAllButton.titleLabel?.font = ScreenAdapter.font(17)
        clearAllButton.backgroundColor = .systemRed
        clearAllButton.setTitleColor(.white, for: .normal)
        clearAllButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        clearAllButton.addTarget(self, action: #selector(clearAllTapped), for: .touchUpInside)
        view.addSubview(clearAllButton)

        clearAllButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.right.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(16))
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }

        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(clearAllButton.snp.top).offset(-ScreenAdapter.scaleH(12))
        }
    }

    // MARK: - 缓存大小计算

    private func loadCacheSizes() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var sizes: [CacheCategory: UInt64] = [:]

            // 图片缓存 = Kingfisher 磁盘缓存 + Caches/image
            let kfSize = UInt64((try? ImageCache.default.diskStorageSize) ?? 0)
            sizes[.image] = kfSize + self.folderSize(self.cachesURL.appendingPathComponent("image", isDirectory: true))

            for category in [CacheCategory.video, .voice, .file] {
                if let name = category.directoryName {
                    sizes[category] = self.folderSize(self.cachesURL.appendingPathComponent(name, isDirectory: true))
                }
            }

            // 其他缓存 = tmp 目录 + Caches 中除分类目录和 Kingfisher 目录之外的内容
            var other = self.folderSize(self.tmpURL)
            let fm = FileManager.default
            if let items = try? fm.contentsOfDirectory(atPath: self.cachesURL.path) {
                for item in items where !self.isKnownCacheItem(item) {
                    other += self.folderSize(self.cachesURL.appendingPathComponent(item, isDirectory: true))
                }
            }
            sizes[.other] = other

            let total = CacheCategory.allCases.reduce(UInt64(0)) { $0 + (sizes[$1] ?? 0) }

            DispatchQueue.main.async {
                self.categorySizes = sizes
                self.totalSize = total
                self.totalSizeLabel.text = self.formatSize(total)
                self.tableView.reloadData()
            }
        }
    }

    private func isKnownCacheItem(_ name: String) -> Bool {
        if ["image", "video", "voice", "file"].contains(name) { return true }
        if name.contains("Kingfisher") { return true }
        return false
    }

    private func folderSize(_ url: URL) -> UInt64 {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path),
              let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: []) else {
            return 0
        }
        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += UInt64(size)
            }
        }
        return total
    }

    private func formatSize(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        if b < 1024 { return String(format: "%.0f B", b) }
        let kb = b / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        return String(format: "%.2f GB", mb / 1024)
    }

    // MARK: - 清理

    private func removeContents(of url: URL) {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(atPath: url.path) else { return }
        for item in items {
            try? fm.removeItem(at: url.appendingPathComponent(item))
        }
    }

    private func removeCacheDirectory(named name: String) {
        try? FileManager.default.removeItem(at: cachesURL.appendingPathComponent(name, isDirectory: true))
    }

    private func clearCategory(_ category: CacheCategory) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            switch category {
            case .image:
                // 清理 Kingfisher 图片缓存 + Caches/image
                ImageCache.default.clearDiskCache()
                self.removeCacheDirectory(named: "image")
            case .video:
                self.removeCacheDirectory(named: "video")
            case .voice:
                self.removeCacheDirectory(named: "voice")
            case .file:
                self.removeCacheDirectory(named: "file")
            case .other:
                // 清理 tmp 目录 + Caches 中其他内容
                self.removeContents(of: self.tmpURL)
                let fm = FileManager.default
                if let items = try? fm.contentsOfDirectory(atPath: self.cachesURL.path) {
                    for item in items where !self.isKnownCacheItem(item) {
                        try? fm.removeItem(at: self.cachesURL.appendingPathComponent(item))
                    }
                }
            }
            DispatchQueue.main.async {
                AppUtility.showToast("缓存已清理")
                self.loadCacheSizes()
            }
        }
    }

    @objc private func clearAllTapped() {
        let alert = UIAlertController(title: "清空全部缓存", message: "确定要清空全部缓存吗？清理后不可恢复。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                ImageCache.default.clearDiskCache()
                self.removeContents(of: self.tmpURL)
                self.removeContents(of: self.cachesURL)
                DispatchQueue.main.async {
                    AppUtility.showToast("缓存已清理")
                    self.loadCacheSizes()
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CacheCategory.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CacheCell")
            ?? UITableViewCell(style: .value1, reuseIdentifier: "CacheCell")
        let category = CacheCategory.allCases[indexPath.row]

        cell.textLabel?.text = category.title
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.textLabel?.textColor = .label
        cell.imageView?.image = UIImage(systemName: category.icon)
        cell.imageView?.tintColor = .themePrimary

        if let size = categorySizes[category] {
            cell.detailTextLabel?.text = formatSize(size)
        } else {
            cell.detailTextLabel?.text = "计算中..."
        }
        cell.detailTextLabel?.font = ScreenAdapter.font(14)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        clearCategory(CacheCategory.allCases[indexPath.row])
    }
}
