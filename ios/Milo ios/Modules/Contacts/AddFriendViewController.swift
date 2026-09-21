import UIKit
import SnapKit
import Kingfisher

class AddFriendViewController: UIViewController {

    private let searchField = UITextField()
    private let searchButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var searchResult: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "添加好友"
        view.backgroundColor = .themeBackground

        searchField.placeholder = "输入用户ID"
        searchField.borderStyle = .roundedRect
        searchField.font = ScreenAdapter.font(16)
        searchField.keyboardType = .asciiCapable

        searchButton.setTitle("搜索", for: .normal)
        searchButton.backgroundColor = .themePrimary
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.titleLabel?.font = ScreenAdapter.mediumFont(15)
        searchButton.layer.cornerRadius = ScreenAdapter.scaleW(6)
        searchButton.addTarget(self, action: #selector(searchUser), for: .touchUpInside)

        let searchStack = UIStackView(arrangedSubviews: [searchField, searchButton])
        searchStack.axis = .horizontal
        searchStack.spacing = ScreenAdapter.scaleW(8)
        searchButton.widthAnchor.constraint(equalToConstant: ScreenAdapter.scaleW(64)).isActive = true

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ResultCell")
        tableView.tableHeaderView = searchStack
        searchStack.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: ScreenAdapter.scaleH(52))
        searchStack.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        searchStack.isLayoutMarginsRelativeArrangement = true

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func searchUser() {
        let uid = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !uid.isEmpty else {
            AppUtility.showToast("请输入用户ID")
            return
        }
        view.endEditing(true)
        Task {
            do {
                let response: APIResponse<User> = try await APIClient.shared.request(.getUserInfo(uid: uid))
                if let user = response.data {
                    searchResult = user
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } else {
                    AppUtility.showToast("用户不存在")
                }
            } catch {
                AppUtility.showToast("搜索失败")
            }
        }
    }
}

extension AddFriendViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResult != nil ? 1 : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        if let user = searchResult {
            cell.textLabel?.text = user.name
            cell.detailTextLabel?.text = "ID: \(user.uid)"
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let user = searchResult else { return }
        let detailVC = ContactDetailViewController(uid: user.uid)
        navigationController?.pushViewController(detailVC, animated: true)
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
                let response = try await APIClient.shared.requestRaw(.acceptFriendApply(uid: apply.uid))
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
