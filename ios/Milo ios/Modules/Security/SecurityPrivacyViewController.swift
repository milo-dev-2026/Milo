import UIKit
import SnapKit

class SecurityPrivacyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "隐私安全"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PrivacyHubCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private var screenshotEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "screenshot_allowed") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "screenshot_allowed") }
    }

    private var chatPwdEnabled: Bool {
        UserDefaults.standard.bool(forKey: "chat_password_enabled")
    }

    private var lockScreenEnabled: Bool {
        LocalStore.shared.isAppLockEnabled
    }

    func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 5
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "截屏保护"
        case 1: return "隐私设置"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrivacyHubCell", for: indexPath)
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "允许截屏"
            cell.imageView?.image = UIImage(systemName: "camera")
            let sw = UISwitch()
            sw.isOn = screenshotEnabled
            sw.addTarget(self, action: #selector(toggleScreenshot(_:)), for: .valueChanged)
            cell.accessoryView = sw
            cell.accessoryType = .none
            cell.selectionStyle = .none
        case (1, 0):
            cell.textLabel?.text = "消息隐私"
            cell.imageView?.image = UIImage(systemName: "eye.slash")
            cell.accessoryType = .disclosureIndicator
        case (1, 1):
            cell.textLabel?.text = "聊天密码"
            cell.imageView?.image = UIImage(systemName: "key")
            cell.detailTextLabel?.text = chatPwdEnabled ? "已设置" : "未设置"
            cell.accessoryType = .disclosureIndicator
        case (1, 2):
            cell.textLabel?.text = "锁屏密码"
            cell.imageView?.image = UIImage(systemName: "lock")
            cell.detailTextLabel?.text = lockScreenEnabled ? "已设置" : "未设置"
            cell.accessoryType = .disclosureIndicator
        case (1, 3):
            cell.textLabel?.text = "黑名单"
            cell.imageView?.image = UIImage(systemName: "person.badge.minus")
            cell.accessoryType = .disclosureIndicator
        case (1, 4):
            cell.textLabel?.text = "屏保"
            cell.imageView?.image = UIImage(systemName: "moon.zzz")
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            navigationController?.pushViewController(MessagePrivacyViewController(), animated: true)
        case (1, 1):
            navigationController?.pushViewController(ChatPasswordViewController(), animated: true)
        case (1, 2):
            navigationController?.pushViewController(LockScreenPwdViewController(), animated: true)
        case (1, 3):
            navigationController?.pushViewController(BlacklistViewController(), animated: true)
        case (1, 4):
            navigationController?.pushViewController(ScreenSaverViewController(), animated: true)
        default:
            break
        }
    }

    @objc private func toggleScreenshot(_ sw: UISwitch) {
        screenshotEnabled = sw.isOn
    }
}
