import UIKit
import SnapKit

class PerfectUserInfoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let avatarView = UIImageView()
    private let avatarAddIcon = UIImageView()
    private let nameField = UITextField()
    private let submitButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "完善个人信息"
        view.backgroundColor = .themeBackground
        navigationItem.hidesBackButton = true
        setupUI()
    }

    private func setupUI() {
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .lightGray
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(60)
        avatarView.layer.masksToBounds = true
        avatarView.isUserInteractionEnabled = true
        avatarView.backgroundColor = .systemGray6

        avatarAddIcon.image = UIImage(systemName: "camera.fill")
        avatarAddIcon.tintColor = .white
        avatarAddIcon.backgroundColor = .themePrimary
        avatarAddIcon.layer.cornerRadius = ScreenAdapter.scaleW(14)
        avatarAddIcon.layer.masksToBounds = true

        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarView)
        avatarContainer.addSubview(avatarAddIcon)
        avatarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(120))
        }
        avatarAddIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
            make.width.height.equalTo(ScreenAdapter.scaleW(28))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(pickAvatar))
        avatarContainer.addGestureRecognizer(tap)

        nameField.placeholder = "请输入昵称"
        nameField.borderStyle = .roundedRect
        nameField.font = ScreenAdapter.font(16)
        nameField.textAlignment = .center

        submitButton.setTitle("完成", for: .normal)
        submitButton.titleLabel?.font = ScreenAdapter.font(17)
        submitButton.backgroundColor = .themePrimary
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [avatarContainer, nameField, submitButton])
        stack.axis = .vertical
        stack.spacing = ScreenAdapter.scaleH(24)
        stack.alignment = .center
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(48))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }
        nameField.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
        submitButton.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
    }

    @objc private func pickAvatar() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.originalImage] as? UIImage {
            avatarView.image = img
        }
        picker.dismiss(animated: true)
    }

    @objc private func submit() {
        guard let name = nameField.text, !name.isEmpty else {
            AppUtility.showToast("请输入昵称"); return
        }
        UserDefaults.standard.set(name, forKey: "name")
        let mainVC = MainTabBarController()
        view.window?.rootViewController = mainVC
    }
}

class ChooseAreaCodeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var allCodes: [(country: String, code: String, flag: String)] = []
    private var filteredCodes: [(country: String, code: String, flag: String)] = []
    private var onSelected: ((String) -> Void)?
    private let searchController = UISearchController(searchResultsController: nil)

    init(onSelected: @escaping (String) -> Void) {
        self.onSelected = onSelected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择区号"
        view.backgroundColor = .themeBackground
        loadData()
        setupUI()
    }

    private func loadData() {
        allCodes = [
            ("中国大陆", "+86", "🇨🇳"), ("中国香港", "+852", "🇭🇰"), ("中国台湾", "+886", "🇹🇼"),
            ("中国澳门", "+853", "🇲🇴"), ("美国", "+1", "🇺🇸"), ("加拿大", "+1", "🇨🇦"),
            ("英国", "+44", "🇬🇧"), ("法国", "+33", "🇫🇷"), ("德国", "+49", "🇩🇪"),
            ("日本", "+81", "🇯🇵"), ("韩国", "+82", "🇰🇷"), ("新加坡", "+65", "🇸🇬"),
            ("马来西亚", "+60", "🇲🇾"), ("泰国", "+66", "🇹🇭"), ("越南", "+84", "🇻🇳"),
            ("印度", "+91", "🇮🇳"), ("印度尼西亚", "+62", "🇮🇩"), ("菲律宾", "+63", "🇵🇭"),
            ("澳大利亚", "+61", "🇦🇺"), ("新西兰", "+64", "🇳🇿"), ("俄罗斯", "+7", "🇷🇺"),
            ("巴西", "+55", "🇧🇷"), ("墨西哥", "+52", "🇲🇽"), ("意大利", "+39", "🇮🇹"),
            ("西班牙", "+34", "🇪🇸"), ("荷兰", "+31", "🇳🇱"), ("瑞典", "+46", "🇸🇪"),
            ("瑞士", "+41", "🇨🇭"), ("阿联酋", "+971", "🇦🇪"), ("沙特阿拉伯", "+966", "🇸🇦"),
            ("土耳其", "+90", "🇹🇷"), ("埃及", "+20", "🇪🇬"), ("南非", "+27", "🇿🇦"),
            ("尼日利亚", "+234", "🇳🇬"), ("肯尼亚", "+254", "🇰🇪"),
        ]
        filteredCodes = allCodes
    }

    private func setupUI() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "搜索国家或区号"
        navigationItem.searchController = searchController

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AreaCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    func updateSearchResults(for searchController: UISearchController) {
        let keyword = searchController.searchBar.text ?? ""
        if keyword.isEmpty {
            filteredCodes = allCodes
        } else {
            filteredCodes = allCodes.filter { $0.country.contains(keyword) || $0.code.contains(keyword) }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filteredCodes.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AreaCell", for: indexPath)
        let item = filteredCodes[indexPath.row]
        cell.textLabel?.text = "\(item.flag)  \(item.country)"
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.detailTextLabel?.text = item.code
        cell.detailTextLabel?.font = ScreenAdapter.font(14)
        cell.detailTextLabel?.textColor = .themePrimary
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let code = filteredCodes[indexPath.row].code
        onSelected?(code)
        navigationController?.popViewController(animated: true)
    }
}

