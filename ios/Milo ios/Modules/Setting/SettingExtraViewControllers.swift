import UIKit
import SnapKit

// MARK: - 设置主页面
class SettingMainViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "设置"
        view.backgroundColor = .themeBackground

        // 毛玻璃导航栏
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MainSettingCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func logout() {
        let alert = UIAlertController(title: "退出登录", message: "确定要退出当前账号吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { _ in
            LocalStore.shared.clearAll()
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
        })
        present(alert, animated: true)
    }
}

extension SettingMainViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "通用"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainSettingCell", for: indexPath)
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "账号安全"
            cell.imageView?.image = UIImage(systemName: "shield.lefthalf.filled")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .label
        case (0, 1):
            cell.textLabel?.text = "消息通知"
            cell.imageView?.image = UIImage(systemName: "bell")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .label
        case (0, 2):
            cell.textLabel?.text = "通用设置"
            cell.imageView?.image = UIImage(systemName: "gear")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .label
        case (0, 3):
            cell.textLabel?.text = "关于我们"
            cell.imageView?.image = UIImage(systemName: "info.circle")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .label
        case (1, 0):
            cell.textLabel?.text = "退出登录"
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.accessoryType = .none
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            navigationController?.pushViewController(SecurityAccountViewController(), animated: true)
        case (0, 1):
            navigationController?.pushViewController(MsgNoticesSettingViewController(), animated: true)
        case (0, 2):
            navigationController?.pushViewController(GeneralSettingViewController(), animated: true)
        case (0, 3):
            navigationController?.pushViewController(AboutViewController(), animated: true)
        case (1, 0):
            logout()
        default:
            break
        }
    }
}

// MARK: - 消息通知设置页
class MsgNoticesSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "消息通知"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotifCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Switch Actions
    @objc private func toggleNewMessage(_ sender: UISwitch) {
        LocalStore.shared.isMessageNotificationEnabled = sender.isOn
        // 刷新整个表以更新其他开关的可用状态
        tableView.reloadData()
    }

    @objc private func toggleDetail(_ sender: UISwitch) {
        LocalStore.shared.isNotificationDetailEnabled = sender.isOn
    }

    @objc private func toggleSound(_ sender: UISwitch) {
        LocalStore.shared.isSoundEnabled = sender.isOn
    }

    @objc private func toggleVibration(_ sender: UISwitch) {
        LocalStore.shared.isVibrationEnabled = sender.isOn
    }

    @objc private func toggleGroupMute(_ sender: UISwitch) {
        LocalStore.shared.isGroupMuteEnabled = sender.isOn
    }
}

