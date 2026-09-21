import UIKit
import SnapKit
import Kingfisher

class GroupDetailViewController: UIViewController {

    private let groupId: String
    private var group: Group?
    private var members: [GroupMember] = []
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // Section 索引
    private enum Section: Int, CaseIterable {
        case info = 0       // 我在群里的昵称、群二维码
        case settings = 1   // 消息免打扰、置顶、保存通讯录、显示群昵称
        case manage = 2     // 群管理员、入群审核
        case actions = 3    // 查找聊天内容、清空聊天记录
        case bottom = 4     // 退出/解散群聊
    }

    init(groupId: String) {
        self.groupId = groupId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadGroupInfo()
    }

    private func setupUI() {
        title = "群聊详情"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupDetailSwitchCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
        tableView.tableHeaderView = createHeaderView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(56), bottom: 0, right: 0)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Header View
    private func createHeaderView() -> UIView {
        let header = UIView()
        header.backgroundColor = .clear

        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(12)
        cardView.layer.masksToBounds = true

        // 群头像
        let avatarSize = ScreenAdapter.scaleW(64)
        let avatarImageView = UIImageView()
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(systemName: "person.3.fill")
        avatarImageView.tintColor = .systemGray5
        avatarImageView.backgroundColor = .systemGray6

        // 群名称
        let nameLabel = UILabel()
        nameLabel.font = ScreenAdapter.mediumFont(18)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0

        // 成员数
        let memberCountLabel = UILabel()
        memberCountLabel.font = ScreenAdapter.font(13)
        memberCountLabel.textColor = .secondaryLabel
        memberCountLabel.textAlignment = .center

        // 群公告
        let noticeContainer = UIView()
        noticeContainer.isUserInteractionEnabled = true
        let tapNotice = UITapGestureRecognizer(target: self, action: #selector(didTapNotice))
        noticeContainer.addGestureRecognizer(tapNotice)

        let noticeIcon = UIImageView(image: UIImage(systemName: "megaphone.fill"))
        noticeIcon.tintColor = .themePrimary
        noticeIcon.contentMode = .scaleAspectFit

        let noticeLabel = UILabel()
        noticeLabel.font = ScreenAdapter.font(14)
        noticeLabel.textColor = .secondaryLabel
        noticeLabel.numberOfLines = 2
        noticeLabel.text = "点击编辑群公告"

        let noticeArrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        noticeArrow.tintColor = .tertiaryLabel
        noticeArrow.contentMode = .scaleAspectFit

        noticeContainer.addSubviews(noticeIcon, noticeLabel, noticeArrow)

        noticeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(18))
        }

        noticeArrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(14))
        }

        noticeLabel.snp.makeConstraints { make in
            make.leading.equalTo(noticeIcon.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.trailing.equalTo(noticeArrow.snp.leading).offset(-ScreenAdapter.scaleW(4))
            make.top.bottom.equalToSuperview()
        }

        // 分割线
        let divider = UIView()
        divider.backgroundColor = .systemGray5

        // 成员网格
        let membersTitleLabel = UILabel()
        membersTitleLabel.font = ScreenAdapter.font(14)
        membersTitleLabel.textColor = .secondaryLabel
        membersTitleLabel.text = "群成员"

        let memberGridView = UIView()

        cardView.addSubviews(avatarImageView, nameLabel, memberCountLabel,
                             noticeContainer, divider, membersTitleLabel, memberGridView)
        header.addSubview(cardView)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(8))
        }

        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
        }

        memberCountLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.leading.trailing.equalTo(nameLabel)
        }

        noticeContainer.snp.makeConstraints { make in
            make.top.equalTo(memberCountLabel.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(36))
        }

        divider.snp.makeConstraints { make in
            make.top.equalTo(noticeContainer.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(0.5)
        }

        membersTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
        }

        memberGridView.snp.makeConstraints { make in
            make.top.equalTo(membersTitleLabel.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(16))
        }

        headerCache = HeaderCache(
            avatar: avatarImageView,
            nameLabel: nameLabel,
            memberCountLabel: memberCountLabel,
            noticeLabel: noticeLabel,
            memberGridView: memberGridView
        )

        // 计算 header 高度
        let headerWidth = view.bounds.width > 0 ? view.bounds.width : ScreenAdapter.screenWidth
        let cardWidth = headerWidth - ScreenAdapter.scaleW(32)
        let memberGridHeight = calculateMemberGridHeight(cardWidth: cardWidth)
        let headerHeight = ScreenAdapter.scaleH(20) + avatarSize + ScreenAdapter.scaleH(12 + 4 + 16 + 36 + 12 + 12 + 12) + memberGridHeight + ScreenAdapter.scaleH(16 + 20)
        header.frame = CGRect(x: 0, y: 0, width: headerWidth, height: headerHeight)

        return header
    }

    private struct HeaderCache {
        weak var avatar: UIImageView?
        weak var nameLabel: UILabel?
        weak var memberCountLabel: UILabel?
        weak var noticeLabel: UILabel?
        weak var memberGridView: UIView?
    }

    private var headerCache: HeaderCache?

    private func calculateMemberGridHeight(cardWidth: CGFloat) -> CGFloat {
        let columns: CGFloat = 5
        let horizontalSpacing = ScreenAdapter.scaleW(8)
        let itemWidth = (cardWidth - ScreenAdapter.scaleW(32) - (columns - 1) * horizontalSpacing) / columns
        let labelHeight = ScreenAdapter.scaleH(18)
        let verticalSpacing = ScreenAdapter.scaleH(8)
        return itemWidth + verticalSpacing + labelHeight
    }

    private func setupMemberGrid() {
        guard let gridView = headerCache?.memberGridView else { return }
        gridView.subviews.forEach { $0.removeFromSuperview() }

        let columns: CGFloat = 5
        let horizontalSpacing = ScreenAdapter.scaleW(8)
        let verticalSpacing = ScreenAdapter.scaleH(8)
        let cardWidth = gridView.bounds.width > 0 ? gridView.bounds.width : (ScreenAdapter.screenWidth - ScreenAdapter.scaleW(64))
        let itemWidth = (cardWidth - (columns - 1) * horizontalSpacing) / columns
        let avatarSize = itemWidth
        let labelHeight = ScreenAdapter.scaleH(18)

        let displayMembers = Array(members.prefix(9))
        let totalItems = displayMembers.count + 1 // +1 for add button

        for i in 0..<min(totalItems, 10) {
            let row = CGFloat(i / Int(columns))
            let col = CGFloat(i % Int(columns))
            let x = col * (itemWidth + horizontalSpacing)
            let y = row * (avatarSize + verticalSpacing + labelHeight)

            let container = UIView()
            container.frame = CGRect(x: x, y: y, width: itemWidth, height: avatarSize + verticalSpacing + labelHeight)

            let avatarView = UIImageView()
            avatarView.frame = CGRect(x: 0, y: 0, width: avatarSize, height: avatarSize)
            avatarView.layer.cornerRadius = avatarSize / 2
            avatarView.clipsToBounds = true
            avatarView.contentMode = .scaleAspectFill
            avatarView.backgroundColor = .systemGray6

            let nameLabel = UILabel()
            nameLabel.frame = CGRect(x: 0, y: avatarSize + verticalSpacing, width: itemWidth, height: labelHeight)
            nameLabel.font = ScreenAdapter.font(11)
            nameLabel.textColor = .secondaryLabel
            nameLabel.textAlignment = .center
            nameLabel.lineBreakMode = .byTruncatingTail

            if i < displayMembers.count {
                let member = displayMembers[i]
                nameLabel.text = member.name
                if let url = member.avatarURL {
                    avatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
                } else {
                    avatarView.image = UIImage(systemName: "person.circle.fill")
                    avatarView.tintColor = .systemGray4
                }
            } else {
                // 添加按钮
                avatarView.image = UIImage(systemName: "plus")
                avatarView.tintColor = .themePrimary
                avatarView.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.1)
                nameLabel.text = ""
                let tap = UITapGestureRecognizer(target: self, action: #selector(didTapAddMember))
                container.addGestureRecognizer(tap)
            }

            container.addSubview(avatarView)
            container.addSubview(nameLabel)
            container.isUserInteractionEnabled = true
            gridView.addSubview(container)
        }
    }

    // MARK: - Load Data
    private func loadGroupInfo() {
        Task {
            do {
                let response: APIResponse<Group> = try await APIClient.shared.request(.getGroupInfo(groupId: groupId))
                if let data = response.data {
                    group = data
                    if let ms = data.members {
                        members = ms
                    }
                    DispatchQueue.main.async {
                        self.updateHeaderUI()
                        self.tableView.reloadData()
                    }
                }
            } catch {
                AppUtility.showToast("加载群信息失败")
            }
        }
    }

    private func updateHeaderUI() {
        guard let group = group else { return }
        title = group.name
        headerCache?.nameLabel?.text = group.name
        if let count = group.memberCount {
            headerCache?.memberCountLabel?.text = "共 \(count) 人"
        }
        if let notice = group.notice, !notice.isEmpty {
            headerCache?.noticeLabel?.text = notice
            headerCache?.noticeLabel?.textColor = .label
        } else {
            headerCache?.noticeLabel?.text = "点击编辑群公告"
            headerCache?.noticeLabel?.textColor = .secondaryLabel
        }
        if let url = group.avatar, !url.isEmpty,
           let avatarURL = URL(string: url.hasPrefix("http") ? url : APIConfig.apiBaseURL + "/" + url) {
            headerCache?.avatar?.kf.setImage(with: avatarURL, placeholder: UIImage(systemName: "person.3.fill"))
        }
        setupMemberGrid()
    }

    // MARK: - Actions
    @objc private func didTapNotice() {
        let notice = group?.notice ?? ""
        let vc = GroupNoticeViewController(groupId: groupId, notice: notice)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func didTapAddMember() {
        let vc = AddGroupMembersViewController(groupId: groupId)
        vc.onMembersAdded = { [weak self] in
            self?.loadGroupInfo()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Switch Actions
    @objc private func toggleMessageDisturb(_ sender: UISwitch) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.setMessageDisturb(groupId: groupId, disturbed: sender.isOn))
                DispatchQueue.main.async {
                    AppUtility.showToast(sender.isOn ? "已开启消息免打扰" : "已关闭消息免打扰")
                }
            } catch {
                DispatchQueue.main.async {
                    sender.isOn = !sender.isOn
                    AppUtility.showToast("设置失败")
                }
            }
        }
    }

    @objc private func toggleChatTop(_ sender: UISwitch) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.setChatTop(groupId: groupId, topped: sender.isOn))
                DispatchQueue.main.async {
                    AppUtility.showToast(sender.isOn ? "已置顶" : "已取消置顶")
                }
            } catch {
                DispatchQueue.main.async {
                    sender.isOn = !sender.isOn
                    AppUtility.showToast("设置失败")
                }
            }
        }
    }

    @objc private func toggleSaveToContacts(_ sender: UISwitch) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.saveToContacts(groupId: groupId, saved: sender.isOn))
                DispatchQueue.main.async {
                    AppUtility.showToast(sender.isOn ? "已保存到通讯录" : "已从通讯录移除")
                }
            } catch {
                DispatchQueue.main.async {
                    sender.isOn = !sender.isOn
                    AppUtility.showToast("设置失败")
                }
            }
        }
    }

    @objc private func toggleShowNickname(_ sender: UISwitch) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.setShowGroupNickname(groupId: groupId, show: sender.isOn))
                DispatchQueue.main.async {
                    AppUtility.showToast(sender.isOn ? "已显示群昵称" : "已隐藏群昵称")
                }
            } catch {
                DispatchQueue.main.async {
                    sender.isOn = !sender.isOn
                    AppUtility.showToast("设置失败")
                }
            }
        }
    }

    // MARK: - Leave / Dismiss Group
    private func confirmLeaveGroup() {
        let alert = UIAlertController(title: "退出群聊", message: "确定退出此群聊？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出", style: .destructive) { [weak self] _ in
            self?.leaveGroup()
        })
        present(alert, animated: true)
    }

    private func leaveGroup() {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.leaveGroup(groupId: groupId))
                DispatchQueue.main.async {
                    AppUtility.showToast("已退出群聊")
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("退出失败")
                }
            }
        }
    }

    private func confirmDismissGroup() {
        let alert = UIAlertController(title: "解散群聊", message: "解散后所有成员将被移出，聊天记录将被清空，确定解散？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "解散", style: .destructive) { [weak self] _ in
            self?.dismissGroup()
        })
        present(alert, animated: true)
    }

    private func dismissGroup() {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.dismissGroup(groupId: groupId))
                DispatchQueue.main.async {
                    AppUtility.showToast("群聊已解散")
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("解散失败")
                }
            }
        }
    }

    private func confirmClearHistory() {
        let alert = UIAlertController(title: "清空聊天记录", message: "确定清空此群聊的聊天记录？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            self?.clearChatHistory()
        })
        present(alert, animated: true)
    }

    private func clearChatHistory() {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.clearChatHistory(groupId: groupId))
                DispatchQueue.main.async {
                    AppUtility.showToast("聊天记录已清空")
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("清空失败")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension GroupDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .info: return 2
        case .settings: return 4
        case .manage:
            // 群主/管理员才显示管理功能组
            return (group?.isAdmin ?? false) ? 2 : 0
        case .actions: return 2
        case .bottom: return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sec = Section(rawValue: section) else { return nil }
        switch sec {
        case .info, .settings, .manage, .actions:
            // 空字符串显示间距，nil 不显示
            return ""
        case .bottom:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .info: return ScreenAdapter.scaleH(8)
        case .settings, .manage, .actions:
            return (tableView.numberOfRows(inSection: section) > 0) ? ScreenAdapter.scaleH(8) : 0.01
        case .bottom: return ScreenAdapter.scaleH(24)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sec = Section(rawValue: indexPath.section) else { return UITableViewCell() }

        switch sec {
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.tintColor = .themePrimary
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.detailTextLabel?.font = ScreenAdapter.font(14)
            cell.detailTextLabel?.textColor = .secondaryLabel

            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "我在群里的昵称"
                cell.imageView?.image = UIImage(systemName: "person.text.rectangle")
                cell.detailTextLabel?.text = group?.myNickname ?? ""
            case 1:
                cell.textLabel?.text = "群二维码"
                cell.imageView?.image = UIImage(systemName: "qrcode")
            default: break
            }
            return cell

        case .settings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! GroupDetailSwitchCell
            cell.imageView?.tintColor = .themePrimary
            cell.textLabel?.font = ScreenAdapter.font(16)

            switch indexPath.row {
            case 0:
                cell.configure(title: "消息免打扰", icon: "bell.slash", isOn: group?.messageDisturb ?? false)
                cell.switchControl.addTarget(self, action: #selector(toggleMessageDisturb(_:)), for: .valueChanged)
            case 1:
                cell.configure(title: "置顶聊天", icon: "pin.fill", isOn: group?.chatTop ?? false)
                cell.switchControl.addTarget(self, action: #selector(toggleChatTop(_:)), for: .valueChanged)
            case 2:
                cell.configure(title: "保存到通讯录", icon: "person.crop.circle.badge.plus", isOn: group?.savedToContacts ?? false)
                cell.switchControl.addTarget(self, action: #selector(toggleSaveToContacts(_:)), for: .valueChanged)
            case 3:
                cell.configure(title: "显示群昵称", icon: "text.bubble", isOn: group?.showGroupNickname ?? true)
                cell.switchControl.addTarget(self, action: #selector(toggleShowNickname(_:)), for: .valueChanged)
            default: break
            }
            return cell

        case .manage:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.tintColor = .themePrimary
            cell.textLabel?.font = ScreenAdapter.font(16)

            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "群管理员"
                cell.imageView?.image = UIImage(systemName: "person.badge.shield.checkmark")
            case 1:
                cell.textLabel?.text = "入群审核"
                cell.imageView?.image = UIImage(systemName: "checkmark.shield")
                cell.detailTextLabel?.text = (group?.joinApproval ?? false) ? "已开启" : "已关闭"
                cell.detailTextLabel?.font = ScreenAdapter.font(14)
                cell.detailTextLabel?.textColor = .secondaryLabel
            default: break
            }
            return cell

        case .actions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.tintColor = .themePrimary
            cell.textLabel?.font = ScreenAdapter.font(16)

            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "查找聊天内容"
                cell.imageView?.image = UIImage(systemName: "magnifyingglass")
            case 1:
                cell.textLabel?.text = "清空聊天记录"
                cell.imageView?.image = UIImage(systemName: "trash")
            default: break
            }
            return cell

        case .bottom:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            cell.accessoryType = .none
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.imageView?.image = nil

            if group?.isOwner ?? false {
                cell.textLabel?.text = "解散群聊"
                cell.textLabel?.textColor = .systemRed
            } else {
                cell.textLabel?.text = "退出群聊"
                cell.textLabel?.textColor = .systemRed
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sec = Section(rawValue: indexPath.section) else { return }

        switch sec {
        case .info:
            switch indexPath.row {
            case 0:
                // 我在群里的昵称
                let vc = EditMyNicknameViewController(groupId: groupId, currentNickname: group?.myNickname ?? "")
                vc.onNicknameUpdated = { [weak self] nickname in
                    self?.group?.myNickname = nickname
                    self?.tableView.reloadData()
                }
                navigationController?.pushViewController(vc, animated: true)
            case 1:
                // 群二维码
                let vc = GroupQRCodeViewController(groupId: groupId, groupName: group?.name ?? "群聊")
                navigationController?.pushViewController(vc, animated: true)
            default: break
            }

        case .settings:
            break // 开关操作已处理

        case .manage:
            switch indexPath.row {
            case 0:
                // 群管理员
                let vc = GroupAdminsViewController(groupId: groupId)
                navigationController?.pushViewController(vc, animated: true)
            case 1:
                // 入群审核 - 跳转到群管理页面对应位置
                let vc = GroupManageViewController(groupId: groupId)
                navigationController?.pushViewController(vc, animated: true)
            default: break
            }

        case .actions:
            switch indexPath.row {
            case 0:
                // 查找聊天内容
                let vc = SearchAllViewController()
                navigationController?.pushViewController(vc, animated: true)
            case 1:
                // 清空聊天记录
                confirmClearHistory()
            default: break
            }

        case .bottom:
            if group?.isOwner ?? false {
                confirmDismissGroup()
            } else {
                confirmLeaveGroup()
            }
        }
    }
}

// MARK: - 带开关的 Cell
class GroupDetailSwitchCell: UITableViewCell {

    let switchControl = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        switchControl.onTintColor = .themePrimary
        accessoryView = switchControl
    }

    func configure(title: String, icon: String, isOn: Bool) {
        textLabel?.text = title
        imageView?.image = UIImage(systemName: icon)
        switchControl.isOn = isOn
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        switchControl.removeTarget(nil, action: nil, for: .allEvents)
    }
}

// MARK: - 编辑我在群里的昵称
class EditMyNicknameViewController: UIViewController {

    private let groupId: String
    private var currentNickname: String
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)

    var onNicknameUpdated: ((String) -> Void)?

    init(groupId: String, currentNickname: String) {
        self.groupId = groupId
        self.currentNickname = currentNickname
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "我在群里的昵称"
        view.backgroundColor = .themeBackground

        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(10)

        textField.placeholder = "请输入昵称"
        textField.borderStyle = .none
        textField.font = ScreenAdapter.font(16)
        textField.text = currentNickname
        textField.clearButtonMode = .whileEditing

        cardView.addSubview(textField)
        view.addSubview(cardView)

        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = ScreenAdapter.font(17)
        saveButton.backgroundColor = .themePrimary
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        view.addSubview(saveButton)

        cardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }

        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(ScreenAdapter.scaleH(32))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
    }

    @objc private func save() {
        let nickname = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !nickname.isEmpty else {
            AppUtility.showToast("请输入昵称")
            return
        }

        saveButton.isEnabled = false
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.updateMyNicknameInGroup(groupId: groupId, nickname: nickname))
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.saveButton.isEnabled = true
                    AppUtility.showToast("已保存")
                    self.onNicknameUpdated?(nickname)
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.saveButton.isEnabled = true
                    AppUtility.showToast("保存失败")
                }
            }
        }
    }
}

