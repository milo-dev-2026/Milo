//
//  BackupRestoreViewController.swift
//  Milo
//
//  聊天记录备份与恢复页面
//  包含：备份状态、内容选择、备份/恢复操作、可用备份列表、自动备份设置
//  使用液态玻璃风格按钮、AnimatedProgressBar 进度条、旋转动画
//

import UIKit
import SnapKit

// MARK: - 备份记录模型
struct BackupRecord: Codable {
    var id: String
    var timestamp: Int64
    var size: Int64
    var contentSummary: String
    var items: [String]

    var timeString: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    var sizeString: String {
        let mb = Double(size) / 1024.0 / 1024.0
        if mb > 1024 {
            return String(format: "%.2fGB", mb / 1024.0)
        } else if mb > 1 {
            return String(format: "%.1fMB", mb)
        } else {
            return String(format: "%.0fKB", Double(size) / 1024.0)
        }
    }
}

// MARK: - 备份恢复页面
class BackupRestoreViewController: UIViewController {

    // MARK: - 表格
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - 状态
    private var isBackingUp = false
    private var isRestoring = false
    private var backupProgress: CGFloat = 0
    private var restoreProgress: CGFloat = 0
    private var progressTimer: Timer?

    // MARK: - 备份内容选择
    private var contentSelection: [(title: String, icon: String, selected: Bool)] = [
        (AppStrings.Backup.chatHistory, "message.fill", true),
        (AppStrings.Backup.images, "photo.fill", true),
        (AppStrings.Backup.videos, "video.fill", false),
        (AppStrings.Backup.files, "doc.fill", false),
    ]

    // MARK: - 自动备份设置
    private var autoBackupEnabled = false
    private var backupFrequency = 1 // 0:每天 1:每周 2:每月
    private var wifiOnly = true
    private var backupHour = 2 // 凌晨2点

    // MARK: - 模拟备份数据
    private var backupRecords: [BackupRecord] = [
        BackupRecord(
            id: "backup_001",
            timestamp: Int64(Date().addingTimeInterval(-86400 * 3).timeIntervalSince1970),
            size: 256 * 1024 * 1024,
            contentSummary: "聊天记录 + 图片",
            items: ["chatHistory", "images"]
        ),
        BackupRecord(
            id: "backup_002",
            timestamp: Int64(Date().addingTimeInterval(-86400 * 7).timeIntervalSince1970),
            size: 128 * 1024 * 1024,
            contentSummary: "聊天记录",
            items: ["chatHistory"]
        ),
    ]

