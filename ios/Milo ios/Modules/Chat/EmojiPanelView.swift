import UIKit
import SnapKit

// MARK: - 表情面板委托
protocol EmojiPanelDelegate: AnyObject {
    func didSelectEmoji(_ emoji: String)
    func didTapDelete()
}

// MARK: - 表情面板
class EmojiPanelView: UIView {

    weak var delegate: EmojiPanelDelegate?

    private let collectionView: UICollectionView
    private var emojis: [String] = []
    private var recentEmojis: [String] = []

    private static let emojiSet: [String] = [
        "😀","😁","😂","🤣","😃","😄","😅","😆",
        "😉","😊","😋","😎","😍","😘","🥰","😗",
        "😙","😚","🙂","🤗","🤩","🤔","🤨","😐",
        "😑","😶","🙄","😏","😣","😥","😮","🤐",
        "😯","😪","😫","😴","😌","😛","😜","😝",
        "🤤","😒","😓","😔","😕","🙃","🤑","😲",
        "🙁","😖","😞","😟","😤","悲哀","🤯","😬",
        "🥵","🥶","😱","😨","😰","😥","😓","🤗",
        "🤔","🤭","🤫","🤥","😶","🙄","😏","😪",
        "🙏","👏","👍","👎","👌","✌️","🤞","🤟",
        "🤘","🤙","👈","👉","👆","👇","☝️","✋",
        "🤚","🖐️","👋","🤝","💪","✊","👊","🤛",
        "❤️","🧡","💛","💚","💙","💜","🖤","🤍",
        "💔","❣️","💕","💞","💓","💗","💖","💘",
        "💝","💟","♥️","💯","💢","💥","💫","💦",
        "🔥","✨","🌟","⭐️","🌈","☀️","⛅️","☁️"
    ]

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        let cols = 8
        let totalSpacing = CGFloat(cols - 1) * 8 + 24
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / CGFloat(cols)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
        loadEmojis()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .systemBackground

        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiPanelCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.alwaysBounceVertical = true

        let deleteBtn = UIButton(type: .system)
        deleteBtn.setImage(UIImage(systemName: "delete.left"), for: .normal)
        deleteBtn.tintColor = .darkGray
        deleteBtn.backgroundColor = .systemGray6
        deleteBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        deleteBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        addSubview(collectionView)
        addSubview(deleteBtn)

        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(deleteBtn.snp.top).offset(-4)
        }
        deleteBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-8)
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
    }

    private func loadEmojis() {
        recentEmojis = UserDefaults.standard.stringArray(forKey: "recent_emojis") ?? []
        emojis = EmojiPanelView.emojiSet
        collectionView.reloadData()
    }

    @objc private func deleteTapped() {
        delegate?.didTapDelete()
    }

    func saveRecentEmoji(_ emoji: String) {
        var recent = UserDefaults.standard.stringArray(forKey: "recent_emojis") ?? []
        recent.removeAll { $0 == emoji }
        recent.insert(emoji, at: 0)
        if recent.count > 32 { recent = Array(recent.prefix(32)) }
        UserDefaults.standard.set(recent, forKey: "recent_emojis")
        recentEmojis = recent
        collectionView.reloadData()
    }
}

// MARK: - Emoji Cell
private class EmojiPanelCell: UICollectionViewCell {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 28)
        contentView.addSubview(label)
        label.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - DataSource & Delegate
extension EmojiPanelView: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return recentEmojis.isEmpty ? 1 : 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 && !recentEmojis.isEmpty {
            return recentEmojis.count
        }
        return emojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiPanelCell
        if indexPath.section == 0 && !recentEmojis.isEmpty {
            cell.label.text = recentEmojis[indexPath.item]
        } else {
            cell.label.text = emojis[indexPath.item]
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji: String
        if indexPath.section == 0 && !recentEmojis.isEmpty {
            emoji = recentEmojis[indexPath.item]
        } else {
            emoji = emojis[indexPath.item]
        }
        saveRecentEmoji(emoji)
        delegate?.didSelectEmoji(emoji)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = EmojiSectionHeader()
        header.label.text = indexPath.section == 0 ? "常用表情" : "全部表情"
        return header
    }
}

// MARK: - Section Header
private class EmojiSectionHeader: UICollectionReusableView {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}