// MARK: - 群管理员列表
class GroupAdminsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let groupId: String
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var admins: [GroupMember] = []
    private var owner: GroupMember?

    init(groupId: String) {
        self.groupId = groupId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAdmins()
    }

    private func setupUI() {
        title = "群管理员"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "AdminCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 添加管理员按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addAdmin)
        )
        navigationItem.rightBarButtonItem?.tintColor = .themePrimary
    }

    private func loadAdmins() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.getGroupAdmins(groupId: groupId))
                if let data = response["data"] as? [[String: Any]] {
                    var list: [GroupMember] = []
                    var ownerMember: GroupMember?
                    for dict in data {
                        let uid = dict["uid"] as? String ?? ""
                        let name = dict["name"] as? String ?? ""
                        let avatar = dict["avatar"] as? String
                        let role = dict["role"] as? Int ?? 0
                        let member = GroupMember(uid: uid, name: name, avatar: avatar, role: role, nickname: nil, joinTime: nil, isMuted: nil)
                        if role == 1 {
                            ownerMember = member
                        } else {
                            list.append(member)
                        }
                    }
                    DispatchQueue.main.async {
                        self.owner = ownerMember
                        self.admins = list
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

    @objc private func addAdmin() {
        let vc = ChooseContactsViewController()
        vc.onContactsSelected = { [weak self] (uids: [String]) in
            guard let self = self, let uid = uids.first else { return }
            self.addAdminAction(uid: uid)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func addAdminAction(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.addGroupAdmin(groupId: groupId, uid: uid))
                DispatchQueue.main.async {
                    AppUtility.showToast("已添加管理员")
                    self.loadAdmins()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("添加失败")
                }
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return owner != nil ? 1 : 0
        }
        return max(admins.count, 1)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return owner != nil ? "群主" : nil
        }
        return "管理员"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AdminCell", for: indexPath) as! GroupMemberCell

        if indexPath.section == 0 {
            if let owner = owner {
                cell.configure(with: owner)
                cell.accessoryType = .none
            }
        } else {
            if admins.isEmpty {
                cell.textLabel?.text = "暂无管理员"
                cell.textLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .center
                cell.imageView?.image = nil
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                let admin = admins[indexPath.row]
                cell.configure(with: admin)
                cell.accessoryType = .none
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1, !admins.isEmpty else { return }
        // 移除管理员
        let admin = admins[indexPath.row]
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "移除管理员", style: .destructive) { [weak self] _ in
            self?.removeAdmin(uid: admin.uid)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func removeAdmin(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.removeGroupAdmin(groupId: groupId, uid: uid))
                DispatchQueue.main.async {
                    AppUtility.showToast("已移除管理员")
                    self.loadAdmins()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("移除失败")
                }
            }
        }
    }
}

