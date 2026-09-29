//
//  MessageSwipeManager.swift
//  Milo
//
//  消息左滑操作管理器
//  负责：左滑操作配置、回复引用条、多选工具栏
//

import UIKit
import SnapKit

// MARK: - 滑动操作类型
enum MessageSwipeActionType {
    case reply      // 回复
    case forward    // 转发
    case delete     // 删除
    case select     // 多选
}

// MARK: - 回复引用条
class ReplyQuoteBar: UIView {

    // MARK: - 回调
    var onClose: (() -> Void)?

    // MARK: - UI 组件
    private let verticalLine = UIView()
    private let nameLabel = UILabel()
    private let contentLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let stackView = UIStackView()

    // MARK: - 数据
    private(set) var repliedMessage: Message?

    // MARK: - 高度常量
    static let barHeight: CGFloat = 36

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemGray6

        // 左侧竖线
        verticalLine.backgroundColor = .themePrimary
        verticalLine.layer.cornerRadius = 1
        addSubview(verticalLine)

        // 名字标签
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = .themePrimary
        nameLabel.text = "回复"

        // 内容标签
        contentLabel.font = UIFont.systemFont(ofSize: 11)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 1
        contentLabel.lineBreakMode = .byTruncatingTail

        // 垂直 StackView（名字 + 内容）
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 2
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(contentLabel)
        addSubview(stackView)

        // 关闭按钮
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.addPressScaleEffect()
        addSubview(closeButton)

        // 约束
        verticalLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(2)
            make.height.equalTo(20)
        }

        stackView.snp.makeConstraints { make in
            make.leading.equalTo(verticalLine.snp.trailing).offset(8)
            make.trailing.equalTo(closeButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    // MARK: - 配置

    func configure(with message: Message, senderName: String) {
        repliedMessage = message
        nameLabel.text = "回复 \(senderName)"
        contentLabel.text = messageContentPreview(message)
    }

    private func messageContentPreview(_ message: Message) -> String {
        switch message.type {
        case .text:
            return message.content
        case .image:
            return "[图片]"
        case .voice:
            return "[语音]"
        case .video:
            return "[视频]"
        case .file:
            return "[文件]"
        case .location:
            return "[位置]"
        case .card:
            return "[名片]"
        case .note:
            return "[笔记]"
        case .system:
            return message.content
        case .call:
            return "[通话]"
        case .multiForward:
            return "[合并转发]"
        default:
            return message.content
        }
    }

    // MARK: - 动画

    func show(in superview: UIView, above bottomView: UIView, animated: Bool = true) {
        superview.addSubview(self)
        isHidden = false
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: ReplyQuoteBar.barHeight)

        snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
            make.height.equalTo(ReplyQuoteBar.barHeight)
        }

        if animated && AnimationIntegration.shared.config.enableListEntranceAnimation {
            UIView.animate(withDuration: AnimationDuration.normal,
                           delay: 0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut) {
                self.alpha = 1
                self.transform = .identity
            }
        } else {
            alpha = 1
            transform = .identity
        }
    }

    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated && AnimationIntegration.shared.config.enableListEntranceAnimation {
            UIView.animate(withDuration: AnimationDuration.fast,
                           delay: 0,
                           options: .curveEaseIn) {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: ReplyQuoteBar.barHeight)
            } completion: { _ in
                self.removeFromSuperview()
                self.transform = .identity
                self.repliedMessage = nil
                completion?()
            }
        } else {
            removeFromSuperview()
            repliedMessage = nil
            completion?()
        }
    }

    // MARK: - 动作

    @objc private func closeTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
        onClose?()
    }
}

// MARK: - 多选底部操作工具栏
class MultiSelectToolbar: UIView {

    // MARK: - 回调
    var onSelectAll: (() -> Void)?
    var onFavorite: (() -> Void)?
    var onForward: (() -> Void)?
    var onDelete: (() -> Void)?

    // MARK: - UI 组件
    private let stackView = UIStackView()
    private let selectAllButton = MultiSelectToolButton()
    private let favoriteButton = MultiSelectToolButton()
    private let forwardButton = MultiSelectToolButton()
    private let deleteButton = MultiSelectToolButton()

