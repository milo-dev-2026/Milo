//
//  MyInfoViewController.swift
//  Milo
//
//  个人信息页面（对照 Android MyInfoActivity）
//  包含：MyInfoViewController（个人信息主页）、
//        UpdateUserInfoViewController（昵称/Milo号编辑）、
//        MyHeadPortraitViewController（头像查看/更换）、
//        SignEditViewController（签名编辑）
//

import UIKit
import SnapKit
import Kingfisher

// MARK: - 个人信息主页
class MyInfoViewController: UIViewController {

    private enum InfoRow {
        case avatar, name, shortNo, sex, sign, qrcode
    }

    private let sections: [[InfoRow]] = [
        [.avatar, .name, .shortNo],
        [.sex, .sign],
        [.qrcode]
    ]

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // 顶部大卡片
    private let headerView = UIView()
    private let headerCard = UIView()
    private let headerAvatarView = UIImageView()
    private let headerNameLabel = UILabel()
    private let headerIdLabel = UILabel()
    private let headerSexLabel = UILabel()
    private let headerSignLabel = UILabel()

    // 列表头像行的缩略图
    private let avatarThumbView = UIImageView()
    private lazy var avatarAccessoryView: UIView = {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 66, height: 44))
        avatarThumbView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        avatarThumbView.layer.cornerRadius = 6
        avatarThumbView.clipsToBounds = true
        avatarThumbView.contentMode = .scaleAspectFill
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(white: 0.8, alpha: 1.0)
        chevron.contentMode = .scaleAspectFit
        chevron.frame = CGRect(x: 52, y: 15, width: 14, height: 14)
        container.addSubview(avatarThumbView)
        container.addSubview(chevron)
        return container
    }()

    // 本地数据
    private var uid = ""
    private var name = ""
    private var shortNo = ""
    private var sign = ""
    private var sex: Int?

    private var sexText: String {
        guard let sex = sex else { return "保密" }
        switch sex {
        case 1: return "男"
        case 0: return "女"
        default: return "保密"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserInfo()
        setupObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserInfo()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 根据宽度自适应 tableHeaderView 高度
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let size = headerView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if headerView.frame.height != size.height || headerView.frame.width != width {
            headerView.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
            tableView.tableHeaderView = headerView
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleUserInfoUpdated(_:)),
            name: NSNotification.Name("UserInfoUpdated"), object: nil
        )
    }

    @objc private func handleUserInfoUpdated(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadUserInfo()
        }
    }

    // MARK: - 布局
    private func setupUI() {
        title = "个人信息"
        view.backgroundColor = .themeBackground

        tableView.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupHeader()
        tableView.tableHeaderView = headerView
    }

    private func setupHeader() {
        headerCard.backgroundColor = .secondarySystemGroupedBackground
        headerCard.layer.cornerRadius = 12
        headerCard.clipsToBounds = true
        headerView.addSubview(headerCard)
        headerCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-12)
        }

        // 头像（可点击跳转头像查看页）
        headerAvatarView.layer.cornerRadius = 36
        headerAvatarView.clipsToBounds = true
        headerAvatarView.contentMode = .scaleAspectFill
        headerAvatarView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showHeadPortrait))
        headerAvatarView.addGestureRecognizer(tap)
        headerCard.addSubview(headerAvatarView)
        headerAvatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(72)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
        }

        headerNameLabel.font = ScreenAdapter.boldFont(18)
        headerNameLabel.textColor = .label
        headerCard.addSubview(headerNameLabel)
        headerNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(headerAvatarView.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        headerIdLabel.font = ScreenAdapter.font(13)
        headerIdLabel.textColor = .secondaryLabel
        headerCard.addSubview(headerIdLabel)
        headerIdLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(headerNameLabel)
            make.top.equalTo(headerNameLabel.snp.bottom).offset(6)
        }

        headerSexLabel.font = ScreenAdapter.font(13)
        headerSexLabel.textColor = .secondaryLabel
        headerCard.addSubview(headerSexLabel)
        headerSexLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(headerNameLabel)
            make.top.equalTo(headerIdLabel.snp.bottom).offset(6)
        }

        headerSignLabel.font = ScreenAdapter.font(13)
        headerSignLabel.textColor = .secondaryLabel
        headerSignLabel.numberOfLines = 2
        headerCard.addSubview(headerSignLabel)
        headerSignLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(headerNameLabel)
            make.top.equalTo(headerSexLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // MARK: - 加载用户信息
    private func loadUserInfo() {
        let defaults = UserDefaults.standard
        uid = defaults.string(forKey: "uid") ?? ""
        name = defaults.string(forKey: "name") ?? ""
        shortNo = defaults.string(forKey: "short_no") ?? ""
        sign = defaults.string(forKey: "sign") ?? ""
        if let sexValue = defaults.object(forKey: "sex") as? Int {
            sex = sexValue
        } else if let sexStr = defaults.string(forKey: "sex"), let sexValue = Int(sexStr) {
            sex = sexValue
        } else {
            sex = nil
        }

        headerNameLabel.text = name.isEmpty ? "Milo用户" : name
        headerIdLabel.text = "Milo号：\(shortNo.isEmpty ? uid : shortNo)"
        headerSexLabel.text = "性别：\(sexText)"
        headerSignLabel.text = "签名：\(sign)"

        AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: name, into: headerAvatarView)
        AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: name, into: avatarThumbView)

        tableView.reloadData()
    }

    // MARK: - 页面跳转
    @objc private func showHeadPortrait() {
        navigationController?.pushViewController(MyHeadPortraitViewController(), animated: true)
    }

    private func showQRCode() {
        let qrVC = UserQRCodeViewController(uid: uid, name: name)
        navigationController?.pushViewController(qrVC, animated: true)
    }

    // MARK: - 性别选择
    private func showSexPicker(sourceView: UIView) {
        let alert = UIAlertController(title: "性别", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "男", style: .default) { [weak self] _ in
            self?.updateSex(1)
        })
        alert.addAction(UIAlertAction(title: "女", style: .default) { [weak self] _ in
            self?.updateSex(0)
        })
        alert.addAction(UIAlertAction(title: "保密", style: .default) { [weak self] _ in
            self?.updateSex(2)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.popoverPresentationController?.sourceView = sourceView
        alert.popoverPresentationController?.sourceRect = sourceView.bounds
        present(alert, animated: true)
    }

    private func updateSex(_ value: Int) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.updateUserInfoFields(["sex": value]))
                DispatchQueue.main.async {
                    UserDefaults.standard.set(value, forKey: "sex")
                    NotificationCenter.default.post(name: NSNotification.Name("UserInfoUpdated"), object: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("更新失败，请稍后重试")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MyInfoViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return sections[indexPath.section][indexPath.row] == .avatar ? 64 : 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyInfoCell")
            ?? UITableViewCell(style: .value1, reuseIdentifier: "MyInfoCell")
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.font = ScreenAdapter.font(15)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .disclosureIndicator
        cell.accessoryView = nil
        cell.imageView?.image = nil

        switch row {
        case .avatar:
            cell.textLabel?.text = "头像"
            cell.accessoryType = .none
            cell.accessoryView = avatarAccessoryView
        case .name:
            cell.textLabel?.text = "昵称"
            cell.detailTextLabel?.text = name.isEmpty ? "未设置" : name
        case .shortNo:
            cell.textLabel?.text = "Milo号"
            cell.detailTextLabel?.text = shortNo.isEmpty ? uid : shortNo
        case .sex:
            cell.textLabel?.text = "性别"
            cell.detailTextLabel?.text = sexText
        case .sign:
            cell.textLabel?.text = "签名"
            cell.detailTextLabel?.text = sign.isEmpty ? "未设置" : sign
            cell.detailTextLabel?.lineBreakMode = .byTruncatingTail
        case .qrcode:
            cell.textLabel?.text = "我的二维码"
            cell.imageView?.image = UIImage(systemName: "qrcode")
            cell.imageView?.tintColor = .secondaryLabel
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section][indexPath.row] {
        case .avatar:
            showHeadPortrait()
        case .name:
            navigationController?.pushViewController(UpdateUserInfoViewController(type: .name), animated: true)
        case .shortNo:
            navigationController?.pushViewController(UpdateUserInfoViewController(type: .shortNo), animated: true)
        case .sex:
            if let cell = tableView.cellForRow(at: indexPath) {
                showSexPicker(sourceView: cell)
            }
        case .sign:
            navigationController?.pushViewController(SignEditViewController(), animated: true)
        case .qrcode:
            showQRCode()
        }
    }
}


