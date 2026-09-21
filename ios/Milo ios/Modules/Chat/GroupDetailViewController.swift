import UIKit
import SnapKit
import Kingfisher

class GroupDetailViewController: UIViewController {

    private let groupId: String
    private var group: Group?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

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
        loadGroupInfo()
    }

    private func setupUI() {
        title = "群聊详情"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GroupCell")
        tableView.tableHeaderView = createHeaderView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func createHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: ScreenAdapter.scaleH(100)))
        header.backgroundColor = .systemBackground

        let avatarSize = ScreenAdapter.scaleW(56)
        let avatar = UIImageView()
        avatar.layer.cornerRadius = avatarSize / 2
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.image = UIImage(systemName: "person.3.fill")
        avatar.tintColor = .systemGray5

        let nameLabel = UILabel()
        nameLabel.font = ScreenAdapter.mediumFont(17)

        let memberLabel = UILabel()
        memberLabel.font = ScreenAdapter.font(13)
        memberLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [nameLabel, memberLabel])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(2)

        header.addSubviews(avatar, stack)

        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        stack.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
        }

        headerCache = (avatar, nameLabel, memberLabel)
        return header
    }

    private var headerCache: (avatar: UIImageView, name: UILabel, member: UILabel)?

    private func loadGroupInfo() {
        Task {
            do {
                let response: APIResponse<Group> = try await APIClient.shared.request(.getGroupInfo(groupId: groupId))
                if let data = response.data {
                    group = data
                    DispatchQueue.main.async {
                        self.title = data.name
                        self.headerCache?.name.text = data.name
                        if let count = data.memberCount {
                            self.headerCache?.member.text = "群成员 \(count) 人"
                        }
                        if let url = data.avatar, !url.isEmpty,
                           let avatarURL = URL(string: url.hasPrefix("http") ? url : APIConfig.apiBaseURL + "/" + url) {
                            self.headerCache?.avatar.kf.setImage(with: avatarURL, placeholder: UIImage(systemName: "person.3.fill"))
                        }
                        self.tableView.reloadData()
                    }
                }
            } catch {
                AppUtility.showToast("加载群信息失败")
            }
        }
    }
}

extension GroupDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "群聊信息"
        case 1: return nil
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = .themePrimary
        cell.textLabel?.font = ScreenAdapter.font(16)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "群公告"
            cell.imageView?.image = UIImage(systemName: "megaphone")
            cell.detailTextLabel?.text = group?.notice ?? "暂无"
        case (0, 1):
            cell.textLabel?.text = "群二维码"
            cell.imageView?.image = UIImage(systemName: "qrcode")
        case (0, 2):
            cell.textLabel?.text = "群成员"
            cell.imageView?.image = UIImage(systemName: "person.3")
            if let count = group?.memberCount {
                cell.detailTextLabel?.text = "\(count)"
            }
        case (0, 3):
            cell.textLabel?.text = "禁言管理"
            cell.imageView?.image = UIImage(systemName: "speaker.slash")
        case (1, 0):
            cell.textLabel?.text = "退出群聊"
            cell.textLabel?.textColor = .systemRed
            cell.imageView?.image = UIImage(systemName: "arrow.right.square")
            cell.accessoryType = .none
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let notice = group?.notice ?? ""
            navigationController?.pushViewController(GroupNoticeViewController(groupId: groupId, notice: notice), animated: true)
        case (0, 1):
            navigationController?.pushViewController(GroupQRCodeViewController(groupId: groupId, groupName: group?.name ?? "群聊"), animated: true)
        case (0, 2):
            navigationController?.pushViewController(AllMembersViewController(groupId: groupId), animated: true)
        case (0, 3):
            navigationController?.pushViewController(GroupMuteViewController(groupId: groupId, members: []), animated: true)
        case (1, 0):
            confirmLeaveGroup()
        default:
            break
        }
    }

    private func confirmLeaveGroup() {
        let alert = UIAlertController(title: "退出群聊", message: "确定退出此群聊？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出", style: .destructive) { [weak self] _ in
            AppUtility.showToast("已退出群聊")
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
