import UIKit
import SnapKit

// MARK: - 群二维码
class GroupQRCodeViewController: UIViewController {
    private let groupId: String
    private let groupName: String
    private let qrImageView = UIImageView()
    private let nameLabel = UILabel()
    private let tipLabel = UILabel()

    init(groupId: String, groupName: String) {
        self.groupId = groupId
        self.groupName = groupName
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群二维码"
        view.backgroundColor = .themeBackground

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.backgroundColor = .white
        qrImageView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        qrImageView.clipsToBounds = true

        nameLabel.text = groupName
        nameLabel.font = ScreenAdapter.mediumFont(18)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center

        tipLabel.text = "该二维码永久有效"
        tipLabel.font = ScreenAdapter.font(14)
        tipLabel.textColor = .secondaryLabel
        tipLabel.textAlignment = .center

        view.addSubviews(qrImageView, nameLabel, tipLabel)

        qrImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(40))
            make.width.height.equalTo(ScreenAdapter.scaleW(240))
        }

        nameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(qrImageView.snp.bottom).offset(ScreenAdapter.scaleH(20))
        }

        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
        }

        generateQRCode()
        loadServerQRCode()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(showMoreMenu)
        )
        navigationItem.rightBarButtonItem?.tintColor = .themePrimary
    }

    @objc private func showMoreMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "保存二维码图片", style: .default) { [weak self] _ in
            self?.saveQRCodeImage()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func saveQRCodeImage() {
        guard let image = qrImageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            AppUtility.showToast("保存失败")
        } else {
            AppUtility.showToast("已保存到相册")
        }
    }

    private func loadServerQRCode() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.getGroupQrCode(groupId: groupId))
                if let data = response["data"] as? [String: Any],
                   let qrcode = data["qrcode"] as? String, !qrcode.isEmpty {
                    DispatchQueue.main.async {
                        self.displayQRCode(from: qrcode)
                        self.tipLabel.text = "该二维码永久有效"
                    }
                }
            } catch {
                // 服务端获取失败时保持本地生成的二维码（本地内容同样走 /v1/qrcode/g 路由，永久有效）
            }
        }
    }

    /// CIQRCodeGenerator 输出的是原始 CIImage，直接用 UIImage(ciImage:) 会模糊且尺寸为 0 时为空。
    /// 固定输出尺寸 + 位图上下文渲染，保证清晰且必能生成（修复"群二维码显示空白"）
    private func displayQRCode(from string: String) {
        qrImageView.image = Self.makeQRCode(from: string, size: 512)
    }

    private func generateQRCode() {
        // 与后端 /v1/groups/{id}/qrcode 返回内容一致，扫码端统一走 /v1/qrcode/g{id} 解析入群
        let qrString = "\(APIConfig.apiBaseURL)/v1/qrcode/g\(groupId)"
        qrImageView.image = Self.makeQRCode(from: qrString, size: 512)
    }

    static func makeQRCode(from string: String, size: CGFloat) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else { return nil }
        let scale = size / max(outputImage.extent.width, 1)
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            // 白底 + 最近邻放大（无插值模糊）
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            let ciCtx = CIContext(cgContext: ctx.cgContext, options: nil)
            if let cg = ciCtx.createCGImage(scaled, from: scaled.extent) {
                ctx.cgContext.interpolationQuality = .none
                ctx.cgContext.draw(cg, in: CGRect(x: 0, y: 0, width: size, height: size))
            }
        }
    }
}

