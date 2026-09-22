import UIKit
import SnapKit
import Kingfisher

class ChooseContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchField = UITextField()
    private var allContacts: [(uid: String, name: String, avatar: String?)] = []
    private var filteredContacts: [(uid: String, name: String, avatar: String?)] = []
    private var selectedUids: Set<String> = []
    private var maxSelection: Int
    private var onSelected: (([(uid: String, name: String)]) -> Void)?
    var onContactsSelected: (([String]) -> Void)?

    init(maxSelection: Int = 9, onSelected: (([(uid: String, name: String)]) -> Void)? = nil) {
        self.maxSelection = maxSelection
        self.onSelected = onSelected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择联系人"
        view.backgroundColor = .themeBackground

        searchField.placeholder = "搜索联系人"
        searchField.borderStyle = .roundedRect
        searchField.font = ScreenAdapter.font(16)
        searchField.returnKeyType = .search
        searchField.addTarget(self, action: #selector(filterContacts), for: .editingChanged)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChooseContactCell")

        let stack = UIStackView(arrangedSubviews: [searchField, tableView])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(8)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0))
        }
        searchField.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(44))
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(done))
        loadData()
    }

    private func loadData() {
        Task {
            do {
                let friends: [FriendSyncInfo] = try await APIClient.shared.requestFlexible(.syncFriends)
                allContacts = friends.map { ($0.uid, $0.displayName, $0.avatar) }
                filteredContacts = allContacts
                DispatchQueue.main.async { self.tableView.reloadData() }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载联系人失败")
                }
            }
        }
    }

    @objc private func filterContacts() {
        let keyword = (searchField.text ?? "").lowercased()
        if keyword.isEmpty {
            filteredContacts = allContacts
        } else {
            filteredContacts = allContacts.filter { $0.name.lowercased().contains(keyword) }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(filteredContacts.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseContactCell", for: indexPath)
        cell.textLabel?.font = ScreenAdapter.font(16)

        if filteredContacts.isEmpty {
            cell.textLabel?.text = "暂无联系人"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
            cell.imageView?.image = nil
            cell.accessoryType = .none
            return cell
        }

        let c = filteredContacts[indexPath.row]
        cell.textLabel?.text = c.name
        cell.textLabel?.textColor = .label
        cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        cell.imageView?.tintColor = .lightGray

        if let avatarStr = c.avatar, !avatarStr.isEmpty {
            let urlStr = avatarStr.hasPrefix("http") ? avatarStr : APIConfig.apiBaseURL + "/" + avatarStr
            if let url = URL(string: urlStr) {
                cell.imageView?.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
            }
        }

        cell.accessoryType = selectedUids.contains(c.uid) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !filteredContacts.isEmpty else { return }
        let c = filteredContacts[indexPath.row]
        if selectedUids.contains(c.uid) {
            selectedUids.remove(c.uid)
        } else {
            guard selectedUids.count < maxSelection else {
                AppUtility.showToast("最多选择\(maxSelection)位")
                return
            }
            selectedUids.insert(c.uid)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    @objc private func done() {
        let selected = allContacts.filter { selectedUids.contains($0.uid) }.map { (uid: $0.uid, name: $0.name) }
        onSelected?(selected)
        onContactsSelected?(selected.map { $0.uid })
        navigationController?.popViewController(animated: true)
    }
}
