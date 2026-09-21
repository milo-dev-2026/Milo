import UIKit
import SnapKit

struct NoteItem: Codable {
    var id: String
    var title: String
    var content: String
    var group: String
    var createdAt: Int64
    var updatedAt: Int64
}

class NoteViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var notes: [NoteItem] = []
    private var groups: [String] = ["全部", "未分组"]
    private var currentGroup = "全部"

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

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NoteCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNote)
        )
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "notes"),
           let decoded = try? JSONDecoder().decode([NoteItem].self, from: data) {
            notes = decoded
        }
        tableView.reloadData()
    }

    private func saveData() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: "notes")
        }
    }

    @objc private func addNote() {
        let editor = NoteEditorViewController()
        editor.onSave = { [weak self] note in
            self?.notes.insert(note, at: 0)
            self?.saveData()
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(editor, animated: true)
    }
}

extension NoteViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let filtered = currentGroup == "全部" ? notes : notes.filter { $0.group == currentGroup }
        return filtered.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "笔记列表"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
        let filtered = currentGroup == "全部" ? notes : notes.filter { $0.group == currentGroup }
        let note = filtered[indexPath.row]
        cell.textLabel?.text = note.title.isEmpty ? "无标题" : note.title
        cell.detailTextLabel?.text = note.content
        cell.detailTextLabel?.numberOfLines = 1
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let filtered = currentGroup == "全部" ? notes : notes.filter { $0.group == currentGroup }
        let editor = NoteEditorViewController(note: filtered[indexPath.row])
        editor.onSave = { [weak self] updated in
            if let idx = self?.notes.firstIndex(where: { $0.id == updated.id }) {
                self?.notes[idx] = updated
                self?.saveData()
                self?.tableView.reloadData()
            }
        }
        editor.onDelete = { [weak self] noteId in
            self?.notes.removeAll { $0.id == noteId }
            self?.saveData()
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            let filtered = self?.currentGroup == "全部" ? self?.notes : self?.notes.filter { $0.group == self?.currentGroup ?? "" }
            guard let note = filtered?[indexPath.row] else { completion(false); return }
            self?.notes.removeAll { $0.id == note.id }
            self?.saveData()
            tableView.deleteRows(at: [indexPath], with: .fade)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

class NoteEditorViewController: UIViewController {

    private var note: NoteItem?
    var onSave: ((NoteItem) -> Void)?
    var onDelete: ((String) -> Void)?

    private let titleField = UITextField()
    private let contentField = UITextView()
    private let groupField = UITextField()

    init(note: NoteItem? = nil) {
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = note == nil ? "新建笔记" : "编辑笔记"
        view.backgroundColor = .themeBackground

        titleField.placeholder = "标题"
        titleField.borderStyle = .roundedRect
        titleField.font = ScreenAdapter.mediumFont(18)
        titleField.text = note?.title

        groupField.placeholder = "分组"
        groupField.borderStyle = .roundedRect
        groupField.font = ScreenAdapter.font(14)
        groupField.text = note?.group

        contentField.font = ScreenAdapter.font(16)
        contentField.layer.cornerRadius = ScreenAdapter.scaleW(8)
        contentField.backgroundColor = .systemBackground
        contentField.text = note?.content

        let stack = UIStackView(arrangedSubviews: [titleField, groupField, contentField])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(12)

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(16))
        }

        groupField.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        titleField.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "保存",
            style: .done,
            target: self,
            action: #selector(save)
        )

        if note != nil {
            let deleteBtn = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(deleteNote)
            )
            navigationItem.leftBarButtonItem = deleteBtn
        }
    }

    @objc private func save() {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let saved = NoteItem(
            id: note?.id ?? UUID().uuidString,
            title: titleField.text ?? "",
            content: contentField.text ?? "",
            group: groupField.text?.isEmpty == false ? groupField.text! : "未分组",
            createdAt: note?.createdAt ?? now,
            updatedAt: now
        )
        onSave?(saved)
        navigationController?.popViewController(animated: true)
    }

    @objc private func deleteNote() {
        guard let id = note?.id else { return }
        let alert = UIAlertController(title: "删除笔记", message: "确定删除？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.onDelete?(id)
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
