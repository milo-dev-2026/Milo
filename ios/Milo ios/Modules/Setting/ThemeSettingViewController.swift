//
//  ThemeSettingViewController.swift
//  Milo
//
//  主题设置 - 跟随系统 / 浅色 / 深色
//

import UIKit
import SnapKit

class ThemeSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let options: [(key: String, title: String, subtitle: String)] = [
        ("system", "跟随系统", "自动根据系统外观切换"),
        ("light",  "浅色模式", "始终使用浅色外观"),
        ("dark",   "深色模式", "始终使用深色外观"),
    ]

    private var currentKey: String {
        UserDefaults.standard.string(forKey: "app_theme") ?? "system"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "主题设置"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ThemeCell")
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 应用主题
    private func applyTheme(_ key: String) {
        let style: UIUserInterfaceStyle
        switch key {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        // 应用到所有 window
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}

extension ThemeSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ThemeCell")
        let option = options[indexPath.row]

        cell.textLabel?.text = option.title
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary

        cell.detailTextLabel?.text = option.subtitle
        cell.detailTextLabel?.font = ThemeFont.caption(13)
        cell.detailTextLabel?.textColor = .themeTextSecondary

        cell.backgroundColor = .themeBgWhite
        cell.tintColor = .themeColorPrimary
        cell.accessoryType = option.key == currentKey ? .checkmark : .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]

        UserDefaults.standard.set(option.key, forKey: "app_theme")
        applyTheme(option.key)
        tableView.reloadData()
    }
}
