//
//  SettingMoreViewControllers.swift
//  Milo
//
//  设置模块补充页面
//  包含：关于、FAQ、反馈、多语言、消息备份、地区选择
//

import UIKit
import SnapKit

// MARK: - 关于页面
class AboutViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let sections: [(title: String?, items: [(title: String, detail: String?)])] = [
        (nil, [
            ("版本", "1.0.0"),
        ]),
        ("", [
            ("用户协议", nil),
            ("隐私政策", nil),
            ("服务条款", nil),
        ]),
        ("", [
            ("给我们评分", nil),
            ("检查更新", nil),
        ]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "关于我们"
        view.backgroundColor = .themeBg

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AboutCell")

        // Logo Header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 180))
        headerView.backgroundColor = .clear

        let logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "AppIcon") ?? UIImage(systemName: "message.circle.fill")
        logoImageView.tintColor = .themeColorPrimary
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.layer.cornerRadius = 20
        logoImageView.clipsToBounds = true
        headerView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }

        let appNameLabel = UILabel()
        appNameLabel.text = "Milo"
        appNameLabel.font = ThemeFont.title1(20)
        appNameLabel.textColor = .themeTextPrimary
        appNameLabel.textAlignment = .center
        headerView.addSubview(appNameLabel)
        appNameLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        let sloganLabel = UILabel()
        sloganLabel.text = "让沟通更简单"
        sloganLabel.font = ThemeFont.bodySmall(13)
        sloganLabel.textColor = .themeTextSecondary
        sloganLabel.textAlignment = .center
        headerView.addSubview(sloganLabel)
        sloganLabel.snp.makeConstraints { make in
            make.top.equalTo(appNameLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        tableView.tableHeaderView = headerView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AboutCell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary

        if let detail = item.detail {
            cell.detailTextLabel?.text = detail
            cell.detailTextLabel?.font = ThemeFont.bodySmall(14)
            cell.detailTextLabel?.textColor = .themeTextSecondary
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - FAQ / 帮助与反馈
class FaqViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private let faqs: [(question: String, answer: String)] = [
        ("如何修改密码？", "前往「设置 - 账号安全 - 修改密码」，按照提示操作即可。"),
        ("如何添加好友？", "可以通过搜索 UID、手机号、扫一扫二维码等方式添加好友。"),
        ("如何创建群组？", "在聊天列表页点击右上角「+」，选择「发起群聊」即可。"),
        ("消息可以撤回吗？", "发送后2分钟内可以撤回消息，长按消息选择「撤回」。"),
        ("如何设置聊天背景？", "进入聊天设置，选择「设置聊天背景」，可以选择系统背景或从相册选择。"),
        ("如何开启深色模式？", "前往「设置 - 通用设置 - 深色模式」，可以选择跟随系统或手动切换。"),
        ("忘记密码怎么办？", "在登录页点击「忘记密码」，通过手机或邮箱验证后重置密码。"),
        ("如何注销账号？", "前往「设置 - 账号安全 - 注销账号」，按照提示操作即可。"),
    ]

    private var filteredFaqs: [(question: String, answer: String)] = []
    private var expandedIndex: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        filteredFaqs = faqs
        setupUI()
    }

    private func setupUI() {
        title = "帮助与反馈"
        view.backgroundColor = .themeBg

        // 搜索栏
        searchBar.placeholder = "搜索问题"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
        tableView.tableHeaderView = searchBar

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FaqCell.self, forCellReuseIdentifier: "FaqCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableFooterView = UIView()

        // 底部反馈入口
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 100))
        footerView.backgroundColor = .clear

        let feedbackLabel = UILabel()
        feedbackLabel.text = "没有找到答案？"
        feedbackLabel.font = ThemeFont.bodySmall(14)
        feedbackLabel.textColor = .themeTextSecondary
        feedbackLabel.textAlignment = .center
        footerView.addSubview(feedbackLabel)
        feedbackLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
        }

        let feedbackBtn = UIButton(type: .system)
        feedbackBtn.setTitle("意见反馈", for: .normal)
        feedbackBtn.titleLabel?.font = ThemeFont.bodyMedium(15)
        feedbackBtn.setTitleColor(.themeColorPrimary, for: .normal)
        feedbackBtn.addTarget(self, action: #selector(showFeedback), for: .touchUpInside)
        footerView.addSubview(feedbackBtn)
        feedbackBtn.snp.makeConstraints { make in
            make.top.equalTo(feedbackLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        tableView.tableFooterView = footerView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func showFeedback() {
        let vc = FeedbackViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension FaqViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredFaqs = faqs
        } else {
            filteredFaqs = faqs.filter { $0.question.contains(searchText) || $0.answer.contains(searchText) }
        }
        tableView.reloadData()
    }
}

extension FaqViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFaqs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FaqCell", for: indexPath) as! FaqCell
        let faq = filteredFaqs[indexPath.row]
        let isExpanded = expandedIndex == indexPath.row
        cell.configure(question: faq.question, answer: faq.answer, isExpanded: isExpanded)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if expandedIndex == indexPath.row {
            expandedIndex = nil
        } else {
            expandedIndex = indexPath.row
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - FAQ Cell
class FaqCell: UITableViewCell {

    private let questionLabel = UILabel()
    private let answerLabel = UILabel()
    private let arrowImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .themeBgWhite
        contentView.backgroundColor = .themeBgWhite
        selectionStyle = .none

        questionLabel.font = ThemeFont.title3(16)
        questionLabel.textColor = .themeTextPrimary
        questionLabel.numberOfLines = 0
        contentView.addSubview(questionLabel)
        questionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-40)
        }

        arrowImageView.image = UIImage(systemName: "chevron.down")
        arrowImageView.tintColor = .themeTextTertiary
        arrowImageView.contentMode = .scaleAspectFit
        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(questionLabel)
            make.width.height.equalTo(16)
        }

        answerLabel.font = ThemeFont.bodySmall(14)
        answerLabel.textColor = .themeTextSecondary
        answerLabel.numberOfLines = 0
        answerLabel.isHidden = true
        contentView.addSubview(answerLabel)
        answerLabel.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(8)
            make.left.equalTo(questionLabel)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    func configure(question: String, answer: String, isExpanded: Bool) {
        questionLabel.text = question
        answerLabel.text = answer
        answerLabel.isHidden = !isExpanded
        arrowImageView.transform = isExpanded ? CGAffineTransform(rotationAngle: .pi) : .identity
    }
}

