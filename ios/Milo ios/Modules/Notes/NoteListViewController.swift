import UIKit
import SnapKit
import Kingfisher

// MARK: - 笔记列表页
class NoteListViewController: UIViewController {
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addButton = UIButton(type: .system)
    private var notes: [NoteEntity] = []
    private var isSearching = false
    
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
        title = "笔记"
        view.backgroundColor = .themeBackground
        
        // 搜索栏
        searchBar.delegate = self
        searchBar.placeholder = "搜索笔记"
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
        tableView.register(NoteListCell.self, forCellReuseIdentifier: "NoteListCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // 悬浮添加按钮
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = .themePrimary
        addButton.layer.cornerRadius = ScreenAdapter.scaleW(28)
        addButton.layer.shadowColor = UIColor.themePrimary.cgColor
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowRadius = 8
        addButton.addTarget(self, action: #selector(addNote), for: .touchUpInside)
        view.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(56))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(20))
        }
    }
    
    private func loadData() {
        if isSearching, let keyword = searchBar.text, !keyword.isEmpty {
            notes = NoteStorageManager.shared.searchNotes(keyword: keyword)
        } else {
            notes = NoteStorageManager.shared.getAllNotes()
        }
        tableView.reloadData()
    }
    
    @objc private func addNote() {
        let editor = NoteEditViewController()
        editor.onSave = { [weak self] _ in
            self?.loadData()
        }
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension NoteListViewController: UISearchBarDelegate {
    
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
extension NoteListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(notes.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if notes.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "EmptyCell")
            cell.textLabel?.text = "暂无笔记"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = ScreenAdapter.font(15)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteListCell", for: indexPath) as! NoteListCell
        cell.configure(with: notes[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if notes.isEmpty {
            return ScreenAdapter.scaleH(200)
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return ScreenAdapter.scaleH(100)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !notes.isEmpty else { return }
        let note = notes[indexPath.row]
        let detail = NoteDetailViewController(note: note)
        detail.onEdit = { [weak self] updatedNote in
            self?.loadData()
        }
        detail.onDelete = { [weak self] _ in
            self?.loadData()
        }
        navigationController?.pushViewController(detail, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !notes.isEmpty else { return nil }
        
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            let note = self.notes[indexPath.row]
            let alert = UIAlertController(title: "删除笔记", message: "确定删除该笔记？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completion(false) })
            alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
                NoteStorageManager.shared.deleteNote(id: note.id)
                self?.loadData()
                completion(true)
            })
            self.present(alert, animated: true)
        }
        delete.backgroundColor = .systemRed
        
        let sticky = UIContextualAction(style: .normal, title: notes[indexPath.row].isSticky ? "取消置顶" : "置顶") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            let note = self.notes[indexPath.row]
            NoteStorageManager.shared.toggleSticky(noteId: note.id)
            self.loadData()
            completion(true)
        }
        sticky.backgroundColor = .systemOrange
        
        return UISwipeActionsConfiguration(actions: [delete, sticky])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !notes.isEmpty else { return nil }
        
        let sticky = UIContextualAction(style: .normal, title: notes[indexPath.row].isSticky ? "取消置顶" : "置顶") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            let note = self.notes[indexPath.row]
            NoteStorageManager.shared.toggleSticky(noteId: note.id)
            self.loadData()
            completion(true)
        }
        sticky.backgroundColor = .systemOrange
        
        return UISwipeActionsConfiguration(actions: [sticky])
    }
}

// MARK: - 笔记列表Cell
class NoteListCell: UITableViewCell {
    
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let previewLabel = UILabel()
    private let timeLabel = UILabel()
    private let stickyImageView = UIImageView()
    private let thumbnailImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.05
        cardView.layer.shadowRadius = 4
        contentView.addSubview(cardView)
        
        titleLabel.font = ScreenAdapter.mediumFont(16)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        cardView.addSubview(titleLabel)
        
        previewLabel.font = ScreenAdapter.font(14)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 2
        cardView.addSubview(previewLabel)
        
        timeLabel.font = ScreenAdapter.font(12)
        timeLabel.textColor = .tertiaryLabel
        cardView.addSubview(timeLabel)
        
        stickyImageView.image = UIImage(systemName: "pin.fill")
        stickyImageView.tintColor = .systemOrange
        stickyImageView.isHidden = true
        cardView.addSubview(stickyImageView)
        
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        thumbnailImageView.backgroundColor = .systemGray6
        cardView.addSubview(thumbnailImageView)
        
        cardView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(8))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(8))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.trailing.lessThanOrEqualTo(stickyImageView.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }
        
        stickyImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(ScreenAdapter.scaleW(16))
        }
        
        thumbnailImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.width.height.equalTo(ScreenAdapter.scaleW(56))
        }
        
        previewLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(6))
            make.trailing.equalTo(thumbnailImageView.snp.leading).offset(-ScreenAdapter.scaleW(10))
        }
        
        timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
            make.top.equalTo(previewLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(12))
        }
    }
    
    func configure(with note: NoteEntity) {
        titleLabel.text = note.title.isEmpty ? "无标题" : note.title
        previewLabel.text = note.previewText
        timeLabel.text = note.timeString
        stickyImageView.isHidden = !note.isSticky
        
        if let imgURL = note.firstImageURL, !imgURL.isEmpty {
            thumbnailImageView.isHidden = false
            let url: URL?
            if imgURL.hasPrefix("http") {
                url = URL(string: imgURL)
            } else if imgURL.hasPrefix("/") {
                url = URL(string: APIConfig.apiBaseURL + imgURL)
            } else {
                url = URL(string: APIConfig.apiBaseURL + "/" + imgURL)
            }
            if let url = url {
                thumbnailImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
            } else {
                thumbnailImageView.image = UIImage(systemName: "photo")
            }
            previewLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
                make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(6))
                make.trailing.equalTo(thumbnailImageView.snp.leading).offset(-ScreenAdapter.scaleW(10))
            }
        } else {
            thumbnailImageView.isHidden = true
            previewLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(14))
                make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(6))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(14))
            }
        }
    }
}
