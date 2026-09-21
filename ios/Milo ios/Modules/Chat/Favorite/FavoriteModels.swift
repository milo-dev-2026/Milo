import Foundation

// MARK: - 收藏类型
enum FavoriteType: Int, Codable {
    case text = 1
    case image = 2
    case voice = 3
    case video = 4
    case file = 5
    case location = 6
    case link = 7
    
    var title: String {
        switch self {
        case .text: return "文字"
        case .image: return "图片"
        case .voice: return "语音"
        case .video: return "视频"
        case .file: return "文件"
        case .location: return "位置"
        case .link: return "链接"
        }
    }
    
    var iconName: String {
        switch self {
        case .text: return "text.bubble"
        case .image: return "photo"
        case .voice: return "mic.circle"
        case .video: return "video"
        case .file: return "doc.fill"
        case .location: return "mappin.circle"
        case .link: return "link"
        }
    }
}

// MARK: - 发送者信息
struct FavoriteFromUser: Codable {
    var uid: String
    var name: String
    var avatar: String?
    
    init(uid: String, name: String, avatar: String? = nil) {
        self.uid = uid
        self.name = name
        self.avatar = avatar
    }
}

// MARK: - 位置信息
struct FavoriteLocation: Codable {
    var latitude: Double
    var longitude: Double
    var address: String
    
    init(latitude: Double, longitude: Double, address: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

// MARK: - 收藏项模型
struct FavoriteItem: Codable {
    var id: String
    var type: FavoriteType
    var content: String
    var imageURL: String?
    var videoURL: String?
    var fileURL: String?
    var fileName: String?
    var fileSize: Int64?
    var voiceURL: String?
    var voiceDuration: TimeInterval?
    var location: FavoriteLocation?
    var createTime: Int64
    var fromUser: FavoriteFromUser?
    var extra: String?
    
    init(id: String = UUID().uuidString,
         type: FavoriteType,
         content: String = "",
         imageURL: String? = nil,
         videoURL: String? = nil,
         fileURL: String? = nil,
         fileName: String? = nil,
         fileSize: Int64? = nil,
         voiceURL: String? = nil,
         voiceDuration: TimeInterval? = nil,
         location: FavoriteLocation? = nil,
         createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         fromUser: FavoriteFromUser? = nil,
         extra: String? = nil) {
        self.id = id
        self.type = type
        self.content = content
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.fileURL = fileURL
        self.fileName = fileName
        self.fileSize = fileSize
        self.voiceURL = voiceURL
        self.voiceDuration = voiceDuration
        self.location = location
        self.createTime = createTime
        self.fromUser = fromUser
        self.extra = extra
    }
    
    /// 预览文本
    var previewText: String {
        switch type {
        case .text:
            return content
        case .image:
            return "[图片]"
        case .voice:
            if let duration = voiceDuration {
                return "[语音] \(Int(duration))\""
            }
            return "[语音]"
        case .video:
            return "[视频]"
        case .file:
            return fileName ?? "[文件]"
        case .location:
            return location?.address ?? "[位置]"
        case .link:
            return content
        }
    }
    
    /// 格式化时间
    var timeString: String {
        let date = Date(timeIntervalSince1970: TimeInterval(createTime / 1000))
        let formatter = DateFormatter()
        let now = Date()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨天"
        } else if Calendar.current.isDate(date, equalTo: now, toGranularity: .year) {
            formatter.dateFormat = "MM/dd HH:mm"
        } else {
            formatter.dateFormat = "yyyy/MM/dd"
        }
        return formatter.string(from: date)
    }
}
