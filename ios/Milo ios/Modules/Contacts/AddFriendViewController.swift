import UIKit
import SnapKit
import Kingfisher

// MARK: - 搜索结果模型（后端 /v1/user/search 返回单个用户）
private struct AddFriendSearchResult {
    let uid: String
    let username: String
    let name: String
    let shortNo: String
    let vercode: String

    var displayName: String {
        if !name.isEmpty { return name }
        if !username.isEmpty { return username }
        return uid
    }

    var subTitle: String {
        return shortNo.isEmpty ? "ID: \(uid)" : "Milo号: \(shortNo)"
    }
}

class AddFriendViewController: UIViewController {

    private let searchField = UITextField()
    private let searchButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()
    private var searchResults: [AddFriendSearchResult] = []
    private var addedUids: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "添加好友"
        view.backgroundColor = .themeBg

        searchField.placeholder = "输入用户ID/Milo号/账号"
        searchField.borderStyle = .roundedRect
        searchField.font = ScreenAdapter.font(16)
        searchField.keyboardType = .default
        searchField.autocorrectionType = .no
        searchField.autocapitalizationType = .none
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .whileEditing
        searchField.delegate = self

        searchButton.setTitle("搜索", for: .normal)
        searchButton.backgroundColor = .themeColorPrimary
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.titleLabel?.font = ScreenAdapter.mediumFont(15)
        searchButton.layer.cornerRadius = ScreenAdapter.scaleW(6)
        searchButton.addTarget(self, action: #selector(searchUser), for: .touchUpInside)

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        let searchStack = UIStackView(arrangedSubviews: [searchField, searchButton])
        searchStack.axis = .horizontal
        searchStack.spacing = ScreenAdapter.scaleW(8)
        headerView.addSubview(searchStack)
        searchStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
        searchButton.snp.makeConstraints { make in
            make.width.equalTo(ScreenAdapter.scaleW(64))
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AddFriendResultCell.self, forCellReuseIdentifier: "ResultCell")
        tableView.rowHeight = 64
        tableView.backgroundColor = .themeBg
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView()

        emptyLabel.text = "未找到该用户"
        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .themeTextSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    @objc private func searchUser() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !keyword.isEmpty else {
            AppUtility.showToast("请输入搜索关键词")
            return
        }
        view.endEditing(true)
        Task {
            do {
                // 后端 /v1/user/search 精确匹配，data 为单个用户对象；make_success 直接返回 {"exist":0/1,"data":...}
                let resp = try await APIClient.shared.requestRaw(.searchUser(keyword: keyword, page: 1, pageSize: 1))
                var payload: [String: Any] = resp
                if let wrapped = resp["data"] as? [String: Any], wrapped["exist"] != nil {
                    payload = wrapped
                }

                var results: [AddFriendSearchResult] = []
                let existValue = payload["exist"]
                let exist: Int = (existValue as? Int) ?? Int((existValue as? String) ?? "") ?? 0
                if exist == 1, let dict = payload["data"] as? [String: Any] {
                    let uid = (dict["uid"] as? String) ?? ""
                    if !uid.isEmpty {
                        let shortNo: String
                        if let s = dict["short_no"] as? String {
                            shortNo = s
                        } else if let n = dict["short_no"] as? Int {
                            shortNo = String(n)
                        } else {
                            shortNo = ""
                        }
                        results.append(AddFriendSearchResult(
                            uid: uid,
                            username: (dict["username"] as? String) ?? "",
                            name: (dict["name"] as? String) ?? "",
                            shortNo: shortNo,
                            vercode: (dict["vercode"] as? String) ?? ""
                        ))
                    }
                }
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.emptyLabel.isHidden = !results.isEmpty
                    self.tableView.reloadData()
                    if results.isEmpty {
                        AppUtility.showToast("未找到该用户")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.searchResults = []
                    self.emptyLabel.isHidden = false
                    self.tableView.reloadData()
                    AppUtility.showToast("搜索失败")
                }
            }
        }
    }

