import UIKit
import SnapKit

class MultiForwardDetailViewController: UIViewController {

    private let messages: [Message]
    private let tableView = UITableView()

    init(messages: [Message]) {
        self.messages = messages
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "合并转发 (\(messages.count)条)"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MFCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: ScreenAdapter.scaleW(16), bottom: 0, right: 0)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let forwardBtn = UIButton(type: .system)
        forwardBtn.setTitle("转发给...", for: .normal)
        forwardBtn.backgroundColor = .themePrimary
        forwardBtn.setTitleColor(.white, for: .normal)
        forwardBtn.titleLabel?.font = ScreenAdapter.mediumFont(16)
        forwardBtn.layer.cornerRadius = ScreenAdapter.scaleW(8)
        forwardBtn.addTarget(self, action: #selector(forwardAll), for: .touchUpInside)

        view.addSubview(forwardBtn)
        forwardBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-ScreenAdapter.scaleH(16))
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ScreenAdapter.scaleH(64), right: 0)
    }

    @objc private func forwardAll() {
        let alert = UIAlertController(title: "转发给", message: "输入对方ID", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "用户ID"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "发送", style: .default) { [weak self] _ in
            guard let targetId = alert.textFields?.first?.text, !targetId.isEmpty else { return }
            self?.sendMultiForward(to: targetId)
        })
        present(alert, animated: true)
    }

    private func sendMultiForward(to targetId: String) {
        let combined = messages.map { msg in
            "\(msg.fromUID): \(msg.content)"
        }.joined(separator: "\n\n")

        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.sendMessage(channelId: targetId, content: combined, type: 1, channelType: 1))
                DispatchQueue.main.async {
                    AppUtility.showToast("已转发")
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("转发失败")
                }
            }
        }
    }
}

extension MultiForwardDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MFCell", for: indexPath)
        let msg = messages[indexPath.row]
        let timeStr = msg.timeString
        cell.textLabel?.text = "[\(timeStr)] \(msg.content)"
        cell.textLabel?.font = ScreenAdapter.font(15)
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }
}
