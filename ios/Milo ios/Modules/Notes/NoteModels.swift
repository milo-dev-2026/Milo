import Foundation

// MARK: - 笔记内容块类型
enum NoteBlockType: String, Codable {
    case title = "title"
    case text = "text"
    case image = "image"
    case video = "video"
    case location = "location"
}

// MARK: - 位置信息
struct NoteLocation: Codable {
    var latitude: Double
    var longitude: Double
    var address: String
}

// MARK: - 笔记内容块
struct NoteBlock: Codable {
    var id: String
    var type: NoteBlockType
    var content: String
    var imageURL: String?
    var videoURL: String?
    var location: NoteLocation?
    
    init(id: String = UUID().uuidString, type: NoteBlockType, content: String = "",
         imageURL: String? = nil, videoURL: String? = nil, location: NoteLocation? = nil) {
        self.id = id
        self.type = type
        self.content = content
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.location = location
    }

    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "type": type.rawValue,
            "content": content
        ]
        if let imageURL = imageURL { dict["imageURL"] = imageURL }
        if let videoURL = videoURL { dict["videoURL"] = videoURL }
        if let location = location {
            dict["location"] = [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address
            ]
        }
        return dict
    }

    static func fromDict(_ dict: [String: Any]) -> NoteBlock? {
        let id = dict["id"] as? String ?? UUID().uuidString
        let typeStr = dict["type"] as? String ?? "text"
        let type = NoteBlockType(rawValue: typeStr) ?? .text
        let content = dict["content"] as? String ?? ""
        let imageURL = dict["imageURL"] as? String ?? dict["image_url"] as? String ?? dict["url"] as? String
        let videoURL = dict["videoURL"] as? String ?? dict["video_url"] as? String
        var location: NoteLocation?
        if let locDict = dict["location"] as? [String: Any],
           let lat = (locDict["latitude"] as? NSNumber)?.doubleValue ?? locDict["latitude"] as? Double,
           let lng = (locDict["longitude"] as? NSNumber)?.doubleValue ?? locDict["longitude"] as? Double {
            location = NoteLocation(latitude: lat, longitude: lng, address: locDict["address"] as? String ?? "")
        }
        return NoteBlock(id: id, type: type, content: content, imageURL: imageURL, videoURL: videoURL, location: location)
    }
}
struct NoteEntity: Codable {
    var id: String
    var title: String
    var blocks: [NoteBlock]
    var createTime: Int64
    var updateTime: Int64
    var isSticky: Bool
    var remark: String
    var group: String
    
    init(id: String = UUID().uuidString, title: String = "", blocks: [NoteBlock] = [],
         createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         updateTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         isSticky: Bool = false, remark: String = "", group: String = "普通笔记") {
        self.id = id
        self.title = title
        self.blocks = blocks
        self.createTime = createTime
        self.updateTime = updateTime
        self.isSticky = isSticky
        self.remark = remark
        self.group = group
    }

    enum CodingKeys: String, CodingKey {
        case id, title, blocks, createTime, updateTime, isSticky, remark, group
        case content // Android 扁平正文字段
        case create_time, update_time // 兼容 snake_case
    }

    /// 容错解码：兼容 Android 笔记结构（扁平 content / 缺字段 / 时间戳为字符串或秒级）
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
        blocks = (try? c.decodeIfPresent([NoteBlock].self, forKey: .blocks)) ?? []
        // 兼容 Android 扁平 content 字段：无 blocks 时包装为单个文本块
        if blocks.isEmpty,
           let text = try? c.decodeIfPresent(String.self, forKey: .content),
           !text.isEmpty {
            blocks = [NoteBlock(type: .text, content: text)]
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        createTime = NoteEntity.decodeTime(from: c, keys: [.createTime, .create_time]) ?? now
        updateTime = NoteEntity.decodeTime(from: c, keys: [.updateTime, .update_time]) ?? createTime
        // 秒级时间戳（10位）转毫秒
        if createTime > 0 && createTime < 10_000_000_000 { createTime *= 1000 }
        if updateTime > 0 && updateTime < 10_000_000_000 { updateTime *= 1000 }
        isSticky = (try? c.decodeIfPresent(Bool.self, forKey: .isSticky)) ?? false
        remark = (try? c.decodeIfPresent(String.self, forKey: .remark)) ?? ""
        group = (try? c.decodeIfPresent(String.self, forKey: .group)) ?? "普通笔记"
    }

