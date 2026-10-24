import UIKit
import SnapKit
import UserNotifications

// MARK: - 消息通知设置（对照 Android MsgNoticesSettingActivity）
class MsgNoticesSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // Section 索引
    private enum Section: Int, CaseIterable {
        case notice = 0   // 新消息通知、声音、震动、通知显示详情
        case dnd = 1      // 免打扰
    }

    // MARK: - 本地存储 Key
    private enum Keys {
        static let dndEnabled = "dnd_enabled"
        static let dndStartTime = "dnd_start_time"
        static let dndEndTime = "dnd_end_time"
    }

    // MARK: - 免打扰设置（本地保存，默认关闭，时间段 22:00 - 08:00）
    private var dndEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.dndEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dndEnabled) }
    }

    private var dndStartTime: String {
        get { UserDefaults.standard.string(forKey: Keys.dndStartTime) ?? "22:00" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dndStartTime) }
    }

    private var dndEndTime: String {
        get { UserDefaults.standard.string(forKey: Keys.dndEndTime) ?? "08:00" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dndEndTime) }
    }

    /// 系统通知授权状态
    private var systemNotificationEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshSystemNotificationStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSystemNotificationStatus()
    }

    private func setupUI() {
        title = "消息通知"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupDetailSwitchCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(16), bottom: 0, right: 0)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 系统通知授权状态
    private func refreshSystemNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.systemNotificationEnabled = (settings.authorizationStatus == .authorized)
                self?.tableView.reloadData()
            }
        }
    }

    /// 跳转系统通知设置
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - 开关事件
    @objc private func toggleNewMessageNotice(_ sender: UISwitch) {
        // 新消息通知由系统授权控制，引导用户前往系统设置
        openSystemSettings()
        sender.setOn(systemNotificationEnabled, animated: true)
    }

    @objc private func toggleSound(_ sender: UISwitch) {
        LocalStore.shared.isSoundEnabled = sender.isOn
    }

    @objc private func toggleVibration(_ sender: UISwitch) {
        LocalStore.shared.isVibrationEnabled = sender.isOn
    }

    @objc private func toggleNotificationDetail(_ sender: UISwitch) {
        LocalStore.shared.isNotificationDetailEnabled = sender.isOn
    }

    @objc private func toggleDnd(_ sender: UISwitch) {
        dndEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: Section.dnd.rawValue), with: .fade)
    }

    // MARK: - 免打扰时间选择
    private func showTimePicker(isStart: Bool) {
        let current = isStart ? dndStartTime : dndEndTime

        let picker = UIDatePicker()
        picker.datePickerMode = .time
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: current) {
            picker.date = date
        }

        let pickerVC = UIViewController()
        pickerVC.view.addSubview(picker)
        picker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        pickerVC.preferredContentSize = CGSize(width: ScreenAdapter.scaleW(270), height: ScreenAdapter.scaleH(160))

        let alert = UIAlertController(title: isStart ? "开始时间" : "结束时间", message: nil, preferredStyle: .alert)
        alert.setValue(pickerVC, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let time = formatter.string(from: picker.date)
            if isStart {
                self.dndStartTime = time
            } else {
                self.dndEndTime = time
            }
            self.tableView.reloadData()
        })
        present(alert, animated: true)
    }
}

extension MsgNoticesSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .notice: return 4   // 新消息通知、声音、震动、通知显示详情
        case .dnd: return dndEnabled ? 3 : 1   // 免打扰开关 + 开始/结束时间
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .notice: return nil
        case .dnd: return "免打扰"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .notice:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! GroupDetailSwitchCell
            switch indexPath.row {
            case 0:
                cell.configure(title: "新消息通知", icon: "bell.fill", isOn: systemNotificationEnabled)
                cell.switchControl.addTarget(self, action: #selector(toggleNewMessageNotice(_:)), for: .valueChanged)
            case 1:
                cell.configure(title: "声音", icon: "speaker.wave.2.fill", isOn: LocalStore.shared.isSoundEnabled)
                cell.switchControl.addTarget(self, action: #selector(toggleSound(_:)), for: .valueChanged)
            case 2:
                cell.configure(title: "震动", icon: "iphone.radiowaves.left.and.right", isOn: LocalStore.shared.isVibrationEnabled)
                cell.switchControl.addTarget(self, action: #selector(toggleVibration(_:)), for: .valueChanged)
            default:
                cell.configure(title: "通知显示详情", icon: "text.bubble.fill", isOn: LocalStore.shared.isNotificationDetailEnabled)
                cell.switchControl.addTarget(self, action: #selector(toggleNotificationDetail(_:)), for: .valueChanged)
            }
            cell.textLabel?.font = ScreenAdapter.font(16)
            return cell

        case .dnd:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! GroupDetailSwitchCell
                cell.configure(title: "免打扰", icon: "moon.fill", isOn: dndEnabled)
                cell.switchControl.addTarget(self, action: #selector(toggleDnd(_:)), for: .valueChanged)
                cell.textLabel?.font = ScreenAdapter.font(16)
                return cell
            }

            let cell = UITableViewCell(style: .value1, reuseIdentifier: "TimeCell")
            cell.textLabel?.font = ScreenAdapter.font(16)
            cell.detailTextLabel?.font = ScreenAdapter.font(15)
            cell.accessoryType = .disclosureIndicator
            if indexPath.row == 1 {
                cell.textLabel?.text = "开始时间"
                cell.detailTextLabel?.text = dndStartTime
            } else {
                cell.textLabel?.text = "结束时间"
                cell.detailTextLabel?.text = dndEndTime
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {
        case .notice:
            if indexPath.row == 0 {
                openSystemSettings()
            }
        case .dnd:
            if indexPath.row == 1 {
                showTimePicker(isStart: true)
            } else if indexPath.row == 2 {
                showTimePicker(isStart: false)
            }
        }
    }
}
