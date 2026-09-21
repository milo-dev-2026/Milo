import UIKit
import SnapKit
import Kingfisher

// MARK: - 笔记消息Cell
class NoteMessageCell: UITableViewCell {
    
    private let bubbleView = UIView()
    private let titleLabel = UILabel()
    private let previewLabel = UILabel()
    private let iconImageView = UIImageView()
    private let timeLabel = UILabel()
    private let avatarView = UIImageView()
    private let noteTagLabel = UILabel()
    private var isFromMe = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        
        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.textAlignment = .center
        
        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        bubbleView.clipsToBounds = true
        bubbleView.backgroundColor = .white
        
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5
        
        // 笔记标签
        noteTagLabel.text = "笔记"
        noteTagLabel.font = ScreenAdapter.font(10)
        noteTagLabel.textColor = .white
        noteTagLabel.backgroundColor = .themePrimary
        noteTagLabel.textAlignment = .center
        noteTagLabel.layer.cornerRadius = ScreenAdapter.scaleW(8)
        noteTagLabel.clipsToBounds = true
        
        // 标题
        titleLabel.font = ScreenAdapter.mediumFont(15)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        
        // 预览
        previewLabel.font = ScreenAdapter.font(13)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 2
        
        // 图标
        iconImageView.image = UIImage(systemName: "note.text")
        iconImageView.tintColor = .themePrimary
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.1)
        iconImageView.layer.cornerRadius = ScreenAdapter.scaleW(6)
        iconImageView.clipsToBounds = true
        
        bubbleView.addSubviews(noteTagLabel, titleLabel, previewLabel, iconImageView)
        contentView.addSubviews(avatarView, bubbleView, timeLabel)
        
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
    }
    
    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString
        
        // 解析笔记内容
        let noteInfo = parseNoteContent(message.content)
        titleLabel.text = noteInfo.title.isEmpty ? "无标题" : noteInfo.title
        previewLabel.text = noteInfo.preview
        
        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let bubbleWidth = ScreenAdapter.screenWidth * 0.65
        
        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.1)
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
            }
            timeLabel.snp.remakeConstraints { make in
                make.trailing.equalTo(bubbleView.snp.trailing)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        } else {
            avatarView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = .white
            bubbleView.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(bubbleWidth)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }
        
        // 布局气泡内的内容
        noteTagLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.width.equalTo(ScreenAdapter.scaleW(32))
            make.height.equalTo(ScreenAdapter.scaleH(18))
        }
        
        iconImageView.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(10))
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(noteTagLabel.snp.bottom).offset(ScreenAdapter.scaleH(6))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.trailing.equalTo(iconImageView.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }
        
        previewLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.trailing.equalTo(iconImageView.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(12))
        }
    }
    
    /// 解析笔记消息内容
    private func parseNoteContent(_ content: String) -> (title: String, preview: String) {
        // 尝试解析JSON格式的笔记内容
        if let data = content.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let title = dict["title"] as? String ?? ""
            let blocks = dict["blocks"] as? [[String: Any]] ?? []
            var preview = ""
            for block in blocks {
                if let type = block["type"] as? String, type == "text" {
                    preview = block["content"] as? String ?? ""
                    break
                }
                if let type = block["type"] as? String, type == "title" {
                    preview = block["content"] as? String ?? ""
                }
            }
            if preview.isEmpty {
                preview = "查看笔记详情"
            }
            return (title, preview)
        }
        // 简单文本格式
        let lines = content.components(separatedBy: "\n")
        let title = lines.first ?? ""
        let preview = lines.dropFirst().joined(separator: " ")
        return (title, preview.isEmpty ? "查看笔记详情" : preview)
    }
}

// MARK: - 笔记选择视图控制器（用于从聊天中发送笔记）
class NoteSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var notes: [NoteEntity] = []
    var onNoteSelected: ((NoteEntity) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    private func setupUI() {
        title = "选择笔记"
        view.backgroundColor = .themeBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .themeBackground
        tableView.separatorStyle = .none
        tableView.register(NoteListCell.self, forCellReuseIdentifier: "NoteSelectCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
    }
    
    private func loadData() {
        notes = NoteStorageManager.shared.getAllNotes()
        tableView.reloadData()
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(notes.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if notes.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "EmptyCell")
            cell.textLabel?.text = "暂无笔记"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteSelectCell", for: indexPath) as! NoteListCell
        cell.configure(with: notes[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if notes.isEmpty { return ScreenAdapter.scaleH(200) }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return ScreenAdapter.scaleH(100)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !notes.isEmpty else { return }
        let note = notes[indexPath.row]
        onNoteSelected?(note)
        dismiss(animated: true)
    }
}
