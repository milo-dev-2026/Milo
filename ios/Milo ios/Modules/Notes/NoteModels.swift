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
}

// MARK: - 笔记实体
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
}
