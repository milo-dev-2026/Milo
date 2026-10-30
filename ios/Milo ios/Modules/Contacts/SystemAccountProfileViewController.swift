import UIKit
import SnapKit

// MARK: - 系统账号个人信息页（对齐安卓 WKFileHelperActivity / WKSystemTeamActivity）
// 文件传输助手 fileHelper(20000) / 系统通知 u_10000(10000)：非好友但可发消息，有独立个人信息页
final class SystemAccountProfileViewController: UIViewController {

    enum Account {
        case fileHelper
        case systemNotice

        var channelId: String {
            switch self {
            case .fileHelper: return "fileHelper"
            case .systemNotice: return "u_10000"
            }
        }

        var displayName: String {
            switch self {
            case .fileHelper: return "文件传输助手"
            case .systemNotice: return "系统通知"
            }
        }

        var shortNo: String {
            switch self {
            case .fileHelper: return "20000"
            case .systemNotice: return "10000"
            }
        }

        var desc: String {
            switch self {
            case .fileHelper:
                return "用于在手机与电脑间传输文字、图片、音频、视频等文件"
            case .systemNotice:
                return "系统通知用于接收公告、安全提醒、版本更新等官方消息"
            }
        }
    }

    private let account: Account
    private let headerCard = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let idLabel = UILabel()
    private let descLabel = UILabel()

    init(account: Account) {
        self.account = account
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not be implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        title = account.displayName

        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        headerCard.backgroundColor = .white
        headerCard.layer.cornerRadius = 12
        headerCard.clipsToBounds = true
        view.addSubview(headerCard)
        headerCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        avatarImageView.layer.cornerRadius = 40
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(systemName: account == .fileHelper ? "folder.fill" : "bell.fill")
        avatarImageView.tintColor = .systemGray
        avatarImageView.backgroundColor = .systemGray6
        headerCard.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(80)
        }

        nameLabel.font = ScreenAdapter.boldFont(20)
        nameLabel.textColor = .label
        nameLabel.text = account.displayName
        headerCard.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.top.equalTo(avatarImageView.snp.top).offset(8)
            make.trailing.equalToSuperview().offset(-16)
        }

        idLabel.font = ScreenAdapter.font(13)
        idLabel.textColor = .secondaryLabel
        idLabel.text = "Milo号：\(account.shortNo)"
        headerCard.addSubview(idLabel)
        idLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.trailing.equalToSuperview().offset(-16)
        }

        descLabel.font = ScreenAdapter.font(13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.text = account.desc
        headerCard.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(idLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-20)
        }

        // 发消息按钮
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("发消息", for: .normal)
        sendButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = .themePrimary
        sendButton.layer.cornerRadius = 10
        sendButton.addTarget(self, action: #selector(startChat), for: .touchUpInside)
        view.addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.top.equalTo(headerCard.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func startChat() {
        let chat = ChatViewController(channelId: account.channelId, title: account.displayName, channelType: 1)
        chat.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chat, animated: true)
    }
}