extension MsgNoticesSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "消息通知"
        case 1: return "群消息"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary
        cell.accessoryType = .none

        let switchControl = UISwitch()
        switchControl.onTintColor = .themePrimary
        let isNotifEnabled = LocalStore.shared.isMessageNotificationEnabled

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "新消息通知"
            cell.imageView?.image = UIImage(systemName: "bell.badge")
            switchControl.isOn = isNotifEnabled
            switchControl.addTarget(self, action: #selector(toggleNewMessage(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
        case (0, 1):
            cell.textLabel?.text = "通知显示消息详情"
            cell.imageView?.image = UIImage(systemName: "text.bubble")
            switchControl.isOn = LocalStore.shared.isNotificationDetailEnabled
            switchControl.isEnabled = isNotifEnabled
            switchControl.addTarget(self, action: #selector(toggleDetail(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.textLabel?.textColor = isNotifEnabled ? .label : .secondaryLabel
        case (0, 2):
            cell.textLabel?.text = "声音"
            cell.imageView?.image = UIImage(systemName: "speaker.wave.2")
            switchControl.isOn = LocalStore.shared.isSoundEnabled
            switchControl.isEnabled = isNotifEnabled
            switchControl.addTarget(self, action: #selector(toggleSound(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.textLabel?.textColor = isNotifEnabled ? .label : .secondaryLabel
        case (0, 3):
            cell.textLabel?.text = "震动"
            cell.imageView?.image = UIImage(systemName: "iphone.radiowaves.left.and.right")
            switchControl.isOn = LocalStore.shared.isVibrationEnabled
            switchControl.isEnabled = isNotifEnabled
            switchControl.addTarget(self, action: #selector(toggleVibration(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.textLabel?.textColor = isNotifEnabled ? .label : .secondaryLabel
        case (1, 0):
            cell.textLabel?.text = "群消息免打扰"
            cell.imageView?.image = UIImage(systemName: "person.3.fill")
            switchControl.isOn = LocalStore.shared.isGroupMuteEnabled
            switchControl.addTarget(self, action: #selector(toggleGroupMute(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
        default:
            break
        }
        return cell
    }
}

// MARK: - 通用设置页
class GeneralSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var cacheSize: String = "0MB"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        calculateCacheSize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupUI() {
        title = "通用设置"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GeneralCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func calculateCacheSize() {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        let fileManager = FileManager.default
        var totalSize: UInt64 = 0

        if let files = try? fileManager.subpathsOfDirectory(atPath: cachePath) {
            for file in files {
                let filePath = (cachePath as NSString).appendingPathComponent(file)
                if let attrs = try? fileManager.attributesOfItem(atPath: filePath),
                   let size = attrs[.size] as? UInt64 {
                    totalSize += size
                }
            }
        }

        // 转换为可读格式
        let mb = Double(totalSize) / 1024.0 / 1024.0
        if mb > 1024 {
            cacheSize = String(format: "%.2fGB", mb / 1024.0)
        } else {
            cacheSize = String(format: "%.1fMB", mb)
        }
        tableView.reloadData()
    }

    private func clearCache() {
        let alert = UIAlertController(title: "清理缓存", message: "确定要清理缓存吗？清理后缓存文件将被删除。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: cachePath) {
                for file in files {
                    let filePath = (cachePath as NSString).appendingPathComponent(file)
                    try? fileManager.removeItem(atPath: filePath)
                }
            }
            self.cacheSize = "0MB"
            self.tableView.reloadData()
            AppUtility.showToast("缓存已清理")
        })
        present(alert, animated: true)
    }

    // MARK: - 选择器弹窗
    private func showAppearancePicker() {
        let alert = UIAlertController(title: "深色模式", message: nil, preferredStyle: .actionSheet)
        let modes = ["跟随系统", "浅色", "深色"]
        for (index, mode) in modes.enumerated() {
            let action = UIAlertAction(title: mode, style: .default) { [weak self] _ in
                LocalStore.shared.appearanceMode = index
                self?.applyAppearanceMode(index)
                self?.tableView.reloadData()
            }
            if LocalStore.shared.appearanceMode == index {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    private func applyAppearanceMode(_ mode: Int) {
        guard let window = view.window else { return }
        switch mode {
        case 0:
            window.overrideUserInterfaceStyle = .unspecified
        case 1:
            window.overrideUserInterfaceStyle = .light
        case 2:
            window.overrideUserInterfaceStyle = .dark
        default:
            break
        }
    }

    private func showFontSizePicker() {
        let alert = UIAlertController(title: "字体大小", message: nil, preferredStyle: .actionSheet)
        let sizes = ["小", "标准", "大", "超大"]
        for (index, size) in sizes.enumerated() {
            let action = UIAlertAction(title: size, style: .default) { [weak self] _ in
                LocalStore.shared.fontSizeLevel = index
                // 同步字体大小数值
                let fontValues = [13, 15, 17, 19]
                LocalStore.shared.fontSize = fontValues[index]
                self?.tableView.reloadData()
            }
            if LocalStore.shared.fontSizeLevel == index {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    private func showLanguagePicker() {
        let alert = UIAlertController(title: "语言设置", message: nil, preferredStyle: .actionSheet)
        let languages = ["简体中文", "繁体中文", "English"]
        for (index, lang) in languages.enumerated() {
            let action = UIAlertAction(title: lang, style: .default) { [weak self] _ in
                LocalStore.shared.languageSetting = index
                self?.tableView.reloadData()
                AppUtility.showToast("语言设置已保存")
            }
            if LocalStore.shared.languageSetting == index {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }
}

extension GeneralSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 2
        case 2: return 2
        case 3: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "显示"
        case 1: return "通用"
        case 2: return "存储"
        case 3: return "聊天"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary
        cell.detailTextLabel?.font = ScreenAdapter.font(14)
        cell.detailTextLabel?.textColor = .secondaryLabel

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "深色模式"
            cell.imageView?.image = UIImage(systemName: "moon")
            let mode = LocalStore.shared.appearanceMode
            let modeTexts = ["跟随系统", "浅色", "深色"]
            cell.detailTextLabel?.text = modeTexts[mode]
        case (1, 0):
            cell.textLabel?.text = "字体大小"
            cell.imageView?.image = UIImage(systemName: "textformat.size")
            let level = LocalStore.shared.fontSizeLevel
            let levelTexts = ["小", "标准", "大", "超大"]
            cell.detailTextLabel?.text = levelTexts[level]
        case (1, 1):
            cell.textLabel?.text = "语言设置"
            cell.imageView?.image = UIImage(systemName: "globe")
            let lang = LocalStore.shared.languageSetting
            let langTexts = ["简体中文", "繁体中文", "English"]
            cell.detailTextLabel?.text = langTexts[lang]
        case (2, 0):
            cell.textLabel?.text = "清理缓存"
            cell.imageView?.image = UIImage(systemName: "trash")
            cell.detailTextLabel?.text = cacheSize
        case (2, 1):
            cell.textLabel?.text = "存储空间"
            cell.imageView?.image = UIImage(systemName: "internaldrive")
            cell.detailTextLabel?.text = "查看"
        case (3, 0):
            cell.textLabel?.text = "聊天背景设置"
            cell.imageView?.image = UIImage(systemName: "photo.on.rectangle")
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            showAppearancePicker()
        case (1, 0):
            showFontSizePicker()
        case (1, 1):
            showLanguagePicker()
        case (2, 0):
            clearCache()
        case (2, 1):
            AppUtility.showToast("功能开发中")
        case (3, 0):
            let bgVC = ChatBackgroundViewController()
            navigationController?.pushViewController(bgVC, animated: true)
        default:
            break
        }
    }
}

// MARK: - 关于页面
class AboutViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "关于我们"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AboutCell")

        // 顶部 Logo Header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: ScreenAdapter.scaleH(180)))
        headerView.backgroundColor = .clear

        let logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "AppIcon") ?? UIImage(systemName: "message.circle.fill")
        logoImageView.tintColor = .themePrimary
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.layer.cornerRadius = ScreenAdapter.scaleW(16)
        logoImageView.clipsToBounds = true

        let appNameLabel = UILabel()
        appNameLabel.text = "Milo"
        appNameLabel.font = ScreenAdapter.mediumFont(20)
        appNameLabel.textAlignment = .center
        appNameLabel.textColor = .label

        let versionLabel = UILabel()
        versionLabel.text = "版本 \(appVersion) (Build \(appBuildNumber))"
        versionLabel.font = ScreenAdapter.font(13)
        versionLabel.textAlignment = .center
        versionLabel.textColor = .secondaryLabel

        let descLabel = UILabel()
        descLabel.text = "简洁高效的即时通讯应用"
        descLabel.font = ScreenAdapter.font(13)
        descLabel.textAlignment = .center
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0

        headerView.addSubviews(logoImageView, appNameLabel, versionLabel, descLabel)

        logoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(72))
        }

        appNameLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.centerX.equalToSuperview()
        }

        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(appNameLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.centerX.equalToSuperview()
        }

        descLabel.snp.makeConstraints { make in
            make.top.equalTo(versionLabel.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        tableView.tableHeaderView = headerView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 底部版权信息
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: ScreenAdapter.scaleH(60)))
        let copyrightLabel = UILabel()
        copyrightLabel.text = "Copyright © 2024 Milo.\nAll rights reserved."
        copyrightLabel.font = ScreenAdapter.font(12)
        copyrightLabel.textAlignment = .center
        copyrightLabel.textColor = .tertiaryLabel
        copyrightLabel.numberOfLines = 0
        footerView.addSubview(copyrightLabel)
        copyrightLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        tableView.tableFooterView = footerView
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "协议与政策"
        case 1: return "更多"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AboutCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.imageView?.tintColor = .themePrimary

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "用户协议"
            cell.imageView?.image = UIImage(systemName: "doc.text")
        case (0, 1):
            cell.textLabel?.text = "隐私政策"
            cell.imageView?.image = UIImage(systemName: "hand.raised")
        case (1, 0):
            cell.textLabel?.text = "功能介绍"
            cell.imageView?.image = UIImage(systemName: "info.circle")
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            // 用户协议
            let webVC = SimpleWebViewController(title: "用户协议", url: "about:blank")
            navigationController?.pushViewController(webVC, animated: true)
        case (0, 1):
            // 隐私政策
            let webVC = SimpleWebViewController(title: "隐私政策", url: "about:blank")
            navigationController?.pushViewController(webVC, animated: true)
        case (1, 0):
            // 功能介绍
            AppUtility.showToast("Milo - 简洁高效的即时通讯应用")
        default:
            break
        }
    }
}

