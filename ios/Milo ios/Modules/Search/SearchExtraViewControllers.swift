import UIKit
import SnapKit

// MARK: - 搜索用户
class SearchUserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let searchField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var results: [(uid: String, name: String)] = []
    var searchKeyword: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "搜索用户"
        view.backgroundColor = .themeBackground
        searchField.placeholder = "输入用户ID或昵称"; searchField.borderStyle = .roundedRect; searchField.font = ScreenAdapter.font(16)
        searchField.returnKeyType = .search; searchField.delegate = self
        if !searchKeyword.isEmpty {
            searchField.text = searchKeyword
        }
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SUCell")
        let stack = UIStackView(arrangedSubviews: [searchField, tableView]); stack.axis = .vertical; stack.spacing = 8
        view.addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16)) }
        searchField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(44)) }
        if !searchKeyword.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.performSearch()
            }
        }
    }

    private func performSearch() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !keyword.isEmpty else { return }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.globalSearch(keyword: keyword, page: 1))
                if let data = resp["data"] as? [String: Any], let friends = data["friends"] as? [[String: Any]] {
                    results = friends.map { ($0["channel_id"] as? String ?? "", $0["name"] as? String ?? "") }
                    DispatchQueue.main.async { tableView.reloadData() }
                }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("搜索失败") }
            }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(results.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SUCell", for: indexPath)
        if results.isEmpty { cell.textLabel?.text = "输入关键词搜索"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let r = results[indexPath.row]; cell.textLabel?.text = r.name; cell.imageView?.image = UIImage(systemName: "person.circle.fill"); cell.imageView?.tintColor = .lightGray; cell.accessoryType = .disclosureIndicator }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !results.isEmpty else { return }
        navigationController?.pushViewController(ContactDetailViewController(uid: results[indexPath.row].uid), animated: true)
    }
}
extension SearchUserViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard let keyword = textField.text, !keyword.isEmpty else { return true }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.searchMessages(keyword: keyword))
                if let data = resp["data"] as? [String: Any], let users = data["users"] as? [[String: Any]] {
                    results = users.map { ($0["uid"] as? String ?? "", $0["name"] as? String ?? "") }
                    DispatchQueue.main.async { tableView.reloadData() }
                }
            } catch { }
        }
        return true
    }
}

// MARK: - 搜索会话
class SearchConversationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let searchField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var results: [(channelId: String, name: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "搜索会话"
        view.backgroundColor = .themeBackground
        searchField.placeholder = "搜索会话"; searchField.borderStyle = .roundedRect; searchField.font = ScreenAdapter.font(16); searchField.delegate = self
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SCCell")
        let stack = UIStackView(arrangedSubviews: [searchField, tableView]); stack.axis = .vertical; stack.spacing = 8
        view.addSubview(stack); stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16)) }
        searchField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(44)) }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(results.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SCCell", for: indexPath)
        if results.isEmpty { cell.textLabel?.text = "输入关键词搜索"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let r = results[indexPath.row]; cell.textLabel?.text = r.name; cell.imageView?.image = UIImage(systemName: "bubble.left.fill"); cell.imageView?.tintColor = .themePrimary }
        return cell
    }
}
extension SearchConversationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }
}

// MARK: - 搜索消息结果
class SearchMsgResultViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var keyword: String
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var results: [(messageId: String, content: String, sender: String, time: String)] = []

    init(keyword: String) { self.keyword = keyword; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\"\(keyword)\" 的搜索结果"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SMRCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        search()
    }
    private func search() {
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.searchMessages(keyword: keyword))
                if let data = resp["data"] as? [String: Any], let msgs = data["messages"] as? [[String: Any]] {
                    results = msgs.map { ($0["message_id"] as? String ?? "", $0["content"] as? String ?? "", $0["sender_name"] as? String ?? "", $0["created_at"] as? String ?? "") }
                    DispatchQueue.main.async { tableView.reloadData() }
                }
            } catch { }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(results.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SMRCell", for: indexPath)
        if results.isEmpty { cell.textLabel?.text = "暂无搜索结果"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let r = results[indexPath.row]; cell.textLabel?.text = r.content; cell.detailTextLabel?.text = "\(r.sender)  \(r.time)" }
        return cell
    }
}