    private func applyFriend(_ user: AddFriendSearchResult) {
        guard !addedUids.contains(user.uid) else { return }
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.applyFriend(uid: user.uid, remark: "", vercode: user.vercode))
                // 后端成功时可能直接返回空对象，无 status 字段也视为成功
                let status = response["status"] as? Int
                if status == nil || status == 200 {
                    DispatchQueue.main.async {
                        self.addedUids.insert(user.uid)
                        self.tableView.reloadData()
                        AppUtility.showToast("已发送好友申请")
                    }
                } else {
                    DispatchQueue.main.async {
                        AppUtility.showToast(response["msg"] as? String ?? "发送申请失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("发送申请失败")
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension AddFriendViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchUser()
        return true
    }
}

// MARK: - UITableViewDataSource & Delegate
extension AddFriendViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! AddFriendResultCell
        let user = searchResults[indexPath.row]
        cell.configure(with: user, added: addedUids.contains(user.uid))
        cell.onAdd = { [weak self] in
            self?.applyFriend(user)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = searchResults[indexPath.row]
        let detailVC = ContactDetailViewController(uid: user.uid, source: "来自搜索")
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - 搜索结果 Cell
private class AddFriendResultCell: UITableViewCell {

    var onAdd: (() -> Void)?

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let subLabel = UILabel()
    private let addButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAdd = nil
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite

        avatarView.layer.cornerRadius = 8
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label

        subLabel.font = ScreenAdapter.font(12)
        subLabel.textColor = .themeTextSecondary

        addButton.titleLabel?.font = ScreenAdapter.font(14)
        addButton.layer.cornerRadius = ScreenAdapter.scaleW(14)
        addButton.clipsToBounds = true
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        contentView.addSubviews(avatarView, textStack, addButton)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(addButton.snp.leading).offset(-8)
        }
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(ScreenAdapter.scaleW(56))
            make.height.equalTo(28)
        }
    }

    func configure(with user: AddFriendSearchResult, added: Bool) {
        nameLabel.text = user.displayName
        subLabel.text = user.subTitle
        AppUtility.loadChannelAvatar(channelId: user.uid, channelType: 1, name: user.displayName, into: avatarView)

        if added {
            addButton.setTitle("已添加", for: .normal)
            addButton.setTitleColor(.themeTextSecondary, for: .normal)
            addButton.backgroundColor = UIColor(white: 0.94, alpha: 1.0)
            addButton.isEnabled = false
        } else {
            addButton.setTitle("添加", for: .normal)
            addButton.setTitleColor(.white, for: .normal)
            addButton.backgroundColor = .themeColorPrimary
            addButton.isEnabled = true
        }
    }

    @objc private func addTapped() {
        onAdd?()
    }
}

class FriendApplyListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var applies: [FriendApply] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func setupUI() {
        title = "好友申请"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ApplyCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadData() {
        Task {
            do {
                let response: APIResponse<[FriendApply]> = try await APIClient.shared.request(.getFriendsApply)
                if let data = response.data {
                    applies = data
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } catch {
                AppUtility.showToast("加载失败")
            }
        }
    }

    private func acceptApply(_ apply: FriendApply) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.acceptFriendApply(token: apply.token ?? ""))
                if response["status"] as? Int == 200 {
                    AppUtility.showToast("已添加好友")
                    loadData()
                }
            } catch {
                AppUtility.showToast("操作失败")
            }
        }
    }
}

extension FriendApplyListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ApplyCell", for: indexPath)
        let apply = applies[indexPath.row]

        cell.textLabel?.text = apply.name
        cell.detailTextLabel?.text = apply.remark ?? ""
        cell.textLabel?.font = ScreenAdapter.font(16)

        if apply.status == 0 {
            let acceptBtn = UIButton(type: .system)
            acceptBtn.setTitle("接受", for: .normal)
            acceptBtn.backgroundColor = .themePrimary
            acceptBtn.setTitleColor(.white, for: .normal)
            acceptBtn.titleLabel?.font = ScreenAdapter.font(14)
            acceptBtn.layer.cornerRadius = ScreenAdapter.scaleW(4)
            acceptBtn.frame = CGRect(x: 0, y: 0, width: ScreenAdapter.scaleW(60), height: ScreenAdapter.scaleH(28))
            acceptBtn.tag = indexPath.row
            acceptBtn.addTarget(self, action: #selector(acceptTapped(_:)), for: .touchUpInside)
            cell.accessoryView = acceptBtn
        } else {
            cell.accessoryView = nil
            cell.textLabel?.textColor = .secondaryLabel
        }
        return cell
    }

    @objc private func acceptTapped(_ sender: UIButton) {
        let apply = applies[sender.tag]
        acceptApply(apply)
    }
}