    // MARK: - 进度 UI（懒加载，仅在操作时显示）
    private lazy var progressOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .themeOverlay
        view.isHidden = true
        return view
    }()

    private lazy var progressCard: LiquidGlassCard = {
        let card = LiquidGlassCard(cornerRadius: ScreenAdapter.scaleW(16))
        card.glassOpacity = 0.8
        card.highlightOpacity = 0.2
        return card
    }()

    private let rotatingIcon = UIImageView()
    private let progressTitleLabel = UILabel()
    private let progressBar = AnimatedProgressBar()
    private let progressPercentLabel = UILabel()

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 入场动画
        if AnimationIntegration.shared.config.enableListEntranceAnimation {
            tableView.animateCellsFadeInUp(delayPerItem: AnimationIntegration.shared.config.listItemDelay)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressTimer?.invalidate()
    }

    // MARK: - UI 设置
    private func setupUI() {
        title = AppStrings.Backup.title
        view.backgroundColor = .themeBgGrouped

        // 导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BackupContentCell.self, forCellReuseIdentifier: "BackupContentCell")
        tableView.register(BackupRecordCell.self, forCellReuseIdentifier: "BackupRecordCell")
        tableView.register(SettingCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
        tableView.separatorColor = .themeSeparator

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupProgressOverlay()
    }

    // MARK: - 进度浮层
    private func setupProgressOverlay() {
        view.addSubview(progressOverlayView)
        progressOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        progressOverlayView.addSubview(progressCard)
        progressCard.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(40))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(40))
        }

        // 旋转图标
        rotatingIcon.image = UIImage(systemName: "arrow.triangle.2.circlepath")
        rotatingIcon.tintColor = .themeColorPrimary
        rotatingIcon.contentMode = .scaleAspectFit
        progressCard.addContent(rotatingIcon)
        rotatingIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }

        // 标题
        progressTitleLabel.font = ThemeFont.title3(16)
        progressTitleLabel.textColor = .themeTextPrimary
        progressTitleLabel.textAlignment = .center
        progressCard.addContent(progressTitleLabel)
        progressTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(rotatingIcon.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
        }

        // 进度条
        progressBar.trackColor = .themeBgInput
        progressBar.progressColor = .themeColorPrimary
        progressBar.cornerRadius = ScreenAdapter.scaleW(4)
        progressCard.addContent(progressBar)
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(progressTitleLabel.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(20))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(20))
            make.height.equalTo(ScreenAdapter.scaleH(8))
        }

        // 百分比
        progressPercentLabel.font = ThemeFont.bodySmall(14)
        progressPercentLabel.textColor = .themeTextSecondary
        progressPercentLabel.textAlignment = .center
        progressPercentLabel.text = "0%"
        progressCard.addContent(progressPercentLabel)
        progressPercentLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(24))
        }
    }

    // MARK: - 计算预计大小
    private var estimatedSizeString: String {
        // TODO: 接入真实数据计算，当前为模拟估算
        var totalMB: Double = 0
        for item in contentSelection where item.selected {
            switch item.title {
            case AppStrings.Backup.chatHistory: totalMB += 85
            case AppStrings.Backup.images: totalMB += 156
            case AppStrings.Backup.videos: totalMB += 320
            case AppStrings.Backup.files: totalMB += 64
            default: break
            }
        }
        if totalMB > 1024 {
            return String(format: "%.2fGB", totalMB / 1024.0)
        } else {
            return String(format: "%.0fMB", totalMB)
        }
    }

    private var lastBackupTimeString: String {
        guard let last = backupRecords.first else {
            return AppStrings.Backup.noBackup
        }
        return last.timeString
    }

    // MARK: - 备份操作
    @objc private func startBackup() {
        guard !isBackingUp else { return }

        // 检查是否至少选择了一项内容
        let hasSelection = contentSelection.contains { $0.selected }
        guard hasSelection else {
            AppUtility.showToast(AppStrings.Backup.backupContent)
            return
        }

        isBackingUp = true
        backupProgress = 0
        progressTitleLabel.text = AppStrings.Backup.backingUp
        showProgressOverlay()
        startRotatingAnimation()

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }

        // TODO: 接入真实备份逻辑，当前为模拟进度
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.backupProgress += 0.02
            self.progressBar.setProgress(self.backupProgress, animated: true, duration: 0.05)
            self.progressPercentLabel.text = String(format: "%.0f%%", self.backupProgress * 100)

            if self.backupProgress >= 1.0 {
                timer.invalidate()
                self.completeBackup()
            }
        }
    }

    private func completeBackup() {
        isBackingUp = false
        hideProgressOverlay()

        // 添加新备份记录
        let selectedItems = contentSelection.filter { $0.selected }.map { $0.title }
        let newRecord = BackupRecord(
            id: "backup_\(Int(Date().timeIntervalSince1970))",
            timestamp: Int64(Date().timeIntervalSince1970),
            size: Int64(estimatedSizeString.contains("GB") ? 256 * 1024 * 1024 : 128 * 1024 * 1024),
            contentSummary: selectedItems.joined(separator: " + "),
            items: []
        )
        backupRecords.insert(newRecord, at: 0)

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.notificationSuccess()
        }
        AppUtility.showToast(AppStrings.Backup.backupComplete)
        tableView.reloadData()
    }

    // MARK: - 恢复操作
    private func startRestore(record: BackupRecord) {
        guard !isRestoring else { return }

        let alert = UIAlertController(title: AppStrings.Backup.restore, message: AppStrings.Backup.restoreConfirm, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: AppStrings.Backup.restore, style: .default) { [weak self] _ in
            self?.performRestore(record: record)
        })
        present(alert, animated: true)
    }

    private func performRestore(record: BackupRecord) {
        isRestoring = true
        restoreProgress = 0
        progressTitleLabel.text = AppStrings.Backup.restoring
        showProgressOverlay()
        startRotatingAnimation()

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }

        // TODO: 接入真实恢复逻辑，当前为模拟进度
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.restoreProgress += 0.015
            self.progressBar.setProgress(self.restoreProgress, animated: true, duration: 0.05)
            self.progressPercentLabel.text = String(format: "%.0f%%", self.restoreProgress * 100)

            if self.restoreProgress >= 1.0 {
                timer.invalidate()
                self.completeRestore()
            }
        }
    }

    private func completeRestore() {
        isRestoring = false
        hideProgressOverlay()

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.notificationSuccess()
        }
        AppUtility.showToast(AppStrings.Backup.restoreComplete)
    }

    // MARK: - 进度浮层控制
    private func showProgressOverlay() {
        progressOverlayView.alpha = 0
        progressOverlayView.isHidden = false
        progressBar.setProgress(0, animated: false)
        progressPercentLabel.text = "0%"

        UIView.animate(withDuration: AnimationDuration.normal) {
            self.progressOverlayView.alpha = 1
        }

        // 玻璃卡片显现
        progressCard.animateGlassAppear(duration: AnimationDuration.slow)
    }

    private func hideProgressOverlay() {
        stopRotatingAnimation()
        UIView.animate(withDuration: AnimationDuration.normal, animations: {
            self.progressOverlayView.alpha = 0
        }) { _ in
            self.progressOverlayView.isHidden = true
        }
    }

    // MARK: - 旋转动画
    private func startRotatingAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1.0
        rotation.repeatCount = .infinity
        rotatingIcon.layer.add(rotation, forKey: "rotation")
    }

    private func stopRotatingAnimation() {
        rotatingIcon.layer.removeAnimation(forKey: "rotation")
    }

    // MARK: - 内容选择切换
    @objc private func toggleContentSelection(_ sender: UISwitch) {
        let index = sender.tag
        contentSelection[index].selected = sender.isOn

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }

        // 刷新状态信息行
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }

    // MARK: - 自动备份开关
    @objc private func toggleAutoBackup(_ sender: UISwitch) {
        autoBackupEnabled = sender.isOn

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }

        // TODO: 保存自动备份设置到本地
        tableView.reloadSections(IndexSet(integer: 4), with: .automatic)
    }

    @objc private func toggleWifiOnly(_ sender: UISwitch) {
        wifiOnly = sender.isOn

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }

        // TODO: 保存设置到本地
    }

    // MARK: - 频率选择
    private func showFrequencyPicker() {
        let alert = UIAlertController(title: AppStrings.Backup.frequency, message: nil, preferredStyle: .actionSheet)
        let frequencies = [AppStrings.Backup.daily, AppStrings.Backup.weekly, AppStrings.Backup.monthly]
        for (index, freq) in frequencies.enumerated() {
            let action = UIAlertAction(title: freq, style: .default) { [weak self] _ in
                self?.backupFrequency = index
                self?.tableView.reloadData()
            }
            if index == backupFrequency {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    // MARK: - 备份时间选择
    private func showTimePicker() {
        let alert = UIAlertController(title: AppStrings.Backup.backupTime, message: nil, preferredStyle: .actionSheet)
        let times = ["00:00", "02:00", "04:00", "06:00", "23:00"]
        for time in times {
            let action = UIAlertAction(title: time, style: .default) { [weak self] _ in
                self?.backupHour = Int(time.prefix(2)) ?? 2
                self?.tableView.reloadData()
            }
            if Int(time.prefix(2)) == backupHour {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    // MARK: - 删除备份
    private func deleteBackup(at index: Int) {
        let alert = UIAlertController(title: AppStrings.Backup.deleteBackup, message: "确认删除此备份？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: AppStrings.Common.delete, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.backupRecords.remove(at: index)
            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.notificationSuccess()
            }
            AppUtility.showToast(AppStrings.Common.operationSuccess)
            self.tableView.reloadData()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension BackupRestoreViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // 状态信息：上次备份时间、预计大小
        case 1: return contentSelection.count // 备份内容选择
        case 2: return 2 // 操作按钮：备份、恢复
        case 3: return max(backupRecords.count, 1) // 可用备份列表
        case 4: return autoBackupEnabled ? 4 : 1 // 自动备份设置
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return nil
        case 1: return AppStrings.Backup.backupContent
        case 2: return nil
        case 3: return AppStrings.Backup.availableBackups
        case 4: return AppStrings.Backup.autoBackupSettings
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return "选择需要备份的内容类型"
        case 4 where autoBackupEnabled: return "自动备份将在设备空闲且连接 Wi-Fi 时进行"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        // Section 0: 状态信息
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
            if indexPath.row == 0 {
                cell.configure(icon: "clock.arrow.circlepath", title: AppStrings.Backup.lastBackupTime, iconColor: .themeColorPrimary)
                cell.setDetailText(lastBackupTimeString)
            } else {
                cell.configure(icon: "externaldrive.fill", title: AppStrings.Backup.estimatedSize, iconColor: .themeColorSecondary)
                cell.setDetailText(estimatedSizeString)
            }
            cell.selectionStyle = .none
            return cell

        // Section 1: 备份内容选择
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BackupContentCell", for: indexPath) as! BackupContentCell
            let item = contentSelection[indexPath.row]
            let iconColors: [UIColor] = [.themeColorPrimary, .themeColorSecondary, .themeSuccess, .themeInfo]
            cell.configure(icon: item.icon, title: item.title, iconColor: iconColors[indexPath.row % iconColors.count], isOn: item.selected)
            cell.toggleSwitch.tag = indexPath.row
            cell.toggleSwitch.addTarget(self, action: #selector(toggleContentSelection(_:)), for: .valueChanged)
            cell.selectionStyle = .none
            return cell

        // Section 2: 操作按钮
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
            if indexPath.row == 0 {
                cell.configure(icon: "arrow.up.circle.fill", title: AppStrings.Backup.backupNow, iconColor: .themeSuccess)
                cell.setTitleColor(.themeColorPrimary)
            } else {
                cell.configure(icon: "arrow.down.circle.fill", title: AppStrings.Backup.restoreNow, iconColor: .themeColorPrimary)
                cell.setTitleColor(.themeColorPrimary)
            }
            return cell

        // Section 3: 可用备份列表
        case 3:
            if backupRecords.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
                cell.configure(icon: "tray", title: AppStrings.Backup.noBackup, iconColor: .themeTextTertiary)
                cell.selectionStyle = .none
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "BackupRecordCell", for: indexPath) as! BackupRecordCell
            let record = backupRecords[indexPath.row]
            cell.configure(record: record)
            cell.selectionStyle = .none
            return cell

        // Section 4: 自动备份设置
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
            switch indexPath.row {
            case 0:
                cell.configure(icon: "arrow.triangle.2.circlepath.circle.fill", title: AppStrings.Backup.autoBackup, iconColor: .themeColorPrimary)
                cell.selectionStyle = .none
                let toggle = UISwitch()
                toggle.onTintColor = .themeColorPrimary
                toggle.isOn = autoBackupEnabled
                toggle.addTarget(self, action: #selector(toggleAutoBackup(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 1:
                cell.configure(icon: "calendar", title: AppStrings.Backup.frequency, iconColor: .themeColorSecondary)
                let freqTexts = [AppStrings.Backup.daily, AppStrings.Backup.weekly, AppStrings.Backup.monthly]
                cell.setDetailText(freqTexts[backupFrequency])
            case 2:
                cell.configure(icon: "wifi", title: AppStrings.Backup.wifiOnly, iconColor: .themeInfo)
                cell.selectionStyle = .none
                let toggle = UISwitch()
                toggle.onTintColor = .themeColorPrimary
                toggle.isOn = wifiOnly
                toggle.addTarget(self, action: #selector(toggleWifiOnly(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 3:
                cell.configure(icon: "clock.fill", title: AppStrings.Backup.backupTime, iconColor: .themeColorSecondary)
                cell.setDetailText(String(format: "%02d:00", backupHour))
            default:
                break
            }
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 2:
            if indexPath.row == 0 {
                startBackup()
            } else {
                // 恢复 - 跳转到备份列表或提示选择
                if backupRecords.isEmpty {
                    AppUtility.showToast(AppStrings.Backup.noBackup)
                } else {
                    tableView.scrollToRow(at: IndexPath(row: 0, section: 3), at: .middle, animated: true)
                }
            }
        case 3:
            if !backupRecords.isEmpty {
                startRestore(record: backupRecords[indexPath.row])
            }
        case 4:
            switch indexPath.row {
            case 1: showFrequencyPicker()
            case 3: showTimePicker()
            default: break
            }
        default:
            break
        }
    }

    // 滑动删除备份
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 3, !backupRecords.isEmpty else { return nil }
        let delete = UIContextualAction(style: .destructive, title: AppStrings.Backup.deleteBackup) { [weak self] _, _, completion in
            self?.deleteBackup(at: indexPath.row)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - 备份内容选择 Cell
class BackupContentCell: UITableViewCell {

    private let iconBgView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    let toggleSwitch = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgCard
        contentView.backgroundColor = .themeBgCard

        let iconSize: CGFloat = 28

        iconBgView.layer.cornerRadius = 6
        iconBgView.clipsToBounds = true
        contentView.addSubview(iconBgView)
        iconBgView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }

        iconImageView.tintColor = .white
        iconImageView.contentMode = .center
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.preferredSymbolConfiguration = config
        iconBgView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        titleLabel.font = ScreenAdapter.font(15)
        titleLabel.textColor = .themeTextPrimary
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBgView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        toggleSwitch.onTintColor = .themeColorPrimary
        contentView.addSubview(toggleSwitch)
        toggleSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    func configure(icon: String, title: String, iconColor: UIColor, isOn: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)
        iconBgView.backgroundColor = iconColor
        titleLabel.text = title
        toggleSwitch.isOn = isOn
    }
}

// MARK: - 备份记录 Cell
class BackupRecordCell: UITableViewCell {

    private let iconBgView = UIView()
    private let iconImageView = UIImageView()
    private let timeLabel = UILabel()
    private let sizeLabel = UILabel()
    private let summaryLabel = UILabel()
    private let arrowView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgCard
        contentView.backgroundColor = .themeBgCard

        let iconSize: CGFloat = 28

        iconBgView.layer.cornerRadius = 6
        iconBgView.clipsToBounds = true
        iconBgView.backgroundColor = .themeColorPrimary
        contentView.addSubview(iconBgView)
        iconBgView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }

        iconImageView.tintColor = .white
        iconImageView.contentMode = .center
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.preferredSymbolConfiguration = config
        iconImageView.image = UIImage(systemName: "arrow.down.to.line.alt", withConfiguration: config)
        iconBgView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 时间标签
        timeLabel.font = ScreenAdapter.mediumFont(15)
        timeLabel.textColor = .themeTextPrimary
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBgView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(8)
        }

        // 大小 + 摘要
        let infoStack = UIStackView()
        infoStack.axis = .horizontal
        infoStack.spacing = 8
        infoStack.alignment = .fill
        contentView.addSubview(infoStack)
        infoStack.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel)
            make.top.equalTo(timeLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(arrowView.snp.leading).offset(-8)
        }

        sizeLabel.font = ScreenAdapter.font(12)
        sizeLabel.textColor = .themeTextSecondary
        infoStack.addArrangedSubview(sizeLabel)

        summaryLabel.font = ScreenAdapter.font(12)
        summaryLabel.textColor = .themeTextTertiary
        infoStack.addArrangedSubview(summaryLabel)

        // 箭头
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = .themeTextTertiary
        arrowView.contentMode = .scaleAspectFit
        contentView.addSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
    }

    func configure(record: BackupRecord) {
        timeLabel.text = record.timeString
        sizeLabel.text = record.sizeString
        summaryLabel.text = "· \(record.contentSummary)"
    }
}