// MARK: - 更多搜索
class SearchMoreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "更多搜索"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SMoCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 5 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SMoCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator; cell.imageView?.tintColor = .themePrimary
        switch indexPath.row {
        case 0: cell.textLabel?.text = "按日期搜索"; cell.imageView?.image = UIImage(systemName: "calendar")
        case 1: cell.textLabel?.text = "按发送者搜索"; cell.imageView?.image = UIImage(systemName: "person.magnifyingglass")
        case 2: cell.textLabel?.text = "图片消息历史"; cell.imageView?.image = UIImage(systemName: "photo.on.rectangle")
        case 3: cell.textLabel?.text = "搜索聊天视频"; cell.imageView?.image = UIImage(systemName: "video")
        case 4: cell.textLabel?.text = "搜索全部成员"; cell.imageView?.image = UIImage(systemName: "person.3.sequence")
        default: break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0: navigationController?.pushViewController(ChatWithDateViewController(), animated: true)
        case 1: navigationController?.pushViewController(ChatWithFromUIDViewController(), animated: true)
        case 2: navigationController?.pushViewController(ImageMessageHistoryViewController(), animated: true)
        case 3: navigationController?.pushViewController(SearchChatVideoViewController(), animated: true)
        case 4: navigationController?.pushViewController(SearchAllMembersViewController(), animated: true)
        default: break
        }
    }
}

// MARK: - 搜索聊天视频
class SearchChatVideoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout(); layout.minimumLineSpacing = 4; layout.minimumInteritemSpacing = 4
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 12) / 3, height: (UIScreen.main.bounds.width - 12) / 3)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private var videos: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad(); title = "聊天视频"; view.backgroundColor = .themeBackground
        collectionView.dataSource = self; collectionView.delegate = self
        collectionView.backgroundColor = .themeBackground
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "VideoCell")
        view.addSubview(collectionView); collectionView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { max(videos.count, 1) }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath)
        cell.contentView.backgroundColor = .systemGray5; cell.contentView.layer.cornerRadius = 4
        if !videos.isEmpty {
            let icon = UIImageView(image: UIImage(systemName: "play.circle.fill")); icon.tintColor = .white; icon.contentMode = .center
            cell.contentView.addSubview(icon); icon.snp.makeConstraints { make in make.center.equalToSuperview() }
        }
        return cell
    }
}

// MARK: - 按日期搜消息
class ChatWithDateViewController: UIViewController {
    private let datePicker = UIDatePicker()
    private let searchButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad(); title = "按日期搜索"; view.backgroundColor = .themeBackground
        datePicker.datePickerMode = .date; datePicker.preferredDatePickerStyle = .wheels
        searchButton.setTitle("搜索", for: .normal); searchButton.titleLabel?.font = ScreenAdapter.font(17)
        searchButton.backgroundColor = .themePrimary; searchButton.setTitleColor(.white, for: .normal)
        searchButton.layer.cornerRadius = ScreenAdapter.scaleW(10); searchButton.addTarget(self, action: #selector(search), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [datePicker, searchButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in make.center.equalToSuperview(); make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24) }
        searchButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func search() {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: datePicker.date)
        navigationController?.pushViewController(SearchMsgResultViewController(keyword: dateStr), animated: true)
    }
}