    // MARK: - 高度常量
    static let toolbarHeight: CGFloat = 50

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        // 顶部分隔线
        let topBorder = UIView()
        topBorder.backgroundColor = .themeSeparator
        addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // 按钮配置
        selectAllButton.configure(imageName: "checkmark.circle", title: "全选")
        favoriteButton.configure(imageName: "star", title: "收藏")
        forwardButton.configure(imageName: "arrowshape.turn.up.right", title: "转发")
        deleteButton.configure(imageName: "trash", title: "删除")

        selectAllButton.addTarget(self, action: #selector(selectAllTapped), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        // StackView
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(selectAllButton)
        stackView.addArrangedSubview(favoriteButton)
        stackView.addArrangedSubview(forwardButton)
        stackView.addArrangedSubview(deleteButton)
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(MultiSelectToolbar.toolbarHeight)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }

        // 初始禁用部分按钮
        updateEnabledState(selectedCount: 0, isAllSelected: false)
    }

    // MARK: - 状态更新

    func updateEnabledState(selectedCount: Int, isAllSelected: Bool) {
        favoriteButton.isEnabled = selectedCount > 0
        forwardButton.isEnabled = selectedCount > 0
        deleteButton.isEnabled = selectedCount > 0

        // 更新全选按钮图标
        let imageName = isAllSelected ? "checkmark.circle.fill" : "checkmark.circle"
        selectAllButton.setImage(UIImage(systemName: imageName), for: .normal)
        selectAllButton.tintColor = isAllSelected ? .themePrimary : .systemBlue
    }

    // MARK: - 动画

    func show(in superview: UIView, animated: Bool = true) {
        superview.addSubview(self)
        isHidden = false
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: MultiSelectToolbar.toolbarHeight + 34)

        snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        if animated && AnimationIntegration.shared.config.enableListEntranceAnimation {
            UIView.animate(withDuration: AnimationDuration.normal,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut) {
                self.alpha = 1
                self.transform = .identity
            }
        } else {
            alpha = 1
            transform = .identity
        }
    }

    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated && AnimationIntegration.shared.config.enableListEntranceAnimation {
            UIView.animate(withDuration: AnimationDuration.normal,
                           delay: 0,
                           options: .curveEaseIn) {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: MultiSelectToolbar.toolbarHeight + 34)
            } completion: { _ in
                self.removeFromSuperview()
                self.transform = .identity
                completion?()
            }
        } else {
            removeFromSuperview()
            completion?()
        }
    }

    // MARK: - 动作

    @objc private func selectAllTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
        onSelectAll?()
    }

    @objc private func favoriteTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
        onFavorite?()
    }

    @objc private func forwardTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
        onForward?()
    }

    @objc private func deleteTapped() {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactMedium()
        }
        onDelete?()
    }
}

// MARK: - 多选工具栏按钮（图标 + 文字垂直排列）
private class MultiSelectToolButton: UIButton {

    private let iconImageView = UIImageView()
    private let titleLabel_ = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue

        titleLabel_.font = UIFont.systemFont(ofSize: 10)
        titleLabel_.textAlignment = .center
        titleLabel_.textColor = .systemBlue

        addSubview(iconImageView)
        addSubview(titleLabel_)

        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(6)
            make.width.height.equalTo(22)
        }

        titleLabel_.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(4)
        }

        addPressScaleEffect()
    }

    func configure(imageName: String, title: String) {
        iconImageView.image = UIImage(systemName: imageName)
        titleLabel_.text = title
    }

    override var isEnabled: Bool {
        didSet {
            iconImageView.alpha = isEnabled ? 1.0 : 0.3
            titleLabel_.alpha = isEnabled ? 1.0 : 0.3
        }
    }

    override var tintColor: UIColor! {
        didSet {
            iconImageView.tintColor = tintColor
            titleLabel_.textColor = tintColor
        }
    }
}

// MARK: - 消息滑动操作管理器
final class MessageSwipeManager: NSObject {

    // MARK: - 配置
    struct SwipeConfig {
        /// 是否启用左滑操作
        var enableTrailingSwipe = true
        /// 是否启用右滑多选
        var enableLeadingSwipe = true
        /// 滑动触觉反馈阈值
        var hapticThreshold: CGFloat = 0.5
    }

    var config = SwipeConfig()

    // MARK: - 回调
    /// 执行滑动操作回调
    var onAction: ((MessageSwipeActionType, IndexPath) -> Void)?

