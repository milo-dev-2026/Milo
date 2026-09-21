import UIKit
import SnapKit

protocol MessageReactionDelegate: AnyObject {
    func didReact(messageId: String, emoji: String)
    func didUnreact(messageId: String, emoji: String)
}

class MessageReactionView: UIView {

    weak var delegate: MessageReactionDelegate?

    private var messageId: String = ""
    private var reactions: [(emoji: String, count: Int)] = []
    private let stack = UIStackView()

    static let availableEmojis = ["👍", "❤️", "😂", "😮", "😢", "🎉", "🔥", "👏"]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        stack.axis = .horizontal
        stack.spacing = ScreenAdapter.scaleW(6)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(messageId: String, reactions: [(String, Int)]) {
        self.messageId = messageId
        self.reactions = reactions
        updateButtons()
    }

    private func updateButtons() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (emoji, count) in reactions {
            let btn = createReactionButton(emoji: emoji, count: count)
            stack.addArrangedSubview(btn)
        }
    }

    private func createReactionButton(emoji: String, count: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = ScreenAdapter.scaleW(12)

        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = ScreenAdapter.font(14)

        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = ScreenAdapter.font(12)
        countLabel.textColor = .secondaryLabel

        let inner = UIStackView(arrangedSubviews: [emojiLabel, countLabel])
        inner.axis = .horizontal
        inner.spacing = 2
        inner.isUserInteractionEnabled = false
        container.addSubview(inner)

        inner.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(24))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(reactionTapped(_:)))
        container.addGestureRecognizer(tap)
        container.tag = MessageReactionView.availableEmojis.firstIndex(of: emoji) ?? 0
        container.isUserInteractionEnabled = true

        return container
    }

    @objc private func reactionTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let emoji = Self.availableEmojis[view.tag]
        delegate?.didReact(messageId: messageId, emoji: emoji)
    }

    static func showReactionPicker(for messageId: String, from view: UIView, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "回复表情", message: nil, preferredStyle: .actionSheet)

        for emoji in availableEmojis {
            alert.addAction(UIAlertAction(title: emoji, style: .default) { _ in
                completion(emoji)
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let vc = view.window?.rootViewController {
            vc.present(alert, animated: true)
        }
    }
}