// MARK: - 群黑名单
class GroupBlackListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [GroupMember] = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群黑名单"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "GBLCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "添加",
            style: .plain,
            target: self,
            action: #selector(addToBlackList)
        )
        navigationItem.rightBarButtonItem?.tintColor = .themePrimary

        loadBlackList()
    }

    private func loadBlackList() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.getGroupBlackList(groupId: groupId))
                if let data = response["data"] as? [[String: Any]] {
                    let list = data.compactMap { dict -> GroupMember? in
                        let uid = dict["uid"] as? String ?? ""
                        let name = dict["name"] as? String ?? ""
                        let avatar = dict["avatar"] as? String
                        return GroupMember(uid: uid, name: name, avatar: avatar, role: 0, nickname: nil, joinTime: nil, isMuted: nil)
                    }
                    DispatchQueue.main.async {
                        self.members = list
                        self.tableView.reloadData()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载失败")
                }
            }
        }
    }

    @objc private func addToBlackList() {
        let vc = ChooseContactsViewController()
        vc.onContactsSelected = { [weak self] (uids: [String]) in
            guard let self = self, let uid = uids.first else { return }
            self.addMemberToBlackList(uid: uid)
        }
navigationController?.pushViewController(vc, animated: true)
    }

    private func addMemberToBlackList(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.addToBlackList(groupId: groupId, uid: uid))
                DispatchQueue.main.async {
                    AppUtility.showToast("已加入黑名单")
                    self.loadBlackList()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("添加失败")
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(members.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GBLCell", for: indexPath) as! GroupMemberCell
        if members.isEmpty {
            cell.textLabel?.text = "暂无黑名单用户"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.selectionStyle = .none
        } else {
            let m = members[indexPath.row]
            cell.configure(with: m)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !members.isEmpty else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "移出") { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            let m = self.members[indexPath.row]
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.removeFromBlackList(groupId: self.groupId, uid: m.uid))
                    DispatchQueue.main.async {
                        self.members.remove(at: indexPath.row)
                        tableView.reloadData()
                        AppUtility.showToast("已移出黑名单")
                        completionHandler(true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("操作失败")
                        completionHandler(false)
                    }
                }
            }
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}

