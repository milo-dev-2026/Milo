import UIKit
import SnapKit
import Kingfisher

// MARK: - 通讯录
class ContactsViewController: UIViewController {

    private let tableView = UITableView()
    private var contacts: [User] = []
    private var filteredContacts: [User] = []
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    private func setupUI() {
        title = "通讯录"
        view.backgroundColor = .themeBackground

        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "搜索"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "person.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(showAddMenu)
        )
        let scanButton = UIBarButtonItem(
            image: UIImage(systemName: "qrcode.viewfinder"),
            style: .plain,
            target: self,
            action: #selector(startScan)
        )
        let applyButton = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle.badge.questionmark"),
            style: .plain,
            target: self,
            action: #selector(showFriendApplyList)
        )
        navigationItem.rightBarButtonItems = [addButton, scanButton, applyButton]
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = .themePrimary }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.rowHeight = ScreenAdapter.scaleH(56)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func startScan() {
        let scanVC = ScanViewController()
        scanVC.onScanResult = { [weak self] result in
            self?.handleScanResult(result)
        }
        navigationController?.pushViewController(scanVC, animated: true)
    }

    @objc private func showAddMenu() {
        let alert = UIAlertController(title: "添加好友", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "搜索用户ID", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(AddFriendViewController(), animated: true)
        })
        alert.addAction(UIAlertAction(title: "扫一扫", style: .default) { [weak self] _ in
            self?.startScan()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showFriendApplyList() {
        navigationController?.pushViewController(FriendApplyListViewController(), animated: true)
    }

    private func handleScanResult(_ result: String) {
        if result.hasPrefix("uid:") {
            let uid = String(result.dropFirst(4))
            applyFriend(uid: uid)
        } else if result.count > 0 {
            applyFriend(uid: result)
        }
    }

    private func applyFriend(uid: String) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.applyFriend(uid: uid, remark: ""))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        AppUtility.showToast("好友申请已发送")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("发送申请失败")
                }
            }
        }
    }

    private func loadData() {
        Task {
            do {
                let response: APIResponse<[User]> = try await APIClient.shared.request(.getContacts)
                if let data = response.data {
                    contacts = data.sorted { $0.name < $1.name }
                    filteredContacts = contacts
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } catch {
                AppUtility.showToast("加载通讯录失败")
            }
        }
    }

    private var displayContacts: [User] {
        return searchController.isActive ? filteredContacts : contacts
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayContacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        cell.configure(with: displayContacts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = displayContacts[indexPath.row]
        let detailVC = ContactDetailViewController(uid: user.uid)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension ContactsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        filteredContacts = contacts.filter { $0.name.contains(searchText) }
        tableView.reloadData()
    }
}

// MARK: - 联系人Cell
class ContactCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let avatarSize = ScreenAdapter.scaleW(40)
        let hPad = ScreenAdapter.scaleW(12)

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        nameLabel.font = ScreenAdapter.font(15)

        contentView.addSubviews(avatarView, nameLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(hPad)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(hPad)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-hPad)
        }
    }

    func configure(with user: User) {
        nameLabel.text = user.name
        AppUtility.loadAvatar(user.avatarURL, into: avatarView)
    }
}