// MARK: - 简单 WebView 控制器
class SimpleWebViewController: UIViewController {

    private let webView = UIWebView()
    private var urlString: String
    private var pageTitle: String

    init(title: String, url: String) {
        self.pageTitle = title
        self.urlString = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = pageTitle
        view.backgroundColor = .themeBackground

        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if let url = URL(string: urlString) {
            webView.loadRequest(URLRequest(url: url))
        }
    }
}

// MARK: - 安全设置页（安全中心）
class SecuritySettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupUI() {
        title = "安全中心"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SecurityCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension SecuritySettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 4
        case 2: return 2
        case 3: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "账号安全"
        case 1: return "隐私安全"
        case 2: return "密码管理"
        case 3: return "账号操作"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SecurityCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(16)
        cell.textLabel?.textColor = .label
        cell.imageView?.tintColor = .themePrimary

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "安全账号"
            cell.imageView?.image = UIImage(systemName: "shield.lefthalf.filled")
            let phone = UserDefaults.standard.string(forKey: "bind_phone") ?? ""
            let email = UserDefaults.standard.string(forKey: "bind_email") ?? ""
            cell.detailTextLabel?.text = !phone.isEmpty || !email.isEmpty ? "已绑定" : "未绑定"
        case (1, 0):
            cell.textLabel?.text = "设备管理"
            cell.imageView?.image = UIImage(systemName: "laptopcomputer")
        case (1, 1):
            cell.textLabel?.text = "消息隐私"
            cell.imageView?.image = UIImage(systemName: "eye.slash")
        case (1, 2):
            cell.textLabel?.text = "聊天密码"
            cell.imageView?.image = UIImage(systemName: "key")
            let enabled = UserDefaults.standard.bool(forKey: "chat_password_enabled")
            cell.detailTextLabel?.text = enabled ? "已设置" : "未设置"
        case (1, 3):
            cell.textLabel?.text = "黑名单"
            cell.imageView?.image = UIImage(systemName: "person.badge.minus")
        case (2, 0):
            cell.textLabel?.text = "锁屏密码"
            cell.imageView?.image = UIImage(systemName: "lock")
            let enabled = LocalStore.shared.isAppLockEnabled
            cell.detailTextLabel?.text = enabled ? "已设置" : "未设置"
        case (2, 1):
            cell.textLabel?.text = "登录密码"
            cell.imageView?.image = UIImage(systemName: "key.viewfinder")
            cell.detailTextLabel?.text = "已设置"
        case (3, 0):
            cell.textLabel?.text = "注销账号"
            cell.imageView?.image = UIImage(systemName: "person.crop.circle.badge.xmark")
            cell.textLabel?.textColor = .systemRed
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            navigationController?.pushViewController(SecurityAccountViewController(), animated: true)
        case (1, 0):
            navigationController?.pushViewController(DeviceManageViewController(), animated: true)
        case (1, 1):
            navigationController?.pushViewController(MessagePrivacyViewController(), animated: true)
        case (1, 2):
            navigationController?.pushViewController(ChatPasswordViewController(), animated: true)
        case (1, 3):
            navigationController?.pushViewController(BlacklistViewController(), animated: true)
        case (2, 0):
            navigationController?.pushViewController(LockScreenPwdViewController(), animated: true)
        case (2, 1):
            navigationController?.pushViewController(LoginPasswordViewController(), animated: true)
        case (3, 0):
            navigationController?.pushViewController(DestroyAccountViewController(), animated: true)
        default:
            break
        }
    }
}

