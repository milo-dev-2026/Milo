import UIKit
import SnapKit

class LockScreenPwdViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let lockOptions = ["立即", "1分钟", "5分钟", "30分钟", "1小时"]
    private let lockValues = [0, 1, 5, 30, 60]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "锁屏密码"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LockCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private var isLockEnabled: Bool {
        get { LocalStore.shared.isAppLockEnabled }
        set { LocalStore.shared.isAppLockEnabled = newValue }
    }

    private var autoLockIndex: Int {
        get { UserDefaults.standard.integer(forKey: "lock_auto_index") }
        set { UserDefaults.standard.set(newValue, forKey: "lock_auto_index") }
    }

    func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return isLockEnabled ? lockOptions.count : 0
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "锁屏密码"
        case 1: return "自动锁定时间"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LockCell", for: indexPath)
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = isLockEnabled ? "关闭锁屏密码" : "设置锁屏密码"
            cell.textLabel?.textColor = isLockEnabled ? .systemRed : .themePrimary
            cell.imageView?.image = UIImage(systemName: isLockEnabled ? "lock.open" : "lock")
            cell.accessoryType = .none
        case (1, let row):
            cell.textLabel?.text = lockOptions[row]
            cell.accessoryType = autoLockIndex == row ? .checkmark : .none
            cell.imageView?.image = UIImage(systemName: "clock")
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            if isLockEnabled {
                let alert = UIAlertController(title: "关闭锁屏密码", message: "确定关闭锁屏密码？", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    let loadingView = self.showLoading()
                    Task {
                        do {
                            _ = try await APIClient.shared.requestRaw(.deleteLockScreenPwd)
                            DispatchQueue.main.async {
                                loadingView?.removeFromSuperview()
                                self.isLockEnabled = false
                                LocalStore.shared.lockPassword = nil
                                tableView.reloadData()
                                AppUtility.showToast("已关闭锁屏密码")
                            }
                        } catch {
                            DispatchQueue.main.async {
                                loadingView?.removeFromSuperview()
                                AppUtility.showToast("关闭失败，请重试")
                            }
                        }
                    }
                })
                present(alert, animated: true)
            } else {
                navigationController?.pushViewController(LockScreenVerifyViewController(mode: .setPassword), animated: true)
            }
        } else if indexPath.section == 1 {
            autoLockIndex = indexPath.row
            let minute = lockValues[indexPath.row]
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.updateLockAfterMinute(minute: minute))
                } catch { }
            }
            tableView.reloadData()
        }
    }

    private func showLoading() -> UIView? {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = overlay.center
        spinner.startAnimating()
        overlay.addSubview(spinner)
        view.addSubview(overlay)
        return overlay
    }
}
