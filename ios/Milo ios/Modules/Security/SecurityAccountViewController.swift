import UIKit
import SnapKit

class SecurityAccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "账号安全"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AcctCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private var bindPhone: String { UserDefaults.standard.string(forKey: "bind_phone") ?? "" }
    private var bindEmail: String { UserDefaults.standard.string(forKey: "bind_email") ?? "" }

    private func maskPhone(_ phone: String) -> String {
        guard phone.count >= 7 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }

    private func maskEmail(_ email: String) -> String {
        guard let atIndex = email.firstIndex(of: "@") else { return email }
        let prefix = String(email[email.startIndex..<atIndex])
        let domain = String(email[atIndex...])
        if prefix.count <= 2 {
            return "\(prefix)***\(domain)"
        }
        return "\(prefix.prefix(2))***\(domain)"
    }

    func numberOfSections(in tableView: UITableView) -> Int { return 4 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 2
        case 2: return 1
        case 3: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "密码管理"
        case 1: return "账号绑定"
        case 2: return "设备管理"
        case 3: return "账号操作"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AcctCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.textLabel?.textColor = .label
        cell.imageView?.tintColor = .themePrimary
        cell.detailTextLabel?.font = ScreenAdapter.font(14)
        cell.detailTextLabel?.textColor = .secondaryLabel

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "修改密码"
            cell.imageView?.image = UIImage(systemName: "key.viewfinder")
            cell.detailTextLabel?.text = "已设置"
        case (1, 0):
            cell.textLabel?.text = bindPhone.isEmpty ? "绑定手机" : maskPhone(bindPhone)
            cell.imageView?.image = UIImage(systemName: "phone")
            cell.detailTextLabel?.text = bindPhone.isEmpty ? "未绑定" : "已绑定"
        case (1, 1):
            cell.textLabel?.text = bindEmail.isEmpty ? "绑定邮箱" : maskEmail(bindEmail)
            cell.imageView?.image = UIImage(systemName: "envelope")
            cell.detailTextLabel?.text = bindEmail.isEmpty ? "未绑定" : "已绑定"
        case (2, 0):
            cell.textLabel?.text = "登录设备管理"
            cell.imageView?.image = UIImage(systemName: "laptopcomputer.and.iphone")
        case (3, 0):
            cell.textLabel?.text = "注销账号"
            cell.imageView?.image = UIImage(systemName: "person.crop.circle.badge.xmark")
            cell.textLabel?.textColor = .systemRed
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            // 修改密码
            navigationController?.pushViewController(LoginPasswordViewController(), animated: true)
        case (1, 0):
            navigationController?.pushViewController(AccountBindingViewController(bindType: .phone), animated: true)
        case (1, 1):
            navigationController?.pushViewController(AccountBindingViewController(bindType: .email), animated: true)
        case (2, 0):
            // 登录设备管理
            navigationController?.pushViewController(DeviceManageViewController(), animated: true)
        case (3, 0):
            navigationController?.pushViewController(DestroyAccountViewController(), animated: true)
        default:
            break
        }
    }
}
