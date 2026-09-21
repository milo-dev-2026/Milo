import UIKit
import SnapKit

class ChatBackgroundViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var backgrounds: [(name: String, color: UIColor)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "聊天背景"
        view.backgroundColor = .themeBackground

        backgrounds = [
            ("默认", .themeChatBackground),
            ("浅灰", UIColor(white: 0.95, alpha: 1)),
            ("白色", .white),
            ("浅蓝", UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)),
            ("浅绿", UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1)),
            ("浅黄", UIColor(red: 1.0, green: 0.98, blue: 0.9, alpha: 1)),
            ("米色", UIColor(red: 0.98, green: 0.96, blue: 0.9, alpha: 1)),
            ("深灰", UIColor(white: 0.3, alpha: 1))
        ]

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BgCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension ChatBackgroundViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return backgrounds.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BgCell", for: indexPath)
        let bg = backgrounds[indexPath.row]
        cell.textLabel?.text = bg.name
        cell.textLabel?.font = ScreenAdapter.font(16)

        let preview = UIView()
        preview.backgroundColor = bg.color
        preview.layer.cornerRadius = ScreenAdapter.scaleW(6)
        preview.layer.borderWidth = 0.5
        preview.layer.borderColor = UIColor.systemGray3.cgColor
        cell.accessoryView = preview
        preview.snp.makeConstraints { make in
            make.width.equalTo(ScreenAdapter.scaleW(40))
            make.height.equalTo(ScreenAdapter.scaleH(28))
        }

        let saved = UserDefaults.standard.integer(forKey: "chat_bg_index")
        cell.accessoryType = saved == indexPath.row ? .checkmark : .none
        cell.imageView?.image = UIImage(systemName: "photo")
        cell.imageView?.tintColor = .themePrimary
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UserDefaults.standard.set(indexPath.row, forKey: "chat_bg_index")
        UserDefaults.standard.synchronize()
        tableView.reloadData()
        AppUtility.showToast("已设置聊天背景")
    }
}
