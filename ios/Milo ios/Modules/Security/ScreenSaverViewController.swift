import UIKit
import SnapKit

class ScreenSaverViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "屏保设置"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ScreenSaverCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private var offlineProtection: Bool {
        get { UserDefaults.standard.object(forKey: "offline_protection") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "offline_protection") }
    }

    private var allowScreenshot: Bool {
        get { UserDefaults.standard.object(forKey: "screenshot_allowed") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "screenshot_allowed") }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 3 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "屏保"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScreenSaverCell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "离线保护"
            cell.imageView?.image = UIImage(systemName: "wifi.slash")
            let sw = UISwitch()
            sw.isOn = offlineProtection
            sw.addTarget(self, action: #selector(toggleOffline(_:)), for: .valueChanged)
            cell.accessoryView = sw
        case 1:
            cell.textLabel?.text = "允许截屏"
            cell.imageView?.image = UIImage(systemName: "camera")
            let sw = UISwitch()
            sw.isOn = allowScreenshot
            sw.addTarget(self, action: #selector(toggleScreenshot(_:)), for: .valueChanged)
            cell.accessoryView = sw
        case 2:
            cell.textLabel?.text = "断连屏保"
            cell.imageView?.image = UIImage(systemName: "link.badge.plus")
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 2 {
            navigationController?.pushViewController(DisconnectScreenSaverViewController(), animated: true)
        }
    }

    @objc private func toggleOffline(_ sw: UISwitch) {
        offlineProtection = sw.isOn
    }

    @objc private func toggleScreenshot(_ sw: UISwitch) {
        allowScreenshot = sw.isOn
    }
}

class DisconnectScreenSaverViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "断连屏保"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DisconnCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private var disconnectProtection: Bool {
        get { UserDefaults.standard.object(forKey: "disconnect_protection") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "disconnect_protection") }
    }

    private var disconnectScreenshot: Bool {
        get { UserDefaults.standard.object(forKey: "disconnect_screenshot") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "disconnect_screenshot") }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 2 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DisconnCell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "断连保护"
            cell.imageView?.image = UIImage(systemName: "link.badge.plus")
            let sw = UISwitch()
            sw.isOn = disconnectProtection
            sw.addTarget(self, action: #selector(toggleDisconn(_:)), for: .valueChanged)
            cell.accessoryView = sw
        case 1:
            cell.textLabel?.text = "断连允许截屏"
            cell.imageView?.image = UIImage(systemName: "camera.viewfinder")
            let sw = UISwitch()
            sw.isOn = disconnectScreenshot
            sw.addTarget(self, action: #selector(toggleDisconnScreenshot(_:)), for: .valueChanged)
            cell.accessoryView = sw
        default:
            break
        }
        return cell
    }

    @objc private func toggleDisconn(_ sw: UISwitch) {
        disconnectProtection = sw.isOn
    }

    @objc private func toggleDisconnScreenshot(_ sw: UISwitch) {
        disconnectScreenshot = sw.isOn
    }
}
