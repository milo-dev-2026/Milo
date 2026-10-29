import UIKit
import SnapKit
import Kingfisher
import AVFoundation
import AVKit
import MapKit

// MARK: - 收藏列表页
class FavoriteViewController: UIViewController {

    private let searchContainer = UIView()
    private let searchIconImageView = UIImageView()
    private let searchTextField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var favorites: [FavoriteItem] = []
    private var isSearching = false
    private var isMultiSelectMode = false
    private var selectedIds: Set<String> = []

    /// 从聊天工具栏进入时携带的会话上下文（对齐安卓 FavoriteActivity channelId/channelType）
    private let contextChannelId: String?
    private let contextChannelType: Int

    init(channelId: String? = nil, channelType: Int = 1) {
        self.contextChannelId = channelId
        self.contextChannelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        
        // 自定义搜索栏
        searchContainer.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        searchContainer.layer.cornerRadius = 18
        searchContainer.clipsToBounds = true
        view.addSubview(searchContainer)
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(36)
        }

        searchIconImageView.image = UIImage(systemName: "magnifyingglass")
        searchIconImageView.tintColor = .secondaryLabel
        searchIconImageView.contentMode = .scaleAspectFit
        searchContainer.addSubview(searchIconImageView)
        searchIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        searchTextField.placeholder = "搜索收藏"
        searchTextField.font = ScreenAdapter.font(14)
        searchTextField.textColor = .label
        searchTextField.tintColor = .themePrimary
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextDidChange(_:)), for: .editingChanged)
        searchContainer.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.leading.equalTo(searchIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        // 表格
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        tableView.separatorStyle = .none
        tableView.register(FavoriteTextCell.self, forCellReuseIdentifier: "FavoriteTextCell")
        tableView.register(FavoriteImageCell.self, forCellReuseIdentifier: "FavoriteImageCell")
        tableView.register(FavoriteVoiceCell.self, forCellReuseIdentifier: "FavoriteVoiceCell")
        tableView.register(FavoriteVideoCell.self, forCellReuseIdentifier: "FavoriteVideoCell")
        tableView.register(FavoriteFileCell.self, forCellReuseIdentifier: "FavoriteFileCell")
        tableView.register(FavoriteLocationCell.self, forCellReuseIdentifier: "FavoriteLocationCell")
        tableView.register(FavoriteLinkCell.self, forCellReuseIdentifier: "FavoriteLinkCell")
        tableView.register(FavoriteNoteCell.self, forCellReuseIdentifier: "FavoriteNoteCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(8)
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
        if isSearching, let keyword = searchTextField.text, !keyword.isEmpty {
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
        let items = selectedIds.compactMap { FavoriteStorageManager.shared.getFavorite(by: $0) }
        guard !items.isEmpty else { return }
        FavoriteForwarder.present(from: self, items: items,
                                  channelId: contextChannelId, channelType: contextChannelType) { [weak self] in
            guard let self = self else { return }
            self.selectedIds.removeAll()
            if self.isMultiSelectMode { self.toggleMultiSelect() }
        }
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
        FavoriteForwarder.present(from: self, items: [item],
                                  channelId: contextChannelId, channelType: contextChannelType)
    }
}

// MARK: - UITextFieldDelegate
extension FavoriteViewController: UITextFieldDelegate {
    
    @objc private func searchTextDidChange(_ textField: UITextField) {
        isSearching = !(textField.text?.isEmpty ?? true)
        loadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
        case .note:
            cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteNoteCell", for: indexPath) as! FavoriteNoteCell
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
        
        // 笔记直接打开笔记详情页（对齐聊天页笔记查看体验）
        if item.type == .note {
            if let note = FavoriteForwarder.parseNote(item.content) {
                let noteVC = NoteDetailViewController(note: note)
                navigationController?.pushViewController(noteVC, animated: true)
            } else {
                AppUtility.showToast("笔记内容无法解析")
            }
            return
        }

        // 进入详情页
        let detail = FavoriteDetailViewController(item: item, channelId: contextChannelId, channelType: contextChannelType)
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
    
    let cardView = UIView()
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

// MARK: - 笔记收藏Cell
class FavoriteNoteCell: FavoriteBaseCell {

    private let noteContainer = UIView()
    private let noteIcon = UIImageView()
    private let noteTitleLabel = UILabel()
    private let notePreviewLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        noteContainer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.08)
        noteContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
        cardView.addSubview(noteContainer)

        noteIcon.image = UIImage(systemName: "note.text")
        noteIcon.tintColor = .systemOrange
        noteIcon.contentMode = .scaleAspectFit
        noteContainer.addSubview(noteIcon)

        noteTitleLabel.font = ScreenAdapter.mediumFont(14)
        noteTitleLabel.textColor = .label
        noteTitleLabel.numberOfLines = 1
        noteContainer.addSubview(noteTitleLabel)

        notePreviewLabel.font = ScreenAdapter.font(12)
        notePreviewLabel.textColor = .secondaryLabel
        notePreviewLabel.numberOfLines = 2
        noteContainer.addSubview(notePreviewLabel)

        noteContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(typeIconView.snp.bottom).offset(ScreenAdapter.scaleH(10))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
        }

        noteIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.width.height.equalTo(ScreenAdapter.scaleW(22))
        }

        noteTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(noteIcon.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalTo(noteIcon)
        }

        notePreviewLabel.snp.makeConstraints { make in
            make.leading.equalTo(noteIcon.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalTo(noteTitleLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(12))
        }
    }

    override func configure(with item: FavoriteItem) {
        super.configure(with: item)
        let note = FavoriteForwarder.parseNote(item.content)
        noteTitleLabel.text = (note?.title.isEmpty == false) ? note!.title : "无标题笔记"
        notePreviewLabel.text = note?.previewText ?? ""
    }
}

