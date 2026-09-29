//
//  TagManager.swift
//  Milo
//
//  标签模块 - 管理器
//  单例管理：标签列表、新增/删除/修改、添加/移除成员、本地持久化
//

import Foundation
import UIKit

// MARK: - 标签管理器
final class TagManager {

    // MARK: - 单例
    static let shared = TagManager()
    private init() {
        loadTags()
    }

    // MARK: - 存储键
    private let tagsKey = "tag_list_data"

    // MARK: - 数据
    private var tags: [Tag] = []

    // MARK: - 公共属性

    /// 获取所有标签
    var allTags: [Tag] {
        return tags
    }

    /// 获取标签数量
    var tagCount: Int {
        return tags.count
    }

    // MARK: - 公共方法

    /// 获取指定ID的标签
    func getTag(by id: String) -> Tag? {
        return tags.first { $0.id == id }
    }

    /// 搜索标签
    func searchTags(keyword: String) -> [Tag] {
        let lowerKeyword = keyword.lowercased()
        return tags.filter { tag in
            tag.name.lowercased().contains(lowerKeyword)
        }
    }

    /// 新增标签
    func addTag(name: String, color: TagColor, members: [TagMember] = []) -> Tag {
        let tag = Tag(
            name: name,
            memberCount: members.count,
            members: members,
            color: color
        )
        tags.append(tag)
        saveTags()

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.notificationSuccess()
        }

        return tag
    }

    /// 删除标签
    func deleteTag(_ tagId: String) {
        tags.removeAll { $0.id == tagId }
        saveTags()
    }

    /// 更新标签
    func updateTag(_ tagId: String, name: String, color: TagColor, members: [TagMember]) {
        guard let index = tags.firstIndex(where: { $0.id == tagId }) else { return }
        var tag = tags[index]
        tag.name = name
        tag.tagColor = color
        tag.members = members
        tag.memberCount = members.count
        tags[index] = tag
        saveTags()
    }

    /// 添加成员到标签
    func addMember(_ member: TagMember, to tagId: String) {
        guard let index = tags.firstIndex(where: { $0.id == tagId }) else { return }
        var tag = tags[index]
        // 避免重复添加
        if !tag.members.contains(where: { $0.uid == member.uid }) {
            tag.members.append(member)
            tag.memberCount = tag.members.count
            tags[index] = tag
            saveTags()
        }
    }

    /// 批量添加成员
    func addMembers(_ members: [TagMember], to tagId: String) {
        guard let index = tags.firstIndex(where: { $0.id == tagId }) else { return }
        var tag = tags[index]
        for member in members {
            if !tag.members.contains(where: { $0.uid == member.uid }) {
                tag.members.append(member)
            }
        }
        tag.memberCount = tag.members.count
        tags[index] = tag
        saveTags()
    }

    /// 从标签移除成员
    func removeMember(_ memberId: String, from tagId: String) {
        guard let index = tags.firstIndex(where: { $0.id == tagId }) else { return }
        var tag = tags[index]
        tag.members.removeAll { $0.uid == memberId }
        tag.memberCount = tag.members.count
        tags[index] = tag
        saveTags()
    }

    /// 检查成员是否在标签中
    func isMember(_ memberId: String, in tagId: String) -> Bool {
        guard let tag = getTag(by: tagId) else { return false }
        return tag.members.contains { $0.uid == memberId }
    }

    // MARK: - 本地持久化

    private func saveTags() {
        do {
            let data = try JSONEncoder().encode(tags)
            UserDefaults.standard.set(data, forKey: tagsKey)
        } catch {
            print("TagManager: 保存标签失败 - \(error)")
        }
    }

    private func loadTags() {
        guard let data = UserDefaults.standard.data(forKey: tagsKey) else {
            // 首次使用，加载模拟数据
            tags = Tag.mockTags
            saveTags()
            return
        }

        do {
            tags = try JSONDecoder().decode([Tag].self, from: data)
        } catch {
            print("TagManager: 加载标签失败 - \(error)")
            tags = Tag.mockTags
            saveTags()
        }
    }

    // MARK: - 云端同步

    func syncFromCloud(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.syncTags)
                guard let data = resp["data"] as? [String: Any] else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                let tagsArray = data["tags"] as? [[String: Any]] ?? []
                var cloudTags: [Tag] = []
                for dict in tagsArray {
                    if let tag = Tag.fromDict(dict) {
                        cloudTags.append(tag)
                    }
                }
                DispatchQueue.main.async {
                    self.tags = cloudTags
                    self.saveTags()
                    completion(true)
                }
            } catch {
                print("[Tags] 云端同步失败: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    func upsertToCloud(_ tag: Tag, completion: ((Bool) -> Void)? = nil) {
        let membersArray = tag.members.map { $0.toDict() }
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.upsertTag(
                    id: tag.id, name: tag.name, colorRawValue: tag.colorRawValue,
                    members: membersArray, updateTime: Int64(Date().timeIntervalSince1970 * 1000)
                ))
                completion?(true)
            } catch {
                print("[Tags] 上传标签失败: \(error)")
                completion?(false)
            }
        }
    }

    func deleteFromCloud(tagId: String, completion: ((Bool) -> Void)? = nil) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.deleteTag(tagId: tagId))
                completion?(true)
            } catch {
                print("[Tags] 云端删除标签失败: \(error)")
                completion?(false)
            }
        }
    }
}
