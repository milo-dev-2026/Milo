import UIKit
import SnapKit
import Kingfisher

// MARK: - 名片消息模型
struct CardMessageInfo {
    var uid: String
    var name: String
    var avatar: String
    var vercode: String
    
    /// 从消息内容解析名片信息
    static func parse(from content: String) -> CardMessageInfo? {
        // 格式: uid|name|avatar|vercode 或 JSON格式
        if content.contains("|") {
            let parts = content.components(separatedBy: "|")
            if parts.count >= 2 {
                return CardMessageInfo(
                    uid: parts[0],
                    name: parts.count > 1 ? parts[1] : "",
                    avatar: parts.count > 2 ? parts[2] : "",
                    vercode: parts.count > 3 ? parts[3] : ""
                )
            }
        }
        
        // 尝试JSON解析
        if let data = content.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return CardMessageInfo(
                uid: dict["uid"] as? String ?? "",
                name: dict["name"] as? String ?? "",
                avatar: dict["avatar"] as? String ?? "",
                vercode: dict["vercode"] as? String ?? ""
            )
        }
        
        return nil
    }
    
    /// 序列化为字符串
    func toString() -> String {
        return "\(uid)|\(name)|\(avatar)|\(vercode)"
    }
}

// MARK: - 名片消息Cell
class CardMessageCell: UITableViewCell {
    
    private let bubbleView = UIView()
    private let timeLabel = UILabel()
    private let avatarView = UIImageView()
    private var isFromMe = false
    
    // 名片内容
    private let cardContainer = UIView()
    private let cardAvatarView = UIImageView()
    private let cardNameLabel = UILabel()
    private let cardTagLabel = UILabel()
    private let cardVercodeLabel = UILabel()
    private let cardArrowView = UIImageView()
    
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
        
        // 名片卡片
        cardContainer.backgroundColor = .white
        cardContainer.layer.cornerRadius = ScreenAdapter.scaleW(10)
        
        // 名片头像
        cardAvatarView.layer.cornerRadius = ScreenAdapter.scaleW(22)
        cardAvatarView.clipsToBounds = true
        cardAvatarView.contentMode = .scaleAspectFill
        cardAvatarView.image = UIImage(systemName: "person.circle.fill")
        cardAvatarView.tintColor = .systemGray5
        
        // 名片昵称
        cardNameLabel.font = ScreenAdapter.mediumFont(15)
        cardNameLabel.textColor = .label
        cardNameLabel.numberOfLines = 1
        
        // "个人名片"标签
        cardTagLabel.text = "个人名片"
        cardTagLabel.font = ScreenAdapter.font(11)
        cardTagLabel.textColor = .themePrimary
        cardTagLabel.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.1)
        cardTagLabel.textAlignment = .center
        cardTagLabel.layer.cornerRadius = ScreenAdapter.scaleW(8)
        cardTagLabel.clipsToBounds = true
        
        // 微信号/vercode
        cardVercodeLabel.font = ScreenAdapter.font(12)
        cardVercodeLabel.textColor = .secondaryLabel
        cardVercodeLabel.numberOfLines = 1
        
        // 箭头
        cardArrowView.image = UIImage(systemName: "chevron.right")
        cardArrowView.tintColor = .systemGray3
        cardArrowView.contentMode = .scaleAspectFit
        
        cardContainer.addSubviews(cardAvatarView, cardNameLabel, cardTagLabel, cardVercodeLabel, cardArrowView)
        bubbleView.addSubview(cardContainer)
        contentView.addSubviews(avatarView, bubbleView, timeLabel)
        
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }
        
        // 名片内部布局
        cardAvatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }
        
        cardNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(cardAvatarView.snp.trailing).offset(ScreenAdapter.scaleW(10))
            make.top.equalTo(cardAvatarView).offset(ScreenAdapter.scaleH(2))
            make.trailing.lessThanOrEqualTo(cardArrowView.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }
        
        cardTagLabel.snp.makeConstraints { make in
            make.leading.equalTo(cardNameLabel.snp.trailing).offset(ScreenAdapter.scaleW(6))
            make.centerY.equalTo(cardNameLabel)
            make.width.equalTo(ScreenAdapter.scaleW(52))
            make.height.equalTo(ScreenAdapter.scaleH(18))
        }
        
        cardVercodeLabel.snp.makeConstraints { make in
            make.leading.equalTo(cardAvatarView.snp.trailing).offset(ScreenAdapter.scaleW(10))
            make.bottom.equalTo(cardAvatarView).offset(-ScreenAdapter.scaleH(2))
            make.trailing.lessThanOrEqualTo(cardArrowView.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }
        
        cardArrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.equalTo(ScreenAdapter.scaleW(12))
        }
    }
    
    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString
        
        // 解析名片信息
        let cardInfo = CardMessageInfo.parse(from: message.content)
        cardNameLabel.text = cardInfo?.name ?? "未知用户"
        if let vercode = cardInfo?.vercode, !vercode.isEmpty {
            cardVercodeLabel.text = "ID: \(vercode)"
        } else {
            cardVercodeLabel.text = "ID: \(cardInfo?.uid ?? "")"
        }
        
        // 设置名片头像
        if let avatarStr = cardInfo?.avatar, !avatarStr.isEmpty {
            let urlStr = avatarStr.hasPrefix("http") ? avatarStr : APIConfig.apiBaseURL + "/" + avatarStr
            if let url = URL(string: urlStr) {
                cardAvatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
            }
        } else {
            cardAvatarView.image = UIImage(systemName: "person.circle.fill")
            cardAvatarView.tintColor = .systemGray5
        }
        
        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let bubbleWidth = ScreenAdapter.screenWidth * 0.72
        
        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.backgroundColor = .themeBubbleOutgoing
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
            bubbleView.backgroundColor = .themeBubbleIncoming
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
        
        // 名片容器布局
        cardContainer.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            make.height.equalTo(ScreenAdapter.scaleH(68))
        }
    }
}
