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
    
    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
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
    
    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
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
    
    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
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
    
    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
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
    @objc public var address: String = ""
    @objc public var latitude: Double = 0
    @objc public var longitude: Double = 0
    
    public override func encodeWithJSON() -> [AnyHashable : Any] {
        // 对齐安卓 WKLocationContent：title/address/lat/lng，同时保留 name/latitude/longitude 兼容旧数据
        var dict = [AnyHashable: Any]()
        dict["title"] = name
        dict["name"] = name
        dict["address"] = address
        dict["lat"] = latitude
        dict["lng"] = longitude
        dict["latitude"] = latitude
        dict["longitude"] = longitude
        return dict
    }
    
    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
        if let title = contentDic["title"] as? String, !title.isEmpty {
            self.name = title
        } else if let name = contentDic["name"] as? String {
            self.name = name
        }
        if let address = contentDic["address"] as? String {
            self.address = address
        }
        let latVal = contentDic["lat"] ?? contentDic["latitude"]
        if let latitude = latVal as? Double {
            self.latitude = latitude
        } else if let latitude = latVal as? NSNumber {
            self.latitude = latitude.doubleValue
        }
        let lngVal = contentDic["lng"] ?? contentDic["longitude"]
        if let longitude = lngVal as? Double {
            self.longitude = longitude
        } else if let longitude = lngVal as? NSNumber {
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
    
    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
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
/// 线缆格式与安卓 WKNoteContent 完全一致：noteId/noteTitle/noteContent/noteGroup/noteTime/blockListJson/coverUrl/resource/summary/containVideo/containLocation
/// 保证 iOS↔安卓↔utalk 双端互通，无需安卓改动
@objc public class WKNoteMessageContent: WKMessageContent {
    @objc public var noteId: String = ""
    @objc public var noteTitle: String = ""
    @objc public var noteContent: String = ""
    @objc public var noteGroup: String = ""
    @objc public var noteTime: String = ""
    @objc public var blockListJson: String = ""
    @objc public var coverUrl: String = ""
    @objc public var summary: String = ""
    @objc public var containVideo: Int = 0
    @objc public var containLocation: Int = 0

    // 旧字段兼容（本端解析用）
    @objc public var title: String = ""
    @objc public var noteJSON: String = ""

    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable: Any]()
        dict["noteId"] = noteId
        dict["noteTitle"] = noteTitle
        dict["noteContent"] = noteContent
        dict["noteGroup"] = noteGroup
        dict["noteTime"] = noteTime
        dict["blockListJson"] = blockListJson
        // 与安卓一致：coverUrl 和 resource 都写封面图，兼容 utalk
        dict["coverUrl"] = coverUrl
        dict["resource"] = coverUrl
        dict["resourceType"] = ""
        dict["summary"] = summary
        dict["containVideo"] = containVideo
        dict["containLocation"] = containLocation
        return dict
    }

    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
        guard let contentDic = contentDic else { return }
        func str(_ key: String) -> String {
            if let s = contentDic[key] as? String { return s }
            if let n = contentDic[key] as? NSNumber { return n.stringValue }
            return ""
        }
        // 安卓/utalk 原生字段
        noteId = str("noteId")
        noteTitle = str("noteTitle")
        noteContent = str("noteContent")
        noteGroup = str("noteGroup")
        noteTime = str("noteTime")
        blockListJson = str("blockListJson")
        coverUrl = str("coverUrl").isEmpty ? str("resource") : str("coverUrl")
        summary = str("summary")
        if let v = contentDic["containVideo"] as? NSNumber { containVideo = v.intValue }
        if let v = contentDic["containLocation"] as? NSNumber { containLocation = v.intValue }
        // 兼容旧 iOS 格式 note_id/title/content/note_json
        if noteId.isEmpty { noteId = str("note_id") }
        if noteTitle.isEmpty { noteTitle = str("title") }
        if noteContent.isEmpty { noteContent = str("content") }
        noteJSON = str("note_json")
        // 保留完整 JSON 供详情页解析
        if let data = try? JSONSerialization.data(withJSONObject: contentDic),
           let s = String(data: data, encoding: .utf8) {
            noteJSON = s
        }
        title = noteTitle
    }

    public override class func contentType() -> NSNumber {
        return NSNumber(value: 100)
    }
}

