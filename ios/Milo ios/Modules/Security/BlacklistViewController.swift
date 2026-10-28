import UIKit
import SnapKit

// MARK: - 黑名单（对照 Android 黑名单页）
class BlacklistViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let countLabel = UILabel()
    private let emptyView = UIView()

    private var uids: [String] = []
    private var contactNames: [String: String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "黑名单"
        view.backgroundColor = .themeBackground
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    // MARK: - 数据
    private func loadData() {
        uids = UserDefaults.standard.stringArray(forKey: "blacklist_uids") ?? []

        contactNames = [:]
        if let data = UserDefaults.standard.data(forKey: "contacts_cache_v1"),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            for user in users {
                contactNames[user.uid] = user.name
            }
        }

        countLabel.text = "已屏蔽 \(uids.count) 位用户"
        emptyView.isHidden = !uids.isEmpty
        tableView.reloadData()
    }

    // MARK: - 布局
    private func setupUI() {
        let banner = makeBanner(
            icon: "shield.lefthalf.filled",
            title: "管理已屏蔽的用户",
            desc: "黑名单中的用户无法向你发送消息"
        )
        view.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        countLabel.font = ScreenAdapter.font(13)
        countLabel.textColor = .secondaryLabel
        view.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BlacklistCell.self, forCellReuseIdentifier: "BlacklistCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        setupEmptyView()
    }

    private func setupEmptyView() {
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }

        let titleLabel = UILabel()
        titleLabel.text = "黑名单中暂无用户"
        titleLabel.font = ScreenAdapter.boldFont(17)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        emptyView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let descLabel = UILabel()
        descLabel.text = "被你屏蔽的用户会显示在这里"
        descLabel.font = ScreenAdapter.font(13)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        emptyView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func makeBanner(icon: String, title: String, desc: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 1.0, alpha: 1.0)
        card.layer.cornerRadius = 16

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 24
        iconBg.clipsToBounds = true
        card.addSubview(iconBg)
        iconBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .themePrimary
        iconView.contentMode = .scaleAspectFit
        iconBg.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ScreenAdapter.boldFont(16)
        titleLabel.textColor = .label
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBg.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-20)
        }

        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = ScreenAdapter.font(13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-26)
        }

        return card
    }

    // MARK: - 移除
    private func removeUser(_ uid: String) {
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.removeBlackList(uid: uid))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 {
                        self.uids.removeAll { $0 == uid }
                        UserDefaults.standard.set(self.uids, forKey: "blacklist_uids")
                        self.countLabel.text = "已屏蔽 \(self.uids.count) 位用户"
                        self.emptyView.isHidden = !self.uids.isEmpty
                        self.tableView.reloadData()
                        AppUtility.showToast("已移除")
                    } else {
                        AppUtility.showToast(resp["msg"] as? String ?? "操作失败")
                    }
                }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("操作失败") }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension BlacklistViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uids.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlacklistCell", for: indexPath) as! BlacklistCell
        let uid = uids[indexPath.row]
        let name = contactNames[uid] ?? uid
        cell.configure(uid: uid, name: name) { [weak self] in
            self?.removeUser(uid)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
}

// MARK: - 黑名单行 Cell
private final class BlacklistCell: UITableViewCell {

    private let container = UIView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let removeButton = UIButton(type: .system)
    private var onRemove: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        avatarView.layer.cornerRadius = 8
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        container.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label
        container.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        removeButton.setTitle("移除", for: .normal)
        removeButton.titleLabel?.font = ScreenAdapter.font(13)
        removeButton.setTitleColor(.themePrimary, for: .normal)
        removeButton.backgroundColor = .white
        removeButton.layer.cornerRadius = 14
        removeButton.layer.borderWidth = 1
        removeButton.layer.borderColor = UIColor.themePrimary.cgColor
        removeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        container.addSubview(removeButton)
        removeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
        }

        nameLabel.snp.makeConstraints { make in
            make.trailing.lessThanOrEqualTo(removeButton.snp.leading).offset(-8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(uid: String, name: String, onRemove: @escaping () -> Void) {
        nameLabel.text = name
        self.onRemove = onRemove
        AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: name, into: avatarView)
    }

    @objc private func removeTapped() {
        onRemove?()
    }
}