// MARK: - 意见反馈
class FeedbackViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let typeSegmentControl = UISegmentedControl(items: ["功能建议", "Bug反馈", "其他"])
    private let contentTextView = UITextView()
    private let placeholderLabel = UILabel()
    private let contactTextField = UITextField()
    private let submitButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "意见反馈"
        view.backgroundColor = .themeBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // 反馈类型
        let typeLabel = UILabel()
        typeLabel.text = "反馈类型"
        typeLabel.font = ThemeFont.title3(15)
        typeLabel.textColor = .themeTextPrimary
        contentView.addSubview(typeLabel)
        typeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(16)
        }

        typeSegmentControl.selectedSegmentIndex = 0
        contentView.addSubview(typeSegmentControl)
        typeSegmentControl.snp.makeConstraints { make in
            make.top.equalTo(typeLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(36)
        }

        // 反馈内容
        let contentLabel = UILabel()
        contentLabel.text = "反馈内容"
        contentLabel.font = ThemeFont.title3(15)
        contentLabel.textColor = .themeTextPrimary
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(typeSegmentControl.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
        }

        contentTextView.font = ThemeFont.body(15)
        contentTextView.textColor = .themeTextPrimary
        contentTextView.backgroundColor = .themeBgCard
        contentTextView.layer.cornerRadius = 8
        contentTextView.layer.borderWidth = 1
        contentTextView.layer.borderColor = UIColor.themeSeparator.cgColor
        contentTextView.delegate = self
        contentView.addSubview(contentTextView)
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(150)
        }

        placeholderLabel.text = "请详细描述您的问题或建议..."
        placeholderLabel.font = ThemeFont.body(15)
        placeholderLabel.textColor = .themeTextHint
        contentTextView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
        }

        // 字数统计
        let charCountLabel = UILabel()
        charCountLabel.text = "0/500"
        charCountLabel.font = ThemeFont.tiny(12)
        charCountLabel.textColor = .themeTextHint
        charCountLabel.textAlignment = .right
        charCountLabel.tag = 100
        contentView.addSubview(charCountLabel)
        charCountLabel.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(4)
            make.right.equalToSuperview().offset(-16)
        }

        // 联系方式
        let contactLabel = UILabel()
        contactLabel.text = "联系方式（选填）"
        contactLabel.font = ThemeFont.title3(15)
        contactLabel.textColor = .themeTextPrimary
        contentView.addSubview(contactLabel)
        contactLabel.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(16)
        }

        contactTextField.font = ThemeFont.body(15)
        contactTextField.textColor = .themeTextPrimary
        contactTextField.placeholder = "手机号或邮箱，方便我们联系您"
        contactTextField.backgroundColor = .themeBgCard
        contactTextField.layer.cornerRadius = 8
        contactTextField.layer.borderWidth = 1
        contactTextField.layer.borderColor = UIColor.themeSeparator.cgColor
        contactTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        contactTextField.leftViewMode = .always
        contentView.addSubview(contactTextField)
        contactTextField.snp.makeConstraints { make in
            make.top.equalTo(contactLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(44)
        }

        // 提交按钮
        submitButton.setTitle("提交反馈", for: .normal)
        submitButton.titleLabel?.font = ThemeFont.buttonLarge(16)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = .themeColorPrimary
        submitButton.layer.cornerRadius = 10
        submitButton.addTarget(self, action: #selector(submitFeedback), for: .touchUpInside)
        contentView.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.top.equalTo(contactTextField.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    @objc private func submitFeedback() {
        guard let content = contentTextView.text, !content.isEmpty else {
            AppUtility.showToast("请输入反馈内容")
            return
        }

        AppUtility.showToast("反馈已提交，感谢您的建议！")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}

extension FeedbackViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        let count = textView.text.count
        if let label = viewWithTag(100) as? UILabel {
            label.text = "\(count)/500"
        }
    }
}

// MARK: - 多语言设置
class LanguageSettingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let languages = [
        (code: "zh-Hans", name: "简体中文"),
        (code: "zh-Hant", name: "繁體中文"),
        (code: "en", name: "English"),
        (code: "ja", name: "日本語"),
        (code: "ko", name: "한국어"),
    ]

    private var selectedLanguage = "zh-Hans"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "多语言"
        view.backgroundColor = .themeBg

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension LanguageSettingViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "选择语言"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        let lang = languages[indexPath.row]
        cell.textLabel?.text = lang.name
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.backgroundColor = .themeBgWhite
        cell.contentView.backgroundColor = .themeBgWhite

        if lang.code == selectedLanguage {
            cell.accessoryType = .checkmark
            cell.tintColor = .themeColorPrimary
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedLanguage = languages[indexPath.row].code
        tableView.reloadData()
        AppUtility.showToast("已切换为 \(languages[indexPath.row].name)")
    }
}

