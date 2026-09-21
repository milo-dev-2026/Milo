import UIKit
import SnapKit
import Kingfisher
import AVFoundation
import AVKit
import MapKit

// MARK: - 收藏列表页
class FavoriteViewController: UIViewController {
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var favorites: [FavoriteItem] = []
    private var isSearching = false
    private var isMultiSelectMode = false
    private var selectedIds: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    private func setupUI() {
        title = "收藏"
        view.backgroundColor = .themeBackground
        
        // 搜索栏
        searchBar.delegate = self
        searchBar.placeholder = "搜索收藏"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .themeBackground
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }
        
        // 表格
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .themeBackground
        tableView.separatorStyle = .none
        tableView.register(FavoriteTextCell.self, forCellReuseIdentifier: "FavoriteTextCell")
        tableView.register(FavoriteImageCell.self, forCellReuseIdentifier: "FavoriteImageCell")
        tableView.register(FavoriteVoiceCell.self, forCellReuseIdentifier: "FavoriteVoiceCell")
        tableView.register(FavoriteVideoCell.self, forCellReuseIdentifier: "FavoriteVideoCell")
        tableView.register(FavoriteFileCell.self, forCellReuseIdentifier: "FavoriteFileCell")
        tableView.register(FavoriteLocationCell.self, forCellReuseIdentifier: "FavoriteLocationCell")
        tableView.register(FavoriteLinkCell.self, forCellReuseIdentifier: "FavoriteLinkCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // 长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
        
        // 右上角管理按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "管理",
            style: .plain,
            target: self,
            action: #selector(toggleMultiSelect)
        )
    }
    
    private func loadData() {
        if isSearching, let keyword = searchBar.text, !keyword.isEmpty {
            favorites = FavoriteStorageManager.shared.searchFavorites(keyword: keyword)
        } else {
            favorites = FavoriteStorageManager.shared.getAllFavorites()
        }
        tableView.reloadData()
        updateBottomToolbar()
    }
    
    @objc private func toggleMultiSelect() {
        isMultiSelectMode.toggle()
        selectedIds.removeAll()
        
        if isMultiSelectMode {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "取消",
                style: .plain,
                target: self,
                action: #selector(toggleMultiSelect)
            )
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "全选",
                style: .plain,
                target: self,
                action: #selector(toggleSelectAll)
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "管理",
                style: .plain,
                target: self,
                action: #selector(toggleMultiSelect)
            )
            navigationItem.leftBarButtonItem = nil
        }
        
        tableView.reloadData()
        updateBottomToolbar()
    }
    
    @objc private func toggleSelectAll() {
        if selectedIds.count == favorites.count {
            selectedIds.removeAll()
        } else {
            selectedIds = Set(favorites.map { $0.id })
        }
        tableView.reloadData()
        updateBottomToolbar()
    }
    
    private func updateBottomToolbar() {
        if isMultiSelectMode && !selectedIds.isEmpty {
            navigationController?.setToolbarHidden(false, animated: true)
            let deleteBtn = UIBarButtonItem(
                title: "删除",
                style: .plain,
                target: self,
                action: #selector(batchDelete)
            )
            deleteBtn.tintColor = .systemRed
            
            let forwardBtn = UIBarButtonItem(
                title: "转发",
                style: .plain,
                target: self,
                action: #selector(batchForward)
            )
            
            let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let countLabel = UILabel()
            countLabel.text = "已选 \(selectedIds.count) 项"
            countLabel.font = ScreenAdapter.font(14)
            countLabel.textColor = .secondaryLabel
            let countItem = UIBarButtonItem(customView: countLabel)
            
            toolbarItems = [deleteBtn, flex, countItem, flex, forwardBtn]
        } else {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    @objc private func batchDelete() {
        guard !selectedIds.isEmpty else { return }
        let alert = UIAlertController(
            title: "删除收藏",
            message: "确定删除选中的 \(selectedIds.count) 项收藏？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            FavoriteStorageManager.shared.deleteFavorites(ids: Array(self.selectedIds))
            self.selectedIds.removeAll()
            self.isMultiSelectMode = false
            self.toggleMultiSelect()
            self.loadData()
            AppUtility.showToast("已删除")
        })
        present(alert, animated: true)
    }
    
    @objc private func batchForward() {
        guard !selectedIds.isEmpty else { return }
        let alert = UIAlertController(title: "转发到", message: "请选择转发目标", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "输入对方ID"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "发送", style: .default) { [weak self] _ in
            guard let targetId = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !targetId.isEmpty else { return }
            Task {
                for id in self?.selectedIds ?? [] {
                    if let item = FavoriteStorageManager.shared.getFavorite(by: id) {
                        do {
                            _ = try await APIClient.shared.requestRaw(
                                .sendMessage(channelId: targetId, content: item.content, type: item.type.rawValue)
                            )
                        } catch {}
                    }
                }
                DispatchQueue.main.async {
                    AppUtility.showToast("已转发")
                }
            }
        })
        present(alert, animated: true)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              indexPath.row < favorites.count else { return }
        
        let item = favorites[indexPath.row]
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "转发", style: .default) { [weak self] _ in
            self?.forwardItem(item)
        })
        
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            FavoriteStorageManager.shared.deleteFavorite(id: item.id)
            self?.loadData()
            AppUtility.showToast("已删除")
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func forwardItem(_ item: FavoriteItem) {
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
                        .sendMessage(channelId: targetId, content: item.content, type: item.type.rawValue)
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
}