class ResetLoginPwdViewController: UIViewController {

    // 顶部区域
    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // 玻璃卡片
    private let glassCard = GlassCardView()
    private let segmentedControl = GlassSegmentedControl(items: ["手机号", "邮箱"])
    private var isEmailMode = false

    private let phoneField = CapsulePhoneField()
    private let emailField = CapsuleTextField()
    private let codeField = CapsuleCodeField()
    private let pwdField = CapsulePasswordField()
    private let confirmPwdField = CapsulePasswordField()

    private let submitButton = UIButton(type: .system)
    private var countdown = 0
    private var countdownTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    deinit { countdownTimer?.invalidate() }

    private func setupUI() {
        // 顶部：左侧Logo + 右侧标题+副标题
        logoView.image = UIImage(named: "LoginLogo")
        logoView.contentMode = .scaleAspectFit

        titleLabel.text = "重置密码"
        titleLabel.font = ScreenAdapter.mediumFont(22)
        titleLabel.textColor = .label

        subtitleLabel.text = "重置您的账号密码"
        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel

        // 右侧标题+副标题垂直排列
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = ScreenAdapter.scaleH(4)
        titleStack.alignment = .leading

        // 整体：左logo + 右标题
        let headerStack = UIStackView(arrangedSubviews: [logoView, titleStack])
        headerStack.axis = .horizontal
        headerStack.spacing = ScreenAdapter.scaleW(12)
        headerStack.alignment = .center

        let headerContainer = UIView()
        headerContainer.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        logoView.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleH(48))
        }

        // 玻璃卡片
        view.addSubview(glassCard)

        // 分段控件
        segmentedControl.onSelected = { [weak self] index in
            self?.switchMode(index)
        }
        glassCard.addSubview(segmentedControl)

        // 手机号输入框
        phoneField.placeholder = "请输入手机号"
        glassCard.addSubview(phoneField)

        // 邮箱输入框
        emailField.placeholder = "请输入邮箱地址"
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocapitalizationType = .none
        emailField.isHidden = true
        glassCard.addSubview(emailField)

        // 验证码输入框
        codeField.placeholder = "请输入验证码"
        codeField.sendCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)
        glassCard.addSubview(codeField)

        // 新密码输入框
        pwdField.placeholder = "请输入新密码(6-20位)"
        glassCard.addSubview(pwdField)

        // 确认密码输入框
        confirmPwdField.placeholder = "请确认新密码"
        glassCard.addSubview(confirmPwdField)

        // 卡片内布局
        segmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        phoneField.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        emailField.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        codeField.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        pwdField.snp.makeConstraints { make in
            make.top.equalTo(codeField.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
        }
        confirmPwdField.snp.makeConstraints { make in
            make.top.equalTo(pwdField.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(20))
        }

        // 提交按钮
        submitButton.setTitle("确认重置", for: .normal)
        submitButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        submitButton.backgroundColor = .themePrimary
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(26)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)

        // 整体布局
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        let mainStack = UIStackView(arrangedSubviews: [headerContainer, glassCard, submitButton])
        mainStack.axis = .vertical
        mainStack.spacing = ScreenAdapter.scaleH(20)
        mainStack.alignment = .fill
        contentView.addSubview(mainStack)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(16))
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.lessThanOrEqualToSuperview().offset(-ScreenAdapter.scaleH(20))
        }
        submitButton.snp.makeConstraints { make in
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    private func switchMode(_ index: Int) {
        isEmailMode = (index == 1)
        phoneField.isHidden = isEmailMode
        emailField.isHidden = !isEmailMode
    }

    @objc private func getCode() {
        if isEmailMode {
            guard let email = emailField.textField.text, !email.isEmpty else {
                AppUtility.showToast("请输入邮箱"); return
            }
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.sendEmailCode(email: email))
                    DispatchQueue.main.async { self.startCountdown() }
                } catch { DispatchQueue.main.async { AppUtility.showToast("发送失败") } }
            }
        } else {
            guard let phone = phoneField.textField.text, !phone.isEmpty else {
                AppUtility.showToast("请输入手机号"); return
            }
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.sendSMSCode(phone: phone))
                    DispatchQueue.main.async { self.startCountdown() }
                } catch { DispatchQueue.main.async { AppUtility.showToast("发送失败") } }
            }
        }
    }

    private func startCountdown() {
        countdown = 60
        codeField.sendCodeButton.isEnabled = false
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 {
                t.invalidate()
                self.codeField.sendCodeButton.setTitle("获取验证码", for: .normal)
                self.codeField.sendCodeButton.isEnabled = true
            } else {
                self.codeField.sendCodeButton.setTitle("\(self.countdown)秒", for: .normal)
            }
        }
    }

    @objc private func submit() {
        if isEmailMode {
            guard let email = emailField.textField.text, !email.isEmpty else {
                AppUtility.showToast("请输入邮箱"); return
            }
            guard let code = codeField.textField.text, code.count == 6 else {
                AppUtility.showToast("请输入6位验证码"); return
            }
            guard let pwd = pwdField.textField.text, pwd.count >= 6, pwd.count <= 20 else {
                AppUtility.showToast("密码需6-20位"); return
            }
            guard let confirmPwd = confirmPwdField.textField.text, confirmPwd == pwd else {
                AppUtility.showToast("两次密码不一致"); return
            }

            submitButton.isEnabled = false
            Task {
                do {
                    // 邮箱重置密码：尝试通过邮箱验证码重置
                    let resp = try await APIClient.shared.requestRaw(.changePwdByPhone(zone: "+86", phone: email, code: code, pwd: pwd))
                    let status = resp["status"] as? Int ?? 0
                    DispatchQueue.main.async {
                        self.submitButton.isEnabled = true
                        if status == 200 {
                            AppUtility.showToast("密码重置成功")
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            AppUtility.showToast(resp["msg"] as? String ?? "重置失败")
                        }
                    }
                } catch {
                    DispatchQueue.main.async { self.submitButton.isEnabled = true; AppUtility.showToast("操作失败") }
                }
            }
        } else {
            guard let phone = phoneField.textField.text, !phone.isEmpty else {
                AppUtility.showToast("请输入手机号"); return
            }
            guard let code = codeField.textField.text, code.count == 6 else {
                AppUtility.showToast("请输入6位验证码"); return
            }
            guard let pwd = pwdField.textField.text, pwd.count >= 6, pwd.count <= 20 else {
                AppUtility.showToast("密码需6-20位"); return
            }
            guard let confirmPwd = confirmPwdField.textField.text, confirmPwd == pwd else {
                AppUtility.showToast("两次密码不一致"); return
            }

            submitButton.isEnabled = false
            Task {
                do {
                    let resp = try await APIClient.shared.requestRaw(.changePwdByPhone(zone: "+86", phone: phone, code: code, pwd: pwd))
                    let status = resp["status"] as? Int ?? 0
                    DispatchQueue.main.async {
                        self.submitButton.isEnabled = true
                        if status == 200 {
                            AppUtility.showToast("密码重置成功")
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            AppUtility.showToast(resp["msg"] as? String ?? "重置失败")
                        }
                    }
                } catch {
                    DispatchQueue.main.async { self.submitButton.isEnabled = true; AppUtility.showToast("操作失败") }
                }
            }
        }
    }
}
