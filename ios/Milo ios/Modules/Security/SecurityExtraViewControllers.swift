//
//  SecurityExtraViewControllers.swift
//  Milo
//
//  安全中心补充页面
//  包含：滑动验证码、阅后即焚定时器
//

import UIKit
import SnapKit

// MARK: - 滑动验证码
class SwipeCaptchaViewController: UIViewController {

    private let captchaView = SwipeCaptchaView()
    private let verifyButton = UIButton(type: .system)

    var onVerifySuccess: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "安全验证"
        view.backgroundColor = .themeBg

        // 提示卡片
        let tipCard = UIView()
        tipCard.backgroundColor = .themeBgCard
        tipCard.layer.cornerRadius = 12
        view.addSubview(tipCard)
        tipCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }

        let tipIcon = UIImageView(image: UIImage(systemName: "shield.lefthalf.filled"))
        tipIcon.tintColor = .themeColorPrimary
        tipIcon.contentMode = .scaleAspectFit
        tipCard.addSubview(tipIcon)
        tipIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(48)
        }

        let tipTitle = UILabel()
        tipTitle.text = "请完成安全验证"
        tipTitle.font = ThemeFont.title2(18)
        tipTitle.textColor = .themeTextPrimary
        tipTitle.textAlignment = .center
        tipCard.addSubview(tipTitle)
        tipTitle.snp.makeConstraints { make in
            make.top.equalTo(tipIcon.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        let tipDesc = UILabel()
        tipDesc.text = "请向右滑动完成验证，以证明您不是机器人"
        tipDesc.font = ThemeFont.bodySmall(14)
        tipDesc.textColor = .themeTextSecondary
        tipDesc.textAlignment = .center
        tipDesc.numberOfLines = 0
        tipCard.addSubview(tipDesc)
        tipDesc.snp.makeConstraints { make in
            make.top.equalTo(tipTitle.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        // 滑块验证码
        view.addSubview(captchaView)
        captchaView.snp.makeConstraints { make in
            make.top.equalTo(tipCard.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(40)
        }

        captchaView.onVerify = { [weak self] completion in
            // 模拟验证过程
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let success = Bool.random() // 模拟随机成功/失败
                completion(success)
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.handleVerifySuccess()
                    }
                }
            }
        }

        tipCard.snp.makeConstraints { make in
            make.bottom.equalTo(tipDesc.snp.bottom).offset(24)
        }
    }

    private func handleVerifySuccess() {
        AppUtility.showToast("验证成功")
        onVerifySuccess?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - 阅后即焚定时器
class SecretDeleteTimerViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let timerOptions = [
        (seconds: 0, title: "关闭", desc: "阅后即焚已关闭"),
        (seconds: 5, title: "5秒", desc: "消息已读后5秒自动销毁"),
        (seconds: 10, title: "10秒", desc: "消息已读后10秒自动销毁"),
        (seconds: 30, title: "30秒", desc: "消息已读后30秒自动销毁"),
        (seconds: 60, title: "1分钟", desc: "消息已读后1分钟自动销毁"),
        (seconds: 300, title: "5分钟", desc: "消息已读后5分钟自动销毁"),
    ]

    private var selectedIndex = 0
    var channelId: String = ""
    var channelType: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "阅后即焚"
        view.backgroundColor = .themeBg

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TimerCell")

        // Header 说明
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        headerView.backgroundColor = .clear

        let tipLabel = UILabel()
        tipLabel.text = "设置阅后即焚时间后，消息在对方已读后将在指定时间内自动销毁"
        tipLabel.font = ThemeFont.caption(13)
        tipLabel.textColor = .themeTextSecondary
        tipLabel.numberOfLines = 0
        headerView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        tableView.tableHeaderView = headerView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension SecretDeleteTimerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timerOptions.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "销毁时间"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimerCell", for: indexPath)
        let option = timerOptions[indexPath.row]

        cell.textLabel?.text = option.title
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite

        if indexPath.row == selectedIndex {
            cell.accessoryType = .checkmark
            cell.tintColor = .themeColorPrimary
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = indexPath.row
        tableView.reloadData()

        let option = timerOptions[indexPath.row]
        AppUtility.showToast("已设置为 \(option.title)")

        // TODO: 调用 API 设置阅后即焚时间
    }
}

// MARK: - 消息隐私 - 阅后即焚入口集成
class SecretChatSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let sections: [(title: String, items: [(title: String, detail: String?, type: CellType)])] = [
        ("", [
            (title: "阅后即焚", detail: "关闭", type: .disclosure),
        ]),
        ("", [
            (title: "截屏通知", detail: nil, type: .switch(true)),
        ]),
    ]

    enum CellType {
        case disclosure
        case `switch`(Bool)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "消息隐私"
        view.backgroundColor = .themeBg

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PrivacyCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension SecretChatSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrivacyCell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]

        cell.textLabel?.text = item.title
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite

        switch item.type {
        case .disclosure:
            cell.detailTextLabel?.text = item.detail
            cell.detailTextLabel?.font = ThemeFont.bodySmall(14)
            cell.detailTextLabel?.textColor = .themeTextSecondary
            cell.accessoryType = .disclosureIndicator

        case .switch(let isOn):
            cell.selectionStyle = .none
            let switchControl = UISwitch()
            switchControl.isOn = isOn
            switchControl.onTintColor = .themeColorPrimary
            switchControl.tag = indexPath.row
            switchControl.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 && indexPath.row == 0 {
            let vc = SecretDeleteTimerViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc private func switchToggled(_ sender: UISwitch) {
        AppUtility.showToast(sender.isOn ? "已开启" : "已关闭")
    }
}