// MARK: - UISearchBarDelegate
extension FavoriteViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearching = !searchText.isEmpty
        loadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        loadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension FavoriteViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(favorites.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if favorites.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "EmptyCell")
            cell.textLabel?.text = "暂无收藏"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = ScreenAdapter.font(15)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        }
        
        let item = favorites[indexPath.row]
        let cell: FavoriteBaseCell
        
        switch item.type {
        case .text:
            cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteTextCell", for: indexPath) as! FavoriteTextCell
        case .image:
            cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteImageCell", for: indexPath) as! FavoriteImageCell
        case .voice:
            cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteVoiceCell", for: indexPath) as! FavoriteVoiceCell
        case .video:
            cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteVideoCell", for: indexPath) as! FavoriteVideoCell
        case .file:
            cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteFileCell", for: indexPath) as! FavoriteFileCell
        case .location:
            cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteLocationCell", for: indexPath) as! FavoriteLocationCell
        case .link:
            cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteLinkCell", for: indexPath) as! FavoriteLinkCell
        }
        
        cell.configure(with: item)
        cell.setSelected(selectedIds.contains(item.id), inMultiSelect: isMultiSelectMode)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if favorites.isEmpty { return ScreenAdapter.scaleH(200) }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return ScreenAdapter.scaleH(90)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !favorites.isEmpty else { return }
        
        let item = favorites[indexPath.row]
        
        if isMultiSelectMode {
            if selectedIds.contains(item.id) {
                selectedIds.remove(item.id)
            } else {
                selectedIds.insert(item.id)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
            updateBottomToolbar()
            return
        }
        
        // 进入详情页
        let detail = FavoriteDetailViewController(item: item)
        detail.onDelete = { [weak self] _ in
            self?.loadData()
        }
        navigationController?.pushViewController(detail, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !favorites.isEmpty && !isMultiSelectMode else { return nil }
        
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            let item = self.favorites[indexPath.row]
            let alert = UIAlertController(title: "删除收藏", message: "确定删除该收藏？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completion(false) })
            alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
                FavoriteStorageManager.shared.deleteFavorite(id: item.id)
                self?.loadData()
                completion(true)
            })
            self.present(alert, animated: true)
        }
        delete.backgroundColor = .systemRed
        
        let forward = UIContextualAction(style: .normal, title: "转发") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.forwardItem(self.favorites[indexPath.row])
            completion(true)
        }
        forward.backgroundColor = .themePrimary
        
        return UISwipeActionsConfiguration(actions: [delete, forward])
    }
}

// MARK: - 收藏Cell基类
class FavoriteBaseCell: UITableViewCell {
    
    private let cardView = UIView()
    let typeIconView = UIImageView()
    let timeLabel = UILabel()
    let senderLabel = UILabel()
    private let checkImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupBaseUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBaseUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.04
        cardView.layer.shadowRadius = 4
        contentView.addSubview(cardView)
        
