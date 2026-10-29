import UIKit
import SnapKit
import Kingfisher

// MARK: - Tap Helper
private class TapActionWrapper: NSObject {
    let action: () -> Void
    init(action: @escaping () -> Void) { self.action = action }
    @objc func performAction() { action() }
}

private var actionWrapperKey: UInt8 = 0

// MARK: - 联系人详情
class ContactDetailViewController: UIViewController {

    private let uid: String
    private let source: String?
    private var userInfo: ChannelInfo?
    private var remarkTopToIdConstraint: Constraint?
    private var remarkTopToNameConstraint: Constraint?

    // MARK: - 顶部用户信息
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerCard = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let idLabel = UILabel()
    private let remarkLabel = UILabel()

    // MARK: - 信息区
    private let infoCard = UIView()

    // MARK: - 按钮区
    private let sendMsgButton = UIButton(type: .system)
    private let audioCallButton = UIButton(type: .system)

    init(uid: String, source: String? = nil) {
        self.uid = uid
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        prefillFromLocalCache()
        loadUserInfo()
    }

    /// 先用通讯录本地缓存秒显昵称与头像，再异步拉取频道信息刷新
    private func prefillFromLocalCache() {
        // 与 ContactsViewController.contactsCacheKey 一致
        guard let data = UserDefaults.standard.data(forKey: "contacts_cache_v1"),
              let cached = try? JSONDecoder().decode([User].self, from: data),
              let user = cached.first(where: { $0.uid == uid }) else { return }
        nameLabel.text = user.name
        AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: user.name, into: avatarImageView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        title = "个人信息"

        // 导航栏返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        // ScrollView
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // MARK: - 顶部用户卡片
        headerCard.backgroundColor = .white
        headerCard.layer.cornerRadius = 12
        headerCard.clipsToBounds = true
        contentView.addSubview(headerCard)
        headerCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 头像
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemGray5
        headerCard.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(80)
        }
        // 保证卡片高度不小于头像区域（Milo号隐藏时不塌陷）
        headerCard.snp.makeConstraints { make in
            make.bottom.greaterThanOrEqualTo(avatarImageView.snp.bottom).offset(20)
        }

