//
//  RobotChatViewController.swift
//  Milo
//
//  机器人模块 - 机器人聊天页
//  功能：复用聊天UI布局、机器人自动回复、打字指示器动画
//

import UIKit
import SnapKit

// MARK: - 机器人聊天控制器
class RobotChatViewController: UIViewController {

    // MARK: - 数据
    private let robot: Robot
    private var messages: [RobotMessage] = []

    // MARK: - UI 组件
    private let titleBarView = UIView()
    private let backButton = UIButton(type: .custom)
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let moreButton = UIButton(type: .custom)

    private let tableView = UITableView()
    private let inputBar = UIView()
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .custom)

    // MARK: - 正在输入指示器
    private let typingIndicatorView = UIView()
    private let typingDot1 = UIView()
    private let typingDot2 = UIView()
    private let typingDot3 = UIView()
    private var isTypingIndicatorAnimating = false
    private var isRobotTyping = false

    // MARK: - 键盘相关
    private var inputBarBottomConstraint: Constraint?
    private var isKeyboardVisible = false

    // MARK: - 动画相关
    private var hasAnimatedEntrance = false

    // MARK: - 初始化
    init(robot: Robot) {
        self.robot = robot
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObserver()
        addWelcomeMessage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !hasAnimatedEntrance && AnimationIntegration.shared.config.enableListEntranceAnimation {
            hasAnimatedEntrance = true
            scrollToBottom(animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 设置 UI
    private func setupUI() {
        view.backgroundColor = .themeBgChat

        // MARK: 标题栏
        titleBarView.backgroundColor = .themeBgWhite
        view.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        // 返回按钮
        let backConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: backConfig), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.addPressScaleEffect()
        titleBarView.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // 头像
        avatarLabel.font = UIFont.systemFont(ofSize: 22)
        avatarLabel.textAlignment = .center
        avatarLabel.backgroundColor = .themeBgGrayF5
        avatarLabel.layer.cornerRadius = 16
        avatarLabel.clipsToBounds = true
        avatarLabel.text = robot.avatar
        titleBarView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        // 名称
        nameLabel.text = robot.name
        nameLabel.font = ScreenAdapter.font(15, weight: .semibold)
        nameLabel.textColor = .label
        titleBarView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarLabel.snp.trailing).offset(8)
            make.top.equalTo(avatarLabel.snp.top).offset(0)
        }

        // 在线状态
        statusLabel.text = "在线"
        statusLabel.font = ScreenAdapter.font(11)
        statusLabel.textColor = .themeSuccess
        titleBarView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarLabel.snp.trailing).offset(8)
            make.bottom.equalTo(avatarLabel.snp.bottom).offset(0)
        }

        // 更多按钮
        let moreConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        moreButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: moreConfig), for: .normal)
        moreButton.tintColor = .label
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        moreButton.addPressScaleEffect()
        titleBarView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // MARK: 消息列表
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RobotTextMessageCell.self, forCellReuseIdentifier: "RobotTextMessageCell")
        tableView.register(RobotTypingCell.self, forCellReuseIdentifier: "RobotTypingCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .interactive
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleBarView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        // MARK: 输入栏
        inputBar.backgroundColor = .themeBgWhite
        view.addSubview(inputBar)
        inputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
            inputBarBottomConstraint = make.bottom.equalToSuperview().constraint
        }

        // 顶部边线
        let topLine = UIView()
        topLine.backgroundColor = .themeSeparatorLight
        inputBar.addSubview(topLine)
        topLine.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // 输入框
        inputTextField.placeholder = AppStrings.Chat.inputPlaceholder
        inputTextField.font = ScreenAdapter.font(15)
        inputTextField.textColor = .label
        inputTextField.tintColor = .themeColorPrimary
        inputTextField.returnKeyType = .send
        inputTextField.delegate = self
        inputTextField.backgroundColor = .themeBgInput
        inputTextField.layer.cornerRadius = 18
        inputTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        inputTextField.leftViewMode = .always
        inputBar.addSubview(inputTextField)
        inputTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            make.trailing.equalTo(sendButton.snp.leading).offset(-10)
        }

        // 发送按钮
        let sendConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: sendConfig), for: .normal)
        sendButton.tintColor = .themeColorPrimary
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.addPressScaleEffect()
        inputBar.addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
    }

    // MARK: - 欢迎消息
    private func addWelcomeMessage() {
        let welcomeText = "你好呀！我是\(robot.name)，\(robot.description)\n\n有什么可以帮你的吗？😊"
        let welcomeMsg = RobotMessage(content: welcomeText, isFromMe: false)
        messages.append(welcomeMsg)
        tableView.reloadData()
    }

    // MARK: - 键盘监听
    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        isKeyboardVisible = true
        let keyboardHeight = keyboardFrame.height

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) { [weak self] in
            guard let self = self else { return }
            self.inputBarBottomConstraint?.update(offset: -keyboardHeight)
            self.view.layoutIfNeeded()
        }

        // 滚动到底部
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.scrollToBottom(animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        isKeyboardVisible = false

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) { [weak self] in
            guard let self = self else { return }
            self.inputBarBottomConstraint?.update(offset: 0)
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - 发送消息
    @objc private func sendButtonTapped() {
        sendMessage()
    }

    private func sendMessage() {
        guard let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }

        // 添加用户消息
        let userMsg = RobotMessage(content: text, isFromMe: true)
        messages.append(userMsg)
        inputTextField.text = ""

        // 刷新并滚动到底部
        tableView.reloadData()
        scrollToBottom(animated: true)

        // 模拟机器人回复
        simulateRobotReply(to: text)
    }

    // MARK: - 模拟机器人回复
    private func simulateRobotReply(to message: String) {
        // 显示"正在输入"指示器
        isRobotTyping = true
        tableView.reloadData()
        scrollToBottom(animated: true)

        // 开始打字动画
        startTypingAnimation()

        // 延迟 1-2 秒后回复
        let delay = Double.random(in: 1.0...2.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }

            // 停止打字动画
            self.stopTypingAnimation()
            self.isRobotTyping = false

            // 生成回复
            let reply = RobotManager.shared.generateReply(for: self.robot.id, message: message)
            let replyMsg = RobotMessage(content: reply, isFromMe: false)
            self.messages.append(replyMsg)

            // 刷新并滚动到底部
            self.tableView.reloadData()
            self.scrollToBottom(animated: true)

            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.impactSoft()
            }
        }
    }

    // MARK: - 打字指示器动画
    private func startTypingAnimation() {
        guard !isTypingIndicatorAnimating else { return }
        isTypingIndicatorAnimating = true

        // 三点跳动动画
        let dots = [typingDot1, typingDot2, typingDot3]
        for (index, dot) in dots.enumerated() {
            let delay = Double(index) * 0.15
            UIView.animate(withDuration: 0.5,
                           delay: delay,
                           options: [.repeat, .autoreverse, .curveEaseInOut]) {
                dot.transform = CGAffineTransform(translationX: 0, y: -6)
            }
        }
    }

    private func stopTypingAnimation() {
        guard isTypingIndicatorAnimating else { return }
        isTypingIndicatorAnimating = false

        let dots = [typingDot1, typingDot2, typingDot3]
        for dot in dots {
            dot.layer.removeAllAnimations()
            dot.transform = .identity
        }
    }

    // MARK: - 滚动到底部
    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty || isRobotTyping else { return }

        let lastSection = 0
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
        guard lastRow >= 0 else { return }

        let indexPath = IndexPath(row: lastRow, section: lastSection)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    // MARK: - 按钮点击
    @objc private func backButtonTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func moreButtonTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
        AppUtility.showToast("更多功能开发中...")
    }
}