// MARK: - 收藏转发器（对齐安卓 FavoriteActivity.showForwardDialog）
enum FavoriteForwarder {

    /// 解析笔记 JSON（本端 NoteEntity 格式 / 安卓 WKNoteContent 格式均兼容）
    static func parseNote(_ content: String) -> NoteEntity? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return nil }
        if let note = try? JSONDecoder().decode(NoteEntity.self, from: data), !note.blocks.isEmpty || !note.title.isEmpty {
            return note
        }
        guard let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        // 安卓 WKNoteContent 原生格式
        if dict["noteTitle"] != nil || dict["blockListJson"] != nil || dict["noteId"] != nil {
            var note = NoteEntity()
            if let nid = dict["noteId"] as? String, !nid.isEmpty { note.id = nid }
            note.title = dict["noteTitle"] as? String ?? ""
            note.group = dict["noteGroup"] as? String ?? "普通笔记"
            var blocks: [NoteBlock] = []
            if let blJson = dict["blockListJson"] as? String, !blJson.isEmpty,
               let bd = blJson.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: bd) as? [[String: Any]] {
                for b in arr {
                    let t = (b["type"] as? NSNumber)?.intValue ?? 2
                    let c = b["content"] as? String ?? ""
                    switch t {
                    case 1: blocks.append(NoteBlock(type: .title, content: c))
                    case 3:
                        let img = b["imagePath"] as? String ?? ""
                        blocks.append(NoteBlock(type: .image, imageURL: img.isEmpty ? nil : img))
                    case 4:
                        let v = b["videoPath"] as? String ?? ""
                        blocks.append(NoteBlock(type: .video, videoURL: v.isEmpty ? nil : v))
                    case 5:
                        let lat = (b["latitude"] as? NSNumber)?.doubleValue ?? 0
                        let lng = (b["longitude"] as? NSNumber)?.doubleValue ?? 0
                        let ln = b["locationName"] as? String ?? ""
                        let la = b["locationAddress"] as? String ?? ""
                        blocks.append(NoteBlock(type: .location, content: ln,
                                                location: NoteLocation(latitude: lat, longitude: lng, address: la.isEmpty ? ln : la)))
                    default: blocks.append(NoteBlock(type: .text, content: c))
                    }
                }
            }
            if blocks.isEmpty, let nc = dict["noteContent"] as? String, !nc.isEmpty {
                blocks = [NoteBlock(type: .text, content: nc)]
            }
            note.blocks = blocks
            return note
        }
        if let note = try? JSONDecoder().decode(NoteEntity.self, from: data) { return note }
        return nil
    }

    /// 相对路径/绝对地址统一转 URL（聊天媒体走 /v1/static/chat/ 前缀规则）
    static func mediaURL(_ urlStr: String) -> URL? {
        guard !urlStr.isEmpty else { return nil }
        if urlStr.hasPrefix("http") { return URL(string: urlStr) }
        if urlStr.hasPrefix("/") { return URL(string: APIConfig.apiBaseURL + urlStr) }
        return URL(string: APIConfig.apiBaseURL + "/" + urlStr)
    }

    /// 转发入口：有会话上下文（聊天工具栏进入）→ 弹"发送给当前好友 确定/取消"；
    /// 无上下文（我的页面进入）→ 上下滑动选择好友 → 再弹确认
    static func present(from vc: UIViewController, items: [FavoriteItem],
                        channelId: String?, channelType: Int, onSent: (() -> Void)? = nil) {
        if let cid = channelId, !cid.isEmpty {
            let name = IMManager.shared.getChannelInfo(channelId: cid, channelType: channelType)?.displayName ?? "当前好友"
            let sheet = FavoriteForwardSheet(items: items, targetId: cid, targetType: channelType, targetName: name)
            sheet.onSent = onSent
            vc.present(sheet, animated: true)
        } else {
            let picker = FriendPickerSheet()
            picker.onPicked = { [weak vc] friend in
                guard let vc = vc, let friend = friend else { return }
                let sheet = FavoriteForwardSheet(items: items, targetId: friend.uid, targetType: 1, targetName: friend.displayName)
                sheet.onSent = onSent
                vc.present(sheet, animated: true)
            }
            vc.present(picker, animated: true)
        }
    }

    /// 逐条发送收藏内容（全部走 IM SDK 类型消息，保证与安卓双端互通）
    static func send(_ item: FavoriteItem, to channelId: String, channelType: Int) {
        let im = IMManager.shared
        switch item.type {
        case .text, .link:
            im.sendTextMessage(channelId: channelId, content: item.content, channelType: channelType)
        case .image:
            let url = item.imageURL ?? item.content
            guard !url.isEmpty, !url.hasPrefix("local:") else {
                im.sendTextMessage(channelId: channelId, content: "[图片]", channelType: channelType)
                return
            }
            im.sendImageMessage(channelId: channelId, imageURL: url, width: 0, height: 0, channelType: channelType)
        case .voice:
            guard let url = item.voiceURL, !url.isEmpty else {
                im.sendTextMessage(channelId: channelId, content: "[语音]", channelType: channelType)
                return
            }
            im.sendVoiceMessage(channelId: channelId, voiceURL: url,
                                duration: max(1, Int(item.voiceDuration ?? 1)), channelType: channelType)
        case .video:
            let video = item.videoURL ?? ""
            guard !video.isEmpty else {
                im.sendTextMessage(channelId: channelId, content: "[视频]", channelType: channelType)
                return
            }
            im.sendVideoMessage(channelId: channelId, thumbURL: item.imageURL ?? "", videoURL: video,
                                duration: 0, channelType: channelType)
        case .file:
            guard let url = item.fileURL, !url.isEmpty else {
                im.sendTextMessage(channelId: channelId, content: item.fileName ?? "[文件]", channelType: channelType)
                return
            }
            im.sendFileMessage(channelId: channelId, fileName: item.fileName ?? "文件",
                               fileSize: item.fileSize ?? 0, fileURL: url, channelType: channelType)
        case .location:
            guard let loc = item.location else {
                im.sendTextMessage(channelId: channelId, content: "[位置]", channelType: channelType)
                return
            }
            // 收藏存的 address 可能为 "名称\n地址"，拆分回 name/address
            let parts = loc.address.components(separatedBy: "\n")
            let name = parts.first ?? loc.address
            let addr = parts.count > 1 ? parts.dropFirst().joined(separator: "\n") : ""
            im.sendLocationMessage(channelId: channelId, name: name, address: addr,
                                   latitude: loc.latitude, longitude: loc.longitude, channelType: channelType)
        case .note:
            guard let note = parseNote(item.content),
                  let data = try? JSONEncoder().encode(note),
                  let json = String(data: data, encoding: .utf8) else {
                im.sendTextMessage(channelId: channelId, content: "[笔记]", channelType: channelType)
                return
            }
            im.sendNoteMessage(channelId: channelId, noteJSON: json, channelType: channelType)
        }
    }
}

