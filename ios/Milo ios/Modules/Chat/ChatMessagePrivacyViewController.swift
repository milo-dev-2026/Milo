import UIKit
import SnapKit

// MARK: - 消息隐私设置页（对标 Android ChatMessagePrivacyActivity）
class ChatMessagePrivacyViewController: UIViewController {

    // MARK: - 属性
    private let channelId: String
    private let channelType: Int

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // 本地存储 key 前缀（按会话隔离）
    private func storageKey(_ name: String) -> String {
        return "chat_privacy_\(name)_\(channelType)_\(channelId)"
    }

    private enum PrivacyItem: Int, CaseIterable {
        case burnAfterRead = 0
        case encryptMessage
        case screenshotAlert
        case forbidForward

        var title: String {
            switch self {
            case .burnAfterRead: return "阅后即焚"
            case .encryptMessage: return "消息加密"
            case .screenshotAlert: return "截图提醒"
            case .forbidForward: return "禁止转发"
            }
        }

        var icon: String {
            switch self {
            case .burnAfterRead: return "flame"
            case .encryptMessage: return "lock.shield"
            case .screenshotAlert: return "camera.viewfinder"
            case .forbidForward: return "arrowshape.turn.up.right.slash"
            }
        }

        var subtitle: String {
            switch self {
            case .burnAfterRead: return "对方查看后消息自动销毁"
            case .encryptMessage: return "对该会话消息进行端到端加密"
            case .screenshotAlert: return "对方截图时通知我"
            case .forbidForward: return "禁止对方转发该会话消息"
            }
        }

        var keyName: String {
            switch self {
            case .burnAfterRead: return "burn"
            case .encryptMessage: return "encrypt"
            case .screenshotAlert: return "screenshot_alert"
            case .forbidForward: return "forbid_forward"
            }
        }
    }

    // MARK: - 初始化
    init(channelId: String, channelType: Int = 1) {
        self.channelId = channelId
        self.channelType = channelType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "消息隐私"
        view.backgroundColor = .themeBackground
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI
    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PrivacyCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 开关事件（本地保存）
    @objc private func switchChanged(_ sender: UISwitch) {
        guard let item = PrivacyItem(rawValue: sender.tag) else { return }
        UserDefaults.standard.set(sender.isOn, forKey: storageKey(item.keyName))
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatMessagePrivacyViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PrivacyItem.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "会话隐私"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "以上设置仅对当前会话生效"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrivacyCell", for: indexPath)
        guard let item = PrivacyItem(rawValue: indexPath.row) else { return cell }

        cell.selectionStyle = .none
        cell.textLabel?.text = item.title
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.detailTextLabel?.text = nil
        cell.imageView?.image = UIImage(systemName: item.icon)
        cell.imageView?.tintColor = .themePrimary

        let sw = UISwitch()
        sw.tag = item.rawValue
        sw.isOn = UserDefaults.standard.bool(forKey: storageKey(item.keyName))
        sw.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = sw
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
