import UIKit
import SnapKit

class PwdManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "密码管理"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PwdCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private var isLockScreenPwdSet: Bool {
        LocalStore.shared.isAppLockEnabled
    }

    func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "密码管理"
        case 1: return "帮助"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PwdCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.textLabel?.textColor = .label
        cell.imageView?.tintColor = .themePrimary
        cell.detailTextLabel?.font = ScreenAdapter.font(14)
        cell.detailTextLabel?.textColor = .secondaryLabel

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "修改登录密码"
            cell.imageView?.image = UIImage(systemName: "key")
            cell.detailTextLabel?.text = nil
        case (0, 1):
            cell.textLabel?.text = "设置锁屏密码"
            cell.imageView?.image = UIImage(systemName: "lock")
            cell.detailTextLabel?.text = isLockScreenPwdSet ? "已设置" : "未设置"
        case (1, 0):
            cell.textLabel?.text = "忘记密码"
            cell.imageView?.image = UIImage(systemName: "questionmark.circle")
            cell.detailTextLabel?.text = nil
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            // 修改登录密码（输入旧密码、新密码、确认新密码）
            navigationController?.pushViewController(LoginPasswordViewController(), animated: true)
        case (0, 1):
            // 设置锁屏密码
            navigationController?.pushViewController(LockScreenPwdViewController(), animated: true)
        case (1, 0):
            // 忘记密码，跳转找回密码流程
            navigationController?.pushViewController(ForgotPasswordViewController(), animated: true)
        default:
            break
        }
    }
}
