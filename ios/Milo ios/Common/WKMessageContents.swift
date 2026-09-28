import Foundation
import WuKongIMSDK

// MARK: - 图片消息内容 (type: 2)
@objc public class WKImageMessageContent: WKMessageContent {
    @objc public var url: String = ""
    @objc public var width: CGFloat = 0
    @objc public var height: CGFloat = 0
    
    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable: Any]()
        dict["url"] = url
        dict["width"] = width
        dict["height"] = height
        return dict
    }
    
    public override func decodeMsg(_ contentDic: [AnyHashable : Any]) {
        if let url = contentDic["url"] as? String {
            self.url = url
        }
        if let width = contentDic["width"] as? CGFloat {
            self.width = width
        } else if let width = contentDic["width"] as? NSNumber {
            self.width = CGFloat(width.floatValue)
        }
        if let height = contentDic["height"] as? CGFloat {
            self.height = height
        } else if let height = contentDic["height"] as? NSNumber {
            self.height = CGFloat(height.floatValue)
        }
    }
    
    public override class func contentType() -> NSNumber {
        return NSNumber(value: 2)
    }
}

// MARK: - 语音消息内容 (type: 3)
@objc public class WKVoiceMessageContent: WKMessageContent {
    @objc public var url: String = ""
    @objc public var duration: Int = 0
    @objc public var waveform: Data?
    
    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable: Any]()
        dict["url"] = url
        dict["duration"] = duration
        if let waveform = waveform {
            dict["waveform"] = waveform.base64EncodedString()
        }
        return dict
    }
    
    public override func decodeMsg(_ contentDic: [AnyHashable : Any]) {
        if let url = contentDic["url"] as? String {
            self.url = url
        }
        if let duration = contentDic["duration"] as? Int {
            self.duration = duration
        } else if let duration = contentDic["duration"] as? NSNumber {
            self.duration = duration.intValue
        }
        if let waveformStr = contentDic["waveform"] as? String {
            self.waveform = Data(base64Encoded: waveformStr)
        }
    }
    
    public override class func contentType() -> NSNumber {
        return NSNumber(value: 3)
    }
}

// MARK: - 视频消息内容 (type: 4)
@objc public class WKVideoMessageContent: WKMessageContent {
    @objc public var thumbURL: String = ""
    @objc public var videoURL: String = ""
    @objc public var duration: Int = 0
    @objc public var size: Int64 = 0
    
    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable: Any]()
        dict["thumb_url"] = thumbURL
        dict["video_url"] = videoURL
        dict["duration"] = duration
        dict["size"] = size
        return dict
    }
    
    public override func decodeMsg(_ contentDic: [AnyHashable : Any]) {
        if let thumbURL = contentDic["thumb_url"] as? String {
            self.thumbURL = thumbURL
        }
        if let videoURL = contentDic["video_url"] as? String {
            self.videoURL = videoURL
        }
        if let duration = contentDic["duration"] as? Int {
            self.duration = duration
        } else if let duration = contentDic["duration"] as? NSNumber {
            self.duration = duration.intValue
        }
        if let size = contentDic["size"] as? Int64 {
            self.size = size
        } else if let size = contentDic["size"] as? NSNumber {
            self.size = size.int64Value
        }
    }
    
    public override class func contentType() -> NSNumber {
        return NSNumber(value: 4)
    }
}

// MARK: - 文件消息内容 (type: 5)
@objc public class WKFileMessageContent: WKMessageContent {
    @objc public var fileName: String = ""
    @objc public var fileSize: Int64 = 0
    @objc public var url: String = ""
    
    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable: Any]()
        dict["file_name"] = fileName
        dict["file_size"] = fileSize
        dict["url"] = url
        return dict
    }
    
    public override func decodeMsg(_ contentDic: [AnyHashable : Any]) {
        if let fileName = contentDic["file_name"] as? String {
            self.fileName = fileName
        }
        if let fileSize = contentDic["file_size"] as? Int64 {
            self.fileSize = fileSize
        } else if let fileSize = contentDic["file_size"] as? NSNumber {
            self.fileSize = fileSize.int64Value
        }
        if let url = contentDic["url"] as? String {
            self.url = url
        }
    }
    
    public override class func contentType() -> NSNumber {
        return NSNumber(value: 5)
    }
}

