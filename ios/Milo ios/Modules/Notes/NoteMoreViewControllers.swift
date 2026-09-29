//
//  NoteMoreViewControllers.swift
//  Milo
//
//  笔记模块扩充页面
//  包含：笔记文件夹管理、笔记分享、笔记历史版本
//

import UIKit
import SnapKit

// MARK: - 笔记文件夹管理
class NoteFolderManagerViewController: UIViewController {

    // MARK: - 数据模型
    struct NoteFolder {
        let id: String
        let name: String
        let noteCount: Int
        let isDefault: Bool
    }

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var folders: [NoteFolder] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFolders()
    }

    private func setupUI() {
        title = "文件夹管理"
        view.backgroundColor = .themeBg

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addFolder)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FolderCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadFolders() {
        // 模拟数据
        folders = [
            NoteFolder(id: "default", name: "全部笔记", noteCount: 12, isDefault: true),
            NoteFolder(id: "1", name: "工作", noteCount: 5, isDefault: false),
            NoteFolder(id: "2", name: "生活", noteCount: 4, isDefault: false),
            NoteFolder(id: "3", name: "学习", noteCount: 3, isDefault: false),
        ]
        tableView.reloadData()
    }

    @objc private func addFolder() {
        let alert = UIAlertController(title: "新建文件夹", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "请输入文件夹名称"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.isEmpty else { return }
            let newFolder = NoteFolder(id: UUID().uuidString, name: name, noteCount: 0, isDefault: false)
            self.folders.append(newFolder)
            self.tableView.reloadData()
            AppUtility.showToast("创建成功")
        })
        present(alert, animated: true)
    }

    private func renameFolder(at indexPath: IndexPath) {
        let folder = folders[indexPath.row]
        guard !folder.isDefault else { return }

        let alert = UIAlertController(title: "重命名", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = folder.name
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text,
                  !newName.isEmpty else { return }
            // 更新名称
            AppUtility.showToast("已重命名")
            self.loadFolders()
        })
        present(alert, animated: true)
    }

    private func deleteFolder(at indexPath: IndexPath) {
        let folder = folders[indexPath.row]
        guard !folder.isDefault else {
            AppUtility.showToast("默认文件夹不能删除")
            return
        }

        let alert = AlertDialog(
            title: "删除文件夹",
            message: "确定要删除「\(folder.name)」吗？\n文件夹内的笔记将移动到「全部笔记」"
        )
        alert.onConfirm = { [weak self] in
            self?.folders.remove(at: indexPath.row)
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            AppUtility.showToast("已删除")
        }
        present(alert, animated: false)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NoteFolderManagerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)
        let folder = folders[indexPath.row]

        cell.textLabel?.text = folder.name
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.detailTextLabel?.text = "\(folder.noteCount) 篇笔记"
        cell.detailTextLabel?.font = ThemeFont.caption(13)
        cell.detailTextLabel?.textColor = .themeTextSecondary
        cell.imageView?.image = UIImage(systemName: folder.isDefault ? "tray.fill" : "folder.fill")
        cell.imageView?.tintColor = .themeColorPrimary
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let folder = folders[indexPath.row]
        guard !folder.isDefault else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completion) in
            self?.deleteFolder(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = .themeError

        let renameAction = UIContextualAction(style: .normal, title: "重命名") { [weak self] (_, _, completion) in
            self?.renameFolder(at: indexPath)
            completion(true)
        }
        renameAction.backgroundColor = .themeColorPrimary

        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }
}