// MARK: - 黑名单
class BlacklistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var blacklist: [[String: String]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "黑名单"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BlackCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        loadData()
    }

    private func loadData() {
        if let saved = UserDefaults.standard.array(forKey: "blacklist") as? [[String: String]] {
            blacklist = saved
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(blacklist.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlackCell", for: indexPath)
        if blacklist.isEmpty {
            cell.textLabel?.text = "暂无黑名单用户"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
        } else {
            let item = blacklist[indexPath.row]
            cell.textLabel?.text = item["name"] ?? ""
        }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !blacklist.isEmpty else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "移除") { _, _, completion in
            self.blacklist.remove(at: indexPath.row)
            UserDefaults.standard.set(self.blacklist, forKey: "blacklist")
            tableView.reloadData()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}

// MARK: - 密码管理（统一入口）
class PwdManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad(); title = "密码管理"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PMCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData() }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 3 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "密码管理" }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PMCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator; cell.imageView?.tintColor = .themePrimary
        switch indexPath.row {
        case 0: cell.textLabel?.text = "登录密码"; cell.imageView?.image = UIImage(systemName: "key.viewfinder"); cell.detailTextLabel?.text = "已设置"
        case 1: cell.textLabel?.text = "聊天密码"; cell.imageView?.image = UIImage(systemName: "key"); cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "chat_password_enabled") ? "已设置" : "未设置"
        case 2: cell.textLabel?.text = "锁屏密码"; cell.imageView?.image = UIImage(systemName: "lock"); cell.detailTextLabel?.text = LocalStore.shared.isAppLockEnabled ? "已设置" : "未设置"
        default: break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0: navigationController?.pushViewController(LoginPasswordViewController(), animated: true)
        case 1: navigationController?.pushViewController(ChatPasswordViewController(), animated: true)
        case 2: navigationController?.pushViewController(LockScreenPwdViewController(), animated: true)
        default: break
        }
    }
}

