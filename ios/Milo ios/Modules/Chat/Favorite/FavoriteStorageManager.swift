import Foundation

// MARK: - 收藏存储管理
class FavoriteStorageManager {
    
    static let shared = FavoriteStorageManager()
    private init() {}
    
    private let userDefaultsKey = "milo_favorites"
    
    // MARK: - 私有方法
    
    private func loadFromStorage() -> [FavoriteItem] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let items = try? JSONDecoder().decode([FavoriteItem].self, from: data) else {
            return []
        }
        return items
    }
    
    private func saveToStorage(_ items: [FavoriteItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - 增删改查
    
    /// 获取所有收藏（按时间倒序）
    func getAllFavorites() -> [FavoriteItem] {
        let items = loadFromStorage()
        return items.sorted { $0.createTime > $1.createTime }
    }
    
    /// 根据ID获取收藏
    func getFavorite(by id: String) -> FavoriteItem? {
        return loadFromStorage().first { $0.id == id }
    }
    
    /// 添加收藏
    func addFavorite(_ item: FavoriteItem) {
        var items = loadFromStorage()
        items.insert(item, at: 0)
        saveToStorage(items)
    }
    
    /// 删除收藏
    func deleteFavorite(id: String) {
        var items = loadFromStorage()
        items.removeAll { $0.id == id }
        saveToStorage(items)
    }
    
    /// 批量删除收藏
    func deleteFavorites(ids: [String]) {
        var items = loadFromStorage()
        items.removeAll { ids.contains($0.id) }
        saveToStorage(items)
    }
    
    /// 搜索收藏
    func searchFavorites(keyword: String) -> [FavoriteItem] {
        guard !keyword.isEmpty else { return getAllFavorites() }
        let all = getAllFavorites()
        let lower = keyword.lowercased()
        return all.filter { item in
            if item.content.lowercased().contains(lower) { return true }
            if item.fileName?.lowercased().contains(lower) == true { return true }
            if item.location?.address.lowercased().contains(lower) == true { return true }
            if item.fromUser?.name.lowercased().contains(lower) == true { return true }
            return false
        }
    }
    
    // MARK: - 从消息创建收藏
    
    /// 从消息创建收藏项
    func createFavorite(from message: Message, senderName: String = "") -> FavoriteItem {
        let from = FavoriteFromUser(
            uid: message.fromUID,
            name: senderName.isEmpty ? message.fromUID : senderName
        )
        
        switch message.type {
        case .text:
            return FavoriteItem(
                type: .text,
                content: message.content,
                fromUser: from
            )
            
        case .image:
            return FavoriteItem(
                type: .image,
                content: message.content,
                imageURL: message.content,
                fromUser: from
            )
            
        case .voice:
            // 语音消息内容格式: url|duration
            let parts = message.content.components(separatedBy: "|")
            let url = parts.first ?? ""
            let duration = TimeInterval(parts.last ?? "0") ?? 0
            return FavoriteItem(
                type: .voice,
                content: message.content,
                voiceURL: url,
                voiceDuration: duration,
                fromUser: from
            )
            
        case .video:
            // 视频消息内容格式: thumb|url
            let parts = message.content.components(separatedBy: "|")
            let url = parts.count > 1 ? parts[1] : ""
            return FavoriteItem(
                type: .video,
                content: message.content,
                imageURL: parts.first,
                videoURL: url,
                fromUser: from
            )
            
        case .file:
            // 文件消息内容格式: fileName|fileSize
            let parts = message.content.components(separatedBy: "|")
            let fileName = parts.first ?? ""
            let fileSize = Int64(parts.last ?? "0") ?? 0
            return FavoriteItem(
                type: .file,
                content: message.content,
                fileName: fileName,
                fileSize: fileSize,
                fromUser: from
            )
            
        case .location:
            // 位置消息内容格式: name|lat,lng
            let parts = message.content.components(separatedBy: "|")
            let name = parts.first ?? ""
            let coordParts = parts.count > 1 ? parts[1].components(separatedBy: ",") : []
            let lat = Double(coordParts.first ?? "0") ?? 0
            let lng = Double(coordParts.last ?? "0") ?? 0
            let location = FavoriteLocation(latitude: lat, longitude: lng, address: name)
            return FavoriteItem(
                type: .location,
                content: message.content,
                location: location,
                fromUser: from
            )
            
        default:
            return FavoriteItem(
                type: .text,
                content: message.content,
                fromUser: from
            )
        }
    }
}