// MARK: - 笔记分享
class NoteShareViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var noteId: String
    private var noteTitle: String

    init(noteId: String, title: String) {
        self.noteId = noteId
        self.noteTitle = title
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
        title = "分享笔记"
        view.backgroundColor = .themeBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // 笔记预览卡片
        let previewCard = UIView()
        previewCard.backgroundColor = .themeBgCard
        previewCard.layer.cornerRadius = 12
        contentView.addSubview(previewCard)
        previewCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        let titleLabel = UILabel()
        titleLabel.text = noteTitle
        titleLabel.font = ThemeFont.title3(16)
        titleLabel.textColor = .themeTextPrimary
        titleLabel.numberOfLines = 1
        previewCard.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        let descLabel = UILabel()
        descLabel.text = "点击下方按钮分享笔记"
        descLabel.font = ThemeFont.bodySmall(14)
        descLabel.textColor = .themeTextSecondary
        previewCard.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        // 分享方式标题
        let shareTitleLabel = UILabel()
        shareTitleLabel.text = "分享方式"
        shareTitleLabel.font = ThemeFont.title3(15)
        shareTitleLabel.textColor = .themeTextPrimary
        contentView.addSubview(shareTitleLabel)
        shareTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(previewCard.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(16)
        }

        // 分享按钮网格
        let shareOptions = [
            ("message", "好友", UIColor.themeColorPrimary),
            ("person.2.fill", "群聊", UIColor(red: 0.20, green: 0.65, blue: 0.42, alpha: 1.0)),
            ("square.and.arrow.up", "更多", UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0)),
            ("link", "复制链接", UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0)),
        ]

        let shareStack = UIStackView()
        shareStack.axis = .horizontal
        shareStack.distribution = .fillEqually
        shareStack.spacing = 12
        contentView.addSubview(shareStack)
        shareStack.snp.makeConstraints { make in
            make.top.equalTo(shareTitleLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(90)
        }

        for (index, option) in shareOptions.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.addTarget(self, action: #selector(shareOptionTapped(_:)), for: .touchUpInside)
            shareStack.addArrangedSubview(button)

            let iconView = UIImageView(image: UIImage(systemName: option.0))
            iconView.tintColor = option.2
            iconView.contentMode = .scaleAspectFit
            button.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(36)
            }

            let label = UILabel()
            label.text = option.1
            label.font = ThemeFont.caption(12)
            label.textColor = .themeTextSecondary
            label.textAlignment = .center
            button.addSubview(label)
            label.snp.makeConstraints { make in
                make.top.equalTo(iconView.snp.bottom).offset(6)
                make.centerX.equalToSuperview()
            }
        }

        // 权限设置
        let permissionTitleLabel = UILabel()
        permissionTitleLabel.text = "分享设置"
        permissionTitleLabel.font = ThemeFont.title3(15)
        permissionTitleLabel.textColor = .themeTextPrimary
        contentView.addSubview(permissionTitleLabel)
        permissionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(shareStack.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(16)
        }

        let permissionCard = UIView()
        permissionCard.backgroundColor = .themeBgCard
        permissionCard.layer.cornerRadius = 12
        contentView.addSubview(permissionCard)
        permissionCard.snp.makeConstraints { make in
            make.top.equalTo(permissionTitleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-20)
        }

        let permissionItems = [
            ("允许评论", true),
            ("允许转发", true),
            ("公开分享", false),
        ]

        var lastView: UIView?
        for (index, item) in permissionItems.enumerated() {
            let row = UIView()
            permissionCard.addSubview(row)
            row.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(52)
                if let last = lastView {
                    make.top.equalTo(last.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }

            let label = UILabel()
            label.text = item.0
            label.font = ThemeFont.body(15)
            label.textColor = .themeTextPrimary
            row.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }

            let switchControl = UISwitch()
            switchControl.isOn = item.1
            switchControl.onTintColor = .themeColorPrimary
            switchControl.tag = index
            switchControl.addTarget(self, action: #selector(permissionSwitchToggled(_:)), for: .valueChanged)
            row.addSubview(switchControl)
            switchControl.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
            }

            // 分割线
            if index < permissionItems.count - 1 {
                let line = UIView()
                line.backgroundColor = .themeSeparatorLight
                row.addSubview(line)
                line.snp.makeConstraints { make in
                    make.left.equalToSuperview().offset(16)
                    make.right.bottom.equalToSuperview()
                    make.height.equalTo(0.5)
                }
            }

            lastView = row
        }

        lastView?.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    @objc private func shareOptionTapped(_ sender: UIButton) {
        let options = ["好友", "群聊", "更多", "复制链接"]
        AppUtility.showToast("分享到\(options[sender.tag])")
    }

    @objc private func permissionSwitchToggled(_ sender: UISwitch) {
        AppUtility.showToast(sender.isOn ? "已开启" : "已关闭")
    }
}

// MARK: - 笔记历史版本
class NoteHistoryViewController: UIViewController {

    // MARK: - 数据模型
    struct NoteVersion {
        let id: String
        let title: String
        let content: String
        let timestamp: Date
        let size: String
    }

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var versions: [NoteVersion] = []
    private var noteId: String

    init(noteId: String) {
        self.noteId = noteId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadVersions()
    }