// MARK: - 验证密码入口
class VertifyPwdViewController: UIViewController {
    private let pwdField = UITextField()
    private let submitButton = UIButton(type: .system)
    private var target: String
    private var boundAccount: String

    init(target: String, boundAccount: String) { self.target = target; self.boundAccount = boundAccount; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "验证密码"; view.backgroundColor = .themeBackground
        pwdField.placeholder = "请输入登录密码"; pwdField.borderStyle = .roundedRect; pwdField.isSecureTextEntry = true; pwdField.font = ScreenAdapter.font(16)
        submitButton.setTitle("验证", for: .normal); submitButton.titleLabel?.font = ScreenAdapter.font(17)
        submitButton.backgroundColor = .themePrimary; submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = ScreenAdapter.scaleW(10); submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [pwdField, submitButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        pwdField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        submitButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func submit() {
        guard let pwd = pwdField.text, !pwd.isEmpty else { AppUtility.showToast("请输入密码"); return }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.verifyLoginPwd(pwd: pwd))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 {
                        switch self.target {
                        case "phone": self.navigationController?.pushViewController(VertifyPhoneViewController(account: self.boundAccount), animated: true)
                        case "email": self.navigationController?.pushViewController(VertifyEmailViewController(account: self.boundAccount), animated: true)
                        default: self.navigationController?.pushViewController(AccountBindingViewController(bindType: .phone), animated: true)
                        }
                    } else { AppUtility.showToast(resp["msg"] as? String ?? "密码错误") }
                }
            } catch { DispatchQueue.main.async { AppUtility.showToast("验证失败") } }
        }
    }
}

