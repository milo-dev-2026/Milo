import UIKit
import SnapKit
import Kingfisher

// MARK: - 选择视频通话成员
class ChooseVideoCallMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let groupId: String
    private let groupType: Int

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var members: [(uid: String, name: String, avatar: String?, role: Int)] = []
    private var selectedUids: Set<String> = []
    private var maxSelection = 9

    var onSelected: (([String]) -> Void)?

    init(groupId: String, groupType: Int = 2) {
        self.groupId = groupId
        self.groupType = groupType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择成员"
        view.backgroundColor = .themeBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "确定", style: .done, target: self, action: #selector(confirm))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "VCMCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        loadMembers()
    }

    private func loadMembers() {
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.getGroupInfo(groupId: groupId))
                if let data = resp["data"] as? [String: Any], let ms = data["members"] as? [[String: Any]] {
                    let currentUid = UserDefaults.standard.string(forKey: "uid") ?? ""
                    members = ms.compactMap {
                        let uid = $0["uid"] as? String ?? ""
                        guard uid != currentUid else { return nil }
                        return (uid, $0["name"] as? String ?? "", $0["avatar"] as? String, $0["role"] as? Int ?? 0)
                    }
                    DispatchQueue.main.async { self.tableView.reloadData() }
                }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("加载成员失败") }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VCMCell", for: indexPath)
        let m = members[indexPath.row]
        cell.textLabel?.text = m.name
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        cell.imageView?.tintColor = .lightGray
        cell.accessoryType = selectedUids.contains(m.uid) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let m = members[indexPath.row]
        if selectedUids.contains(m.uid) {
            selectedUids.remove(m.uid)
        } else {
            guard selectedUids.count < maxSelection else {
                AppUtility.showToast("最多选择\(maxSelection)人")
                return
            }
            selectedUids.insert(m.uid)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updateConfirmButton()
    }

    private func updateConfirmButton() {
        navigationItem.rightBarButtonItem?.title = selectedUids.isEmpty ? "确定" : "确定(\(selectedUids.count))"
    }

    @objc private func confirm() {
        guard !selectedUids.isEmpty else {
            AppUtility.showToast("请选择成员")
            return
        }
        onSelected?(Array(selectedUids))
        navigationController?.popViewController(animated: true)
    }
}