// MARK: - 按发送者搜消息
class ChatWithFromUIDViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var contacts: [(uid: String, name: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad(); title = "按发送者搜索"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CWUCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(contacts.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CWUCell", for: indexPath)
        if contacts.isEmpty { cell.textLabel?.text = "暂无联系人"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let c = contacts[indexPath.row]; cell.textLabel?.text = c.name; cell.imageView?.image = UIImage(systemName: "person.circle.fill"); cell.imageView?.tintColor = .lightGray; cell.accessoryType = .disclosureIndicator }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !contacts.isEmpty else { return }
        navigationController?.pushViewController(SearchMsgResultViewController(keyword: contacts[indexPath.row].name), animated: true)
    }
}

// MARK: - 图片消息历史
class ImageMessageHistoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout(); layout.minimumLineSpacing = 4; layout.minimumInteritemSpacing = 4
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 12) / 3, height: (UIScreen.main.bounds.width - 12) / 3)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private var images: [(url: String, time: String)] = []
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad(); title = "图片历史"; view.backgroundColor = .themeBackground
        collectionView.dataSource = self; collectionView.delegate = self
        collectionView.backgroundColor = .themeBackground
        collectionView.register(ImgHistCell.self, forCellWithReuseIdentifier: "ImgHistCell")
        view.addSubview(collectionView); collectionView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        view.addSubview(activityIndicator); activityIndicator.snp.makeConstraints { make in make.center.equalToSuperview() }
        loadImages()
    }

    private func loadImages() {
        activityIndicator.startAnimating()
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.searchMessages(keyword: "[image]"))
                if let data = resp["data"] as? [String: Any], let msgs = data["messages"] as? [[String: Any]] {
                    images = msgs.compactMap {
                        let content = $0["content"] as? String ?? ""
                        let time = $0["created_at"] as? String ?? ""
                        guard content.hasPrefix("http") || content.contains("/files/") else { return nil }
                        return (content, time)
                    }
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.collectionView.reloadData()
                    }
                } else {
                    DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    AppUtility.showToast("加载失败")
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { max(images.count, 1) }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImgHistCell", for: indexPath) as! ImgHistCell
        if images.isEmpty {
            cell.showEmpty()
        } else {
            cell.configure(url: images[indexPath.item].url)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !images.isEmpty else { return }
        let img = images[indexPath.item]
        let urlStr = img.url.hasPrefix("http") ? img.url : APIConfig.apiBaseURL + "/" + img.url
        let vc = ImagePreviewViewController(url: URL(string: urlStr))
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

private class ImgHistCell: UICollectionViewCell {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.backgroundColor = .systemGray5
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(url: String) {
        let fullUrl = url.hasPrefix("http") ? url : APIConfig.apiBaseURL + "/" + url
        if let u = URL(string: fullUrl) {
            imageView.kf.setImage(with: u, placeholder: UIImage(systemName: "photo"))
            imageView.tintColor = .systemGray3
        }
    }

    func showEmpty() {
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray3
    }
}

// MARK: - 搜索全部成员
class SearchAllMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let searchField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var members: [(uid: String, name: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad(); title = "搜索成员"; view.backgroundColor = .themeBackground
        searchField.placeholder = "搜索成员"; searchField.borderStyle = .roundedRect; searchField.font = ScreenAdapter.font(16); searchField.returnKeyType = .search; searchField.delegate = self
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SAMCell")
        let stack = UIStackView(arrangedSubviews: [searchField, tableView]); stack.axis = .vertical; stack.spacing = 8
        view.addSubview(stack); stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16)) }
        searchField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(44)) }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(members.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SAMCell", for: indexPath)
        if members.isEmpty { cell.textLabel?.text = "输入关键词搜索"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let m = members[indexPath.row]; cell.textLabel?.text = m.name; cell.imageView?.image = UIImage(systemName: "person.circle.fill"); cell.imageView?.tintColor = .lightGray; cell.accessoryType = .disclosureIndicator }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !members.isEmpty else { return }
        navigationController?.pushViewController(ContactDetailViewController(uid: members[indexPath.row].uid), animated: true)
    }
}
extension SearchAllMembersViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard let keyword = textField.text, !keyword.isEmpty else { return true }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.searchMessages(keyword: keyword))
                if let data = resp["data"] as? [String: Any], let users = data["users"] as? [[String: Any]] {
                    members = users.map { ($0["uid"] as? String ?? "", $0["name"] as? String ?? "") }
                    DispatchQueue.main.async { tableView.reloadData() }
                }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("搜索失败") }
            }
        }
        return true
    }
}

// MARK: - 记录搜索
class RecordSearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var records: [(keyword: String, time: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad(); title = "搜索记录"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RSCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "清空", style: .plain, target: self, action: #selector(clearAll))
        loadData()
    }
    private func loadData() {
        records = (UserDefaults.standard.array(forKey: "search_history") as? [[String: String]] ?? []).map { ($0["keyword"] ?? "", $0["time"] ?? "") }
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(records.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RSCell", for: indexPath)
        if records.isEmpty { cell.textLabel?.text = "暂无搜索记录"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let r = records[indexPath.row]; cell.textLabel?.text = r.keyword; cell.detailTextLabel?.text = r.time; cell.imageView?.image = UIImage(systemName: "clock"); cell.imageView?.tintColor = .secondaryLabel }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !records.isEmpty else { return }
        navigationController?.pushViewController(SearchMsgResultViewController(keyword: records[indexPath.row].keyword), animated: true)
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !records.isEmpty else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, c in
            guard let self = self else { c(false); return }
            self.records.remove(at: indexPath.row)
            let data = self.records.map { ["keyword": $0.keyword, "time": $0.time] }
            UserDefaults.standard.set(data, forKey: "search_history")
            tableView.reloadData()
            c(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
    @objc private func clearAll() {
        records.removeAll(); UserDefaults.standard.removeObject(forKey: "search_history"); tableView.reloadData()
    }
}

// MARK: - 消息列表
class MailListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var messages: [(messageId: String, content: String, sender: String, time: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad(); title = "消息列表"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MLCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(messages.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MLCell", for: indexPath)
        if messages.isEmpty { cell.textLabel?.text = "暂无消息"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let m = messages[indexPath.row]; cell.textLabel?.text = m.content; cell.detailTextLabel?.text = "\(m.sender)  \(m.time)" }
        return cell
    }
}