// MARK: - 签名编辑页（对照 Android PersonalSignatureActivity）
class SignEditViewController: UIViewController, UITextViewDelegate {

    private let textContainer = UIView()
    private let textView = UITextView()
    private let countLabel = UILabel()

    private let maxLength = 100

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "签名"
        view.backgroundColor = .themeBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "保存", style: .done, target: self, action: #selector(save)
        )

        textContainer.backgroundColor = .secondarySystemGroupedBackground
        textContainer.layer.cornerRadius = ScreenAdapter.scaleW(12)
        textContainer.clipsToBounds = true
        view.addSubview(textContainer)
        textContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.height.equalTo(ScreenAdapter.scaleH(140))
        }

        textView.font = ScreenAdapter.font(16)
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.text = UserDefaults.standard.string(forKey: "sign") ?? ""
        textContainer.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(8))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(10))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(10))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(28))
        }

        countLabel.font = ScreenAdapter.font(12)
        countLabel.textColor = .secondaryLabel
        countLabel.textAlignment = .right
        countLabel.text = "\(textView.text.count)/\(maxLength)"
        textContainer.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(8))
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        var text = textView.text ?? ""
        if text.count > maxLength {
            text = String(text.prefix(maxLength))
            textView.text = text
        }
        countLabel.text = "\(text.count)/\(maxLength)"
    }

    @objc private func save() {
        let value = (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        navigationItem.rightBarButtonItem?.isEnabled = false
        Task {
            do {
                // 与 Android 一致：服务端字段为 signature
                _ = try await APIClient.shared.requestRaw(.updateUserInfoFields(["signature": value]))
            } catch {
                // 接口不支持 signature 字段时仅本地保存（对齐 Android 行为）
            }
            DispatchQueue.main.async {
                UserDefaults.standard.set(value, forKey: "sign")
                NotificationCenter.default.post(name: NSNotification.Name("UserInfoUpdated"), object: nil)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
