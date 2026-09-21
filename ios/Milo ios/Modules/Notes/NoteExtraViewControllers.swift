import UIKit
import SnapKit

// MARK: - 选择收藏（转发用）
class FavoriteSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var favorites: [(id: String, type: String, content: String)] = []
    private var selectedIds: Set<String> = []
    var onSelected: (([(id: String, content: String)]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择收藏"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FavSelCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "发送", style: .done, target: self, action: #selector(send))
        loadData()
    }
    private func loadData() {
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.getFavorites)
                if let data = resp["data"] as? [[String: Any]] {
                    favorites = data.map { ($0["id"] as? String ?? "", $0["type"] as? String ?? "text", $0["content"] as? String ?? "") }
                    DispatchQueue.main.async { self.tableView.reloadData() }
                }
            } catch { }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(favorites.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavSelCell", for: indexPath)
        if favorites.isEmpty { cell.textLabel?.text = "暂无收藏"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let f = favorites[indexPath.row]; cell.textLabel?.text = f.content; cell.accessoryType = selectedIds.contains(f.id) ? .checkmark : .none; cell.imageView?.image = UIImage(systemName: f.type == "image" ? "photo" : "doc.text"); cell.imageView?.tintColor = .themePrimary }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !favorites.isEmpty else { return }
        let f = favorites[indexPath.row]
        if selectedIds.contains(f.id) { selectedIds.remove(f.id) } else { selectedIds.insert(f.id) }
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    @objc private func send() {
        let selected = favorites.filter { selectedIds.contains($0.id) }.map { ($0.id, $0.content) }
        onSelected?(selected); navigationController?.popViewController(animated: true)
    }
}

// MARK: - 文本收藏详情
class DetailTextViewController: UIViewController {
    private var content: String
    private let textView = UITextView()

    init(content: String) { self.content = content; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文本详情"
        view.backgroundColor = .themeBackground
        textView.text = content; textView.font = ScreenAdapter.font(16); textView.isEditable = false
        view.addSubview(textView); textView.snp.makeConstraints { make in make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)) }
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(share))
    }
    @objc private func share() { AppUtility.showToast("转发功能") }
}

// MARK: - 图片收藏详情
class DetailImgViewController: UIViewController {
    private var imageUrl: String
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    init(imageUrl: String) { self.imageUrl = imageUrl; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "图片详情"
        view.backgroundColor = .black
        scrollView.frame = view.bounds; scrollView.minimumZoomScale = 1; scrollView.maximumZoomScale = 4
        scrollView.delegate = self
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        imageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        if let url = URL(string: imageUrl) { imageView.kf.setImage(with: url) }
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(share))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:))); doubleTap.numberOfTapsRequired = 2; scrollView.addGestureRecognizer(doubleTap)
    }
    @objc private func share() { AppUtility.showToast("转发功能") }
    @objc private func doubleTap(_ gr: UITapGestureRecognizer) { scrollView.setZoomScale(scrollView.zoomScale > 1 ? 1 : 2, animated: true) }
}
extension DetailImgViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return imageView }
}

// MARK: - 笔记预览
class NotePreviewViewController: UIViewController {
    private var note: [String: Any]
    private let textView = UITextView()

    init(note: [String: Any]) { self.note = note; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = note["title"] as? String ?? "预览"
        view.backgroundColor = .themeBackground
        textView.text = note["content"] as? String; textView.font = ScreenAdapter.font(16); textView.isEditable = false
        view.addSubview(textView); textView.snp.makeConstraints { make in make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)) }
    }
}

// MARK: - 笔记详情
class NoteDetailViewController: UIViewController {
    private var note: [String: Any]
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(note: [String: Any]) { self.note = note; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "笔记详情"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NDCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
}
extension NoteDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 4 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NDCell", for: indexPath)
        cell.selectionStyle = .none; cell.imageView?.tintColor = .themePrimary
        switch indexPath.row {
        case 0: cell.textLabel?.text = "标题"; cell.detailTextLabel?.text = note["title"] as? String
        case 1: cell.textLabel?.text = "分组"; cell.detailTextLabel?.text = note["group"] as? String ?? "默认"
        case 2: cell.textLabel?.text = "创建时间"; cell.detailTextLabel?.text = note["createTime"] as? String
        case 3: cell.textLabel?.text = "内容"; cell.detailTextLabel?.text = (note["content"] as? String ?? "").prefix(20) + "..."
        default: break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 3 { navigationController?.pushViewController(NotePreviewViewController(note: note), animated: true) }
    }
}

// MARK: - 文件夹管理
class NoteFolderManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var folders: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文件夹管理"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NFMCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFolder))
        loadData()
    }
    private func loadData() {
        folders = UserDefaults.standard.stringArray(forKey: "note_folders") ?? ["默认"]
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { folders.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NFMCell", for: indexPath)
        cell.textLabel?.text = folders[indexPath.row]; cell.imageView?.image = UIImage(systemName: "folder.fill"); cell.imageView?.tintColor = .themePrimary
        return cell
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row > 0 else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "删除") { _, _, c in self.folders.remove(at: indexPath.row); UserDefaults.standard.set(self.folders, forKey: "note_folders"); tableView.reloadData(); c(true) }
        return UISwipeActionsConfiguration(actions: [delete])
    }
    @objc private func addFolder() {
        let alert = UIAlertController(title: "新建文件夹", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "文件夹名称" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let name = alert.textFields?[0].text, !name.isEmpty { self.folders.append(name); UserDefaults.standard.set(self.folders, forKey: "note_folders"); self.tableView.reloadData() }
        })
        present(alert, animated: true)
    }
}

// MARK: - 笔记备注
class NoteRemarkViewController: UIViewController {
    private var noteId: String
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)

    init(noteId: String) { self.noteId = noteId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "笔记备注"
        view.backgroundColor = .themeBackground
        textField.placeholder = "添加备注"; textField.borderStyle = .roundedRect; textField.font = ScreenAdapter.font(16)
        textField.text = UserDefaults.standard.string(forKey: "note_remark_\(noteId)")
        saveButton.setTitle("保存", for: .normal); saveButton.titleLabel?.font = ScreenAdapter.font(17); saveButton.backgroundColor = .themePrimary
        saveButton.setTitleColor(.white, for: .normal); saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [textField, saveButton]); stack.axis = .vertical; stack.spacing = ScreenAdapter.scaleH(16)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24)); make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        textField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func save() {
        UserDefaults.standard.set(textField.text, forKey: "note_remark_\(noteId)")
        AppUtility.showToast("已保存"); navigationController?.popViewController(animated: true)
    }
}
