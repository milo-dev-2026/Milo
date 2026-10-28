import UIKit

// MARK: - 特殊用户 / 特殊群聊标识（与安卓 SpecialUserUtils 保持一致）
enum SpecialUserUtils {

    /// 特殊用户 UID（安卓 SPECIAL_UID）
    static let specialUid = "06448fc919214f0b8615710d40910382"
    /// 特殊用户 Milo 号
    static let specialShortNo = "888"
    /// 特殊用户昵称
    static let specialName = "西安雷虎虎"

    /// 特殊群聊名称（安卓：西安修车车友交流2群 / 西安修车大队），额外补充「骗人出门让车撞」
    static let specialGroupNames = ["西安修车车友交流2群", "西安修车大队", "骗人出门让车撞"]

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
}
