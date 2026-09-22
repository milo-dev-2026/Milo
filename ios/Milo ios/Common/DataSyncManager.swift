import Foundation

class DataSyncManager {
    static let shared = DataSyncManager()
    private var hasSynced = false

    private init() {}

    func syncAll() {
        guard !hasSynced else { return }
        hasSynced = true
        syncUserProfile()
    }

    func resetSyncFlag() {
        hasSynced = false
    }

    private func syncUserProfile() {
        guard let uid = UserDefaults.standard.string(forKey: "uid"), !uid.isEmpty else { return }
        Task {
            do {
                let channelInfo: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: uid, channelType: 1)
                )
                let user = channelInfo.toUser()
                UserDefaults.standard.set(user.name, forKey: "name")
                if let avatar = user.avatar {
                    UserDefaults.standard.set(avatar, forKey: "avatar")
                }
                NotificationCenter.default.post(name: NSNotification.Name("UserProfileUpdated"), object: nil)
            } catch {}
        }
    }
}
