import UIKit
import SnapKit

// MARK: - 消息通知设置（对照 Android MsgNoticesSettingActivity）
class MsgNoticesSettingViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - 本地存储 Key（notify_ 前缀）
    private enum Keys {
        static let newMessage = "notify_new_message"
        static let showDetail = "notify_show_detail"
        static let voice = "notify_voice"
        static let shock = "notify_shock"
        static let dndOn = "notify_dnd_on"
        static let dndStart = "notify_dnd_start"
        static let dndEnd = "notify_dnd_end"
    }

    private var newMessageOn: Bool {
        get {
            UserDefaults.standard.object(forKey: Keys.newMessage) as? Bool
                ?? LocalStore.shared.isMessageNotificationEnabled
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.newMessage) }
    }

    private var showDetailOn: Bool {
        get {
            UserDefaults.standard.object(forKey: Keys.showDetail) as? Bool
                ?? LocalStore.shared.isNotificationDetailEnabled
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.showDetail) }
    }

    private var voiceOn: Bool {
        get {
            UserDefaults.standard.object(forKey: Keys.voice) as? Bool
                ?? LocalStore.shared.isSoundEnabled
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.voice) }
    }

    private var shockOn: Bool {
        get {
            UserDefaults.standard.object(forKey: Keys.shock) as? Bool
                ?? LocalStore.shared.isVibrationEnabled
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.shock) }
    }

    private var dndOn: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.dndOn) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dndOn) }
    }

    private var dndStart: String {
        get { UserDefaults.standard.string(forKey: Keys.dndStart) ?? "22:00" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dndStart) }
    }

    private var dndEnd: String {
        get { UserDefaults.standard.string(forKey: Keys.dndEnd) ?? "08:00" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dndEnd) }
    }

    // 行引用（用于刷新开关/时间显示）
    private let newMessageRow = MsgNoticeRowView(showSwitch: true)
    private let detailRow = MsgNoticeRowView(showSwitch: true)
    private let voiceRow = MsgNoticeRowView(showSwitch: true)
    private let shockRow = MsgNoticeRowView(showSwitch: true)
    private let dndRow = MsgNoticeRowView(showSwitch: true)
    private let dndStartRow = MsgNoticeRowView(showArrow: true)
    private let dndEndRow = MsgNoticeRowView(showArrow: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "消息通知"
        view.backgroundColor = .themeBackground
        setupUI()
        refreshUI()
    }

    // MARK: - 布局
    private func setupUI() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // 顶部横幅
        let banner = makeBanner(
            icon: "bell.fill",
            title: "自定义消息提醒方式",
            desc: "设置消息展示、声音与震动，也可前往系统管理通知权限"
        )
        contentView.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 消息提醒
        for row in [newMessageRow, detailRow, voiceRow, shockRow, dndRow] {
            row.switchControl.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        }

        let reminderLabel = makeSectionLabel("消息提醒")
        contentView.addSubview(reminderLabel)
        reminderLabel.snp.makeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        newMessageRow.configure(
            title: "新消息通知",
            subtitle: "控制是否接收聊天消息的推送提醒",
            switchOn: newMessageOn,
            tag: 0
        )
        newMessageRow.onTap = { [weak self] in
            self?.showGoSettingDialog(
                title: "新消息通知",
                message: "前往系统设置页面开启新消息通知权限，以确保您能及时收到消息提醒。"
            )
        }

        detailRow.configure(
            title: "通知显示消息详情",
            subtitle: "在通知中显示发送人和消息内容",
            switchOn: showDetailOn,
            tag: 1
        )
        detailRow.onTap = { [weak self] in
            self?.showGoSettingDialog(
                title: "通知显示消息详情",
                message: "前往系统通知渠道设置页面，可设置通知是否在锁屏时显示消息详情。"
            )
        }

        voiceRow.configure(
            title: "声音",
            subtitle: "收到新消息时播放提示音",
            switchOn: voiceOn,
            tag: 2
        )
        voiceRow.onTap = { [weak self] in
            self?.showGoSettingDialog(
                title: "通知声音",
                message: "前往系统通知渠道设置页面，可自定义通知铃声和声音大小。"
            )
        }

        shockRow.configure(
            title: "震动",
            subtitle: "收到新消息时使用震动提醒",
            switchOn: shockOn,
            tag: 3
        )
        shockRow.onTap = { [weak self] in
            self?.showGoSettingDialog(
                title: "通知震动",
                message: "前往系统通知渠道设置页面，可开启或关闭通知震动提醒。"
            )
        }

        let reminderCard = makeGlassCard(rows: [newMessageRow, detailRow, voiceRow, shockRow])
        contentView.addSubview(reminderCard)
        reminderCard.snp.makeConstraints { make in
            make.top.equalTo(reminderLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 系统通知
        let systemLabel = makeSectionLabel("系统通知")
        contentView.addSubview(systemLabel)
        systemLabel.snp.makeConstraints { make in
            make.top.equalTo(reminderCard.snp.bottom).offset(20)
            make.leading.equalTo(reminderLabel)
        }

        let systemMessageRow = MsgNoticeRowView(showArrow: true)
        systemMessageRow.configure(
            title: "新消息通知",
            subtitle: "管理新消息通知渠道、铃声与重要程度",
            rightText: "前往系统设置"
        )
        systemMessageRow.onTap = { [weak self] in
            self?.openSystemSettings()
        }

        let systemCallRow = MsgNoticeRowView(showArrow: true)
        systemCallRow.configure(
            title: "语音通话提醒",
            subtitle: "管理语音通话的系统提醒",
            rightText: "前往系统设置"
        )
        systemCallRow.onTap = { [weak self] in
            self?.openSystemSettings()
        }

        let systemCard = makeGlassCard(rows: [systemMessageRow, systemCallRow])
        contentView.addSubview(systemCard)
        systemCard.snp.makeConstraints { make in
            make.top.equalTo(systemLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(reminderCard)
        }

        // 免打扰时段
        let dndLabel = makeSectionLabel("免打扰时段")
        contentView.addSubview(dndLabel)
        dndLabel.snp.makeConstraints { make in
            make.top.equalTo(systemCard.snp.bottom).offset(20)
            make.leading.equalTo(reminderLabel)
        }

        dndRow.configure(
            title: "开启免打扰",
            subtitle: "在设定时段内静音消息和通话提醒",
            switchOn: dndOn,
            tag: 4
        )
        dndRow.onTap = nil

        dndStartRow.configure(title: "开始时间", subtitle: nil, rightText: dndStart)
        dndStartRow.onTap = { [weak self] in
            self?.showTimePicker(isStart: true)
        }

        dndEndRow.configure(title: "结束时间", subtitle: nil, rightText: dndEnd)
        dndEndRow.onTap = { [weak self] in
            self?.showTimePicker(isStart: false)
        }

        let dndCard = makeGlassCard(rows: [dndRow, dndStartRow, dndEndRow])
        contentView.addSubview(dndCard)
        dndCard.snp.makeConstraints { make in
            make.top.equalTo(dndLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(reminderCard)
            make.bottom.equalToSuperview().offset(-30)
        }
    }

    // MARK: - 刷新
    private func refreshUI() {
        newMessageRow.switchControl.isOn = newMessageOn
        detailRow.switchControl.isOn = showDetailOn
        voiceRow.switchControl.isOn = voiceOn
        shockRow.switchControl.isOn = shockOn
        dndRow.switchControl.isOn = dndOn

        dndStartRow.setRightText(dndStart)
        dndEndRow.setRightText(dndEnd)

        let enabled = dndOn
        dndStartRow.isEnabled = enabled
        dndEndRow.isEnabled = enabled
    }

    // MARK: - 开关事件
    @objc private func switchChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 0:
            newMessageOn = sender.isOn
            LocalStore.shared.isMessageNotificationEnabled = sender.isOn
            AppUtility.showToast(sender.isOn ? "已开启新消息通知" : "已关闭新消息通知")
        case 1:
            showDetailOn = sender.isOn
            LocalStore.shared.isNotificationDetailEnabled = sender.isOn
            AppUtility.showToast(sender.isOn ? "已开启消息详情" : "已关闭消息详情")
        case 2:
            voiceOn = sender.isOn
            LocalStore.shared.isSoundEnabled = sender.isOn
            AppUtility.showToast(sender.isOn ? "已开启声音" : "已关闭声音")
        case 3:
            shockOn = sender.isOn
            LocalStore.shared.isVibrationEnabled = sender.isOn
            AppUtility.showToast(sender.isOn ? "已开启震动" : "已关闭震动")
        default:
            dndOn = sender.isOn
            AppUtility.showToast(sender.isOn ? "已开启免打扰" : "已关闭免打扰")
            refreshUI()
        }
    }

    // MARK: - 免打扰时间选择
    private func showTimePicker(isStart: Bool) {
        guard dndOn else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "zh_CN")
        if let date = formatter.date(from: isStart ? dndStart : dndEnd) {
            picker.date = date
        }

        let sheet = UIViewController()
        sheet.view.backgroundColor = .themeBgCard
        if let sheetPresentation = sheet.sheetPresentationController {
            sheetPresentation.detents = [.medium()]
            sheetPresentation.prefersGrabberVisible = true
        }

        let titleLabel = UILabel()
        titleLabel.text = isStart ? "开始时间" : "结束时间"
        titleLabel.font = ScreenAdapter.mediumFont(16)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        sheet.view.addSubview(titleLabel)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = ScreenAdapter.font(15)
        cancelButton.setTitleColor(.secondaryLabel, for: .normal)
        cancelButton.addAction(UIAction { [weak sheet] _ in
            sheet?.dismiss(animated: true)
        }, for: .touchUpInside)
        sheet.view.addSubview(cancelButton)

        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.titleLabel?.font = ScreenAdapter.font(15)
        confirmButton.setTitleColor(.themePrimary, for: .normal)
        confirmButton.addAction(UIAction { [weak self, weak sheet] _ in
            guard let self = self else { return }
            let time = formatter.string(from: picker.date)
            if isStart {
                self.dndStart = time
            } else {
                self.dndEnd = time
            }
            self.refreshUI()
            AppUtility.showToast("\(isStart ? "开始时间" : "结束时间")已设为 \(time)")
            sheet?.dismiss(animated: true)
        }, for: .touchUpInside)
        sheet.view.addSubview(confirmButton)

        sheet.view.addSubview(picker)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalTo(titleLabel)
            make.width.equalTo(48)
            make.height.equalTo(32)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
            make.width.equalTo(48)
            make.height.equalTo(32)
        }
        picker.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(sheet.view.safeAreaLayoutGuide).offset(-12)
        }

        present(sheet, animated: true)
    }

    // MARK: - 系统设置
    private func showGoSettingDialog(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { [weak self] _ in
            self?.openSystemSettings()
        })
        present(alert, animated: true)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - UI 构建
    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = ScreenAdapter.font(13)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeBanner(icon: String, title: String, desc: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .clear
        card.layer.cornerRadius = 16
        card.applyLiquidGlassEffect(cornerRadius: 16)

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor.themePrimary.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 24
        iconBg.clipsToBounds = true
        card.addSubview(iconBg)
        iconBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .themePrimary
        iconView.contentMode = .scaleAspectFit
        iconBg.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ScreenAdapter.boldFont(16)
        titleLabel.textColor = .label
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBg.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-20)
        }

        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = ScreenAdapter.font(13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-26)
        }

        return card
    }

    /// 液态玻璃卡片，内部按顺序纵向排列行
    private func makeGlassCard(rows: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = .clear
        card.layer.cornerRadius = 16
        card.applyLiquidGlassEffect(cornerRadius: 16)

        var previous: UIView?
        for row in rows {
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                if let previous = previous {
                    make.top.equalTo(previous.snp.bottom).offset(0.5)
                } else {
                    make.top.equalToSuperview()
                }
            }
            if previous != nil {
                let separator = UIView()
                separator.backgroundColor = .themeSeparatorLight
                card.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.trailing.equalToSuperview()
                    make.height.equalTo(0.5)
                    make.bottom.equalTo(row.snp.top)
                }
            }
            previous = row
        }
        previous?.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
        return card
    }
}