        typeIconView.tintColor = .themePrimary
        typeIconView.contentMode = .scaleAspectFit
        typeIconView.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.1)
        typeIconView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        typeIconView.clipsToBounds = true
        cardView.addSubview(typeIconView)
        
        senderLabel.font = ScreenAdapter.font(12)
        senderLabel.textColor = .secondaryLabel
        cardView.addSubview(senderLabel)
        
        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel
        cardView.addSubview(timeLabel)
        
        checkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkImageView.tintColor = .themePrimary
        checkImageView.isHidden = true
        cardView.addSubview(checkImageView)
        
        cardView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(6))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(6))
        }
        
        typeIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.width.height.equalTo(ScreenAdapter.scaleW(32))
        }
        
        checkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalTo(typeIconView)
            make.width.height.equalTo(ScreenAdapter.scaleW(22))
        }
        
        senderLabel.snp.makeConstraints { make in
            make.leading.equalTo(typeIconView.snp.trailing).offset(ScreenAdapter.scaleW(10))
            make.centerY.equalTo(typeIconView)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(checkImageView.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.centerY.equalTo(typeIconView)
        }
    }
    
    func configure(with item: FavoriteItem) {
        typeIconView.image = UIImage(systemName: item.type.iconName)
        timeLabel.text = item.timeString
        senderLabel.text = item.fromUser?.name ?? ""
    }
    
    func setSelected(_ selected: Bool, inMultiSelect: Bool) {
        checkImageView.isHidden = !inMultiSelect
        if inMultiSelect {
            checkImageView.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
            checkImageView.tintColor = selected ? .themePrimary : .systemGray3
        }
    }
}

// MARK: - 文字收藏Cell
class FavoriteTextCell: FavoriteBaseCell {
    
    private let contentLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentLabel.font = ScreenAdapter.font(15)
        contentLabel.textColor = .label
        contentLabel.numberOfLines = 3
        cardView.addSubview(contentLabel)
        
        contentLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(typeIconView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
    }
    
    override func configure(with item: FavoriteItem) {
        super.configure(with: item)
        contentLabel.text = item.content
    }
}

// MARK: - 图片收藏Cell
class FavoriteImageCell: FavoriteBaseCell {
    
    private let previewImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        previewImageView.backgroundColor = .systemGray6
        cardView.addSubview(previewImageView)
        
        previewImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(typeIconView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(160))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
    }
    
    override func configure(with item: FavoriteItem) {
        super.configure(with: item)
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
            previewImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        } else {
            previewImageView.image = UIImage(systemName: "photo")
        }
    }
}

// MARK: - 语音收藏Cell
class FavoriteVoiceCell: FavoriteBaseCell {
    
    private let voiceContainer = UIView()
    private let playIcon = UIImageView()
    private let durationLabel = UILabel()
    private let waveformView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        voiceContainer.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.08)
        voiceContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        cardView.addSubview(voiceContainer)
        
        playIcon.image = UIImage(systemName: "play.fill")
        playIcon.tintColor = .themePrimary
        playIcon.contentMode = .scaleAspectFit
        voiceContainer.addSubview(playIcon)
        
        durationLabel.font = ScreenAdapter.font(14)
        durationLabel.textColor = .themePrimary
        voiceContainer.addSubview(durationLabel)
        
        waveformView.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.3)
        waveformView.layer.cornerRadius = 2
        voiceContainer.addSubview(waveformView)
        
        voiceContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(typeIconView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(48))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
        
        playIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }
        
        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
        }
        
        waveformView.snp.makeConstraints { make in
            make.leading.equalTo(playIcon.snp.trailing).offset(ScreenAdapter.scaleW(10))
            make.trailing.equalTo(durationLabel.snp.leading).offset(-ScreenAdapter.scaleW(10))
            make.centerY.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(20))
        }
    }
    
    override func configure(with item: FavoriteItem) {
        super.configure(with: item)
        if let duration = item.voiceDuration {
            durationLabel.text = "\(Int(duration))\""
        } else {
            durationLabel.text = "0\""
        }
    }
}

// MARK: - 视频收藏Cell
class FavoriteVideoCell: FavoriteBaseCell {
    
    private let videoContainer = UIView()
    private let thumbImageView = UIImageView()
    private let playIcon = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        videoContainer.backgroundColor = .black
        videoContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        videoContainer.clipsToBounds = true
        cardView.addSubview(videoContainer)
        
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        videoContainer.addSubview(thumbImageView)
        
        playIcon.image = UIImage(systemName: "play.circle.fill")
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit
        videoContainer.addSubview(playIcon)
        
        videoContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(typeIconView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(160))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
        
        thumbImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(48))
        }
    }
    
    override func configure(with item: FavoriteItem) {
        super.configure(with: item)
        if let thumb = item.imageURL, !thumb.isEmpty {
            let url: URL?
            if thumb.hasPrefix("http") {
                url = URL(string: thumb)
            } else if thumb.hasPrefix("/") {
                url = URL(string: APIConfig.apiBaseURL + thumb)
            } else {
                url = URL(string: APIConfig.apiBaseURL + "/" + thumb)
            }
            if let url = url {
                thumbImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "video"))
            }
        } else {
            thumbImageView.image = UIImage(systemName: "video")
            thumbImageView.tintColor = .white
            thumbImageView.contentMode = .center
        }
    }
}

