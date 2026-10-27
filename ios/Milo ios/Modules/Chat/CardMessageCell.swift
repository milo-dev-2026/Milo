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
    private let tailView = ChatBubbleTailView()
    
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

        bubbleView.layer.cornerRadius = ThemeDimension.bubbleCornerRadius
        bubbleView.clipsToBounds = true
        bubbleView.backgroundColor = .white
        
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
        contentView.addSubviews(tailView, bubbleView)
        
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
    
    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
        let isFromMe = message.isFromMe

        // 解析名片信息
        let cardInfo = CardMessageInfo.parse(from: message.content)
        cardNameLabel.text = cardInfo?.name ?? "未知用户"
        if let vercode = cardInfo?.vercode, !vercode.isEmpty {
            cardVercodeLabel.text = "ID: \(vercode)"
        } else {
            cardVercodeLabel.text = "ID: \(cardInfo?.uid ?? "")"
        }
        
        // 设置名片头像（与Android一致：通过uid构造头像URL）
        if let cardInfo = cardInfo, !cardInfo.uid.isEmpty {
            AppUtility.loadChannelAvatar(channelId: cardInfo.uid, channelType: 1, name: cardInfo.name, into: cardAvatarView)
        } else {
            cardAvatarView.image = AppUtility.defaultAvatarImage(name: cardInfo?.name ?? "", size: 88)
        }

        // 发送方气泡为品牌色时，名片内部转为深色文字反白
        cardContainer.backgroundColor = isFromMe ? UIColor.white.withAlphaComponent(0.16) : .white
        cardNameLabel.textColor = isFromMe ? .themeBubbleSendText : .label
        cardVercodeLabel.textColor = isFromMe ? UIColor.white.withAlphaComponent(0.8) : .secondaryLabel
        cardTagLabel.textColor = isFromMe ? .white : .themePrimary
        cardTagLabel.backgroundColor = isFromMe ? UIColor.white.withAlphaComponent(0.2) : UIColor.themePrimary.withAlphaComponent(0.1)
        cardArrowView.tintColor = isFromMe ? UIColor.white.withAlphaComponent(0.7) : .systemGray3

        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: ScreenAdapter.screenWidth * 0.72,
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar
        )
        
        // 名片容器布局
        cardContainer.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            make.height.equalTo(ScreenAdapter.scaleH(68))
        }
    }
}