// MARK: - 聊天记录备份/迁移
class ChatBackupViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "聊天记录备份"
        view.backgroundColor = .themeBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // 备份状态卡片
        let statusCard = UIView()
        statusCard.backgroundColor = .themeBgCard
        statusCard.layer.cornerRadius = 12
        contentView.addSubview(statusCard)
        statusCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(120)
        }

        let statusIcon = UIImageView(image: UIImage(systemName: "icloud.and.arrow.up"))
        statusIcon.tintColor = .themeColorPrimary
        statusIcon.contentMode = .scaleAspectFit
        statusCard.addSubview(statusIcon)
        statusIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        let statusTitle = UILabel()
        statusTitle.text = "备份聊天记录"
        statusTitle.font = ThemeFont.title2(18)
        statusTitle.textColor = .themeTextPrimary
        statusCard.addSubview(statusTitle)
        statusTitle.snp.makeConstraints { make in
            make.left.equalTo(statusIcon.snp.right).offset(16)
            make.top.equalTo(statusIcon).offset(-2)
        }

        let statusDesc = UILabel()
        statusDesc.text = "将聊天记录备份到云端，换机时可一键迁移"
        statusDesc.font = ThemeFont.bodySmall(13)
        statusDesc.textColor = .themeTextSecondary
        statusDesc.numberOfLines = 0
        statusCard.addSubview(statusDesc)
        statusDesc.snp.makeConstraints { make in
            make.left.equalTo(statusTitle)
            make.top.equalTo(statusTitle.snp.bottom).offset(6)
            make.right.equalToSuperview().offset(-16)
        }

        // 立即备份按钮
        let backupButton = UIButton(type: .system)
        backupButton.setTitle("立即备份", for: .normal)
        backupButton.titleLabel?.font = ThemeFont.buttonLarge(16)
        backupButton.setTitleColor(.white, for: .normal)
        backupButton.backgroundColor = .themeColorPrimary
        backupButton.layer.cornerRadius = 10
        backupButton.addTarget(self, action: #selector(startBackup), for: .touchUpInside)
        contentView.addSubview(backupButton)
        backupButton.snp.makeConstraints { make in
            make.top.equalTo(statusCard.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }

        // 恢复备份
        let restoreButton = UIButton(type: .system)
        restoreButton.setTitle("恢复聊天记录", for: .normal)
        restoreButton.titleLabel?.font = ThemeFont.button(16)
        restoreButton.setTitleColor(.themeColorPrimary, for: .normal)
        restoreButton.backgroundColor = .themeColorPrimary.withAlphaComponent(0.1)
        restoreButton.layer.cornerRadius = 10
        restoreButton.addTarget(self, action: #selector(restoreBackup), for: .touchUpInside)
        contentView.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { make in
            make.top.equalTo(backupButton.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }

        // 备份信息
        let infoLabel = UILabel()
        infoLabel.text = "上次备份：暂无备份记录"
        infoLabel.font = ThemeFont.caption(12)
        infoLabel.textColor = .themeTextHint
        infoLabel.textAlignment = .center
        contentView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(restoreButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    @objc private func startBackup() {
        AppUtility.showToast("开始备份...")
    }

    @objc private func restoreBackup() {
        AppUtility.showToast("恢复聊天记录")
    }
}

// MARK: - 国家/地区选择
class RegionSelectViewController: UIViewController {

    private let tableView = UITableView()
    private let searchBar = UISearchBar()

    private let regions = [
        ("86", "中国大陆", "+86"),
        ("852", "中国香港", "+852"),
        ("853", "中国澳门", "+853"),
        ("886", "中国台湾", "+886"),
        ("1", "美国", "+1"),
        ("44", "英国", "+44"),
        ("81", "日本", "+81"),
        ("82", "韩国", "+82"),
        ("65", "新加坡", "+65"),
        ("61", "澳大利亚", "+61"),
        ("33", "法国", "+33"),
        ("49", "德国", "+49"),
        ("7", "俄罗斯", "+7"),
        ("91", "印度", "+91"),
        ("55", "巴西", "+55"),
    ]

    private var filteredRegions: [(code: String, name: String, dial: String)] = []
    var onSelected: ((String, String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        filteredRegions = regions
        setupUI()
    }

    private func setupUI() {
        title = "选择国家/地区"
        view.backgroundColor = .themeBg

        searchBar.placeholder = "搜索国家/地区"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RegionCell")
        tableView.rowHeight = 52
        tableView.backgroundColor = .clear
        tableView.separatorColor = .themeSeparatorLight
        tableView.tableHeaderView = searchBar
        searchBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension RegionSelectViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredRegions = regions
        } else {
            filteredRegions = regions.filter {
                $0.name.contains(searchText) || $0.dial.contains(searchText)
            }
        }
        tableView.reloadData()
    }
}

extension RegionSelectViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRegions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegionCell", for: indexPath)
        let region = filteredRegions[indexPath.row]
        cell.textLabel?.text = region.name
        cell.textLabel?.font = ThemeFont.body(16)
        cell.textLabel?.textColor = .themeTextPrimary
        cell.detailTextLabel?.text = region.dial
        cell.detailTextLabel?.font = ThemeFont.bodySmall(14)
        cell.detailTextLabel?.textColor = .themeTextSecondary
        cell.backgroundColor = .themeBgWhite
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let region = filteredRegions[indexPath.row]
        onSelected?(region.code, region.dial)
        navigationController?.popViewController(animated: true)
    }
}