// MARK: - 群成员 Cell
class GroupMemberCell: UITableViewCell {

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let avatarSize = ScreenAdapter.scaleW(40)
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .systemGray6

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label

        roleLabel.font = ScreenAdapter.font(12)
        roleLabel.textColor = .themePrimary
        roleLabel.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.1)
        roleLabel.layer.cornerRadius = ScreenAdapter.scaleW(4)
        roleLabel.layer.masksToBounds = true
        roleLabel.textAlignment = .center
        roleLabel.isHidden = true

        contentView.addSubviews(avatarImageView, nameLabel, roleLabel)

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
        }

        roleLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.centerY.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(18))
            make.width.equalTo(ScreenAdapter.scaleW(48))
        }
    }

    func configure(with member: GroupMember) {
        nameLabel.text = member.name
        if let url = member.avatarURL {
            avatarImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemGray4
        }

        if let role = member.role, role > 0 {
            roleLabel.isHidden = false
            roleLabel.text = member.roleText
            roleLabel.textColor = member.roleColor
            roleLabel.backgroundColor = member.roleColor.withAlphaComponent(0.1)
        } else {
            roleLabel.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        roleLabel.isHidden = true
        textLabel?.text = nil
        textLabel?.textColor = .label
        textLabel?.textAlignment = .left
        imageView?.image = nil
        selectionStyle = .default
    }
}