// MARK: - 底部转发确认弹层（对齐安卓 chat_favorite_forward_dialog）
class FavoriteForwardSheet: UIViewController {

    var onSent: (() -> Void)?

    private let items: [FavoriteItem]
    private let targetId: String
    private let targetType: Int
    private let targetName: String

    private let dimView = UIView()
    private let cardView = UIView()

    init(items: [FavoriteItem], targetId: String, targetType: Int, targetName: String) {
        self.items = items
        self.targetId = targetId
        self.targetType = targetType
        self.targetName = targetName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        dimView.addGestureRecognizer(tap)

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(14)
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.clipsToBounds = true
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        let titleLabel = UILabel()
        titleLabel.text = "发送给"
        titleLabel.font = ScreenAdapter.mediumFont(16)
        titleLabel.textColor = .label
        cardView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.centerX.equalToSuperview()
        }

        // 好友头像 + 昵称
        let avatarView = UIImageView()
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(20)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        AppUtility.loadChannelAvatar(channelId: targetId, channelType: targetType, name: targetName, into: avatarView)
        cardView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(14))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }

        let nameLabel = UILabel()
        nameLabel.text = targetName
        nameLabel.font = ScreenAdapter.mediumFont(15)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        cardView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(ScreenAdapter.scaleW(10))
            make.centerY.equalTo(avatarView)
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(20))
        }

        // 内容预览区
        let previewContainer = UIView()
        previewContainer.backgroundColor = .systemGray6
        previewContainer.layer.cornerRadius = ScreenAdapter.scaleW(10)
        cardView.addSubview(previewContainer)
        previewContainer.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(ScreenAdapter.scaleH(14))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }

        if items.count > 1 {
            let label = UILabel()
            label.text = "【逐条转发】共\(items.count)条消息"
            label.font = ScreenAdapter.font(14)
            label.textColor = .label
            previewContainer.addSubview(label)
            label.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(ScreenAdapter.scaleH(14))
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
                make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
            }
        } else if let item = items.first {
            switch item.type {
            case .image, .video:
                let imgView = UIImageView()
                imgView.contentMode = .scaleAspectFill
                imgView.clipsToBounds = true
                imgView.backgroundColor = .systemGray5
                imgView.layer.cornerRadius = ScreenAdapter.scaleW(6)
                let urlStr = item.imageURL ?? item.content
                if let url = FavoriteForwarder.mediaURL(urlStr) {
                    imgView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
                }
                previewContainer.addSubview(imgView)
                imgView.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
                    make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
                    make.width.equalTo(ScreenAdapter.scaleW(80))
                    make.height.equalTo(ScreenAdapter.scaleH(80))
                    make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(10))
                }
                if item.type == .video {
                    let playIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                    playIcon.tintColor = .white
                    imgView.addSubview(playIcon)
                    playIcon.snp.makeConstraints { make in
                        make.center.equalToSuperview()
                        make.width.height.equalTo(ScreenAdapter.scaleW(28))
                    }
                }
            default:
                let label = UILabel()
                label.text = item.previewText
                label.font = ScreenAdapter.font(14)
                label.textColor = .label
                label.numberOfLines = 3
                previewContainer.addSubview(label)
                label.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(ScreenAdapter.scaleH(14))
                    make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
                    make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
                    make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(14))
                }
            }
        }

        // 取消 / 确定 按钮
        let btnStack = UIStackView()
        btnStack.axis = .horizontal
        btnStack.spacing = ScreenAdapter.scaleW(12)
        btnStack.distribution = .fillEqually
        cardView.addSubview(btnStack)
        btnStack.snp.makeConstraints { make in
            make.top.equalTo(previewContainer.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.height.equalTo(ScreenAdapter.scaleH(44))
            make.bottom.equalToSuperview().offset(-(ScreenAdapter.scaleH(16) + view.safeAreaInsets.bottom))
        }

        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(.label, for: .normal)
        cancelBtn.backgroundColor = .systemGray5
        cancelBtn.titleLabel?.font = ScreenAdapter.mediumFont(15)
        cancelBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        btnStack.addArrangedSubview(cancelBtn)

        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("确定", for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.backgroundColor = .themePrimary
        confirmBtn.titleLabel?.font = ScreenAdapter.mediumFont(15)
        confirmBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        btnStack.addArrangedSubview(confirmBtn)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func confirmTapped() {
        for item in items {
            FavoriteForwarder.send(item, to: targetId, channelType: targetType)
        }
        dismiss(animated: true) { [weak self] in
            AppUtility.showToast("已发送给\(self?.targetName ?? "")")
            self?.onSent?()
        }
    }
}

// MARK: - 好友滑动选择弹层（我的页面转发收藏：上下滑动选择好友）
class FriendPickerSheet: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    var onPicked: ((FriendSyncInfo?) -> Void)?

    private var friends: [FriendSyncInfo] = []
    private let dimView = UIView()
    private let cardView = UIView()
    private let pickerView = UIPickerView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFriends()
    }

    private func setupUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        dimView.addGestureRecognizer(tap)

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(14)
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.clipsToBounds = true
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        let titleLabel = UILabel()
        titleLabel.text = "选择好友"
        titleLabel.font = ScreenAdapter.mediumFont(16)
        titleLabel.textColor = .label
        cardView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.centerX.equalToSuperview()
        }

        pickerView.dataSource = self
        pickerView.delegate = self
        cardView.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(180))
        }

        loadingIndicator.hidesWhenStopped = true
        cardView.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(pickerView)
        }

        let btnStack = UIStackView()
        btnStack.axis = .horizontal
        btnStack.spacing = ScreenAdapter.scaleW(12)
        btnStack.distribution = .fillEqually
        cardView.addSubview(btnStack)
        btnStack.snp.makeConstraints { make in
            make.top.equalTo(pickerView.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.height.equalTo(ScreenAdapter.scaleH(44))
            make.bottom.equalToSuperview().offset(-(ScreenAdapter.scaleH(16) + view.safeAreaInsets.bottom))
        }

        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(.label, for: .normal)
        cancelBtn.backgroundColor = .systemGray5
        cancelBtn.titleLabel?.font = ScreenAdapter.mediumFont(15)
        cancelBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        btnStack.addArrangedSubview(cancelBtn)

        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("确定", for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.backgroundColor = .themePrimary
        confirmBtn.titleLabel?.font = ScreenAdapter.mediumFont(15)
        confirmBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        btnStack.addArrangedSubview(confirmBtn)
    }

    private func loadFriends() {
        loadingIndicator.startAnimating()
        Task {
            do {
                let list: [FriendSyncInfo] = try await APIClient.shared.requestFlexible(.syncFriends)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.loadingIndicator.stopAnimating()
                    self.friends = list
                    self.pickerView.reloadAllComponents()
                    if list.isEmpty {
                        AppUtility.showToast("暂无好友")
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.loadingIndicator.stopAnimating()
                    AppUtility.showToast("好友列表加载失败")
                }
            }
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func confirmTapped() {
        guard !friends.isEmpty else {
            AppUtility.showToast("暂无可转发的好友")
            return
        }
        let row = pickerView.selectedRow(inComponent: 0)
        guard row >= 0, row < friends.count else { return }
        let friend = friends[row]
        dismiss(animated: true) { [weak self] in
            self?.onPicked?(friend)
        }
    }

    // MARK: UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return friends.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard row < friends.count else { return nil }
        return friends[row].displayName
    }
}