// MARK: - 消息通知行
private final class MsgNoticeRowView: UIView, UIGestureRecognizerDelegate {

    let switchControl = UISwitch()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let rightLabel = UILabel()
    private let arrowView = UIImageView()

    private let showsSwitch: Bool
    private let showsArrow: Bool

    /// 无副标题时由 title 决定行高
    private var titleBottomConstraint: Constraint?
    private var subtitleBottomConstraint: Constraint?

    var onTap: (() -> Void)?

    init(showSwitch: Bool = false, showArrow: Bool = false) {
        self.showsSwitch = showSwitch
        self.showsArrow = showArrow
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        titleLabel.font = ScreenAdapter.font(16)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            titleBottomConstraint = make.bottom.equalToSuperview().offset(-14).constraint
        }
        titleBottomConstraint?.isActive = false

        subtitleLabel.font = ScreenAdapter.font(13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            subtitleBottomConstraint = make.bottom.equalToSuperview().offset(-14).constraint
        }

        if showsSwitch {
            addSubview(switchControl)
            switchControl.onTintColor = .themePrimary
            switchControl.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
            }
            titleLabel.snp.makeConstraints { make in
                make.trailing.lessThanOrEqualTo(switchControl.snp.leading).offset(-8)
            }
            subtitleLabel.snp.makeConstraints { make in
                make.trailing.lessThanOrEqualTo(switchControl.snp.leading).offset(-8)
            }
        }

        if showsArrow {
            arrowView.image = UIImage(systemName: "chevron.right")
            arrowView.tintColor = UIColor(white: 0.8, alpha: 1.0)
            arrowView.contentMode = .scaleAspectFit
            addSubview(arrowView)
            arrowView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(14)
            }
            addSubview(rightLabel)
            rightLabel.font = ScreenAdapter.font(13)
            rightLabel.textColor = .themePrimary
            rightLabel.snp.makeConstraints { make in
                make.trailing.equalTo(arrowView.snp.leading).offset(-8)
                make.centerY.equalToSuperview()
            }
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.delegate = self
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    func configure(title: String, subtitle: String?, switchOn: Bool = false, tag: Int = 0, rightText: String? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        let hasSubtitle = !(subtitle ?? "").isEmpty
        subtitleLabel.isHidden = !hasSubtitle
        subtitleBottomConstraint?.isActive = hasSubtitle
        titleBottomConstraint?.isActive = !hasSubtitle
        if showsSwitch {
            switchControl.isOn = switchOn
            switchControl.tag = tag
        }
        if showsArrow, let rightText = rightText {
            rightLabel.text = rightText
        }
    }

    func setRightText(_ text: String) {
        rightLabel.text = text
    }

    @objc private func handleTap() {
        onTap?()
    }

    // 开关自身处理点击，避免同时触发行点击
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !(touchedView === switchControl || touchedView.isDescendant(of: switchControl))
    }

    var isEnabled: Bool = true {
        didSet {
            isUserInteractionEnabled = isEnabled
            rightLabel.alpha = isEnabled ? 1.0 : 0.5
        }
    }
}
