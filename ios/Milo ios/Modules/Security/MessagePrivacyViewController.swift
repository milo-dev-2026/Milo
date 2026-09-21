import UIKit
import SnapKit

class MessagePrivacyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var burnExpanded = false
    private let burnOptions = ["5秒", "10秒", "30秒", "1分钟"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "消息隐私"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PrivacyCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private var burnAfterReading: Bool {
        get { UserDefaults.standard.bool(forKey: "msg_burn_after_reading") }
        set { UserDefaults.standard.set(newValue, forKey: "msg_burn_after_reading") }
    }

    private var burnTimeIndex: Int {
        get { UserDefaults.standard.integer(forKey: "msg_burn_time_index") }
        set { UserDefaults.standard.set(newValue, forKey: "msg_burn_time_index") }
    }

    private var readReceipt: Bool {
        get { UserDefaults.standard.object(forKey: "msg_read_receipt") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "msg_read_receipt") }
    }

    private var typingStatus: Bool {
        get { UserDefaults.standard.object(forKey: "msg_typing_status") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "msg_typing_status") }
    }

    func numberOfSections(in tableView: UITableView) -> Int { return 3 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return burnExpanded ? 1 + burnOptions.count : 1
        case 1: return 1
        case 2: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "阅后即焚"
        case 1: return "已读回执"
        case 2: return "输入状态"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrivacyCell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "开启阅后即焚"
            cell.imageView?.image = UIImage(systemName: "flame")
            let sw = UISwitch()
            sw.isOn = burnAfterReading
            sw.tag = 100
            sw.addTarget(self, action: #selector(toggleBurn(_:)), for: .valueChanged)
            cell.accessoryView = sw
            cell.accessoryType = .none
        case (0, let row) where row > 0 && row <= burnOptions.count:
            let idx = row - 1
            cell.textLabel?.text = burnOptions[idx]
            cell.imageView?.image = nil
            cell.accessoryType = burnTimeIndex == idx ? .checkmark : .none
            cell.selectionStyle = .default
        case (1, 0):
            cell.textLabel?.text = "已读回执"
            cell.imageView?.image = UIImage(systemName: "checkmark.circle")
            let sw = UISwitch()
            sw.isOn = readReceipt
            sw.tag = 101
            sw.addTarget(self, action: #selector(toggleReceipt(_:)), for: .valueChanged)
            cell.accessoryView = sw
        case (2, 0):
            cell.textLabel?.text = "输入状态"
            cell.imageView?.image = UIImage(systemName: "keyboard")
            let sw = UISwitch()
            sw.isOn = typingStatus
            sw.tag = 102
            sw.addTarget(self, action: #selector(toggleTyping(_:)), for: .valueChanged)
            cell.accessoryView = sw
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row > 0 && indexPath.row <= burnOptions.count {
            burnTimeIndex = indexPath.row - 1
            tableView.reloadSections(IndexSet(integer: 0), with: .none)
        }
    }

    @objc private func toggleBurn(_ sw: UISwitch) {
        burnAfterReading = sw.isOn
        burnExpanded = sw.isOn
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }

    @objc private func toggleReceipt(_ sw: UISwitch) {
        readReceipt = sw.isOn
    }

    @objc private func toggleTyping(_ sw: UISwitch) {
        typingStatus = sw.isOn
    }
}
