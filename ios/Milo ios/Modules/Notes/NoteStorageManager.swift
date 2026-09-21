import Foundation

// MARK: - 笔记存储管理
class NoteStorageManager {
    
    static let shared = NoteStorageManager()
    private init() {}
    
    private let userDefaultsKey = "milo_notes"
    private let groupsKey = "milo_note_groups"
    
    // MARK: - 私有方法
    
    private func loadNotesFromStorage() -> [NoteEntity] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let notes = try? JSONDecoder().decode([NoteEntity].self, from: data) else {
            return []
        }
        return notes
    }
    
    private func saveNotesToStorage(_ notes: [NoteEntity]) {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - 增删改查
    
    /// 获取所有笔记（按置顶和更新时间排序）
    func getAllNotes() -> [NoteEntity] {
        let notes = loadNotesFromStorage()
        return notes.sorted { (n1, n2) -> Bool in
            if n1.isSticky != n2.isSticky {
                return n1.isSticky
            }
            return n1.updateTime > n2.updateTime
        }
    }
    
    /// 根据分组获取笔记
    func getNotes(in group: String) -> [NoteEntity] {
        let all = getAllNotes()
        if group == "全部" {
            return all
        }
        return all.filter { $0.group == group }
    }
    
    /// 搜索笔记
    func searchNotes(keyword: String) -> [NoteEntity] {
        guard !keyword.isEmpty else { return getAllNotes() }
        let all = getAllNotes()
        let lowerKeyword = keyword.lowercased()
        return all.filter { note in
            if note.title.lowercased().contains(lowerKeyword) { return true }
            if note.remark.lowercased().contains(lowerKeyword) { return true }
            for block in note.blocks {
                if block.content.lowercased().contains(lowerKeyword) { return true }
                if let loc = block.location, loc.address.lowercased().contains(lowerKeyword) { return true }
            }
            return false
        }
    }
    
    /// 根据ID获取笔记
    func getNote(by id: String) -> NoteEntity? {
        return loadNotesFromStorage().first { $0.id == id }
    }
    
    /// 添加笔记
    func addNote(_ note: NoteEntity) {
        var notes = loadNotesFromStorage()
        notes.append(note)
        saveNotesToStorage(notes)
    }
    
    /// 更新笔记
    func updateNote(_ note: NoteEntity) {
        var notes = loadNotesFromStorage()
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updated = note
            updated.updateTime = Int64(Date().timeIntervalSince1970 * 1000)
            notes[index] = updated
            saveNotesToStorage(notes)
        }
    }
    
    /// 删除笔记
    func deleteNote(id: String) {
        var notes = loadNotesFromStorage()
        notes.removeAll { $0.id == id }
        saveNotesToStorage(notes)
    }
    
    /// 切换置顶
    func toggleSticky(noteId: String) {
        var notes = loadNotesFromStorage()
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].isSticky.toggle()
            notes[index].updateTime = Int64(Date().timeIntervalSince1970 * 1000)
            saveNotesToStorage(notes)
        }
    }
    
    // MARK: - 分组管理
    
    /// 获取所有分组
    func getAllGroups() -> [String] {
        if let groups = UserDefaults.standard.stringArray(forKey: groupsKey) {
            return groups
        }
        let defaultGroups = ["全部", "普通笔记", "收藏笔记"]
        UserDefaults.standard.set(defaultGroups, forKey: groupsKey)
        return defaultGroups
    }
    
    /// 添加分组
    func addGroup(_ name: String) {
        var groups = getAllGroups()
        if !groups.contains(name) {
            groups.append(name)
            UserDefaults.standard.set(groups, forKey: groupsKey)
        }
    }
    
    /// 删除分组
    func deleteGroup(_ name: String) {
        guard name != "全部" && name != "普通笔记" && name != "收藏笔记" else { return }
        var groups = getAllGroups()
        groups.removeAll { $0 == name }
        UserDefaults.standard.set(groups, forKey: groupsKey)
        
        // 将该分组下的笔记移到"普通笔记"
        var notes = loadNotesFromStorage()
        for i in 0..<notes.count {
            if notes[i].group == name {
                notes[i].group = "普通笔记"
            }
        }
        saveNotesToStorage(notes)
    }
}
