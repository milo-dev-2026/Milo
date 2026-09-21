import UIKit
import SnapKit

protocol StickerPanelDelegate: AnyObject {
    func didSelectEmoji(_ emoji: String)
    func didSelectSticker(_ name: String)
}

class StickerPanelView: UIView {

    weak var delegate: StickerPanelDelegate?

    private let collectionView: UICollectionView
    private let segmentControl = UISegmentedControl(items: ["表情", "贴纸"])
    private var currentMode = 0
    private let emojis = ["😀", "😂", "😍", "🥰", "😎", "🤔", "😢", "😭", "😡", "🤯", "👍", "👎", "👌", "👏",🙏", "💪", "🎉", "🎁", "❤️", "💔", "🔥", "⭐", "🌈", "☀️"]
    private let stickers = ["sticker_1", "sticker_2", "sticker_3", "sticker_4", "sticker_5", "sticker_6"]

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ScreenAdapter.scaleW(40), height: ScreenAdapter.scaleW(40))
        layout.minimumLineSpacing = ScreenAdapter.scaleH(12)
        layout.minimumInteritemSpacing = ScreenAdapter.scaleW(12)
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: "StickerCell")

        addSubviews(segmentControl, collectionView)

        segmentControl.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16))
            make.height.equalTo(ScreenAdapter.scaleH(32))
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc private func segmentChanged() {
        currentMode = segmentControl.selectedSegmentIndex
        collectionView.reloadData()
    }
}

extension StickerPanelView: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentMode == 0 ? emojis.count : stickers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if currentMode == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
            cell.configure(emoji: emojis[indexPath.item])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCell", for: indexPath) as! StickerCell
            cell.configure(name: stickers[indexPath.item])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if currentMode == 0 {
            delegate?.didSelectEmoji(emojis[indexPath.item])
        } else {
            delegate?.didSelectSticker(stickers[indexPath.item])
        }
    }
}

class EmojiCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 28)
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(emoji: String) {
        label.text = emoji
    }
}

class StickerCell: UICollectionViewCell {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themePrimary
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String) {
        imageView.image = UIImage(systemName: "face.smiling")
    }
}