    // MARK: - 触觉反馈状态追踪
    private var hasTriggeredHapticForRow: Set<IndexPath> = []

    // MARK: - 创建右侧滑动操作（从右往左滑，露出操作按钮）
    func makeTrailingSwipeActions(forRowAt indexPath: IndexPath, message: Message) -> UISwipeActionsConfiguration? {
        guard config.enableTrailingSwipe else { return nil }

        // 删除操作（红色）
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
            self?.triggerHapticIfNeeded(for: indexPath, type: .delete)
            self?.onAction?(.delete, indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed

        // 转发操作（绿色）
        let forwardAction = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, completion) in
            self?.triggerHapticIfNeeded(for: indexPath, type: .forward)
            self?.onAction?(.forward, indexPath)
            completion(true)
        }
        forwardAction.image = UIImage(systemName: "arrowshape.turn.up.right.fill")
        forwardAction.backgroundColor = .systemGreen

        // 回复操作（蓝色）
        let replyAction = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, completion) in
            self?.triggerHapticIfNeeded(for: indexPath, type: .reply)
            self?.onAction?(.reply, indexPath)
            completion(true)
        }
        replyAction.image = UIImage(systemName: "arrow.uturn.backward")
        replyAction.backgroundColor = .systemBlue

        let config = UISwipeActionsConfiguration(actions: [deleteAction, forwardAction, replyAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // MARK: - 创建左侧滑动操作（从左往右滑，露出多选按钮）
    func makeLeadingSwipeActions(forRowAt indexPath: IndexPath, message: Message) -> UISwipeActionsConfiguration? {
        guard config.enableLeadingSwipe else { return nil }

        // 多选操作（蓝色）
        let selectAction = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, completion) in
            self?.triggerHapticIfNeeded(for: indexPath, type: .select)
            self?.onAction?(.select, indexPath)
            completion(true)
        }
        selectAction.image = UIImage(systemName: "checkmark.circle.fill")
        selectAction.backgroundColor = .systemBlue

        let config = UISwipeActionsConfiguration(actions: [selectAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // MARK: - 触觉反馈

    private func triggerHapticIfNeeded(for indexPath: IndexPath, type: MessageSwipeActionType) {
        guard AnimationIntegration.shared.config.enableHapticFeedback else { return }

        switch type {
        case .delete:
            HapticManager.shared.impactMedium()
        case .reply, .forward, .select:
            HapticManager.shared.impactSoft()
        }
    }

    /// 滑动过程中阈值触觉反馈
    func triggerSwipeThresholdHapticIfNeeded(for indexPath: IndexPath) {
        guard AnimationIntegration.shared.config.enableHapticFeedback else { return }
        guard !hasTriggeredHapticForRow.contains(indexPath) else { return }
        hasTriggeredHapticForRow.insert(indexPath)
        HapticManager.shared.selectionChanged()
    }

    /// 重置某行的触觉反馈状态
    func resetHapticState(for indexPath: IndexPath) {
        hasTriggeredHapticForRow.remove(indexPath)
    }

    /// 重置所有触觉反馈状态
    func resetAllHapticStates() {
        hasTriggeredHapticForRow.removeAll()
    }
}

// MARK: - 多选模式勾选框视图
class MultiSelectCheckmarkView: UIView {

    private let imageView = UIImageView()
    private var isChecked: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.systemGray4.cgColor
        layer.cornerRadius = 12
        backgroundColor = .white

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.image = UIImage(systemName: "checkmark")
        imageView.alpha = 0
        addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }

    func setChecked(_ checked: Bool, animated: Bool = true) {
        guard isChecked != checked else { return }
        isChecked = checked

        if animated && AnimationIntegration.shared.config.enableButtonPressAnimation {
            UIView.animate(withDuration: AnimationDuration.fast,
                           delay: 0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.8,
                           options: .curveEaseOut) {
                self.updateAppearance(checked: checked)
            }
        } else {
            updateAppearance(checked: checked)
        }
    }

    private func updateAppearance(checked: Bool) {
        if checked {
            backgroundColor = .systemBlue
            layer.borderColor = UIColor.systemBlue.cgColor
            imageView.alpha = 1
            transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } else {
            backgroundColor = .white
            layer.borderColor = UIColor.systemGray4.cgColor
            imageView.alpha = 0
            transform = .identity
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 24, height: 24)
    }
}