// MARK: - 已加入群列表
class JoinedGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groups: [(groupId: String, name: String, memberCount: Int)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "已加入的群"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "JGCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        loadGroups()
    }

    private func loadGroups() {
        // 来源1：本地 IM SDK 会话列表中的群频道
        let conversations = IMManager.shared.getConversationList()
        var seenIDs = Set<String>()
        var list: [(groupId: String, name: String, memberCount: Int)] = []
        for conv in conversations where conv.channel.channelType == 2 {
            let gid = conv.channel.channelId ?? ""
            guard !gid.isEmpty, !seenIDs.contains(gid) else { continue }
            seenIDs.insert(gid)
            var name = IMManager.shared.getChannelInfo(channelId: gid, channelType: 2)?.displayName ?? ""
            if name.isEmpty { name = "群聊" }
            list.append((groupId: gid, name: name, memberCount: 0))
        }
        list.sort { $0.name < $1.name }
        DispatchQueue.main.async {
            self.groups = list
            self.tableView.reloadData()
        }

        // 来源2：服务端会话列表（补齐本地库里缺失的群，修复"我加入的群聊里没有任何群"）
        Task {
            guard let resp: WKSyncChat = try? await APIClient.shared.requestFlexible(.syncConversations) else { return }
            let serverGroupIDs = (resp.conversations ?? [])
                .filter { $0.channel_type == 2 }
                .compactMap { $0.channel_id }
                .filter { !$0.isEmpty && !seenIDs.contains($0) }
            guard !serverGroupIDs.isEmpty else { return }
            var added: [(groupId: String, name: String, memberCount: Int)] = []
            for gid in serverGroupIDs {
                seenIDs.insert(gid)
                added.append((groupId: gid, name: "群聊", memberCount: 0))
            }
            DispatchQueue.main.async {
                self.groups.append(contentsOf: added)
                self.groups.sort { $0.name < $1.name }
                self.tableView.reloadData()
            }
            for g in added {
                IMManager.shared.fetchChannelInfo(channelId: g.groupId, channelType: 2) { [weak self] info in
                    guard let self = self, let info = info, !info.displayName.isEmpty else { return }
                    let newName = info.displayName
                    DispatchQueue.main.async {
                        if let idx = self.groups.firstIndex(where: { $0.groupId == g.groupId }) {
                            self.groups[idx].name = newName
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(groups.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JGCell", for: indexPath)
        if groups.isEmpty { cell.textLabel?.text = "暂未加入群组"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none; cell.imageView?.image = nil }
        else {
            let g = groups[indexPath.row]
            cell.textLabel?.text = g.name
            cell.detailTextLabel?.text = "\(g.memberCount)人"
            // 先占位图兜底，再异步换成真实群头像
            cell.imageView?.image = AppUtility.defaultAvatarImage(name: g.name, size: 96)
            AppUtility.loadChannelAvatar(channelId: g.groupId, channelType: 2, name: g.name, into: cell.imageView!)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !groups.isEmpty else { return }
        let g = groups[indexPath.row]
        let chatVC = ChatViewController(channelId: g.groupId, title: g.name, channelType: 2)
navigationController?.pushViewController(chatVC, animated: true)
    }
}

// MARK: - 已保存群列表
class SavedGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groups: [(groupId: String, name: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "保存的群"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SGCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "创建新群",
            style: .plain,
            target: self,
            action: #selector(createNewGroup)
        )
        navigationItem.rightBarButtonItem?.tintColor = .themePrimary

        loadSavedGroups()
    }

    private func loadSavedGroups() {
        Task {
            // 从会话列表获取群频道，过滤已保存到通讯录的
            let conversations = IMManager.shared.getConversationList()
            var list: [(groupId: String, name: String)] = []
            for conv in conversations {
                if conv.channel.channelType == 2 {
                    let gid = conv.channel.channelId ?? ""
                    var name = gid
                    if let info = IMManager.shared.getChannelInfo(channelId: gid, channelType: 2) {
                        name = info.name ?? gid
                    }
                    // 检查是否已保存到通讯录
                    if let groupInfo = try? await APIClient.shared.requestRaw(.getGroupInfo(groupId: gid)),
                       let data = groupInfo["data"] as? [String: Any],
                       let saved = data["saved_to_contacts"] as? Bool, saved {
                        list.append((groupId: gid, name: name))
                    }
                }
            }
            list.sort { $0.name < $1.name }
            DispatchQueue.main.async {
                self.groups = list
                self.tableView.reloadData()
            }
        }
    }

    @objc private func createNewGroup() {
        let vc = ChooseContactsViewController(maxSelection: 99)
        vc.onContactsSelected = { [weak self] uids in
            guard let self = self else { return }
            Task {
                do {
                    let response = try await APIClient.shared.requestRaw(.addGroupMembers(groupId: "", uids: uids))
                    _ = response
                    DispatchQueue.main.async {
                        AppUtility.showToast("创建成功")
                        self.loadSavedGroups()
                    }
                } catch {
                    DispatchQueue.main.async { AppUtility.showToast("创建失败") }
                }
            }
        }
navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(groups.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SGCell", for: indexPath)
        if groups.isEmpty { cell.textLabel?.text = "暂无保存的群"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else {
            let g = groups[indexPath.row]
            cell.textLabel?.text = g.name
            cell.imageView?.image = UIImage(systemName: "bookmark.fill")
            cell.imageView?.tintColor = .themePrimary
            AppUtility.loadChannelAvatar(channelId: g.groupId, channelType: 2, name: g.name, into: cell.imageView!)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !groups.isEmpty else { return }
        let g = groups[indexPath.row]
        let chatVC = ChatViewController(channelId: g.groupId, title: g.name, channelType: 2)
navigationController?.pushViewController(chatVC, animated: true)
    }
}

// MARK: - 移出成员
class OutGroupMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [(uid: String, name: String)] = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "移出成员"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OGMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OGMCell", for: indexPath)
        let m = members[indexPath.row]
        cell.textLabel?.text = m.name
        AppUtility.loadChannelAvatar(channelId: m.uid, channelType: 1, name: m.name, into: cell.imageView!)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let out = UIContextualAction(style: .destructive, title: "移出") { _, _, c in
            self.members.remove(at: indexPath.row); tableView.reloadData(); c(true)
        }
        return UISwipeActionsConfiguration(actions: [out])
    }
}

// MARK: - 删除成员
class DeleteGroupMemberViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [(uid: String, name: String)] = []
    private var selectedUids: Set<String> = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "删除成员"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DGMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteMembers))
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DGMCell", for: indexPath)
        let m = members[indexPath.row]
        cell.textLabel?.text = m.name
        AppUtility.loadChannelAvatar(channelId: m.uid, channelType: 1, name: m.name, into: cell.imageView!)
        cell.accessoryType = selectedUids.contains(m.uid) ? .checkmark : .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let m = members[indexPath.row]
        if selectedUids.contains(m.uid) { selectedUids.remove(m.uid) } else { selectedUids.insert(m.uid) }
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    @objc private func deleteMembers() {
        guard !selectedUids.isEmpty else { AppUtility.showToast("请选择成员"); return }
        let alert = UIAlertController(title: "删除成员", message: "确定删除选中的\(selectedUids.count)名成员？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in AppUtility.showToast("已删除"); self.navigationController?.popViewController(animated: true) })
        present(alert, animated: true)
    }
}

// MARK: - 已读成员列表
class ReadMsgMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var readMembers: [(uid: String, name: String, time: String)] = []
    private var unreadMembers: [(uid: String, name: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "已读/未读成员"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? max(readMembers.count, 1) : max(unreadMembers.count, 1) }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { section == 0 ? "已读\(readMembers.count)人" : "未读\(unreadMembers.count)人" }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RMCell", for: indexPath)
        if indexPath.section == 0 && !readMembers.isEmpty { let m = readMembers[indexPath.row]; cell.textLabel?.text = m.name; cell.detailTextLabel?.text = m.time; cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill"); cell.imageView?.tintColor = .systemGreen }
        else if indexPath.section == 1 && !unreadMembers.isEmpty { let m = unreadMembers[indexPath.row]; cell.textLabel?.text = m.name; cell.imageView?.image = UIImage(systemName: "circle"); cell.imageView?.tintColor = .secondaryLabel }
        else { cell.textLabel?.text = "暂无"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        return cell
    }
}

// MARK: - 全部成员列表
class AllMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var groupId: String
    private var members: [(uid: String, name: String, role: Int)] = []

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全部成员"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AMCell", for: indexPath)
        let m = members[indexPath.row]
        cell.textLabel?.text = m.name
        AppUtility.loadChannelAvatar(channelId: m.uid, channelType: 1, name: m.name, into: cell.imageView!)
        switch m.role {
        case 1: cell.detailTextLabel?.text = "群主"; cell.detailTextLabel?.textColor = .themePrimary
        case 2: cell.detailTextLabel?.text = "管理员"; cell.detailTextLabel?.textColor = .systemOrange
        default: cell.detailTextLabel?.text = ""
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let m = members[indexPath.row]
        navigationController?.pushViewController(ContactDetailViewController(uid: m.uid), animated: true)
    }
}

// MARK: - 设置群备注
class SetGroupRemarkViewController: UIViewController {
    private var groupId: String
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群备注"
        view.backgroundColor = .themeBackground
        textField.placeholder = "请输入群备注"
        textField.borderStyle = .roundedRect; textField.font = ScreenAdapter.font(16)
        textField.text = UserDefaults.standard.string(forKey: "group_remark_\(groupId)")
        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = ScreenAdapter.font(17); saveButton.backgroundColor = .themePrimary
        saveButton.setTitleColor(.white, for: .normal); saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [textField, saveButton]); stack.axis = .vertical; stack.spacing = ScreenAdapter.scaleH(16)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24)); make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        textField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func save() {
        let remark = textField.text ?? ""
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.updateGroupSettingString(groupId: groupId, key: "remark", value: remark))
                UserDefaults.standard.set(remark, forKey: "group_remark_\(groupId)")
                DispatchQueue.main.async {
                    AppUtility.showToast("已保存")
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("保存失败")
                }
            }
        }
    }
}

