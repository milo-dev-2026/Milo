import UIKit
import SnapKit
import Kingfisher

/// 聊天信息页（现代 iOS 卡片风格）
class ChatPersonalViewController: UIViewController {

    private let channelId: String
    private var chatTitle: String
    private let channelType: Int
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // 开关状态
    private var muteOn = false
    private var topOn = false

    private enum Section: Int, CaseIterable {
        case settings = 0
        case actions = 1
        case bottom = 2
    }

    init(channelId: String, title: String, channelType: Int = 1) {
        self.channelId = channelId
        self.chatTitle = title
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadChannelInfo()
        loadLocalSettings()
    }

    private func loadLocalSettings() {
        let defaults = UserDefaults.standard
        muteOn = defaults.bool(forKey: "chat_mute_\(channelId)")
        topOn = defaults.bool(forKey: "chat_top_\(channelId)")
        tableView.reloadData()
    }

    private func setupUI() {
        title = "聊天信息"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatInfoSwitchCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(ChatInfoCell.self, forCellReuseIdentifier: "InfoCell")
        tableView.rowHeight = 52
        tableView.tableHeaderView = createHeaderView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 0)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Header（头像 + 昵称 + 语音/视频快捷操作）
    private let headerAvatar = UIImageView()
    private let headerName = UILabel()
    private let headerSub = UILabel()

