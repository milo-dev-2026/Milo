//
//  GeneralSettingViewController.swift
//  Milo
//
//  通用设置 - 主题、语言、字体、缓存
//

import UIKit
import SnapKit

class GeneralSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Row: Int, CaseIterable {
        case theme = 0
        case language = 1
        case fontSize = 2
        case cache = 3
    }

    private let rowTitles = ["主题", "多语言", "字体大小", "缓存管理"]
    private let rowIcons = ["moon.circle.fill", "globe", "textformat.size", "internaldrive"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupUI() {
        title = "通用"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GeneralCell")
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 右侧详情文本
    private func detailText(for row: Row) -> String {
        let defaults = UserDefaults.standard
        switch row {
        case .theme:
            let value = defaults.string(forKey: "app_theme") ?? "system"
            switch value {
            case "light": return "浅色"
            case "dark":  return "深色"
            default:      return "跟随系统"
            }
        case .language:
            let lang = defaults.string(forKey: "app_language") ?? "zh-Hans"
            let map: [String: String] = [
                "zh-Hans": "简体中文",
                "zh-Hant": "繁體中文",
                "en": "English",
                "ja": "日本語",
                "ko": "한국어"
            ]
            return map[lang] ?? "简体中文"
        case .fontSize:
            let scale = defaults.object(forKey: "app_font_scale") as? Float ?? 1.0
            if scale <= 0.9 { return "小" }
            if scale >= 1.3 { return "特大" }
            if scale >= 1.1 { return "大" }
            return "标准"
        case .cache:
            let bytes = IMManager.shared.messageCacheSize
            return formatCacheSize(bytes)
        }
    }

    private func formatCacheSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - 跳转
    private func handleSelect(_ row: Row) {
        switch row {
        case .theme:
            navigationController?.pushViewController(ThemeSettingViewController(), animated: true)
        case .language:
            navigationController?.pushViewController(LanguageSettingViewController(), animated: true)
        case .fontSize:
            navigationController?.pushViewController(FontSizeSettingViewController(), animated: true)
        case .cache:
            navigationController?.pushViewController(CacheManagerViewController(), animated: true)
        }
    }
}

extension GeneralSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "GeneralCell")
        let row = Row(rawValue: indexPath.row)!

        cell.textLabel?.text = rowTitles[indexPath.row]
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary

        cell.detailTextLabel?.text = detailText(for: row)
        cell.detailTextLabel?.font = ThemeFont.bodySmall(14)
        cell.detailTextLabel?.textColor = .themeTextSecondary

        cell.imageView?.image = UIImage(systemName: rowIcons[indexPath.row])
        cell.imageView?.tintColor = .themeColorPrimary

        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .themeBgWhite
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let row = Row(rawValue: indexPath.row) {
            handleSelect(row)
        }
    }
}
