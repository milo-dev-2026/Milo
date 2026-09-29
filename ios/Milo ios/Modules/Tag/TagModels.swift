//
//  TagModels.swift
//  Milo
//
//  标签模块 - 数据模型
//

import Foundation
import UIKit

// MARK: - 标签成员模型
struct TagMember: Codable {
    let uid: String
    let name: String
    let avatar: String

    enum CodingKeys: String, CodingKey {
        case uid, name, avatar
    }

    var avatarURL: URL? {
        guard !avatar.isEmpty else { return nil }
        if avatar.hasPrefix("http") {
            return URL(string: avatar)
        }
        return URL(string: APIConfig.apiBaseURL + "/" + avatar)
    }

    func toDict() -> [String: Any] {
        return ["uid": uid, "name": name, "avatar": avatar]
    }

    static func fromDict(_ dict: [String: Any]) -> TagMember? {
        guard let uid = dict["uid"] as? String else { return nil }
        let name = dict["name"] as? String ?? ""
        let avatar = dict["avatar"] as? String ?? ""
        return TagMember(uid: uid, name: name, avatar: avatar)
    }
}

// MARK: - 标签颜色
enum TagColor: Int, CaseIterable, Codable {
    case red = 0
    case orange = 1
    case yellow = 2
    case green = 3
    case blue = 4
    case purple = 5

    var uiColor: UIColor {
        switch self {
        case .red: return UIColor(red: 1.0, green: 0.42, blue: 0.48, alpha: 1.0)
        case .orange: return UIColor(red: 1.0, green: 0.66, blue: 0.25, alpha: 1.0)
        case .yellow: return UIColor(red: 1.0, green: 0.84, blue: 0.25, alpha: 1.0)
        case .green: return UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0)
        case .blue: return UIColor(red: 0.36, green: 0.55, blue: 0.94, alpha: 1.0)
        case .purple: return UIColor(red: 0.65, green: 0.45, blue: 0.94, alpha: 1.0)
        }
    }

    var colorName: String {
        switch self {
        case .red: return "红色"
        case .orange: return "橙色"
        case .yellow: return "黄色"
        case .green: return "绿色"
        case .blue: return "蓝色"
        case .purple: return "紫色"
        }
    }
}

// MARK: - 标签模型
struct Tag: Codable {
    let id: String
    var name: String
    var memberCount: Int
    var members: [TagMember]
    var colorRawValue: Int

    enum CodingKeys: String, CodingKey {
        case id, name, memberCount, members, colorRawValue
    }

    var color: UIColor {
        get {
            return TagColor(rawValue: colorRawValue)?.uiColor ?? TagColor.blue.uiColor
        }
        set {
            // 通过颜色查找对应的 rawValue
            for tagColor in TagColor.allCases {
                if tagColor.uiColor == newValue {
                    colorRawValue = tagColor.rawValue
                    break
                }
            }
        }
    }

    var tagColor: TagColor {
        get {
            return TagColor(rawValue: colorRawValue) ?? .blue
        }
        set {
            colorRawValue = newValue.rawValue
        }
    }

    init(id: String = UUID().uuidString,
         name: String,
         memberCount: Int = 0,
         members: [TagMember] = [],
         color: TagColor = .blue) {
        self.id = id
        self.name = name
        self.memberCount = memberCount
        self.members = members
        self.colorRawValue = color.rawValue
    }

    static func fromDict(_ dict: [String: Any]) -> Tag? {
        guard let id = dict["id"] as? String else { return nil }
        let name = dict["name"] as? String ?? ""
        let colorRaw = dict["colorRawValue"] as? Int ?? 0
        var members: [TagMember] = []
        if let membersArray = dict["members"] as? [[String: Any]] {
            members = membersArray.compactMap { TagMember.fromDict($0) }
        }
        let memberCount = dict["memberCount"] as? Int ?? members.count
        let tagColor = TagColor(rawValue: colorRaw) ?? .blue
        return Tag(id: id, name: name, memberCount: memberCount, members: members, color: tagColor)
    }
}

// MARK: - 模拟数据
extension Tag {
    /// 模拟标签列表数据
    static let mockTags: [Tag] = [
        Tag(
            id: "tag_family",
            name: "家人",
            memberCount: 5,
            members: [
                TagMember(uid: "member_1", name: "爸爸", avatar: ""),
                TagMember(uid: "member_2", name: "妈妈", avatar: ""),
                TagMember(uid: "member_3", name: "哥哥", avatar: ""),
                TagMember(uid: "member_4", name: "姐姐", avatar: ""),
                TagMember(uid: "member_5", name: "爷爷", avatar: "")
            ],
            color: .red
        ),
        Tag(
            id: "tag_friends",
            name: "朋友",
            memberCount: 8,
            members: [
                TagMember(uid: "member_10", name: "小明", avatar: ""),
                TagMember(uid: "member_11", name: "小红", avatar: ""),
                TagMember(uid: "member_12", name: "小华", avatar: ""),
                TagMember(uid: "member_13", name: "小丽", avatar: ""),
                TagMember(uid: "member_14", name: "小强", avatar: ""),
                TagMember(uid: "member_15", name: "小芳", avatar: ""),
                TagMember(uid: "member_16", name: "小军", avatar: ""),
                TagMember(uid: "member_17", name: "小燕", avatar: "")
            ],
            color: .green
        ),
        Tag(
            id: "tag_colleagues",
            name: "同事",
            memberCount: 12,
            members: [
                TagMember(uid: "member_20", name: "张经理", avatar: ""),
                TagMember(uid: "member_21", name: "李工", avatar: ""),
                TagMember(uid: "member_22", name: "王设计", avatar: ""),
                TagMember(uid: "member_23", name: "赵产品", avatar: ""),
                TagMember(uid: "member_24", name: "陈开发", avatar: ""),
                TagMember(uid: "member_25", name: "刘测试", avatar: ""),
                TagMember(uid: "member_26", name: "周运营", avatar: ""),
                TagMember(uid: "member_27", name: "吴市场", avatar: ""),
                TagMember(uid: "member_28", name: "郑人事", avatar: ""),
                TagMember(uid: "member_29", name: "孙财务", avatar: ""),
                TagMember(uid: "member_30", name: "钱行政", avatar: ""),
                TagMember(uid: "member_31", name: "冯总监", avatar: "")
            ],
            color: .blue
        ),
        Tag(
            id: "tag_vip",
            name: "重要客户",
            memberCount: 3,
            members: [
                TagMember(uid: "member_40", name: "王总", avatar: ""),
                TagMember(uid: "member_41", name: "李总", avatar: ""),
                TagMember(uid: "member_42", name: "张总", avatar: "")
            ],
            color: .orange
        )
    ]
}
