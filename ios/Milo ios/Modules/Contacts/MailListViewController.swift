//
//  MailListViewController.swift
//  Milo
//
//  手机通讯录（对齐 Android MailListActivity）
//  功能：读取手机通讯录、搜索过滤、已注册用户"添加"好友、未注册用户"邀请"短信
//

import UIKit
import SnapKit
import Contacts
import MessageUI

// MARK: - 通讯录联系人模型
struct MailContact {
    let name: String
    let phone: String
    /// 已注册用户的 uid（由服务端匹配返回）
    var uid: String?
    /// 是否已注册（根据 uid 判断）
    var isRegistered: Bool { uid != nil }
}

// MARK: - 手机通讯录控制器
class MailListViewController: UIViewController {

    // MARK: - UI 组件
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - 数据
    private var allContacts: [MailContact] = []
    private var filteredContacts: [MailContact] = []
    private var isSearching = false

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkPermissionAndLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI 设置
    private func setupUI() {
        title = "手机通讯录"
        view.backgroundColor = .themeBackground

        // 返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        // 搜索栏
        searchBar.placeholder = "搜索联系人"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.returnKeyType = .search
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        // 列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MailContactCell.self, forCellReuseIdentifier: "MailContactCell")
        tableView.rowHeight = ScreenAdapter.scaleH(64)
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(72), bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 空列表提示
        emptyLabel.text = "暂无联系人"
        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .themeTextSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 加载指示器
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - 通讯录权限
    private func checkPermissionAndLoad() {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            loadContacts(from: store)
        case .notDetermined:
            loadingIndicator.startAnimating()
            store.requestAccess(for: .contacts) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    if granted {
                        self?.loadContacts(from: store)
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDenied()
        @unknown default:
            showPermissionDenied()
        }
    }

    private func showPermissionDenied() {
        let alert = UIAlertController(
            title: "需要通讯录权限",
            message: "请在系统设置中允许访问通讯录，以便查找已注册的好友",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    // MARK: - 读取通讯录
    private func loadContacts(from store: CNContactStore) {
        loadingIndicator.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keys)

            var contacts: [MailContact] = []
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let name = "\(contact.familyName)\(contact.givenName)"
                        .trimmingCharacters(in: .whitespaces)
                    let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                    if !phone.isEmpty {
                        contacts.append(MailContact(name: name.isEmpty ? phone : name,
                                                    phone: phone,
                                                    uid: nil))
                    }
                }
            } catch {
                print("[MailList] 读取通讯录失败: \(error)")
            }

            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.allContacts = contacts.sorted { $0.name < $1.name }
                self.filteredContacts = self.allContacts
                self.updateEmptyState()
                self.tableView.reloadData()
                // 匹配已注册用户
                self.matchRegisteredContacts()
            }
        }
    }

    /// 调用服务端接口匹配已注册用户（逐个校验）
    private func matchRegisteredContacts() {
        for (index, contact) in allContacts.enumerated() {
            Task {
                do {
                    let resp: SendCodeResponse = try await APIClient.shared.request(
                        .isRegister(phone: contact.phone, email: nil)
                    )
                    if resp.exist == 1 {
                        // 已注册：用 phone 作为 uid 查询通道信息获取真实 uid
                        let channelInfo: ChannelInfo = try await APIClient.shared.requestFlexible(
                            .getChannelInfo(channelId: contact.phone, channelType: 1)
                        )
                        DispatchQueue.main.async {
                            guard index < self.allContacts.count else { return }
                            self.allContacts[index].uid = channelInfo.channel_id ?? contact.phone
                            if self.isSearching, let keyword = self.searchBar.text, !keyword.isEmpty {
                                let lower = keyword.lowercased()
                                self.filteredContacts = self.allContacts.filter {
                                    $0.name.lowercased().contains(lower) || $0.phone.contains(keyword)
                                }
                                self.tableView.reloadData()
                            } else {
                                self.filteredContacts = self.allContacts
                                self.tableView.reloadRows(
                                    at: [IndexPath(row: index, section: 0)],
                                    with: .none
                                )
                            }
                        }
                    }
                } catch {
                    // 单个失败不影响整体
                }
            }
        }
    }

    // MARK: - 搜索过滤
    private func filterContacts(with keyword: String) {
        if keyword.isEmpty {
            filteredContacts = allContacts
            isSearching = false
        } else {
            isSearching = true
            let lower = keyword.lowercased()
            filteredContacts = allContacts.filter {
                $0.name.lowercased().contains(lower) || $0.phone.contains(keyword)
            }
        }
        updateEmptyState()
        tableView.reloadData()
    }

    private func updateEmptyState() {
        let data = isSearching ? filteredContacts : allContacts
        emptyLabel.isHidden = !data.isEmpty
    }

    // MARK: - 按钮事件
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 添加好友
    private func applyFriend(_ contact: MailContact) {
        guard let uid = contact.uid else { return }
        // 弹出备注输入框（对齐 Android 的 showInputDialog）
        let alert = UIAlertController(title: "申请添加好友", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "请输入备注"
        }
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: AppStrings.Common.send, style: .default) { [weak self] _ in
            let remark = alert.textFields?.first?.text ?? ""
            self?.doApplyFriend(uid: uid, remark: remark)
        })
        present(alert, animated: true)
    }

    private func doApplyFriend(uid: String, remark: String) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(
                    .applyFriend(uid: uid, remark: remark)
                )
                DispatchQueue.main.async {
                    if response["status"] as? Int == 200 {
                        AppUtility.showToast("好友申请已发送")
                    } else {
                        AppUtility.showToast(response["msg"] as? String ?? "申请失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("申请失败")
                }
            }
        }
    }

    /// 短信邀请
    private func inviteContact(_ contact: MailContact) {
        guard MFMessageComposeViewController.canSendText() else {
            AppUtility.showToast("设备不支持短信")
            return
        }
        let compose = MFMessageComposeViewController()
        compose.recipients = [contact.phone]
        compose.body = "我正在使用【Milo】app，体验还不错。你也赶快来下载玩玩吧！"
        compose.messageComposeDelegate = self
        present(compose, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension MailListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredContacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailContactCell", for: indexPath) as! MailContactCell
        let contact = filteredContacts[indexPath.row]
        cell.configure(with: contact)
        cell.onButtonTapped = { [weak self] in
            if contact.isRegistered {
                self?.applyFriend(contact)
            } else {
                self?.inviteContact(contact)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension MailListViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContacts(with: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filterContacts(with: "")
    }
}

// MARK: - MFMessageComposeViewControllerDelegate
extension MailListViewController: MFMessageComposeViewControllerDelegate {

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        if result == .sent {
            AppUtility.showToast("邀请短信已发送")
        }
    }
}

// MARK: - 通讯录联系人 Cell
class MailContactCell: UITableViewCell {

    var onButtonTapped: (() -> Void)?

    private let avatarContainer = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let phoneLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onButtonTapped = nil
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite

        // 头像容器（首字符）
        avatarContainer.layer.cornerRadius = ScreenAdapter.scaleW(22)
        avatarContainer.clipsToBounds = true
        avatarContainer.backgroundColor = .themeColorPrimaryLight

        avatarLabel.font = ScreenAdapter.boldFont(18)
        avatarLabel.textColor = .themePrimary
        avatarLabel.textAlignment = .center
        avatarContainer.addSubview(avatarLabel)

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label

        phoneLabel.font = ScreenAdapter.font(13)
        phoneLabel.textColor = .themeTextSecondary

        actionButton.titleLabel?.font = ScreenAdapter.font(13)
        actionButton.layer.cornerRadius = ScreenAdapter.scaleW(14)
        actionButton.clipsToBounds = true
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, phoneLabel])
        textStack.axis = .vertical
        textStack.spacing = ScreenAdapter.scaleH(2)

        contentView.addSubviews(avatarContainer, textStack, actionButton)

        avatarContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }
        avatarLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarContainer.snp.trailing).offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-ScreenAdapter.scaleW(8))
        }

        actionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.equalTo(ScreenAdapter.scaleW(56))
            make.height.equalTo(ScreenAdapter.scaleH(28))
        }
    }

    // MARK: - 配置
    func configure(with contact: MailContact) {
        nameLabel.text = contact.name
        phoneLabel.text = contact.phone

        // 头像：取姓名首字符
        avatarLabel.text = String(contact.name.prefix(1))

        if contact.isRegistered {
            actionButton.setTitle("添加", for: .normal)
            actionButton.backgroundColor = .themePrimary
            actionButton.setTitleColor(.white, for: .normal)
        } else {
            actionButton.setTitle("邀请", for: .normal)
            actionButton.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
            actionButton.setTitleColor(.black, for: .normal)
        }
    }

    @objc private func buttonTapped() {
        onButtonTapped?()
    }
}
