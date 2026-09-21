import UIKit
import SnapKit

class GroupQRCodeViewController: UIViewController {

    private let groupId: String
    private let groupName: String
    private let qrImageView = UIImageView()

    init(groupId: String, groupName: String) {
        self.groupId = groupId
        self.groupName = groupName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateQRCode()
    }

    private func setupUI() {
        title = "群二维码"
        view.backgroundColor = .themeBackground

        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(16)

        let nameLabel = UILabel()
        nameLabel.text = groupName
        nameLabel.font = ScreenAdapter.mediumFont(18)
        nameLabel.textColor = .label

        let idLabel = UILabel()
        idLabel.text = "群ID: \(groupId)"
        idLabel.font = ScreenAdapter.font(13)
        idLabel.textColor = .secondaryLabel

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.backgroundColor = .white

        cardView.addSubviews(nameLabel, idLabel, qrImageView)
        view.addSubview(cardView)

        cardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(40))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.centerX.equalToSuperview()
        }

        idLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.centerX.equalToSuperview()
        }

        qrImageView.snp.makeConstraints { make in
            make.top.equalTo(idLabel.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(200))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(24))
        }
    }

    private func generateQRCode() {
        let qrString = "group:\(groupId)"
        guard let data = qrString.data(using: .utf8) else { return }
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return }
        qrImageView.image = UIImage(cgImage: cgImage)
    }
}

class GroupMuteViewController: UIViewController {

    private let groupId: String
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var members: [(uid: String, name: String, isMuted: Bool)] = []

    init(groupId: String, members: [(String, String, Bool)]) {
        self.groupId = groupId
        self.members = members.map { (uid: $0.0, name: $0.1, isMuted: $0.2) }
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
        title = "禁言管理"
        view.backgroundColor = .themeBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MuteCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension GroupMuteViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MuteCell", for: indexPath)
        let member = members[indexPath.row]
        cell.textLabel?.text = member.name
        cell.textLabel?.font = ScreenAdapter.font(16)

        let sw = UISwitch()
        sw.isOn = member.isMuted
        sw.tag = indexPath.row
        sw.addTarget(self, action: #selector(toggleMute(_:)), for: .valueChanged)
        cell.accessoryView = sw
        cell.selectionStyle = .none
        return cell
    }

    @objc private func toggleMute(_ sender: UISwitch) {
        members[sender.tag].isMuted = sender.isOn
        let status = sender.isOn ? "已禁言" : "已解除"
        AppUtility.showToast("\(members[sender.tag].name) \(status)")
    }
}