    private func createHeaderView() -> UIView {
        let width = ScreenAdapter.screenWidth
        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 196))

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 16
        card.isUserInteractionEnabled = true
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapHeader)))
        header.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(108)
        }

        headerAvatar.layer.cornerRadius = 16
        headerAvatar.clipsToBounds = true
        headerAvatar.contentMode = .scaleAspectFill
        headerAvatar.backgroundColor = .tertiarySystemFill
        card.addSubview(headerAvatar)
        headerAvatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(60)
        }

        headerName.font = ScreenAdapter.boldFont(19)
        headerName.textColor = .label
        headerName.text = chatTitle
        headerName.lineBreakMode = .byTruncatingTail
        card.addSubview(headerName)
        headerName.snp.makeConstraints { make in
            make.leading.equalTo(headerAvatar.snp.trailing).offset(14)
            make.top.equalTo(headerAvatar.snp.top).offset(6)
            make.trailing.lessThanOrEqualToSuperview().offset(-40)
        }

        headerSub.font = ScreenAdapter.font(13)
        headerSub.textColor = .secondaryLabel
        headerSub.text = "Milo号：\(channelId)"
        headerSub.lineBreakMode = .byTruncatingMiddle
        card.addSubview(headerSub)
        headerSub.snp.makeConstraints { make in
            make.leading.equalTo(headerName)
            make.top.equalTo(headerName.snp.bottom).offset(6)
            make.trailing.lessThanOrEqualToSuperview().offset(-40)
        }

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right",
                                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        arrow.tintColor = .tertiaryLabel
        card.addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        AppUtility.loadChannelAvatar(channelId: channelId, channelType: 1, name: chatTitle, into: headerAvatar)

        // 快捷操作：语音通话 / 视频通话
        let callRow = UIStackView()
        callRow.axis = .horizontal
        callRow.distribution = .fillEqually
        callRow.spacing = 12
        header.addSubview(callRow)
        callRow.snp.makeConstraints { make in
            make.top.equalTo(card.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(52)
        }
        callRow.addArrangedSubview(makeActionButton(title: "语音通话", icon: "phone.fill", action: #selector(voiceCallTapped)))
        callRow.addArrangedSubview(makeActionButton(title: "视频通话", icon: "video.fill", action: #selector(videoCallTapped)))

        return header
    }

    private func makeActionButton(title: String, icon: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        config.imagePadding = 6
        config.baseBackgroundColor = .secondarySystemGroupedBackground
        config.baseForegroundColor = .themePrimary
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ScreenAdapter.mediumFont(15)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func voiceCallTapped() {
        startCall(voice: true)
    }

    @objc private func videoCallTapped() {
        startCall(voice: false)
    }

    private func startCall(voice: Bool) {
        let vc = TRTCCallViewController(channelId: channelId)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    // MARK: - Load Data
    private func loadChannelInfo() {
        Task {
            do {
                let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: channelId, channelType: 1)
                )
                DispatchQueue.main.async {
                    if !info.displayName.isEmpty {
                        self.chatTitle = info.displayName
                        self.headerName.text = info.displayName
                    }
                    AppUtility.loadChannelAvatar(channelId: self.channelId, channelType: 1, name: self.chatTitle, into: self.headerAvatar)
                }
            } catch {
                // 静默失败，保留传入的标题
            }
        }
    }

    @objc private func didTapHeader() {
        let vc = ContactDetailViewController(uid: channelId)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Switch Actions
    private func updateSetting(key: String, value: Bool, sender: UISwitch, successMessage: String, applyLocal: ((Bool) -> Void)? = nil) {
        applyLocal?(value)
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.updateUserSetting(key: key, value: value ? 1 : 0))
                DispatchQueue.main.async {
                    AppUtility.showToast(successMessage)
                }
            } catch {
                DispatchQueue.main.async {
                    sender.isOn = !value
                    applyLocal?(!value)
                    AppUtility.showToast("设置失败")
                }
            }
        }
    }

    @objc private func toggleMute(_ sender: UISwitch) {
        updateSetting(key: "mute", value: sender.isOn, sender: sender,
                      successMessage: sender.isOn ? "已开启消息免打扰" : "已关闭消息免打扰") { [weak self] v in
            guard let self = self else { return }
            self.muteOn = v
            UserDefaults.standard.set(v, forKey: "chat_mute_\(self.channelId)")
            IMManager.shared.setChannelMute(channelId: self.channelId, channelType: self.channelType, mute: v)
        }
    }

    @objc private func toggleTop(_ sender: UISwitch) {
        updateSetting(key: "top", value: sender.isOn, sender: sender,
                      successMessage: sender.isOn ? "已置顶" : "已取消置顶") { [weak self] v in
            guard let self = self else { return }
            self.topOn = v
            UserDefaults.standard.set(v, forKey: "chat_top_\(self.channelId)")
            IMManager.shared.setChannelStick(channelId: self.channelId, channelType: self.channelType, stick: v)
        }
    }

    // MARK: - 清空聊天记录
    private func confirmClearHistory() {
        let alert = UIAlertController(title: "清空聊天记录",
                                      message: "确定清空与 \(chatTitle) 的聊天记录？",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            self?.clearChatHistory()
        })
        present(alert, animated: true)
    }

    private func clearChatHistory() {
        IMManager.shared.clearMessages(channelId: channelId, channelType: channelType)
        AppUtility.showToast("已清空")
    }

    // MARK: - 添加群成员
    private func addGroupMembers() {
        let vc = ChooseContactsViewController(maxSelection: 99)
        vc.title = "选择联系人"
        vc.onContactsSelected = { [weak self] uids in
            self?.createGroup(with: uids)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func createGroup(with uids: [String]) {
        guard !uids.isEmpty else { return }
        var memberUids = uids
        if !memberUids.contains(channelId) {
            memberUids.append(channelId)
        }
        AppUtility.showToast("正在创建群聊...")
        Task {
            do {
                let groupId = "group_\(Int(Date().timeIntervalSince1970))"
                let response = try await APIClient.shared.requestRaw(.addGroupMembers(groupId: groupId, uids: memberUids))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        AppUtility.showToast("群聊创建成功")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("创建群聊失败")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatPersonalViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .settings: return 2
        case .actions: return 2
        case .bottom: return 1
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .settings: return 8
        case .actions: return 8
        case .bottom: return 24
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let sec = Section(rawValue: indexPath.section) else { return false }
        return sec != .settings
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sec = Section(rawValue: indexPath.section) else { return UITableViewCell() }

        switch sec {
        case .settings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! ChatInfoSwitchCell
            switch indexPath.row {
            case 0:
                cell.configure(title: "消息免打扰", icon: "bell.slash.fill", iconColor: .systemOrange, isOn: muteOn)
                cell.switchControl.addTarget(self, action: #selector(toggleMute(_:)), for: .valueChanged)
            case 1:
                cell.configure(title: "置顶聊天", icon: "pin.fill", iconColor: .systemBlue, isOn: topOn)
                cell.switchControl.addTarget(self, action: #selector(toggleTop(_:)), for: .valueChanged)
            default: break
            }
            return cell

        case .actions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath) as! ChatInfoCell
            if indexPath.row == 0 {
                cell.configure(title: "聊天背景", icon: "photo.fill", iconColor: .systemTeal, showsArrow: true)
            } else {
                cell.configure(title: "清空聊天记录", icon: "trash.fill", iconColor: .systemRed, showsArrow: false)
            }
            return cell

        case .bottom:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath) as! ChatInfoCell
            cell.configure(title: "添加群成员", icon: "person.badge.plus", iconColor: .systemGreen, showsArrow: false, destructive: true)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sec = Section(rawValue: indexPath.section) else { return }

        switch sec {
        case .settings:
            break
        case .actions:
            if indexPath.row == 0 {
                let vc = ChatBackgroundViewController(channelId: channelId, channelType: channelType)
                navigationController?.pushViewController(vc, animated: true)
            } else {
                confirmClearHistory()
            }
        case .bottom:
            addGroupMembers()
        }
    }
}

// MARK: - 带彩色圆角图标的通用 Cell
class ChatInfoCell: UITableViewCell {

    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleText = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground

        iconContainer.layer.cornerRadius = 7
        iconContainer.clipsToBounds = true
        contentView.addSubview(iconContainer)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }

        titleText.font = ScreenAdapter.font(16)
        titleText.textColor = .label
        contentView.addSubview(titleText)
        titleText.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
    }

    func configure(title: String, icon: String, iconColor: UIColor, showsArrow: Bool, destructive: Bool = false) {
        titleText.text = title
        titleText.textColor = destructive ? .systemRed : .label
        iconView.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        iconContainer.backgroundColor = iconColor
        accessoryType = showsArrow ? .disclosureIndicator : .none
    }
}

// MARK: - 带开关的 Cell
class ChatInfoSwitchCell: UITableViewCell {

    let switchControl = UISwitch()

    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleText = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .secondarySystemGroupedBackground
        switchControl.onTintColor = .themePrimary

        iconContainer.layer.cornerRadius = 7
        iconContainer.clipsToBounds = true
        contentView.addSubview(iconContainer)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }

        titleText.font = ScreenAdapter.font(16)
        titleText.textColor = .label
        contentView.addSubview(titleText)
        titleText.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        accessoryView = switchControl
    }

    func configure(title: String, icon: String, iconColor: UIColor, isOn: Bool) {
        titleText.text = title
        iconView.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        iconContainer.backgroundColor = iconColor
        switchControl.isOn = isOn
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        switchControl.removeTarget(nil, action: nil, for: .allEvents)
    }
}
