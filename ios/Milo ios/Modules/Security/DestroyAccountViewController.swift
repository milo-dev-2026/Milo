import UIKit
import SnapKit

class DestroyAccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var bindPhone: String { UserDefaults.standard.string(forKey: "bind_phone") ?? "" }
    private var bindEmail: String { UserDefaults.standard.string(forKey: "bind_email") ?? "" }
    private var verifyType: String { bindPhone.isEmpty ? "email" : "phone" }
    private var boundAccount: String { verifyType == "phone" ? bindPhone : bindEmail }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "注销账号"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DestroyCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 1 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "绑定信息"
        case 1: return "账号注销"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DestroyCell", for: indexPath)
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.selectionStyle = .none

        switch indexPath.section {
        case 0:
            if verifyType == "phone" {
                let p = boundAccount
                cell.textLabel?.text = p.count >= 7 ? "手机: \(p.prefix(3))****\(p.suffix(4))" : "手机: \(p)"
            } else {
                cell.textLabel?.text = "邮箱: \(boundAccount)"
            }
        case 1:
            cell.textLabel?.text = "继续注销"
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .default
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }

        let alert = UIAlertController(
            title: "注销账号",
            message: "注销后账号数据将无法恢复，确定继续？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "再想想", style: .cancel))
        alert.addAction(UIAlertAction(title: "继续注销", style: .destructive) { [weak self] _ in
            self?.navigationController?.pushViewController(InputDestroyCodeViewController(
                account: self?.boundAccount ?? "",
                verifyType: self?.verifyType ?? "phone"
            ), animated: true)
        })
        present(alert, animated: true)
    }
}

class InputDestroyCodeViewController: UIViewController {

    private let account: String
    private let verifyType: String
    private let codeField = UITextField()
    private let getCodeButton = UIButton(type: .system)
    private let submitButton = UIButton(type: .system)
    private var countdown = 0
    private var countdownTimer: Timer?

    init(account: String, verifyType: String) {
        self.account = account
        self.verifyType = verifyType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "验证码"
        view.backgroundColor = .themeBackground
        setupUI()
        sendCode()
    }

    private func setupUI() {
        let infoLabel = UILabel()
        infoLabel.text = verifyType == "phone"
            ? "验证码已发送至手机 \(account.prefix(3))****\(account.suffix(4))"
            : "验证码已发送至邮箱 \(account)"
        infoLabel.font = ScreenAdapter.font(14)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0

        codeField.placeholder = "请输入6位验证码"
        codeField.borderStyle = .roundedRect
        codeField.keyboardType = .numberPad
        codeField.font = ScreenAdapter.font(16)

        getCodeButton.setTitle("60秒", for: .normal)
        getCodeButton.titleLabel?.font = ScreenAdapter.font(14)
        getCodeButton.isEnabled = false
        getCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)

        let codeRow = UIStackView(arrangedSubviews: [codeField, getCodeButton])
        codeRow.axis = .horizontal
        codeRow.spacing = 12

        submitButton.setTitle("确认注销", for: .normal)
        submitButton.titleLabel?.font = ScreenAdapter.font(17)
        submitButton.backgroundColor = .systemRed
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [infoLabel, codeRow, submitButton])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(16)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }

        codeField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        getCodeButton.snp.makeConstraints { make in make.width.equalTo(ScreenAdapter.scaleW(80)) }
        submitButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }

    private func sendCode() {
        Task {
            do {
                if verifyType == "phone" {
                    _ = try await APIClient.shared.requestRaw(.sendDestroyPhoneCode(zone: "+86", phone: account))
                } else {
                    _ = try await APIClient.shared.requestRaw(.sendDestroyEmailCode(email: account))
                }
                DispatchQueue.main.async { self.startCountdown() }
            } catch {
                DispatchQueue.main.async { AppUtility.showToast("发送失败，请稍后重试") }
            }
        }
    }

    @objc private func getCode() { sendCode() }

    private func startCountdown() {
        countdown = 60
        getCodeButton.isEnabled = false
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 {
                t.invalidate()
                self.getCodeButton.setTitle("重新获取", for: .normal)
                self.getCodeButton.isEnabled = true
            } else {
                self.getCodeButton.setTitle("\(self.countdown)秒", for: .normal)
            }
        }
    }

    @objc private func submit() {
        guard let code = codeField.text, code.count == 6 else {
            AppUtility.showToast("请输入6位验证码"); return
        }

        submitButton.isEnabled = false
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.destroyAccount(
                    account: self.account,
                    code: code,
                    type: self.verifyType,
                    zone: self.verifyType == "phone" ? "+86" : ""
                ))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    if status == 200 {
                        AppUtility.showToast("账号已注销")
                        IMManager.shared.disconnect()
                        LocalStore.shared.clearAll()
                        let loginVC = LoginViewController()
                        self.view.window?.rootViewController = BaseNavigationController(rootViewController: loginVC)
                    } else {
                        AppUtility.showToast(resp["msg"] as? String ?? "注销失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    AppUtility.showToast("操作失败")
                }
            }
        }
    }
}
