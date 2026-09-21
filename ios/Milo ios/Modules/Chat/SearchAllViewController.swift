import UIKit
import SnapKit
import Kingfisher

class SearchAllViewController: UIViewController {

    private let searchField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var searchResults: [SearchResultItem] = []
    private var searchTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "搜索"
        view.backgroundColor = .themeBackground

        searchField.placeholder = "搜索用户/消息"
        searchField.borderStyle = .roundedRect
        searchField.font = ScreenAdapter.font(16)
        searchField.returnKeyType = .search
        searchField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        searchField.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.titleView = searchField

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func textChanged() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.performSearch()
        }
    }

    private func performSearch() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !keyword.isEmpty else {
            searchResults = []
            tableView.reloadData()
            return
        }

        Task {
            do {
                searchResults = []

                let resp = try await APIClient.shared.requestRaw(.globalSearch(keyword: keyword, page: 1))
                if let data = resp["data"] as? [String: Any] {
                    if let friends = data["friends"] as? [[String: Any]] {
                        for f in friends {
                            searchResults.append(SearchResultItem(
                                type: .user,
                                uid: f["channel_id"] as? String ?? "",
                                name: f["name"] as? String,
                                content: nil
                            ))
                        }
                    }
                    if let groups = data["groups"] as? [[String: Any]] {
                        for g in groups {
                            searchResults.append(SearchResultItem(
                                type: .group,
                                uid: g["channel_id"] as? String ?? "",
                                name: g["name"] as? String,
                                content: nil
                            ))
                        }
                    }
                    if let messages = data["messages"] as? [[String: Any]] {
                        for m in messages {
                            let content = m["content"] as? String ?? ""
                            let channelId = m["channel_id"] as? String ?? ""
                            if !content.isEmpty {
                                searchResults.append(SearchResultItem(
                                    type: .message,
                                    uid: channelId,
                                    name: m["channel_name"] as? String,
                                    content: content
                                ))
                            }
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("搜索失败")
                }
            }
        }
    }
}

struct SearchResultItem {
    enum ItemType { case user, group, message }
    let type: ItemType
    let uid: String
    let name: String?
    let content: String?
}

extension SearchAllViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
        let item = searchResults[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)

        switch item.type {
        case .user:
            cell.textLabel?.text = item.name
            cell.detailTextLabel?.text = "ID: \(item.uid)"
            cell.imageView?.image = UIImage(systemName: "person.circle")
        case .group:
            cell.textLabel?.text = item.name
            cell.detailTextLabel?.text = "群聊"
            cell.imageView?.image = UIImage(systemName: "person.3")
        case .message:
            cell.textLabel?.text = item.content
            cell.detailTextLabel?.text = item.name
            cell.imageView?.image = UIImage(systemName: "bubble.left")
        }
        cell.imageView?.tintColor = .themePrimary
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = searchResults[indexPath.row]
        switch item.type {
        case .user:
            let detailVC = ContactDetailViewController(uid: item.uid)
            navigationController?.pushViewController(detailVC, animated: true)
        case .group:
            let chatVC = ChatViewController(channelId: item.uid, title: item.name ?? "群聊")
            navigationController?.pushViewController(chatVC, animated: true)
        case .message:
            let chatVC = ChatViewController(channelId: item.uid, title: item.name ?? "聊天")
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
}