        // 名字
        nameLabel.font = ScreenAdapter.boldFont(20)
        nameLabel.textColor = .label
        nameLabel.text = "加载中..."
        headerCard.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.top.equalTo(avatarImageView.snp.top).offset(8)
            make.trailing.equalToSuperview().offset(-16)
        }

        // Milo号（无 short_no 时隐藏该行）
        idLabel.font = ScreenAdapter.font(13)
        idLabel.textColor = .secondaryLabel
        idLabel.isHidden = true
        headerCard.addSubview(idLabel)
        idLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 备注
        remarkLabel.font = ScreenAdapter.font(13)
        remarkLabel.textColor = .secondaryLabel
        remarkLabel.numberOfLines = 0
        headerCard.addSubview(remarkLabel)
        remarkLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            remarkTopToIdConstraint = make.top.equalTo(idLabel.snp.bottom).offset(4).constraint
            remarkTopToNameConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(6).constraint
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-20)
        }
        // 默认无 Milo 号时，备注直接跟在昵称下方
        remarkTopToNameConstraint?.isActive = true
        remarkTopToIdConstraint?.isActive = false

        // MARK: - 信息区（设置备注等）
        infoCard.backgroundColor = .white
        infoCard.layer.cornerRadius = 12
        infoCard.clipsToBounds = true
        contentView.addSubview(infoCard)
        infoCard.snp.makeConstraints { make in
            make.top.equalTo(headerCard.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        addInfoRow(to: infoCard, title: "设置备注和标签", showArrow: true, isLast: true) { [weak self] in
            self?.showRemarkEditor()
        }

        // MARK: - 操作按钮区
        let buttonsStack = UIStackView()
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually
        buttonsStack.spacing = 12
        buttonsStack.backgroundColor = .white
        buttonsStack.layer.cornerRadius = 12
        buttonsStack.clipsToBounds = true
        buttonsStack.isLayoutMarginsRelativeArrangement = true
        buttonsStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentView.addSubview(buttonsStack)
        buttonsStack.snp.makeConstraints { make in
            make.top.equalTo(infoCard.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 发消息
        sendMsgButton.setImage(UIImage(systemName: "message.fill"), for: .normal)
        sendMsgButton.setTitle("  发消息", for: .normal)
        sendMsgButton.tintColor = .themePrimary
        sendMsgButton.setTitleColor(.themePrimary, for: .normal)
        sendMsgButton.titleLabel?.font = ScreenAdapter.font(14)
        sendMsgButton.addTarget(self, action: #selector(sendMessageTapped), for: .touchUpInside)
        buttonsStack.addArrangedSubview(sendMsgButton)

        // 语音通话
        audioCallButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        audioCallButton.setTitle("  语音", for: .normal)
        audioCallButton.tintColor = .themePrimary
        audioCallButton.setTitleColor(.themePrimary, for: .normal)
        audioCallButton.titleLabel?.font = ScreenAdapter.font(14)
        audioCallButton.addTarget(self, action: #selector(audioCallTapped), for: .touchUpInside)
        buttonsStack.addArrangedSubview(audioCallButton)

        // MARK: - 更多操作区
        let moreCard = UIView()
        moreCard.backgroundColor = .white
        moreCard.layer.cornerRadius = 12
        moreCard.clipsToBounds = true
        contentView.addSubview(moreCard)
        moreCard.snp.makeConstraints { make in
            make.top.equalTo(buttonsStack.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        addInfoRow(to: moreCard, title: "来源", showArrow: false, detailText: source ?? "未知") {
        }
        addInfoRow(to: moreCard, title: "解除好友关系", showArrow: true, isDestructive: true) { [weak self] in
            self?.confirmDeleteFriend()
        }
        addInfoRow(to: moreCard, title: "投诉", showArrow: true) { [weak self] in
            self?.showComplaintEditor()
        }
        addInfoRow(to: moreCard, title: "加入黑名单", showArrow: false, isLast: true, isDestructive: true) { [weak self] in
            self?.showBlockAlert()
        }

        // 底部约束
        contentView.snp.makeConstraints { make in
            make.bottom.equalTo(moreCard.snp.bottom).offset(30)
        }
    }

    private func addInfoRow(to container: UIView, title: String, showArrow: Bool, detailText: String? = nil, isLast: Bool = false, isDestructive: Bool = false, action: @escaping () -> Void) {
        let row = UIView()
        row.backgroundColor = .white
        row.isUserInteractionEnabled = true
        let wrapper = TapActionWrapper(action: action)
        let tap = UITapGestureRecognizer(target: wrapper, action: #selector(TapActionWrapper.performAction))
        objc_setAssociatedObject(row, &actionWrapperKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        row.addGestureRecognizer(tap)
        container.addSubview(row)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ScreenAdapter.font(15)
        titleLabel.textColor = isDestructive ? .systemRed : .label
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        if showArrow {
            let arrowView = UIImageView()
            arrowView.image = UIImage(systemName: "chevron.right")
            arrowView.tintColor = UIColor(white: 0.8, alpha: 1.0)
            arrowView.contentMode = .scaleAspectFit
            row.addSubview(arrowView)
            arrowView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(14)
            }
        } else if let detailText = detailText {
            let valueLabel = UILabel()
            valueLabel.text = detailText
            valueLabel.font = ScreenAdapter.font(14)
            valueLabel.textColor = .secondaryLabel
            valueLabel.textAlignment = .right
            row.addSubview(valueLabel)
            valueLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
            }
        }

        // 找到容器中已有的子视图数量
        let existingRows = container.subviews.filter { $0 is UIView && $0.backgroundColor == .white }
        if existingRows.isEmpty {
            row.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(48)
            }
        } else {
            let lastRow = existingRows.last!
            row.snp.makeConstraints { make in
                make.top.equalTo(lastRow.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(48)
            }

            // 添加分割线
            let line = UIView()
            line.backgroundColor = UIColor(white: 0, alpha: 0.06)
            row.addSubview(line)
            line.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.top.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }

        if isLast {
            row.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
    }

    // MARK: - 加载用户信息
    private func loadUserInfo() {
        Task {
            do {
                let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: uid, channelType: 1)
                )
                self.userInfo = info
                DispatchQueue.main.async {
                    self.nameLabel.text = info.displayName
                    AppUtility.loadChannelAvatar(channelId: self.uid, channelType: 1, name: info.displayName, into: self.avatarImageView)
                    if let remark = info.remark, !remark.isEmpty {
                        self.remarkLabel.text = "备注：\(remark)"
                    } else {
                        self.remarkLabel.text = ""
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载用户信息失败")
                }
            }
        }
        loadMiloNo()
    }

    /// 从 /v1/user/search 读取 short_no（Milo号），无数据时隐藏该行
    private func loadMiloNo() {
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.searchUser(keyword: uid, page: 1, pageSize: 1))
                var payload: [String: Any] = resp
                if let wrapped = resp["data"] as? [String: Any], wrapped["exist"] != nil {
                    payload = wrapped
                }
                let existValue = payload["exist"]
                let exist: Int = (existValue as? Int) ?? Int((existValue as? String) ?? "") ?? 0
                var shortNo = ""
                if exist == 1, let dict = payload["data"] as? [String: Any] {
                    if let s = dict["short_no"] as? String {
                        shortNo = s
                    } else if let n = dict["short_no"] as? Int {
                        shortNo = String(n)
                    }
                }
                DispatchQueue.main.async {
                    self.updateMiloNo(shortNo)
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateMiloNo("")
                }
            }
        }
    }

    private func updateMiloNo(_ shortNo: String) {
        let hasMiloNo = !shortNo.isEmpty
        idLabel.isHidden = !hasMiloNo
        idLabel.text = hasMiloNo ? "Milo号：\(shortNo)" : nil
        remarkTopToIdConstraint?.isActive = hasMiloNo
        remarkTopToNameConstraint?.isActive = !hasMiloNo
    }

    // MARK: - 按钮操作
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - 显示备注编辑
    private func showRemarkEditor() {
        let alert = UIAlertController(title: "设置备注", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "请输入备注名"
            textField.text = self.userInfo?.remark ?? ""
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let self = self, let remark = alert.textFields?.first?.text else { return }
            self.saveRemark(remark)
        })
        present(alert, animated: true)
    }

    private func saveRemark(_ remark: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.updateFriendRemark(uid: uid, remark: remark))
                DispatchQueue.main.async {
                    AppUtility.showToast("备注已保存")
                    self.userInfo?.remark = remark
                    self.remarkLabel.text = remark.isEmpty ? "" : "备注：\(remark)"
                    // 刷新通讯录缓存
                    NotificationCenter.default.post(name: NSNotification.Name("ContactsSynced"), object: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("保存备注失败")
                }
            }
        }
    }

    // MARK: - 显示投诉编辑（原因选择）
    private func showComplaintEditor() {
        let reasons = ["骚扰/辱骂", "广告/营销", "欺诈/诈骗", "色情/违法", "其他"]
        let alert = UIAlertController(title: "投诉", message: "请选择投诉原因", preferredStyle: .actionSheet)
        for reason in reasons {
            alert.addAction(UIAlertAction(title: reason, style: .default) { [weak self] _ in
                self?.submitComplaint(reason: reason)
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    private func submitComplaint(reason: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.complaint(uid: uid, reason: reason))
                DispatchQueue.main.async {
                    AppUtility.showToast("投诉已提交")
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("投诉提交失败")
                }
            }
        }
    }

    // MARK: - 解除好友关系
    private func confirmDeleteFriend() {
        let alert = UIAlertController(title: "解除好友关系", message: "确认删除该好友？删除后将同时清空聊天记录", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteFriend()
        })
        present(alert, animated: true)
    }

    private func deleteFriend() {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.deleteFriend(uid: uid))
                DispatchQueue.main.async {
                    AppUtility.showToast("已解除好友关系")
                    NotificationCenter.default.post(name: NSNotification.Name("ContactsSynced"), object: nil)
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }

    // MARK: - 加入黑名单
    private func addToBlacklist() {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.addBlackList(uid: uid))
                DispatchQueue.main.async {
                    var uids = UserDefaults.standard.stringArray(forKey: "blacklist_uids") ?? []
                    if !uids.contains(self.uid) {
                        uids.append(self.uid)
                        UserDefaults.standard.set(uids, forKey: "blacklist_uids")
                    }
                    AppUtility.showToast("已加入黑名单")
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }

    @objc private func sendMessageTapped() {
        let chatVC = ChatViewController(channelId: uid, title: userInfo?.displayName ?? uid, channelType: 1)
        // 替换当前控制器
        if var vcs = navigationController?.viewControllers {
            vcs.removeLast()
            vcs.append(chatVC)
            navigationController?.setViewControllers(vcs, animated: true)
        } else {
                    self.hidesBottomBarWhenPushed = true
navigationController?.pushViewController(chatVC, animated: true)
        }
    }

    @objc private func audioCallTapped() {
        AppUtility.showToast("发起语音通话")
    }

    private func showBlockAlert() {
        let alert = UIAlertController(title: "加入黑名单", message: "加入黑名单后将不再接收对方消息", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.addToBlacklist()
        })
        present(alert, animated: true)
    }
}
