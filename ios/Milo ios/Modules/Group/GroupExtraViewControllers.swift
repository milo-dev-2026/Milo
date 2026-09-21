import UIKit
import SnapKit
import Kingfisher

class ContactDetailViewController: UIViewController {

    private let uid: String
    private var user: User?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(uid: String) {
        self.uid = uid
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserInfo()
    }

    private func setupUI() {
        title = "联系人详情"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
        tableView.tableHeaderView = createHeaderView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let chatBtn = UIButton(type: .system)
        chatBtn.setTitle("发消息", for: .normal)
        chatBtn.backgroundColor = .themePrimary
        chatBtn.setTitleColor(.white, for: .normal)
        chatBtn.titleLabel?.font = ScreenAdapter.mediumFont(16)
        chatBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        chatBtn.addTarget(self, action: #selector(startChat), for: .touchUpInside)

        view.addSubview(chatBtn)
        chatBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-ScreenAdapter.scaleH(16))
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ScreenAdapter.scaleH(64), right: 0)
    }

    private func createHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: ScreenAdapter.scaleH(120)))
        header.backgroundColor = .systemBackground

        let avatarSize = ScreenAdapter.scaleW(60)
        let avatar = UIImageView()
        avatar.layer.cornerRadius = avatarSize / 2
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.image = UIImage(systemName: "person.circle.fill")
        avatar.tintColor = .systemGray5

        let nameLabel = UILabel()
        nameLabel.font = ScreenAdapter.mediumFont(18)

        let uidLabel = UILabel()
        uidLabel.font = ScreenAdapter.font(13)
        uidLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [nameLabel, uidLabel])
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

        headerViewCache = (avatar, nameLabel, uidLabel)
        return header
    }

    private var headerViewCache: (avatar: UIImageView, name: UILabel, uid: UILabel)?

    private func loadUserInfo() {
        Task {
            do {
                let response: APIResponse<User> = try await APIClient.shared.request(.getUserInfo(uid: uid))
                if let data = response.data {
                    user = data
                    DispatchQueue.main.async {
                        self.title = data.name
                        self.headerViewCache?.name.text = data.name
                        self.headerViewCache?.uid.text = "ID: \(data.uid)"
                        if let url = data.avatarURL {
                            self.headerViewCache?.avatar.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
                        }
                        self.tableView.reloadData()
                    }
                }
            } catch {
                AppUtility.showToast("加载用户信息失败")
            }
        }
    }

    @objc private func startChat() {
        let name = user?.name ?? uid
        let chatVC = ChatViewController(channelId: uid, title: name)
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension ContactDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = .themePrimary
        cell.textLabel?.font = ScreenAdapter.font(16)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "设置备注"
            cell.imageView?.image = UIImage(systemName: "pencil")
        case 1:
            cell.textLabel?.text = "删除好友"
            cell.imageView?.image = UIImage(systemName: "person.badge.minus")
            cell.textLabel?.textColor = .systemRed
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            showSetRemarkAlert()
        case 1:
            confirmDeleteFriend()
        default:
            break
        }
    }

    private func showSetRemarkAlert() {
        let alert = UIAlertController(title: "设置备注", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "备注名"
            tf.text = self.user?.name ?? ""
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let remark = alert.textFields?.first?.text, !remark.isEmpty else { return }
            self?.setRemark(remark)
        })
        present(alert, animated: true)
    }

    private func setRemark(_ remark: String) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.applyFriend(uid: uid, remark: remark))
                if response["status"] as? Int == 200 {
                    AppUtility.showToast("已设置备注")
                }
            } catch {
                AppUtility.showToast("设置失败")
            }
        }
    }

    private func confirmDeleteFriend() {
        let alert = UIAlertController(title: "删除好友", message: "确定删除该好友？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteFriend()
        })
        present(alert, animated: true)
    }

    private func deleteFriend() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.deleteFriend(uid: uid))
                if response["status"] as? Int == 200 {
                    DispatchQueue.main.async {
                        AppUtility.showToast("已删除好友")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                AppUtility.showToast("删除失败")
            }
        }
    }
}
