import Foundation

// MARK: - 好友申请本地存储（对齐Android ApplyDB）
/// Android 通过 IM 的 system CMD（friendRequest / friendAccept / friendDeleted）
/// 把申请记录写入本地 ApplyDB，列表页再从本地数据库读取。
/// iOS 侧用 UserDefaults 持久化，逻辑保持一致。
final class FriendApplyStore {

    static let shared = FriendApplyStore()

    static let changedNotification = Notification.Name("FriendApplyStoreChanged")

    private var storageKey: String {
        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
        return "friend_apply_list_\(uid)"
    }

    private init() {}

    // MARK: 读取
    func all() -> [FriendApply] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([FriendApply].self, from: data) else {
            return []
        }
        return list
    }

    // MARK: 保存/更新一条申请
    /// Android: saveNewFriendsMsg()，相同 apply_uid 则覆盖 token/remark 并重置为待通过
    func upsert(_ apply: FriendApply) {
        var list = all()
        if let index = list.firstIndex(where: { $0.uid == apply.uid }) {
            let oldName = list[index].name
            let item = list.remove(at: index)
            var updated = item
            updated.name = apply.name.isEmpty ? oldName : apply.name
            updated.avatar = apply.avatar ?? item.avatar
            updated.token = apply.token
            updated.remark = apply.remark
            updated.status = 0
            list.insert(updated, at: 0)
        } else {
            list.insert(apply, at: 0)
        }
        save(list)
    }

    // MARK: 更新状态 0待通过 1已通过 2已拒绝
    func markStatus(uid: String, status: Int) {
        var list = all()
        guard let index = list.firstIndex(where: { $0.uid == uid }) else { return }
        list[index].status = status
        save(list)
    }

    func remove(uid: String) {
        var list = all()
        list.removeAll { $0.uid == uid }
        save(list)
    }

    // MARK: 解析 CMD 参数
    /// Android NewFriendEntity: apply_uid / apply_name / token / remark / type
    func saveFromCMD(_ param: [String: Any]) {
        let uid = (param["apply_uid"] as? String) ?? ""
        guard !uid.isEmpty else { return }
        // type: 0 好友申请 1 入群申请；iOS 暂不支持入群申请审批，这里只处理好友申请
        let type = (param["type"] as? NSNumber)?.intValue ?? (param["type"] as? Int) ?? 0
        guard type == 0 else { return }
        let apply = FriendApply(
            uid: uid,
            name: (param["apply_name"] as? String) ?? "",
            avatar: param["apply_avatar"] as? String,
            remark: (param["remark"] as? String) ?? "",
            status: 0,
            token: (param["token"] as? String) ?? ""
        )
        upsert(apply)
    }

    private func save(_ list: [FriendApply]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        NotificationCenter.default.post(name: FriendApplyStore.changedNotification, object: nil)
    }
}