// MARK: - 位置消息内容 (type: 6)
@objc public class WKLocationMessageContent: WKMessageContent {
    @objc public var name: String = ""
    @objc public var latitude: Double = 0
    @objc public var longitude: Double = 0
    
    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable: Any]()
        dict["name"] = name
        dict["latitude"] = latitude
        dict["longitude"] = longitude
        return dict
    }
    
    public override func decodeMsg(_ contentDic: [AnyHashable : Any]) {
        if let name = contentDic["name"] as? String {
            self.name = name
        }
        if let latitude = contentDic["latitude"] as? Double {
            self.latitude = latitude
        } else if let latitude = contentDic["latitude"] as? NSNumber {
            self.latitude = latitude.doubleValue
        }
        if let longitude = contentDic["longitude"] as? Double {
            self.longitude = longitude
        } else if let longitude = contentDic["longitude"] as? NSNumber {
            self.longitude = longitude.doubleValue
        }
    }
    
    public override class func contentType() -> NSNumber {
        return NSNumber(value: 6)
    }
}

// MARK: - 名片消息内容 (type: 7)
@objc public class WKCardMessageContent: WKMessageContent {
    @objc public var uid: String = ""
    @objc public var name: String = ""
    @objc public var avatar: String = ""
    @objc public var vercode: String = ""
    
    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable: Any]()
        dict["uid"] = uid
        dict["name"] = name
        dict["avatar"] = avatar
        dict["vercode"] = vercode
        return dict
    }
    
    public override func decodeMsg(_ contentDic: [AnyHashable : Any]) {
        if let uid = contentDic["uid"] as? String {
            self.uid = uid
        }
        if let name = contentDic["name"] as? String {
            self.name = name
        }
        if let avatar = contentDic["avatar"] as? String {
            self.avatar = avatar
        }
        if let vercode = contentDic["vercode"] as? String {
            self.vercode = vercode
        }
    }
    
    public override class func contentType() -> NSNumber {
        return NSNumber(value: 7)
    }
}

// MARK: - 笔记消息内容 (type: 100)
@objc public class WKNoteMessageContent: WKMessageContent {
    @objc public var noteId: String = ""
    @objc public var title: String = ""
    @objc public var noteContent: String = ""
    @objc public var noteJSON: String = ""
    
    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable: Any]()
        dict["note_id"] = noteId
        dict["title"] = title
        dict["content"] = noteContent
        dict["note_json"] = noteJSON
        return dict
    }
    
    public override func decodeMsg(_ contentDic: [AnyHashable : Any]) {
        if let noteId = contentDic["note_id"] as? String {
            self.noteId = noteId
        }
        if let title = contentDic["title"] as? String {
            self.title = title
        }
        if let noteContent = contentDic["content"] as? String {
            self.noteContent = noteContent
        }
        if let noteJSON = contentDic["note_json"] as? String {
            self.noteJSON = noteJSON
        }
    }
    
    public override class func contentType() -> NSNumber {
        return NSNumber(value: 100)
    }
}

// MARK: - 消息内容类型注册
class WKMessageContentRegistrar {
    static func registerAll() {
        WKSDK.shared().registerMessageContent(WKImageMessageContent.self)
        WKSDK.shared().registerMessageContent(WKVoiceMessageContent.self)
        WKSDK.shared().registerMessageContent(WKVideoMessageContent.self)
        WKSDK.shared().registerMessageContent(WKFileMessageContent.self)
        WKSDK.shared().registerMessageContent(WKLocationMessageContent.self)
        WKSDK.shared().registerMessageContent(WKCardMessageContent.self)
        WKSDK.shared().registerMessageContent(WKNoteMessageContent.self)
    }
}
