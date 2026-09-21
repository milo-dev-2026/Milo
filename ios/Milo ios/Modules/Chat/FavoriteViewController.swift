import UIKit
import SnapKit

class FavoriteViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var favorites: [FavoriteItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func setupUI() {
        title = "收藏"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FavCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadData() {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.getFavorites)
                if let data = response["data"] as? [String: Any],
                   let items = data["items"] as? [[String: Any]] {
                    favorites = items.compactMap { dict in
                        guard let id = dict["id"] as? Int,
                              let typeRaw = dict["type"] as? Int,
                              let type = FavoriteItem.FavType(rawValue: typeRaw),
                              let content = dict["content"] as? String,
                              let ts = (dict["created_at"] as? Int64).map(Int64.init) ?? (dict["created_at"] as? Int).map(Int64.init)
                        else { return nil }
                        return FavoriteItem(id: id, type: type, content: content, timestamp: ts)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载收藏失败")
                }
            }
        }
    }
}

struct FavoriteItem: Codable {
    enum FavType: Int { case text = 1, image = 2, link = 3 }
    let id: Int
    let type: FavType
    let content: String
    let timestamp: Int64
}

extension FavoriteViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavCell", for: indexPath)
        let item = favorites[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = ScreenAdapter.font(15)
        cell.textLabel?.numberOfLines = 2

        switch item.type {
        case .text:
            cell.textLabel?.text = item.content
            cell.imageView?.image = UIImage(systemName: "text.bubble")
        case .image:
            cell.textLabel?.text = "[图片]"
            cell.imageView?.image = UIImage(systemName: "photo")
        case .link:
            cell.textLabel?.text = item.content
            cell.imageView?.image = UIImage(systemName: "link")
        }
        cell.imageView?.tintColor = .themePrimary
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = favorites[indexPath.row]
        let detailVC = FavoriteDetailViewController(item: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            let item = self.favorites[indexPath.row]
            Task {
                do {
                    _ = try await APIClient.shared.requestRaw(.deleteFavorite(favId: item.id))
                    DispatchQueue.main.async {
                        self.favorites.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        AppUtility.showToast("已删除")
                    }
                    completion(true)
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("删除失败")
                    }
                    completion(false)
                }
            }
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

class FavoriteDetailViewController: UIViewController {

    private let item: FavoriteItem

    init(item: FavoriteItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "收藏详情"
        view.backgroundColor = .themeBackground

        let label = UILabel()
        label.text = item.content
        label.font = ScreenAdapter.font(16)
        label.numberOfLines = 0

        let scrollView = UIScrollView()
        scrollView.addSubview(label)
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.width.equalTo(view.bounds.width - ScreenAdapter.scaleW(32))
        }

        let forwardBtn = UIButton(type: .system)
        forwardBtn.setTitle("转发", for: .normal)
        forwardBtn.backgroundColor = .themePrimary
        forwardBtn.setTitleColor(.white, for: .normal)
        forwardBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        forwardBtn.addTarget(self, action: #selector(forward), for: .touchUpInside)

        view.addSubview(forwardBtn)
        forwardBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-ScreenAdapter.scaleH(16))
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }
    }

    @objc private func forward() {
        let alert = UIAlertController(title: "转发到", message: "输入对方ID", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "用户ID"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "发送", style: .default) { [weak self] _ in
            guard let targetId = alert.textFields?.first?.text, !targetId.isEmpty else { return }
            Task {
                do {
                    let typeVal: Int
                    switch self?.item.type {
                    case .text: typeVal = 1
                    case .image: typeVal = 2
                    default: typeVal = 1
                    }
                    _ = try await APIClient.shared.requestRaw(.sendMessage(channelId: targetId, content: self?.item.content ?? "", type: typeVal))
                    DispatchQueue.main.async {
                        AppUtility.showToast("已转发")
                    }
                } catch {
                    DispatchQueue.main.async {
                        AppUtility.showToast("转发失败")
                    }
                }
            }
        })
        present(alert, animated: true)
    }
}