    private static func decodeTime(from container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int64? {
        for key in keys {
            if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return v }
            if let s = try? container.decodeIfPresent(String.self, forKey: key), let v = Int64(s) { return v }
            if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return Int64(d) }
        }
        return nil
    }

    /// 自定义编码：仅编码存储属性（CodingKeys 含兼容解码用的额外 case）
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(blocks, forKey: .blocks)
        try c.encode(createTime, forKey: .createTime)
        try c.encode(updateTime, forKey: .updateTime)
        try c.encode(isSticky, forKey: .isSticky)
        try c.encode(remark, forKey: .remark)
        try c.encode(group, forKey: .group)
    }
    
    /// 从内容块提取预览文本
    var previewText: String {
        for block in blocks {
            switch block.type {
            case .text:
                if !block.content.isEmpty {
                    return block.content
                }
            case .title:
                if !block.content.isEmpty {
                    return block.content
                }
            default:
                continue
            }
        }
        return "无内容"
    }
    
    /// 是否包含图片
    var hasImage: Bool {
        return blocks.contains { $0.type == .image && $0.imageURL != nil }
    }
    
    /// 首张图片URL
    var firstImageURL: String? {
        return blocks.first { $0.type == .image && $0.imageURL != nil }?.imageURL
    }

    /// 从笔记消息原文解析首张图片 URL（兼容 iOS NoteEntity JSON 与安卓 WKNoteContent 的 coverUrl/blockListJson）
    static func firstImageURL(inMessageContent content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return nil
        }
        // 0. 安卓 WKNoteContent 直接带封面图 coverUrl（兼容 utalk 的 resource 字段），优先使用
        if let cover = (dict["coverUrl"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !cover.isEmpty {
            return cover
        }
        if let resource = (dict["resource"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !resource.isEmpty {
            return resource
        }
        // 1. 安卓线缆格式：blockListJson 字符串里的 type=3 块，图片地址在 imagePath
        if let blJson = dict["blockListJson"] as? String, !blJson.isEmpty,
           let bd = blJson.data(using: .utf8),
           let arr = try? JSONSerialization.jsonObject(with: bd) as? [[String: Any]] {
            for item in arr {
                let type = (item["type"] as? NSNumber)?.intValue ?? 2
                guard type == 3 else { continue }
                if let path = item["imagePath"] as? String, !path.isEmpty { return path }
                if let url = item["url"] as? String, !url.isEmpty { return url }
            }
        }
        // 2. iOS NoteEntity JSON：取 blocks 里第一张有地址的图片
        if let note = try? JSONDecoder().decode(NoteEntity.self, from: data), let url = note.firstImageURL {
            return url
        }
        // 3. 嵌套包裹 {"note_json": "..."} / {"note": {...}}
        if let nested = dict["note_json"] as? String, !nested.isEmpty {
            return firstImageURL(inMessageContent: nested)
        }
        if let nestedDict = dict["note"] as? [String: Any],
           let nd = try? JSONSerialization.data(withJSONObject: nestedDict),
           let ns = String(data: nd, encoding: .utf8) {
            return firstImageURL(inMessageContent: ns)
        }
        return nil
    }
    
    /// 格式化时间
    var timeString: String {
        let date = Date(timeIntervalSince1970: TimeInterval(updateTime / 1000))
        let formatter = DateFormatter()
        let now = Date()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨天"
        } else if Calendar.current.isDate(date, equalTo: now, toGranularity: .year) {
            formatter.dateFormat = "MM/dd"
        } else {
            formatter.dateFormat = "yyyy/MM/dd"
        }
        return formatter.string(from: date)
    }

    static func fromDict(_ dict: [String: Any]) -> NoteEntity? {
        var idValue = dict["id"] as? String
        if idValue == nil, let num = dict["id"] as? NSNumber { idValue = num.stringValue }
        guard let id = idValue else { return nil }
        let title = dict["title"] as? String ?? ""
        var blocks: [NoteBlock] = []
        if let blocksArray = dict["blocks"] as? [[String: Any]] {
            blocks = blocksArray.compactMap { NoteBlock.fromDict($0) }
        }
        // 兼容 Android 扁平 content 字段
        if blocks.isEmpty, let content = dict["content"] as? String, !content.isEmpty {
            blocks = [NoteBlock(type: .text, content: content)]
        }
        func toInt64(_ v: Any?) -> Int64 {
            if let n = v as? NSNumber { return n.int64Value }
            if let s = v as? String { return Int64(s) ?? 0 }
            return 0
        }
        var createTime = toInt64(dict["createTime"] ?? dict["create_time"])
        var updateTime = toInt64(dict["updateTime"] ?? dict["update_time"])
        // 秒级时间戳（10位）转毫秒
        if createTime > 0 && createTime < 10_000_000_000 { createTime *= 1000 }
        if updateTime > 0 && updateTime < 10_000_000_000 { updateTime *= 1000 }
        let isSticky = (dict["isSticky"] as? Bool) ?? (dict["is_sticky"] as? Bool) ?? false
        let remark = dict["remark"] as? String ?? ""
        let group = dict["group"] as? String ?? "普通笔记"
        return NoteEntity(id: id, title: title, blocks: blocks,
                          createTime: createTime, updateTime: updateTime,
                          isSticky: isSticky, remark: remark, group: group)
    }
}