// MARK: - UITableViewDataSource & Delegate
extension RobotChatViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 消息数 + 打字指示器（如果正在输入）
        return messages.count + (isRobotTyping ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 最后一行是打字指示器
        if isRobotTyping && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RobotTypingCell", for: indexPath) as! RobotTypingCell
            cell.startAnimating()
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "RobotTextMessageCell", for: indexPath) as! RobotTextMessageCell
        let message = messages[indexPath.row]
        cell.configure(with: message, avatar: robot.avatar)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension RobotChatViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

// MARK: - 文字消息 Cell
class RobotTextMessageCell: UITableViewCell {

    // MARK: - UI 组件
    private let avatarLabel = UILabel()
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()

    // MARK: - 约束
    private var bubbleLeadingConstraint: Constraint!
    private var bubbleTrailingConstraint: Constraint!
    private var avatarLeadingConstraint: Constraint!
    private var avatarTrailingConstraint: Constraint!

    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // 头像
        avatarLabel.font = UIFont.systemFont(ofSize: 18)
        avatarLabel.textAlignment = .center
        avatarLabel.backgroundColor = .themeBgGrayF5
        avatarLabel.layer.cornerRadius = 16
        avatarLabel.clipsToBounds = true
        contentView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.width.height.equalTo(32)
            avatarLeadingConstraint = make.leading.equalToSuperview().offset(8).constraint
            avatarTrailingConstraint = make.trailing.equalToSuperview().offset(-8).constraint
        }
        avatarTrailingConstraint.deactivate()

        // 气泡
        bubbleView.layer.cornerRadius = 16
        bubbleView.clipsToBounds = true
        contentView.addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.width.lessThanOrEqualTo(250)
            bubbleLeadingConstraint = make.leading.equalTo(avatarLabel.snp.trailing).offset(6).constraint
            bubbleTrailingConstraint = make.trailing.equalTo(avatarLabel.snp.leading).offset(-6).constraint
        }
        bubbleTrailingConstraint.deactivate()

        // 消息文字
        messageLabel.font = ScreenAdapter.font(15)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .left
        bubbleView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }

        // 时间
        timeLabel.font = ScreenAdapter.font(10)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.textAlignment = .center
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(bubbleView.snp.bottom).offset(2)
            make.centerX.equalTo(bubbleView)
            make.height.equalTo(12)
        }
    }

    func configure(with message: RobotMessage, avatar: String) {
        messageLabel.text = message.content
        timeLabel.text = message.timeString
        avatarLabel.text = avatar

        if message.isFromMe {
            // 自己的消息 - 右侧
            bubbleView.backgroundColor = .themeBubbleSend
            messageLabel.textColor = .themeBubbleSendText
            avatarLabel.isHidden = true

            bubbleLeadingConstraint.deactivate()
            bubbleTrailingConstraint.activate()
            avatarLeadingConstraint.deactivate()
            avatarTrailingConstraint.activate()

            // 气泡圆角调整（右边方一点）
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        } else {
            // 机器人消息 - 左侧
            bubbleView.backgroundColor = .themeBubbleReceive
            messageLabel.textColor = .themeBubbleReceiveText
            avatarLabel.isHidden = false

            bubbleTrailingConstraint.deactivate()
            bubbleLeadingConstraint.activate()
            avatarTrailingConstraint.deactivate()
            avatarLeadingConstraint.activate()

            // 气泡圆角调整（左边方一点）
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }
}

