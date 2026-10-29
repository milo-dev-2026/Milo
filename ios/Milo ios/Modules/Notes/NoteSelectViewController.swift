import UIKit
import SnapKit
import Kingfisher

// MARK: - 笔记选择页（聊天工具栏发送笔记用，对齐安卓笔记选择弹层）
class NoteSelectViewController: UIViewController {

    var onNoteSelected: ((NoteEntity) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var notes: [NoteEntity] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    private func setupUI() {
        title = "选择笔记"
        view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "新建笔记",
            style: .plain,
            target: self,
            action: #selector(addNoteTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        tableView.separatorStyle = .none
        tableView.register(NoteListCell.self, forCellReuseIdentifier: "NoteListCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyLabel.text = "暂无笔记，点击右上角新建"
        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func loadData() {
        notes = NoteStorageManager.shared.getAllNotes()
        emptyLabel.isHidden = !notes.isEmpty
        tableView.reloadData()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func addNoteTapped() {
        let editor = NoteEditViewController()
        editor.onSave = { [weak self] _ in
            self?.loadData()
        }
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NoteSelectViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteListCell", for: indexPath) as! NoteListCell
        cell.configure(with: notes[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return ScreenAdapter.scaleH(80)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < notes.count else { return }
        let note = notes[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.onNoteSelected?(note)
        }
    }
}