// MARK: - 验证手机
class VertifyPhoneViewController: UIViewController {
    private var account: String
    private let codeField = UITextField()
    private let getCodeButton = UIButton(type: .system)
    private let bindButton = UIButton(type: .system)
    private var countdown = 0; private var timer: Timer?

    init(account: String) { self.account = account; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "验证手机"; view.backgroundColor = .themeBackground
        codeField.placeholder = "验证码"; codeField.borderStyle = .roundedRect; codeField.keyboardType = .numberPad; codeField.font = ScreenAdapter.font(16)
        getCodeButton.setTitle("获取验证码", for: .normal); getCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)
        bindButton.setTitle("绑定", for: .normal); bindButton.titleLabel?.font = ScreenAdapter.font(17)
        bindButton.backgroundColor = .themePrimary; bindButton.setTitleColor(.white, for: .normal)
        bindButton.layer.cornerRadius = ScreenAdapter.scaleW(10); bindButton.addTarget(self, action: #selector(bind), for: .touchUpInside)
        let codeRow = UIStackView(arrangedSubviews: [codeField, getCodeButton]); codeRow.axis = .horizontal; codeRow.spacing = 12
        let stack = UIStackView(arrangedSubviews: [codeRow, bindButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        codeField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        getCodeButton.snp.makeConstraints { make in make.width.equalTo(ScreenAdapter.scaleW(100)) }
        bindButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func getCode() {
        Task {
            do { _ = try await APIClient.shared.requestRaw(.sendBindPhoneCode(zone: "+86", phone: account)); DispatchQueue.main.async { self.startCountdown() } }
            catch { DispatchQueue.main.async { AppUtility.showToast("发送失败") } }
        }
    }
    private func startCountdown() {
        countdown = 60; getCodeButton.isEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 { t.invalidate(); self.getCodeButton.setTitle("获取验证码", for: .normal); self.getCodeButton.isEnabled = true }
            else { self.getCodeButton.setTitle("\(self.countdown)秒", for: .normal) }
        }
    }
    @objc private func bind() {
        guard let code = codeField.text, code.count == 6 else { AppUtility.showToast("请输入6位验证码"); return }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.bindPhone(zone: "+86", phone: account, code: code))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 { UserDefaults.standard.set(self.account, forKey: "bind_phone"); AppUtility.showToast("绑定成功"); self.navigationController?.popViewController(animated: true) }
                    else { AppUtility.showToast(resp["msg"] as? String ?? "绑定失败") }
                }
            } catch { DispatchQueue.main.async { AppUtility.showToast("操作失败") } }
        }
    }
}

// MARK: - 验证邮箱
class VertifyEmailViewController: UIViewController {
    private var account: String
    private let codeField = UITextField()
    private let getCodeButton = UIButton(type: .system)
    private let bindButton = UIButton(type: .system)
    private var countdown = 0; private var timer: Timer?

