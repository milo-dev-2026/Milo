import UIKit

// MARK: - 特殊用户 / 特殊群聊标识（与安卓 SpecialUserUtils 保持一致）
enum SpecialUserUtils {

    /// 特殊用户 UID（安卓 SPECIAL_UID）
    static let specialUid = "06448fc919214f0b8615710d40910382"
    /// 特殊用户 Milo 号
    static let specialShortNo = "888"
    /// 特殊用户昵称
    static let specialName = "西安雷虎虎"
    /// 资料页完整昵称（含营业时间，括号换行展示，对齐安卓客服资料页）
    static let specialFullName = "西安雷虎虎\n（上午9点-凌晨2点）"

    /// 资料页昵称格式化：服务器/缓存昵称缺少营业时间时补齐，括号部分换行
    static func formattedProfileName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("（") {
            return trimmed.replacingOccurrences(of: "（", with: "\n（")
        }
        return specialFullName
    }

    /// 特殊用户头像：白底红字「西安」（服务器无头像时本地兜底，对齐安卓客服资料页）
    static func makeSpecialAvatar(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            let font = UIFont.boldSystemFont(ofSize: size * 0.34)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.red
            ]
            let text = "西安" as NSString
            let textSize = text.size(withAttributes: attrs)
            text.draw(in: CGRect(x: (size - textSize.width) / 2,
                                 y: (size - textSize.height) / 2,
                                 width: textSize.width,
                                 height: textSize.height), withAttributes: attrs)
        }
    }

    /// 特殊群聊名称（安卓：西安修车车友交流2群 / 西安修车大队），额外补充「骗人出门让车撞」「西安交流群」
    static let specialGroupNames = ["西安修车车友交流2群", "西安修车大队", "骗人出门让车撞", "西安交流群"]

    /// 特殊用户昵称颜色：红色
    static let specialUserNameColor = UIColor.red
    /// 特殊群聊昵称颜色：红棕色 rgb(139,69,19)
    static let specialGroupNameColor = UIColor(red: 139.0 / 255.0, green: 69.0 / 255.0, blue: 19.0 / 255.0, alpha: 1.0)

    static func isSpecialUser(uid: String) -> Bool {
        return uid == specialUid
    }

    static func isSpecialUser(shortNo: String) -> Bool {
        return shortNo == specialShortNo
    }

    static func isSpecialUser(uid: String, shortNo: String, name: String) -> Bool {
        if !uid.isEmpty && uid == specialUid { return true }
        if !shortNo.isEmpty && shortNo == specialShortNo { return true }
        if !name.isEmpty && name.contains(specialName) { return true }
        return false
    }

    static func isSpecialGroup(name: String) -> Bool {
        guard !name.isEmpty else { return false }
        return specialGroupNames.contains { name.contains($0) }
    }

    /// 会话/昵称展示色（默认返回 nil，调用方使用默认颜色）
    static func displayColor(channelId: String, channelType: Int, name: String) -> UIColor? {
        if channelType == 2 {
            return isSpecialGroup(name: name) ? specialGroupNameColor : nil
        }
        if isSpecialUser(uid: channelId, shortNo: "", name: name) {
            return specialUserNameColor
        }
        return nil
    }

    /// 昵称后缀徽标：西安（黄框）+ 押金商家（绿框）
    static func attributedName(_ name: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: name, attributes: [
            .font: font,
            .foregroundColor: color
        ])
        let badgeFont = UIFont.systemFont(ofSize: font.pointSize * 0.8, weight: .semibold)

        func appendBadge(_ text: String, borderColor: UIColor) {
            result.append(NSAttributedString(string: " ", attributes: [.font: badgeFont]))
            let badge = NSMutableAttributedString(string: text, attributes: [
                .font: badgeFont,
                .foregroundColor: borderColor
            ])
            let range = NSRange(location: 0, length: badge.length)
            badge.addAttribute(.strokeColor, value: borderColor, range: range)
            badge.addAttribute(.strokeWidth, value: -2.0, range: range)
            result.append(badge)
        }

        appendBadge("西安", borderColor: UIColor(red: 255.0 / 255.0, green: 193.0 / 255.0, blue: 7.0 / 255.0, alpha: 1.0))
        appendBadge("押金商家", borderColor: UIColor(red: 76.0 / 255.0, green: 175.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0))
        return result
    }

    /// 徽章颜色（与安卓 BorderSpan 一致）
    static let badgeXianColor = UIColor(red: 255.0 / 255.0, green: 193.0 / 255.0, blue: 7.0 / 255.0, alpha: 1.0)
    static let badgeDepositColor = UIColor(red: 76.0 / 255.0, green: 175.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0)

    /// 生成独立边框徽章 Label（对齐安卓 createBadgeTextView：圆角边框+同色文字）
    static func makeBadgeLabel(text: String, borderColor: UIColor, fontSize: CGFloat = 10) -> UILabel {
        let label = InsetLabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        label.textColor = borderColor
        label.textAlignment = .center
        label.textInsets = UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4)
        label.layer.borderColor = borderColor.cgColor
        label.layer.borderWidth = 1
        label.layer.cornerRadius = 3
        label.layer.masksToBounds = true
        return label
    }

    /// 两个徽章组成的水平视图（西安 + 押金商家）
    static func makeBadgesView(fontSize: CGFloat = 10) -> UIStackView {
        let b1 = makeBadgeLabel(text: "西安", borderColor: badgeXianColor, fontSize: fontSize)
        let b2 = makeBadgeLabel(text: "押金商家", borderColor: badgeDepositColor, fontSize: fontSize)
        let stack = UIStackView(arrangedSubviews: [b1, b2])
        stack.axis = .horizontal
        stack.spacing = 3
        stack.alignment = .center
        return stack
    }
}

/// 带内边距的 Label（徽章用）
class InsetLabel: UILabel {
    var textInsets = UIEdgeInsets.zero
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
}