// MARK: - 修改群名
class UpdateGroupNameViewController: UIViewController {
    private var groupId: String
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)
    private var currentName: String = ""

    init(groupId: String) { self.groupId = groupId; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "修改群名"
        view.backgroundColor = .themeBackground
        textField.placeholder = "请输入群名称"
        textField.borderStyle = .roundedRect; textField.font = ScreenAdapter.font(16)
        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = ScreenAdapter.font(17); saveButton.backgroundColor = .themePrimary
        saveButton.setTitleColor(.white, for: .normal); saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [textField, saveButton]); stack.axis = .vertical; stack.spacing = ScreenAdapter.scaleH(16)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24)); make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        textField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }

        loadCurrentName()
    }

    private func loadCurrentName() {
        Task {
            do {
                let raw = try await APIClient.shared.requestRaw(.getChannelInfo(channelId: groupId, channelType: 2))
                let payload = (raw["data"] as? [String: Any]) ?? raw
                if let name = payload["name"] as? String, !name.isEmpty {
                    DispatchQueue.main.async {
                        self.currentName = name
                        self.textField.text = name
                    }
                }
            } catch {}
        }
    }

    @objc private func save() {
        guard let name = textField.text, !name.isEmpty else { AppUtility.showToast("请输入群名"); return }
        guard name != currentName else { AppUtility.showToast("群名未修改"); return }
        saveButton.isEnabled = false
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.updateGroupInfo(groupId: groupId, name: name, avatar: nil))
                DispatchQueue.main.async {
                    AppUtility.showToast("已修改")
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.saveButton.isEnabled = true
                    AppUtility.showToast("修改失败")
                }
            }
        }
    }
}

