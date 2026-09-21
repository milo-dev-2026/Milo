import UIKit
import SnapKit
import Kingfisher

// MARK: - 全部成员列表（分页+搜索）
class GroupMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let groupId: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private var members: [GroupMember] = []
    private var filteredMembers: [GroupMember] = []
    private var currentPage = 1
    private var pageSize = 20
    private var total = 0
    private var isLoading = false
    private var hasMore = true

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
        loadMembers(refresh: true)
    }

    private func setupUI() {
        title = "全部成员"
        view.backgroundColor = .themeBackground

        searchBar.placeholder = "搜索成员"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "MemberCell")
        tableView.backgroundColor = .themeBackground
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(64), bottom: 0, right: 0)

        // 下拉刷新
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.loadMembers(refresh: true)
        })

        // 上拉加载更多
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?.loadMembers(refresh: false)
        })

        view.addSubviews(searchBar, tableView)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 右上角添加/移除按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showMoreOptions)
        )
        navigationItem.rightBarButtonItem?.tintColor = .themePrimary
    }

    @objc private func showMoreOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "添加成员", style: .default) { [weak self] _ in
            self?.addMembers()
        })
        alert.addAction(UIAlertAction(title: "移除成员", style: .default) { [weak self] _ in
            self?.removeMembers()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func addMembers() {
        let vc = AddGroupMembersViewController(groupId: groupId)
        vc.onMembersAdded = { [weak self] in
            self?.loadMembers(refresh: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func removeMembers() {
        let vc = RemoveGroupMembersViewController(groupId: groupId)
        vc.onMembersRemoved = { [weak self] in
            self?.loadMembers(refresh: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func loadMembers(refresh: Bool) {
        guard !isLoading else { return }
        isLoading = true

        if refresh {
            currentPage = 1
            hasMore = true
        }

        let keyword = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let kw = keyword?.isEmpty ?? true ? nil : keyword

        Task {
            do {
                let response: APIResponse<GroupMembersResponse> = try await APIClient.shared.request(
                    .getGroupMembers(groupId: groupId, page: currentPage, size: pageSize, keyword: kw)
                )
                if let data = response.data {
                    DispatchQueue.main.async {
                        if refresh {
                            self.members = data.list
                        } else {
                            self.members.append(contentsOf: data.list)
                        }
                        self.filteredMembers = self.members
                        self.total = data.total
                        self.hasMore = self.members.count < data.total
                        self.currentPage += 1
                        self.tableView.reloadData()
                        self.tableView.mj_header?.endRefreshing()
                        self.tableView.mj_footer?.endRefreshing()
                        if !self.hasMore {
                            self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                        }

                        // 更新标题
                        self.title = "全部成员 (\(data.total))"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.tableView.mj_header?.endRefreshing()
                    self.tableView.mj_footer?.endRefreshing()
                    AppUtility.showToast("加载失败")
                }
            }
            isLoading = false
        }
    }

    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredMembers = members
        } else {
            filteredMembers = members.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        loadMembers(refresh: true)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(filteredMembers.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! GroupMemberCell

        if filteredMembers.isEmpty {
            cell.textLabel?.text = "暂无成员"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            let member = filteredMembers[indexPath.row]
            cell.configure(with: member)
            cell.accessoryType = .disclosureIndicator

            // 加载更多
            if indexPath.row == filteredMembers.count - 1 && hasMore && !isLoading {
                loadMembers(refresh: false)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ScreenAdapter.scaleH(60)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !filteredMembers.isEmpty else { return }
        let member = filteredMembers[indexPath.row]
        navigationController?.pushViewController(ContactDetailViewController(uid: member.uid), animated: true)
    }
}

// MARK: - 添加群成员
class AddGroupMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let groupId: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private var friends: [User] = []
    private var filteredFriends: [User] = []
    private var selectedUids: Set<String> = []

    var onMembersAdded: (() -> Void)?

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
        loadFriends()
    }

    private func setupUI() {
        title = "添加成员"
        view.backgroundColor = .themeBackground

        searchBar.placeholder = "搜索好友"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "AddMemberCell")
        tableView.backgroundColor = .themeBackground
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(64), bottom: 0, right: 0)

        let addBtn = UIButton(type: .system)
        addBtn.setTitle("添加", for: .normal)
        addBtn.titleLabel?.font = ScreenAdapter.font(17)
        addBtn.backgroundColor = .themePrimary
        addBtn.setTitleColor(.white, for: .normal)
        addBtn.layer.cornerRadius = ScreenAdapter.scaleW(10)
        addBtn.addTarget(self, action: #selector(addMembers), for: .touchUpInside)

        view.addSubviews(searchBar, tableView, addBtn)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(addBtn.snp.top).offset(-ScreenAdapter.scaleH(12))
        }

        addBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-ScreenAdapter.scaleH(16))
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }

        updateAddButton()
    }

    private func updateAddButton() {
        if selectedUids.isEmpty {
            navigationItem.title = "添加成员"
        } else {
            navigationItem.title = "添加成员 (\(selectedUids.count))"
        }
    }

    private func loadFriends() {
        Task {
            do {
                let response: APIResponse<[User]> = try await APIClient.shared.request(.getContacts)
                if let data = response.data {
                    DispatchQueue.main.async {
                        self.friends = data
                        self.filteredFriends = data
                        self.tableView.reloadData()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载好友列表失败")
                }
            }
        }
    }

    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredFriends = friends
        } else {
            filteredFriends = friends.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(filteredFriends.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddMemberCell", for: indexPath) as! GroupMemberCell

        if filteredFriends.isEmpty {
            cell.textLabel?.text = "暂无好友"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            let friend = filteredFriends[indexPath.row]
            let member = GroupMember(uid: friend.uid, name: friend.name, avatar: friend.avatar, role: 0, nickname: nil, joinTime: nil, isMuted: nil)
            cell.configure(with: member)
            cell.accessoryType = selectedUids.contains(friend.uid) ? .checkmark : .none
            cell.tintColor = .themePrimary
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !filteredFriends.isEmpty else { return }
        let friend = filteredFriends[indexPath.row]
        if selectedUids.contains(friend.uid) {
            selectedUids.remove(friend.uid)
        } else {
            selectedUids.insert(friend.uid)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updateAddButton()
    }

    @objc private func addMembers() {
        guard !selectedUids.isEmpty else {
            AppUtility.showToast("请选择要添加的成员")
            return
        }

        let uids = Array(selectedUids)
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.addGroupMembers(groupId: groupId, uids: uids))
                DispatchQueue.main.async {
                    AppUtility.showToast("添加成功")
                    self.onMembersAdded?()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("添加失败")
                }
            }
        }
    }
}

// MARK: - 移除群成员（多选）
class RemoveGroupMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let groupId: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private var members: [GroupMember] = []
    private var filteredMembers: [GroupMember] = []
    private var selectedUids: Set<String> = []

    var onMembersRemoved: (() -> Void)?

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
        loadMembers()
    }

    private func setupUI() {
        title = "移除成员"
        view.backgroundColor = .themeBackground

        searchBar.placeholder = "搜索成员"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "RemoveCell")
        tableView.backgroundColor = .themeBackground
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(64), bottom: 0, right: 0)

        let removeBtn = UIButton(type: .system)
        removeBtn.setTitle("移除", for: .normal)
        removeBtn.titleLabel?.font = ScreenAdapter.font(17)
        removeBtn.backgroundColor = .systemRed
        removeBtn.setTitleColor(.white, for: .normal)
        removeBtn.layer.cornerRadius = ScreenAdapter.scaleW(10)
        removeBtn.addTarget(self, action: #selector(removeMembers), for: .touchUpInside)

        view.addSubviews(searchBar, tableView, removeBtn)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(removeBtn.snp.top).offset(-ScreenAdapter.scaleH(12))
        }

        removeBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-ScreenAdapter.scaleH(16))
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }

        updateRemoveButton()
    }

    private func updateRemoveButton() {
        if selectedUids.isEmpty {
            navigationItem.title = "移除成员"
        } else {
            navigationItem.title = "移除成员 (\(selectedUids.count))"
        }
    }

    private func loadMembers() {
        Task {
            do {
                let response: APIResponse<GroupMembersResponse> = try await APIClient.shared.request(
                    .getGroupMembers(groupId: groupId, page: 1, size: 100, keyword: nil)
                )
                if let data = response.data {
                    let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
                    // 过滤掉群主和自己
                    let list = data.list.filter { $0.uid != myUid && $0.role != 1 }
                    DispatchQueue.main.async {
                        self.members = list
                        self.filteredMembers = list
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

    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredMembers = members
        } else {
            filteredMembers = members.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(filteredMembers.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RemoveCell", for: indexPath) as! GroupMemberCell

        if filteredMembers.isEmpty {
            cell.textLabel?.text = "暂无成员"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            let member = filteredMembers[indexPath.row]
            cell.configure(with: member)
            cell.accessoryType = selectedUids.contains(member.uid) ? .checkmark : .none
            cell.tintColor = .themePrimary
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !filteredMembers.isEmpty else { return }
        let member = filteredMembers[indexPath.row]
        if selectedUids.contains(member.uid) {
            selectedUids.remove(member.uid)
        } else {
            selectedUids.insert(member.uid)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updateRemoveButton()
    }

    @objc private func removeMembers() {
        guard !selectedUids.isEmpty else {
            AppUtility.showToast("请选择要移除的成员")
            return
        }

        let alert = UIAlertController(
            title: "移除成员",
            message: "确定移除选中的 \(selectedUids.count) 名成员？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "移除", style: .destructive) { [weak self] _ in
            self?.doRemove()
        })
        present(alert, animated: true)
    }

    private func doRemove() {
        let uids = Array(selectedUids)
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.removeGroupMembers(groupId: groupId, uids: uids))
                DispatchQueue.main.async {
                    AppUtility.showToast("移除成功")
                    self.onMembersRemoved?()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("移除失败")
                }
            }
        }
    }
}

// MARK: - 禁言成员列表
class ForbiddenMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let groupId: String
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var members: [GroupMember] = []

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
        loadMutedMembers()
    }

    private func setupUI() {
        title = "禁言成员"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "ForbiddenCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "添加",
            style: .plain,
            target: self,
            action: #selector(addMutedMember)
        )
        navigationItem.rightBarButtonItem?.tintColor = .themePrimary
    }

    private func loadMutedMembers() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.getMutedMembers(groupId: groupId))
                if let data = response["data"] as? [[String: Any]] {
                    let list = data.compactMap { dict -> GroupMember? in
                        let uid = dict["uid"] as? String ?? ""
                        let name = dict["name"] as? String ?? ""
                        let avatar = dict["avatar"] as? String
                        return GroupMember(uid: uid, name: name, avatar: avatar, role: 0, nickname: nil, joinTime: nil, isMuted: true)
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

    @objc private func addMutedMember() {
        let vc = ChooseContactsViewController()
        vc.onContactsSelected = { [weak self] (uids: [String]) in
            guard let self = self, let uid = uids.first else { return }
            self.muteMember(uid: uid)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func muteMember(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.muteGroupMember(groupId: groupId, uid: uid, muted: true))
                DispatchQueue.main.async {
                    AppUtility.showToast("已禁言")
                    self.loadMutedMembers()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }

    private func unmuteMember(uid: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.muteGroupMember(groupId: groupId, uid: uid, muted: false))
                DispatchQueue.main.async {
                    AppUtility.showToast("已解除禁言")
                    self.loadMutedMembers()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(members.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForbiddenCell", for: indexPath) as! GroupMemberCell

        if members.isEmpty {
            cell.textLabel?.text = "暂无禁言成员"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            let member = members[indexPath.row]
            cell.configure(with: member)
            cell.accessoryType = .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !members.isEmpty else { return }
        let member = members[indexPath.row]
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "解除禁言", style: .default) { [weak self] _ in
            self?.unmuteMember(uid: member.uid)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !members.isEmpty else { return nil }
        let unmute = UIContextualAction(style: .normal, title: "解除") { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            let member = self.members[indexPath.row]
            self.unmuteMember(uid: member.uid)
            completionHandler(true)
        }
        unmute.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [unmute])
    }
}

// MARK: - MJRefresh 简单占位（如项目未引入则使用空实现）
import MJRefresh