// MARK: - 正在输入 Cell
class RobotTypingCell: UITableViewCell {

    // MARK: - UI 组件
    private let avatarLabel = UILabel()
    private let bubbleView = UIView()
    private let dotStackView = UIStackView()
    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    private var isAnimating = false

    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // 头像
        avatarLabel.font = UIFont.systemFont(ofSize: 18)
        avatarLabel.textAlignment = .center
        avatarLabel.backgroundColor = .themeBgGrayF5
        avatarLabel.layer.cornerRadius = 16
        avatarLabel.clipsToBounds = true
        contentView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
            make.width.height.equalTo(32)
        }

        // 气泡
        bubbleView.backgroundColor = .themeBubbleReceive
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        bubbleView.clipsToBounds = true
        contentView.addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.leading.equalTo(avatarLabel.snp.trailing).offset(6)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.width.equalTo(60)
            make.height.equalTo(36)
        }

        // 三点
        dotStackView.axis = .horizontal
        dotStackView.spacing = 5
        dotStackView.alignment = .center
        dotStackView.distribution = .fillEqually
        bubbleView.addSubview(dotStackView)
        dotStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(8)
        }

        for dot in [dot1, dot2, dot3] {
            dot.backgroundColor = .themeTextTertiary
            dot.layer.cornerRadius = 4
            dotStackView.addArrangedSubview(dot)
            dot.snp.makeConstraints { make in
                make.width.height.equalTo(8)
            }
        }
    }

    func configure(avatar: String) {
        avatarLabel.text = avatar
    }

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        let dots = [dot1, dot2, dot3]
        for (index, dot) in dots.enumerated() {
            let delay = Double(index) * 0.15
            UIView.animate(withDuration: 0.5,
                           delay: delay,
                           options: [.repeat, .autoreverse, .curveEaseInOut]) {
                dot.transform = CGAffineTransform(translationX: 0, y: -5)
            }
        }
    }

    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false

        for dot in [dot1, dot2, dot3] {
            dot.layer.removeAllAnimations()
            dot.transform = .identity
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
    }
}
