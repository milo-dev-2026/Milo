import UIKit
import SnapKit

class AccountBindingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    enum BindType { case phone, email }
    private let bindType: BindType

    init(bindType: BindType) {
        self.bindType = bindType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var isBound = false
    private var boundAccount = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = bindType == .phone ? "绑定手机" : "绑定邮箱"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BindCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        loadData()
    }

    private func loadData() {
        switch bindType {
        case .phone:
            boundAccount = UserDefaults.standard.string(forKey: "bind_phone") ?? ""
            isBound = !boundAccount.isEmpty
        case .email:
            boundAccount = UserDefaults.standard.string(forKey: "bind_email") ?? ""
            isBound = !boundAccount.isEmpty
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 1 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return bindType == .phone ? "绑定手机号" : "绑定邮箱"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindCell", for: indexPath)
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary
        cell.accessoryType = .disclosureIndicator

        if isBound {
            if bindType == .phone {
                let p = boundAccount
                cell.textLabel?.text = p.count >= 7 ? "\(p.prefix(3))****\(p.suffix(4))" : p
            } else {
                cell.textLabel?.text = boundAccount
            }
            cell.detailTextLabel?.text = "已绑定"
            cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            cell.textLabel?.text = "立即绑定"
            cell.imageView?.image = UIImage(systemName: bindType == .phone ? "phone" : "envelope")
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showBindDialog()
    }

    private func showBindDialog() {
        let alert = UIAlertController(
            title: bindType == .phone ? "绑定手机号" : "绑定邮箱",
            message: isBound ? "当前已绑定，修改将替换原绑定" : nil,
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.placeholder = bindType == .phone ? "请输入手机号" : "请输入邮箱"
            tf.keyboardType = bindType == .phone ? .numberPad : .emailAddress
            if self.isBound { tf.text = self.boundAccount }
        }
        alert.addTextField { tf in
            tf.placeholder = "验证码"
            tf.keyboardType = .numberPad
        }

        let getCodeAction = UIAlertAction(title: "获取验证码", style: .default) { [weak self] _ in
            guard let self = self,
                  let account = alert.textFields?[0].text, !account.isEmpty else { return }
            self.sendCode(account: account)
            self.showBindDialog()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let tf = alert.textFields?[0] { tf.text = account }
            }
        }

        let confirmAction = UIAlertAction(title: "确认绑定", style: .default) { [weak self] _ in
            guard let self = self,
                  let account = alert.textFields?[0].text, !account.isEmpty,
                  let code = alert.textFields?[1].text, code.count == 6 else {
                AppUtility.showToast("请填写完整信息")
                return
            }
            self.bindAccount(account: account, code: code)
        }

        alert.addAction(getCodeAction)
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func sendCode(account: String) {
        Task {
            do {
                switch bindType {
                case .phone:
                    _ = try await APIClient.shared.requestRaw(.sendBindPhoneCode(zone: "+86", phone: account))
                case .email:
                    _ = try await APIClient.shared.requestRaw(.sendBindEmailCode(email: account))
                }
                DispatchQueue.main.async { AppUtility.showToast("验证码已发送") }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("发送失败") }
            }
        }
    }

    private func bindAccount(account: String, code: String) {
        Task {
            do {
                var resp: [String: Any]
                switch bindType {
                case .phone:
                    resp = try await APIClient.shared.requestRaw(.bindPhone(zone: "+86", phone: account, code: code))
                case .email:
                    resp = try await APIClient.shared.requestRaw(.bindEmail(email: account, code: code))
                }
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 {
                        switch self.bindType {
                        case .phone:
                            UserDefaults.standard.set(account, forKey: "bind_phone")
                        case .email:
                            UserDefaults.standard.set(account, forKey: "bind_email")
                        }
                        self.isBound = true
                        self.boundAccount = account
                        self.tableView.reloadData()
                        AppUtility.showToast("绑定成功")
                    } else {
                        AppUtility.showToast(resp["msg"] as? String ?? "绑定失败")
                    }
                }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("操作失败") }
            }
        }
    }
}