    init(account: String) { self.account = account; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "验证邮箱"; view.backgroundColor = .themeBackground
        codeField.placeholder = "验证码"; codeField.borderStyle = .roundedRect; codeField.keyboardType = .numberPad; codeField.font = ScreenAdapter.font(16)
        getCodeButton.setTitle("获取验证码", for: .normal); getCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)
        bindButton.setTitle("绑定", for: .normal); bindButton.titleLabel?.font = ScreenAdapter.font(17)
        bindButton.backgroundColor = .themePrimary; bindButton.setTitleColor(.white, for: .normal)
        bindButton.layer.cornerRadius = ScreenAdapter.scaleW(10); bindButton.addTarget(self, action: #selector(bind), for: .touchUpInside)
        let codeRow = UIStackView(arrangedSubviews: [codeField, getCodeButton]); codeRow.axis = .horizontal; codeRow.spacing = 12
        let stack = UIStackView(arrangedSubviews: [codeRow, bindButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        codeField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        getCodeButton.snp.makeConstraints { make in make.width.equalTo(ScreenAdapter.scaleW(100)) }
        bindButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func getCode() {
        Task {
            do { _ = try await APIClient.shared.requestRaw(.sendBindEmailCode(email: account)); DispatchQueue.main.async { self.startCountdown() } }
            catch { DispatchQueue.main.async { AppUtility.showToast("发送失败") } }
        }
    }
    private func startCountdown() {
        countdown = 60; getCodeButton.isEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 { t.invalidate(); self.getCodeButton.setTitle("获取验证码", for: .normal); self.getCodeButton.isEnabled = true }
            else { self.getCodeButton.setTitle("\(self.countdown)秒", for: .normal) }
        }
    }
    @objc private func bind() {
        guard let code = codeField.text, code.count == 6 else { AppUtility.showToast("请输入6位验证码"); return }
        Task {
            do {
                let resp = try await APIClient.shared.requestRaw(.bindEmail(email: account, code: code))
                let status = resp["status"] as? Int ?? 0
                DispatchQueue.main.async {
                    if status == 200 { UserDefaults.standard.set(self.account, forKey: "bind_email"); AppUtility.showToast("绑定成功"); self.navigationController?.popViewController(animated: true) }
                    else { AppUtility.showToast(resp["msg"] as? String ?? "绑定失败") }
                }
            } catch { DispatchQueue.main.async { AppUtility.showToast("操作失败") } }
        }
    }
}

// MARK: - 个性签名
class PersonalSignatureViewController: UIViewController {
    private let textView = UITextView()
    private let saveButton = UIButton(type: .system)
    private let hintLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad(); title = "个性签名"; view.backgroundColor = .themeBackground
        hintLabel.text = "设置个性签名，让别人更了解你"; hintLabel.font = ScreenAdapter.font(14); hintLabel.textColor = .secondaryLabel
        textView.font = ScreenAdapter.font(16); textView.layer.cornerRadius = 8; textView.layer.borderWidth = 1; textView.layer.borderColor = UIColor.systemGray5.cgColor
        textView.text = UserDefaults.standard.string(forKey: "personal_signature") ?? ""
        saveButton.setTitle("保存", for: .normal); saveButton.titleLabel?.font = ScreenAdapter.font(17)
        saveButton.backgroundColor = .themePrimary; saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10); saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [hintLabel, textView, saveButton]); stack.axis = .vertical; stack.spacing = 12
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        textView.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(120)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func save() {
        UserDefaults.standard.set(textView.text, forKey: "personal_signature")
        AppUtility.showToast("已保存"); navigationController?.popViewController(animated: true)
    }
}

// MARK: - 设置备注
class SetUserRemarkViewController: UIViewController {
    private var uid: String
    private let textField = UITextField()
    private let saveButton = UIButton(type: .system)

    init(uid: String) { self.uid = uid; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "设置备注"; view.backgroundColor = .themeBackground
        textField.placeholder = "输入备注名"; textField.borderStyle = .roundedRect; textField.font = ScreenAdapter.font(16)
        textField.text = UserDefaults.standard.string(forKey: "remark_\(uid)")
        saveButton.setTitle("保存", for: .normal); saveButton.titleLabel?.font = ScreenAdapter.font(17)
        saveButton.backgroundColor = .themePrimary; saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10); saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [textField, saveButton]); stack.axis = .vertical; stack.spacing = 16
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        textField.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
        saveButton.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func save() {
        UserDefaults.standard.set(textField.text, forKey: "remark_\(uid)")
        AppUtility.showToast("已保存"); navigationController?.popViewController(animated: true)
    }
}

