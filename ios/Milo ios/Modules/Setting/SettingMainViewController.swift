import UIKit
import SnapKit

// MARK: - 设置主页面（对照 Android SettingActivity）
class SettingMainViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // Section 索引
    private enum Section: Int, CaseIterable {
        case account = 0   // 账号与安全
        case notice = 1    // 消息通知
        case general = 2   // 通用
        case about = 3     // 关于
        case logout = 4    // 退出登录
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupUI() {
        title = "设置"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LogoutCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(16), bottom: 0, right: 0)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 退出登录
    private func showLogoutConfirm() {
        let alert = UIAlertController(title: "退出登录", message: "确认退出登录？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出登录", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        present(alert, animated: true)
    }

    private func logout() {
        // 断开 IM 连接并清除本地登录状态（token、uid 等）
        IMManager.shared.disconnect()
        LocalStore.shared.clearAll()

        let loginVC = LoginViewController(account: "", isEmail: false)
        let nav = BaseNavigationController(rootViewController: loginVC)
        view.window?.rootViewController = nav
    }
}

extension SettingMainViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .account: return 3   // 手机号、邮箱、密码管理
        case .notice: return 1    // 消息通知
        case .general: return 4   // 主题、语言、字体大小、缓存管理
        case .about: return 3     // 关于我们、意见反馈、常见问题
        case .logout: return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .account: return "账号与安全"
        case .notice: return "消息通知"
        case .general: return "通用"
        case .about: return "关于"
        case .logout: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .account:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "AccountCell")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.detailTextLabel?.font = ScreenAdapter.font(14)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "手机号"
                cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: "phone") ?? ""
            case 1:
                cell.textLabel?.text = "邮箱"
                cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: "email") ?? ""
            default:
                cell.textLabel?.text = "密码管理"
            }
            return cell

        case .notice:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.textLabel?.text = "消息通知"
            return cell

        case .general:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.textLabel?.text = ["主题", "语言", "字体大小", "缓存管理"][indexPath.row]
            return cell

        case .about:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.textLabel?.text = ["关于我们", "意见反馈", "常见问题"][indexPath.row]
            return cell

        case .logout:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutCell", for: indexPath)
            cell.textLabel?.text = "退出登录"
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            cell.accessoryType = .none
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {
        case .account:
            switch indexPath.row {
            case 0:
                navigationController?.pushViewController(AccountBindingViewController(bindType: .phone), animated: true)
            case 1:
                navigationController?.pushViewController(AccountBindingViewController(bindType: .email), animated: true)
            default:
                navigationController?.pushViewController(PwdManagerViewController(), animated: true)
            }

        case .notice:
            navigationController?.pushViewController(MsgNoticesSettingViewController(), animated: true)

        case .general:
            navigationController?.pushViewController(GeneralSettingViewController(), animated: true)

        case .about:
            switch indexPath.row {
            case 0:
                navigationController?.pushViewController(AboutViewController(), animated: true)
            case 1:
                navigationController?.pushViewController(FeedbackViewController(), animated: true)
            default:
                navigationController?.pushViewController(FaqViewController(), animated: true)
            }

        case .logout:
            showLogoutConfirm()
        }
    }
}
