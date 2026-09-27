import UIKit
import SnapKit
import Kingfisher

// MARK: - Tap Helper
private class TapActionWrapper: NSObject {
    let action: () -> Void
    init(action: @escaping () -> Void) { self.action = action }
    @objc func perform() { action() }
}

private var actionWrapperKey: UInt8 = 0

// MARK: - 联系人详情
class ContactDetailViewController: UIViewController {

    private let uid: String
    private var userInfo: ChannelInfo?

    // MARK: - 顶部用户信息
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerCard = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let idLabel = UILabel()
    private let remarkLabel = UILabel()

    // MARK: - 信息区
    private let infoCard = UIView()

    // MARK: - 按钮区
    private let sendMsgButton = UIButton(type: .system)
    private let audioCallButton = UIButton(type: .system)
    private let videoCallButton = UIButton(type: .system)

    init(uid: String) {
        self.uid = uid
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        title = "个人信息"

        // 导航栏返回按钮
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        // ScrollView
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // MARK: - 顶部用户卡片
        headerCard.backgroundColor = .white
        headerCard.layer.cornerRadius = 12
        headerCard.clipsToBounds = true
        contentView.addSubview(headerCard)
        headerCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 头像
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemGray5
        headerCard.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(80)
        }

        // 名字
        nameLabel.font = ScreenAdapter.boldFont(20)
        nameLabel.textColor = .label
        nameLabel.text = "加载中..."
        headerCard.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.top.equalTo(avatarImageView.snp.top).offset(8)
            make.trailing.equalToSuperview().offset(-16)
        }

        // Milo号
        idLabel.font = ScreenAdapter.font(13)
        idLabel.textColor = .secondaryLabel
        headerCard.addSubview(idLabel)
        idLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 备注
        remarkLabel.font = ScreenAdapter.font(13)
        remarkLabel.textColor = .secondaryLabel
        remarkLabel.numberOfLines = 0
        headerCard.addSubview(remarkLabel)
        remarkLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(idLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-20)
        }

        // MARK: - 信息区（设置备注等）
        infoCard.backgroundColor = .white
        infoCard.layer.cornerRadius = 12
        infoCard.clipsToBounds = true
        contentView.addSubview(infoCard)
        infoCard.snp.makeConstraints { make in
            make.top.equalTo(headerCard.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        addInfoRow(to: infoCard, title: "设置备注和标签", showArrow: true, isLast: true) { [weak self] in
            AppUtility.showToast("设置备注")
        }

        // MARK: - 操作按钮区
        let buttonsStack = UIStackView()
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually
        buttonsStack.spacing = 12
        buttonsStack.backgroundColor = .white
        buttonsStack.layer.cornerRadius = 12
        buttonsStack.clipsToBounds = true
        buttonsStack.isLayoutMarginsRelativeArrangement = true
        buttonsStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentView.addSubview(buttonsStack)
        buttonsStack.snp.makeConstraints { make in
            make.top.equalTo(infoCard.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 发消息
        sendMsgButton.setImage(UIImage(systemName: "message.fill"), for: .normal)
        sendMsgButton.setTitle("  发消息", for: .normal)
        sendMsgButton.tintColor = .themePrimary
        sendMsgButton.setTitleColor(.themePrimary, for: .normal)
        sendMsgButton.titleLabel?.font = ScreenAdapter.font(14)
        sendMsgButton.addTarget(self, action: #selector(sendMessageTapped), for: .touchUpInside)
        buttonsStack.addArrangedSubview(sendMsgButton)

        // 语音通话
        audioCallButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        audioCallButton.setTitle("  语音", for: .normal)
        audioCallButton.tintColor = .themePrimary
        audioCallButton.setTitleColor(.themePrimary, for: .normal)
        audioCallButton.titleLabel?.font = ScreenAdapter.font(14)
        audioCallButton.addTarget(self, action: #selector(audioCallTapped), for: .touchUpInside)
        buttonsStack.addArrangedSubview(audioCallButton)

        // 视频通话
        videoCallButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        videoCallButton.setTitle("  视频", for: .normal)
        videoCallButton.tintColor = .themePrimary
        videoCallButton.setTitleColor(.themePrimary, for: .normal)
        videoCallButton.titleLabel?.font = ScreenAdapter.font(14)
        videoCallButton.addTarget(self, action: #selector(videoCallTapped), for: .touchUpInside)
        buttonsStack.addArrangedSubview(videoCallButton)

        // MARK: - 更多操作区
        let moreCard = UIView()
        moreCard.backgroundColor = .white
        moreCard.layer.cornerRadius = 12
        moreCard.clipsToBounds = true
        contentView.addSubview(moreCard)
        moreCard.snp.makeConstraints { make in
            make.top.equalTo(buttonsStack.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        addInfoRow(to: moreCard, title: "推荐给朋友", showArrow: true) {
            AppUtility.showToast("推荐给朋友")
        }
        addInfoRow(to: moreCard, title: "加入黑名单", showArrow: false, isLast: true, isDestructive: true) { [weak self] in
            self?.showBlockAlert()
        }

        // 底部约束
        contentView.snp.makeConstraints { make in
            make.bottom.equalTo(moreCard.snp.bottom).offset(30)
        }
    }

    private func addInfoRow(to container: UIView, title: String, showArrow: Bool, isLast: Bool = false, isDestructive: Bool = false, action: @escaping () -> Void) {
        let row = UIView()
        row.backgroundColor = .white
        row.isUserInteractionEnabled = true
        let wrapper = TapActionWrapper(action: action)
        let tap = UITapGestureRecognizer(target: wrapper, action: #selector(TapActionWrapper.perform))
        objc_setAssociatedObject(row, &actionWrapperKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        row.addGestureRecognizer(tap)
        container.addSubview(row)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ScreenAdapter.font(15)
        titleLabel.textColor = isDestructive ? .systemRed : .label
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        if showArrow {
            let arrowView = UIImageView()
            arrowView.image = UIImage(systemName: "chevron.right")
            arrowView.tintColor = UIColor(white: 0.8, alpha: 1.0)
            arrowView.contentMode = .scaleAspectFit
            row.addSubview(arrowView)
            arrowView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(14)
            }
        }

        // 找到容器中已有的子视图数量
        let existingRows = container.subviews.filter { $0 is UIView && $0.backgroundColor == .white }
        if existingRows.isEmpty {
            row.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(48)
            }
        } else {
            let lastRow = existingRows.last!
            row.snp.makeConstraints { make in
                make.top.equalTo(lastRow.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(48)
            }

            // 添加分割线
            let line = UIView()
            line.backgroundColor = UIColor(white: 0, alpha: 0.06)
            row.addSubview(line)
            line.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.top.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }

        if isLast {
            row.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
    }

    // MARK: - 加载用户信息
    private func loadUserInfo() {
        Task {
            do {
                let info: ChannelInfo = try await APIClient.shared.requestFlexible(
                    .getChannelInfo(channelId: uid, channelType: 1)
                )
                self.userInfo = info
                DispatchQueue.main.async {
                    self.nameLabel.text = info.displayName
                    self.idLabel.text = "Milo号：\(info.channel_id ?? "")"
                    if let avatar = info.logo ?? info.avatar, let url = URL(string: avatar) {
                        AppUtility.loadAvatar(url, into: self.avatarImageView)
                    }
                    if let remark = info.channelRemark, !remark.isEmpty {
                        self.remarkLabel.text = "备注：\(remark)"
                    } else {
                        self.remarkLabel.text = ""
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("加载用户信息失败")
                }
            }
        }
    }

    // MARK: - 按钮操作
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func sendMessageTapped() {
        let chatVC = ChatViewController(channelId: uid, title: userInfo?.displayName ?? uid, channelType: 1)
        // 替换当前控制器
        if var vcs = navigationController?.viewControllers {
            vcs.removeLast()
            vcs.append(chatVC)
            navigationController?.setViewControllers(vcs, animated: true)
        } else {
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }

    @objc private func audioCallTapped() {
        AppUtility.showToast("发起语音通话")
    }

    @objc private func videoCallTapped() {
        AppUtility.showToast("发起视频通话")
    }

    private func showBlockAlert() {
        let alert = UIAlertController(title: "加入黑名单", message: "加入黑名单后将不再接收对方消息", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { _ in
            AppUtility.showToast("已加入黑名单")
        })
        present(alert, animated: true)
    }
}