    private func setupUI() {
        title = "历史版本"
        view.backgroundColor = .themeBg

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(NoteVersionCell.self, forCellReuseIdentifier: "VersionCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadVersions() {
        // 模拟数据
        let now = Date()
        versions = [
            NoteVersion(id: "v1", title: "当前版本", content: "最新保存的内容", timestamp: now, size: "2.3 KB"),
            NoteVersion(id: "v2", title: "版本 2", content: "2小时前编辑的内容...", timestamp: now.addingTimeInterval(-7200), size: "2.1 KB"),
            NoteVersion(id: "v3", title: "版本 3", content: "昨天编辑的内容...", timestamp: now.addingTimeInterval(-86400), size: "1.8 KB"),
            NoteVersion(id: "v4", title: "版本 4", content: "3天前编辑的内容...", timestamp: now.addingTimeInterval(-259200), size: "1.5 KB"),
            NoteVersion(id: "v5", title: "版本 5", content: "一周前的初始内容...", timestamp: now.addingTimeInterval(-604800), size: "1.2 KB"),
        ]
        tableView.reloadData()
    }

    private func restoreVersion(at indexPath: IndexPath) {
        let version = versions[indexPath.row]
        let alert = AlertDialog(
            title: "恢复版本",
            message: "确定要恢复到「\(version.title)」吗？\n当前版本将自动保存为历史版本。"
        )
        alert.onConfirm = {
            AppUtility.showToast("已恢复到 \(version.title)")
        }
        present(alert, animated: false)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NoteHistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return versions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VersionCell", for: indexPath) as! NoteVersionCell
        cell.configure(with: versions[indexPath.row], isCurrent: indexPath.row == 0)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row > 0 else { return nil } // 当前版本不能操作

        let restoreAction = UIContextualAction(style: .normal, title: "恢复") { [weak self] (_, _, completion) in
            self?.restoreVersion(at: indexPath)
            completion(true)
        }
        restoreAction.backgroundColor = .themeColorPrimary

        let previewAction = UIContextualAction(style: .normal, title: "预览") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            let version = self.versions[indexPath.row]
            let vc = NoteVersionPreviewViewController(version: version)
            self.navigationController?.pushViewController(vc, animated: true)
            completion(true)
        }
        previewAction.backgroundColor = .themeSuccess

        return UISwipeActionsConfiguration(actions: [restoreAction, previewAction])
    }
}

// MARK: - 历史版本 Cell
class NoteVersionCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let timeLabel = UILabel()
    private let sizeLabel = UILabel()
    private let currentBadge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        selectionStyle = .none

        titleLabel.font = ThemeFont.title3(15)
        titleLabel.textColor = .themeTextPrimary
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
        }

        currentBadge.text = "当前"
        currentBadge.font = ThemeFont.tiny(10)
        currentBadge.textColor = .themeSuccess
        currentBadge.backgroundColor = .themeSuccess.withAlphaComponent(0.1)
        currentBadge.textAlignment = .center
        currentBadge.layer.cornerRadius = 4
        currentBadge.layer.masksToBounds = true
        currentBadge.isHidden = true
        contentView.addSubview(currentBadge)
        currentBadge.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.centerY.equalTo(titleLabel)
            make.width.equalTo(32)
            make.height.equalTo(18)
        }

        contentLabel.font = ThemeFont.bodySmall(13)
        contentLabel.textColor = .themeTextSecondary
        contentLabel.numberOfLines = 1
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-16)
        }

        timeLabel.font = ThemeFont.tiny(12)
        timeLabel.textColor = .themeTextTertiary
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(4)
            make.left.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
        }

        sizeLabel.font = ThemeFont.tiny(12)
        sizeLabel.textColor = .themeTextTertiary
        sizeLabel.textAlignment = .right
        contentView.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(timeLabel)
        }
    }

    func configure(with version: NoteHistoryViewController.NoteVersion, isCurrent: Bool) {
        titleLabel.text = version.title
        contentLabel.text = version.content
        timeLabel.text = AppUtility.formatTimestamp(Int64(version.timestamp.timeIntervalSince1970 * 1000))
        sizeLabel.text = version.size
        currentBadge.isHidden = !isCurrent
    }
}

// MARK: - 版本预览
class NoteVersionPreviewViewController: UIViewController {

    private let version: NoteHistoryViewController.NoteVersion
    private let textView = UITextView()
    private let restoreButton = UIButton(type: .system)

    init(version: NoteHistoryViewController.NoteVersion) {
        self.version = version
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
        title = version.title
        view.backgroundColor = .themeBg

        textView.font = ThemeFont.body(16)
        textView.textColor = .themeTextPrimary
        textView.backgroundColor = .themeBgCard
        textView.layer.cornerRadius = 8
        textView.text = version.content
        textView.isEditable = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-80)
        }

        restoreButton.setTitle("恢复此版本", for: .normal)
        restoreButton.titleLabel?.font = ThemeFont.buttonLarge(16)
        restoreButton.setTitleColor(.white, for: .normal)
        restoreButton.backgroundColor = .themeColorPrimary
        restoreButton.layer.cornerRadius = 10
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        view.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(48)
        }
    }

    @objc private func restoreTapped() {
        let alert = AlertDialog(
            title: "恢复版本",
            message: "确定要恢复到此版本吗？"
        )
        alert.onConfirm = { [weak self] in
            AppUtility.showToast("已恢复")
            self?.navigationController?.popViewController(animated: true)
        }
        present(alert, animated: false)
    }
}