// MARK: - 头像选择/裁剪
class MyHeadPortraitViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let avatarView = UIImageView()
    private let albumButton = UIButton(type: .system)
    private let cameraButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad(); title = "头像"; view.backgroundColor = .themeBackground
        avatarView.image = UIImage(systemName: "person.circle.fill"); avatarView.tintColor = .lightGray
        avatarView.contentMode = .scaleAspectFill; avatarView.layer.cornerRadius = ScreenAdapter.scaleW(60); avatarView.layer.masksToBounds = true
        albumButton.setTitle("从相册选择", for: .normal); albumButton.titleLabel?.font = ScreenAdapter.font(16)
        albumButton.addTarget(self, action: #selector(fromAlbum), for: .touchUpInside)
        cameraButton.setTitle("拍照", for: .normal); cameraButton.titleLabel?.font = ScreenAdapter.font(16)
        cameraButton.addTarget(self, action: #selector(fromCamera), for: .touchUpInside)
        saveButton.setTitle("保存", for: .normal); saveButton.titleLabel?.font = ScreenAdapter.font(17)
        saveButton.backgroundColor = .themePrimary; saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10); saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let avatarContainer = UIView(); avatarContainer.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in make.center.equalToSuperview(); make.width.height.equalTo(ScreenAdapter.scaleW(120)) }
        let stack = UIStackView(arrangedSubviews: [avatarContainer, albumButton, cameraButton, saveButton]); stack.axis = .vertical; stack.spacing = 16; stack.alignment = .center
        view.addSubview(stack); stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(48)
            make.leading.equalToSuperview().offset(24); make.trailing.equalToSuperview().offset(-24)
        }
        avatarContainer.snp.makeConstraints { make in make.height.equalTo(ScreenAdapter.scaleH(140)) }
        saveButton.snp.makeConstraints { make in make.width.equalToSuperview(); make.height.equalTo(ScreenAdapter.scaleH(48)) }
    }
    @objc private func fromAlbum() {
        let picker = UIImagePickerController(); picker.delegate = self; picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    @objc private func fromCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController(); picker.delegate = self; picker.sourceType = .camera
            present(picker, animated: true)
        } else { AppUtility.showToast("相机不可用") }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.originalImage] as? UIImage { avatarView.image = img }
        picker.dismiss(animated: true)
    }
    @objc private func save() { AppUtility.showToast("已保存"); navigationController?.popViewController(animated: true) }
}

// MARK: - 文件助手
class FileHelperViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var files: [(name: String, size: String, date: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad(); title = "文件助手"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FHCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        files = [("项目文档.pdf", "2.3MB", "2024-01-15"), ("设计稿.zip", "15.6MB", "2024-01-12")]
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(files.count, 1) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FHCell", for: indexPath)
        if files.isEmpty { cell.textLabel?.text = "暂无文件"; cell.textLabel?.textColor = .secondaryLabel; cell.textLabel?.textAlignment = .center; cell.selectionStyle = .none }
        else { let f = files[indexPath.row]; cell.textLabel?.text = f.name; cell.detailTextLabel?.text = "\(f.size)  \(f.date)"; cell.imageView?.image = UIImage(systemName: "doc.fill"); cell.imageView?.tintColor = .themePrimary }
        return cell
    }
}

// MARK: - 系统团队
class SystemTeamViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let teams: [(name: String, desc: String, icon: String)] = [
        ("闲雷虎虎官方", "官方团队", "shield.checkered"),
        ("技术支持", "问题反馈与解答", "wrench.adjustable"),
        ("安全中心", "安全相关事务", "lock.shield"),
        ("意见反馈", "产品建议收集", "envelope"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad(); title = "系统团队"; view.backgroundColor = .themeBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "STCell")
        view.addSubview(tableView); tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { teams.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "STCell", for: indexPath)
        let t = teams[indexPath.row]
        cell.textLabel?.text = t.name; cell.detailTextLabel?.text = t.desc
        cell.imageView?.image = UIImage(systemName: t.icon); cell.imageView?.tintColor = .themePrimary
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        AppUtility.showToast("功能开发中")
    }
}