// MARK: - 群资料页（普通成员只读，仿个人信息页；管理员走 GroupDetailViewController）
class GroupInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let groupId: String
    private var groupName: String = ""
    private var memberCount: Int = 0
    private var groupNotice: String = ""
    /// 本人在群里的角色（1=群主 2=管理员 0=普通成员），用于群管理页权限判定
    private var myRole: Int?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private weak var headerAvatar: UIImageView?
    private weak var headerNameLabel: UILabel?
    private weak var headerCountLabel: UILabel?
    private weak var headerNoticeLabel: UILabel?

    private var isSpecialGroup: Bool { SpecialUserUtils.isSpecialGroup(name: groupName) }

    init(groupId: String) {
        self.groupId = groupId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群聊信息"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "InfoCell")
        tableView.tableHeaderView = createHeader()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        loadInfo()
    }

    // MARK: - 头部（头像 + 群名 + 成员数 + 群公告）
    private func createHeader() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: ScreenAdapter.screenWidth, height: ScreenAdapter.scaleH(150)))

        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 12
        card.layer.masksToBounds = true
        header.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(8))
        }

        let avatar = UIImageView()
        avatar.layer.cornerRadius = 8
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.backgroundColor = .systemGray6
        avatar.image = UIImage(systemName: "person.3.fill")
        avatar.tintColor = .systemGray5

        let name = UILabel()
        name.font = ScreenAdapter.boldFont(18)
        name.textColor = .label
        name.numberOfLines = 2

        let count = UILabel()
        count.font = ScreenAdapter.font(13)
        count.textColor = .secondaryLabel

        let notice = UILabel()
        notice.font = ScreenAdapter.font(13)
        notice.textColor = .secondaryLabel
        notice.numberOfLines = 2
        notice.isHidden = true

        card.addSubviews(avatar, name, count, notice)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(14))
            make.width.height.equalTo(ScreenAdapter.scaleW(56))
        }
        name.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.trailing.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.top.equalTo(avatar.snp.top).offset(ScreenAdapter.scaleH(2))
        }
        count.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(ScreenAdapter.scaleH(4))
        }
        notice.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.top.equalTo(avatar.snp.bottom).offset(ScreenAdapter.scaleH(12))
        }

        headerAvatar = avatar
        headerNameLabel = name
        headerCountLabel = count
        headerNoticeLabel = notice
        return header
    }

    private func loadInfo() {
        Task {
            do {
                let raw = try await APIClient.shared.requestRaw(.getChannelInfo(channelId: groupId, channelType: 2))
                let payload = (raw["data"] as? [String: Any]) ?? raw
                let name = (payload["name"] as? String) ?? ""
                var count = (payload["member_count"] as? Int)
                    ?? ((payload["extra"] as? [String: Any])?["member_count"] as? Int)
                    ?? 0
                // 群公告（notice / announcement / extra.notice）
                let notice = (payload["notice"] as? String)
                    ?? (payload["announcement"] as? String)
                    ?? ((payload["extra"] as? [String: Any])?["notice"] as? String)
                    ?? ""
                if let role = payload["role"] as? Int {
                    self.myRole = role
                } else if let extra = payload["extra"] as? [String: Any] {
                    self.myRole = (extra["role"] as? Int) ?? (extra["role"] as? String).flatMap { Int($0) }
                }

                // 人数以 membersync 实际有效成员为准（频道 member_count 会把已退群成员算进去）
                let memberList: [GroupMember]? = try? await APIClient.shared.requestFlexible(
                    .getGroupMembers(groupId: groupId, page: 1, size: 200, keyword: nil)
                )
                if let list = memberList {
                    var seen = Set<String>()
                    let active = list.filter {
                        ($0.isDeleted ?? 0) == 0 && !$0.uid.isEmpty && seen.insert($0.uid).inserted
                    }
                    if !active.isEmpty { count = active.count }
                    let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
                    // 本人角色在全量记录中查找：is_deleted 标记不可靠（群主记录也可能被标记删除）
                    if let me = list.first(where: { $0.uid == myUid }) {
                        myRole = me.role
                    }
                }

                let finalCount = count
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.groupName = name
                    self.memberCount = finalCount
                    self.groupNotice = notice
                    self.headerNameLabel?.text = name
                    // 特殊群（西安修车大队/西安交流群等）群名使用红棕色
                    self.headerNameLabel?.textColor = self.isSpecialGroup ? SpecialUserUtils.specialGroupNameColor : .label
                    self.headerCountLabel?.text = "共 \(finalCount) 人"
                    // 群公告：有内容则展示"群公告：xxx"，否则隐藏
                    if !notice.isEmpty {
                        self.headerNoticeLabel?.text = "群公告：\(notice)"
                        self.headerNoticeLabel?.isHidden = false
                    } else {
                        self.headerNoticeLabel?.isHidden = true
                    }
                    if let avatar = self.headerAvatar {
                        AppUtility.loadChannelAvatar(channelId: self.groupId, channelType: 2, name: name, into: avatar)
                    }
                    self.tableView.reloadData()
                }
            } catch {}
        }
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 群管理入口对齐安卓/微信：所有人可见（进入后按角色限制可改项）+ 特殊群多一个客服入口
        return 1 + (isSpecialGroup ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath)
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary
        cell.accessoryType = .disclosureIndicator
        if indexPath.row == 0 {
            cell.textLabel?.text = "群管理"
            cell.imageView?.image = UIImage(systemName: "gearshape")
        } else {
            cell.textLabel?.text = "客服"
            cell.imageView?.image = UIImage(systemName: "headset")
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            navigationController?.pushViewController(
                GroupManageViewController(groupId: groupId, myRole: myRole), animated: true
            )
        } else {
            // 客服 → 本群客服个人信息页（标题对齐安卓：本群客服）
            navigationController?.pushViewController(
                ContactDetailViewController(uid: SpecialUserUtils.specialUid, titleOverride: "本群客服"), animated: true
            )
        }
    }
}