// MARK: - RTC 通话结果消息内容 (type: 9989，与安卓 WKRTCType.WK_P2P_CALL / RTCMsgContent 一致)
/// 通话结束时由结束方发送的真实聊天消息，双方会话中展示通话气泡（对齐微信/安卓）
/// callType: 0=语音 1=视频；resultType: 0=取消 1=正常结束 2=未接听 3=拒绝 4=忙线；second: 通话时长(秒)
@objc public class WKRTCMsgContent: WKMessageContent {
    @objc public var callType: Int = 0
    @objc public var resultType: Int = 0
    @objc public var second: Int = 0

    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable : Any]()
        dict["call_type"] = callType
        dict["second"] = second
        dict["result_type"] = resultType
        dict["type"] = 9989
        return dict
    }

    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
        if let v = contentDic["call_type"] as? Int {
            self.callType = v
        } else if let v = contentDic["call_type"] as? NSNumber {
            self.callType = v.intValue
        }
        if let v = contentDic["result_type"] as? Int {
            self.resultType = v
        } else if let v = contentDic["result_type"] as? NSNumber {
            self.resultType = v.intValue
        }
        if let v = contentDic["second"] as? Int {
            self.second = v
        } else if let v = contentDic["second"] as? NSNumber {
            self.second = v.intValue
        }
    }

    public override class func contentType() -> NSNumber {
        return NSNumber(value: 9989)
    }
}

// MARK: - RTC 通话信令消息内容 (type: 9996，与安卓 WKRTCType.wk_video_call_received 一致)
@objc public class WKRTCSignalMessageContent: WKMessageContent {
    @objc public var signalType: Int = 0
    @objc public var callType: Int = 0
    @objc public var roomId: Int = 0
    @objc public var callerId: String = ""
    @objc public var callerName: String = ""

    public override func encodeWithJSON() -> [AnyHashable : Any] {
        var dict = [AnyHashable : Any]()
        dict["signal_type"] = signalType
        dict["call_type"] = callType
        dict["room_id"] = roomId
        dict["caller_id"] = callerId
        dict["caller_name"] = callerName
        // 安卓 RTCStrategy 解析的是 from_uid / from_name，双写保证安卓端能识别主叫昵称
        dict["from_uid"] = callerId
        dict["from_name"] = callerName
        dict["type"] = 9996
        return dict
    }

    public override func decode(withJSON contentDic: [AnyHashable : Any]!) {
        if let v = contentDic["signal_type"] as? Int {
            self.signalType = v
        } else if let v = contentDic["signal_type"] as? NSNumber {
            self.signalType = v.intValue
        }
        if let v = contentDic["call_type"] as? Int {
            self.callType = v
        } else if let v = contentDic["call_type"] as? NSNumber {
            self.callType = v.intValue
        }
        if let v = contentDic["room_id"] as? Int {
            self.roomId = v
        } else if let v = contentDic["room_id"] as? NSNumber {
            self.roomId = v.intValue
        }
        if let v = contentDic["caller_id"] as? String {
            self.callerId = v
        }
        if let v = contentDic["caller_name"] as? String {
            self.callerName = v
        }
    }

    public override class func contentType() -> NSNumber {
        return NSNumber(value: 9996)
    }
}

// MARK: - 消息内容类型注册
class WKMessageContentRegistrar {
    static func registerAll() {
        WKSDK.shared().registerMessageContent(WKRTCSignalMessageContent.self)
        WKSDK.shared().registerMessageContent(WKRTCMsgContent.self)
        WKSDK.shared().registerMessageContent(WKImageMessageContent.self)
        WKSDK.shared().registerMessageContent(WKVoiceMessageContent.self)
        WKSDK.shared().registerMessageContent(WKVideoMessageContent.self)
        WKSDK.shared().registerMessageContent(WKFileMessageContent.self)
        WKSDK.shared().registerMessageContent(WKLocationMessageContent.self)
        WKSDK.shared().registerMessageContent(WKCardMessageContent.self)
        WKSDK.shared().registerMessageContent(WKNoteMessageContent.self)
    }
}