// MARK: - 文件收藏Cell
class FavoriteFileCell: FavoriteBaseCell {
    
    private let fileContainer = UIView()
    private let fileIconView = UIImageView()
    private let fileNameLabel = UILabel()
    private let fileSizeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        fileContainer.backgroundColor = .systemGray6
        fileContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        cardView.addSubview(fileContainer)
        
        fileIconView.image = UIImage(systemName: "doc.text.fill")
        fileIconView.tintColor = .themePrimary
        fileIconView.contentMode = .scaleAspectFit
        fileContainer.addSubview(fileIconView)
        
        fileNameLabel.font = ScreenAdapter.mediumFont(14)
        fileNameLabel.textColor = .label
        fileNameLabel.numberOfLines = 1
        fileContainer.addSubview(fileNameLabel)
        
        fileSizeLabel.font = ScreenAdapter.font(12)
        fileSizeLabel.textColor = .secondaryLabel
        fileContainer.addSubview(fileSizeLabel)
        
        fileContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(typeIconView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(60))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
        
        fileIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(32))
        }
        
        fileNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(fileIconView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
        }
        
        fileSizeLabel.snp.makeConstraints { make in
            make.leading.equalTo(fileIconView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(fileNameLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
        }
    }
    
    override func configure(with item: FavoriteItem) {
        super.configure(with: item)
        fileNameLabel.text = item.fileName ?? "文件"
        if let size = item.fileSize {
            fileSizeLabel.text = formatFileSize(size)
        } else {
            fileSizeLabel.text = ""
        }
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

// MARK: - 位置收藏Cell
class FavoriteLocationCell: FavoriteBaseCell {
    
    private let locContainer = UIView()
    private let locIconView = UIImageView()
    private let addressLabel = UILabel()
    private let coordLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        locContainer.backgroundColor = .systemGray6
        locContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        cardView.addSubview(locContainer)
        
        locIconView.image = UIImage(systemName: "mappin.circle.fill")
        locIconView.tintColor = .themePrimary
        locIconView.contentMode = .scaleAspectFit
        locContainer.addSubview(locIconView)
        
        addressLabel.font = ScreenAdapter.mediumFont(14)
        addressLabel.textColor = .label
        addressLabel.numberOfLines = 2
        locContainer.addSubview(addressLabel)
        
        coordLabel.font = ScreenAdapter.font(12)
        coordLabel.textColor = .secondaryLabel
        locContainer.addSubview(coordLabel)
        
        locContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(typeIconView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.height.equalTo(ScreenAdapter.scaleH(64))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
        
        locIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(32))
        }
        
        addressLabel.snp.makeConstraints { make in
            make.leading.equalTo(locIconView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
        }
        
        coordLabel.snp.makeConstraints { make in
            make.leading.equalTo(locIconView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.top.equalTo(addressLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
        }
    }
    
    override func configure(with item: FavoriteItem) {
        super.configure(with: item)
        addressLabel.text = item.location?.address ?? "位置"
        if let loc = item.location {
            coordLabel.text = String(format: "%.4f, %.4f", loc.latitude, loc.longitude)
        } else {
            coordLabel.text = ""
        }
    }
}

// MARK: - 链接收藏Cell
class FavoriteLinkCell: FavoriteBaseCell {
    
    private let linkContainer = UIView()
    private let linkIconView = UIImageView()
    private let linkLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        linkContainer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        linkContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        cardView.addSubview(linkContainer)
        
        linkIconView.image = UIImage(systemName: "link.circle.fill")
        linkIconView.tintColor = .systemBlue
        linkIconView.contentMode = .scaleAspectFit
        linkContainer.addSubview(linkIconView)
        
        linkLabel.font = ScreenAdapter.font(14)
        linkLabel.textColor = .systemBlue
        linkLabel.numberOfLines = 2
        linkContainer.addSubview(linkLabel)
        
        linkContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(typeIconView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.height.greaterThanOrEqualTo(ScreenAdapter.scaleH(56))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }
        
        linkIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.width.height.equalTo(ScreenAdapter.scaleW(24))
        }
        
        linkLabel.snp.makeConstraints { make in
            make.leading.equalTo(linkIconView.snp.trailing).offset(ScreenAdapter.scaleW(10))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(12))
        }
    }
    
    override func configure(with item: FavoriteItem) {
        super.configure(with: item)
        linkLabel.text = item.content
    }
}
