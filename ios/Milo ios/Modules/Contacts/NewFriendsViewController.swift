import UIKit
import SnapKit
import Kingfisher

// MARK: - 新的朋友（好友申请列表，对齐Android NewFriendsActivity）
class NewFriendsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var applies: [FriendApply] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        title = "新的朋友"
        view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)

        // 导航栏返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FriendApplyCell.self, forCellReuseIdentifier: "FriendApplyCell")
        tableView.rowHeight = 68
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 空列表提示
        emptyLabel.text = "暂无好友申请"
        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = .themeTextSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func loadData() {
        Task {
            do {
                let list: [FriendApply] = try await APIClient.shared.requestFlexible(.getFriendsApply)
                DispatchQueue.main.async {
                    self.applies = list
                    self.emptyLabel.isHidden = !list.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载失败")
                    self.emptyLabel.isHidden = !self.applies.isEmpty
                }
            }
        }
    }

    private func acceptApply(_ apply: FriendApply) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.acceptFriendApply(token: apply.token ?? ""))
                let status = response["status"] as? Int
                if status == nil || status == 200 {
                    AppUtility.showToast("已同意")
                    loadData()
                } else {
                    AppUtility.showToast(response["msg"] as? String ?? "操作失败")
                }
            } catch {
                AppUtility.showToast("操作失败")
            }
        }
    }

    private func rejectApply(_ apply: FriendApply) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.rejectFriendApply(uid: apply.uid))
                let status = response["status"] as? Int
                if status == nil || status == 200 {
                    AppUtility.showToast("已拒绝")
                    loadData()
                } else {
                    AppUtility.showToast(response["msg"] as? String ?? "操作失败")
                }
            } catch {
                AppUtility.showToast("操作失败")
            }
        }
    }
}

extension NewFriendsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendApplyCell", for: indexPath) as! FriendApplyCell
        let apply = applies[indexPath.row]
        cell.configure(with: apply)
        cell.onAccept = { [weak self] in
            self?.acceptApply(apply)
        }
        cell.onReject = { [weak self] in
            self?.rejectApply(apply)
        }
        cell.onAvatarTap = { [weak self] in
            let detailVC = ContactDetailViewController(uid: apply.uid)
            self?.navigationController?.pushViewController(detailVC, animated: true)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 与Android一致：已同意的申请点击整行进入用户详情
        let apply = applies[indexPath.row]
        if apply.status == 1 {
            let detailVC = ContactDetailViewController(uid: apply.uid)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - 好友申请Cell
class FriendApplyCell: UITableViewCell {

    var onAccept: (() -> Void)?
    var onReject: (() -> Void)?
    var onAvatarTap: (() -> Void)?

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let remarkLabel = UILabel()
    private let statusLabel = UILabel()
    private let acceptButton = UIButton(type: .system)
    private let rejectButton = UIButton(type: .system)
    private let buttonStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAccept = nil
        onReject = nil
        onAvatarTap = nil
    }

    private func setupUI() {
        backgroundColor = .white
        contentView.backgroundColor = .white

        avatarView.layer.cornerRadius = 6
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        nameLabel.font = ScreenAdapter.font(16)
        nameLabel.textColor = .label

        remarkLabel.font = ScreenAdapter.font(12)
        remarkLabel.textColor = UIColor(white: 0.6, alpha: 1.0)

        statusLabel.font = ScreenAdapter.font(14)
        statusLabel.textColor = UIColor(white: 0.6, alpha: 1.0)

        // 同意按钮：主题色背景白字圆角
        acceptButton.setTitle("同意", for: .normal)
        acceptButton.backgroundColor = .themePrimary
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.titleLabel?.font = ScreenAdapter.font(14)
        acceptButton.layer.cornerRadius = ScreenAdapter.scaleW(4)
        acceptButton.clipsToBounds = true
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)

        // 拒绝按钮：灰色背景黑字圆角
        rejectButton.setTitle("拒绝", for: .normal)
        rejectButton.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        rejectButton.setTitleColor(.black, for: .normal)
        rejectButton.titleLabel?.font = ScreenAdapter.font(14)
        rejectButton.layer.cornerRadius = ScreenAdapter.scaleW(4)
        rejectButton.clipsToBounds = true
        rejectButton.addTarget(self, action: #selector(rejectTapped), for: .touchUpInside)

        // 与Android一致：拒绝在左，同意在右
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.addArrangedSubview(rejectButton)
        buttonStack.addArrangedSubview(acceptButton)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, remarkLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        contentView.addSubviews(avatarView, textStack, statusLabel, buttonStack)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(statusLabel.snp.leading).offset(-8)
            make.trailing.lessThanOrEqualTo(buttonStack.snp.leading).offset(-8)
        }

        statusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        buttonStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        acceptButton.snp.makeConstraints { make in
            make.width.equalTo(56)
            make.height.equalTo(30)
        }

        rejectButton.snp.makeConstraints { make in
            make.width.equalTo(56)
            make.height.equalTo(30)
        }
    }

    func configure(with apply: FriendApply) {
        nameLabel.text = apply.name

        let remark = apply.remark ?? ""
        remarkLabel.text = remark
        remarkLabel.isHidden = remark.isEmpty

        AppUtility.loadChannelAvatar(channelId: apply.uid, channelType: 1, name: apply.name, into: avatarView)

        if apply.status == 0 {
            // 等待验证：显示同意/拒绝按钮
            statusLabel.isHidden = true
            buttonStack.isHidden = false
        } else {
            // 已同意/已拒绝：显示状态文字
            statusLabel.isHidden = false
            buttonStack.isHidden = true
            statusLabel.text = apply.status == 1 ? "已同意" : "已拒绝"
        }
    }

    @objc private func acceptTapped() {
        onAccept?()
    }

    @objc private func rejectTapped() {
        onReject?()
    }

    @objc private func avatarTapped() {
        onAvatarTap?()
    }
}
