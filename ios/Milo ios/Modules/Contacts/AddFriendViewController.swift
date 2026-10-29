import UIKit
import SnapKit
import Kingfisher

// MARK: - 搜索结果模型（后端 /v1/user/search 返回单个用户）
private struct AddFriendSearchResult {
    let uid: String
    let username: String
    let name: String
    let shortNo: String
    let vercode: String

    var displayName: String {
        if !name.isEmpty { return name }
        if !username.isEmpty { return username }
        return uid
    }

    var subTitle: String {
        return shortNo.isEmpty ? "ID: \(uid)" : "Milo号: \(shortNo)"
    }
}

// MARK: - 添加好友（对齐安卓 AddFriends 布局：搜索入口 + 我的ID/二维码 + 功能列表）
class AddFriendViewController: UIViewController {

    // MARK: - 入口区
    private let searchBar = UIView()
    private let searchIcon = UIImageView()
    private let searchField = UITextField()
    private let myIdLabel = UILabel()
    private let myQRButton = UIButton(type: .custom)
    private let entryCard = UIView()
    private let scanRow = UIView()

    // MARK: - 结果区
    private let resultCard = UIView()
    private let resultAvatar = UIImageView()
    private let resultName = UILabel()
    private let resultSub = UILabel()
    private let resultAddButton = UIButton(type: .custom)
    private let emptyLabel = UILabel()

    private var currentResult: AddFriendSearchResult?
    private var applied = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "添加好友"
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)
        setupSearchBar()
        setupMyIdRow()
        setupEntryCard()
        setupResultCard()
        setupEmptyLabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - 搜索栏（圆角白底，对齐安卓 search_bar_bg）
    private func setupSearchBar() {
        searchBar.backgroundColor = .white
        searchBar.layer.cornerRadius = 10
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(44)
        }

        searchIcon.image = UIImage(systemName: "magnifyingglass")
        searchIcon.tintColor = UIColor(white: 0.6, alpha: 1)
        searchIcon.contentMode = .scaleAspectFit
        searchBar.addSubview(searchIcon)
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }

        searchField.placeholder = "搜索 ID / Milo号 / 账号"
        searchField.font = ScreenAdapter.font(15)
        searchField.textColor = .label
        searchField.tintColor = .themeColorPrimary
        searchField.autocorrectionType = .no
        searchField.autocapitalizationType = .none
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .whileEditing
        searchField.delegate = self
        searchBar.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    // MARK: - 我的ID号 + 二维码入口（对齐安卓）
    private func setupMyIdRow() {
        let myShortNo = UserDefaults.standard.string(forKey: "short_no") ?? ""
        let myUid = UserDefaults.standard.string(forKey: "uid") ?? ""
        let idText = myShortNo.isEmpty ? myUid : myShortNo

        let row = UIView()
        view.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }

        let titleLabel = UILabel()
        titleLabel.text = "我的Milo号："
        titleLabel.font = ScreenAdapter.font(13)
        titleLabel.textColor = UIColor(white: 0.6, alpha: 1)
        row.addSubview(titleLabel)

        myIdLabel.text = idText
        myIdLabel.font = ScreenAdapter.mediumFont(13)
        myIdLabel.textColor = .label
        row.addSubview(myIdLabel)

        myQRButton.setImage(UIImage(systemName: "qrcode"), for: .normal)
        myQRButton.tintColor = .label
        myQRButton.addTarget(self, action: #selector(showMyQRCode), for: .touchUpInside)
        row.addSubview(myQRButton)

        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        myIdLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(2)
            make.centerY.equalToSuperview()
        }
        myQRButton.snp.makeConstraints { make in
            make.leading.equalTo(myIdLabel.snp.trailing).offset(8)
            make.trailing.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    // MARK: - 功能入口卡片（扫一扫）
    private func setupEntryCard() {
        entryCard.backgroundColor = .white
        entryCard.layer.cornerRadius = 10
        view.addSubview(entryCard)
        entryCard.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(52)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(56)
        }

        scanRow.isUserInteractionEnabled = true
        scanRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openScan)))
        entryCard.addSubview(scanRow)
        scanRow.snp.makeConstraints { make in make.edges.equalToSuperview() }

        let iconBg = UIView()
        iconBg.backgroundColor = .themeColorPrimary
        iconBg.layer.cornerRadius = 8
        scanRow.addSubview(iconBg)
        iconBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(34)
        }
        let icon = UIImageView(image: UIImage(systemName: "qrcode.viewfinder"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }

        let title = UILabel()
        title.text = "扫一扫"
        title.font = ScreenAdapter.font(16)
        title.textColor = .label
        scanRow.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalTo(iconBg.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(white: 0.7, alpha: 1)
        arrow.contentMode = .scaleAspectFit
        scanRow.addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(8)
            make.height.equalTo(14)
        }

        let desc = UILabel()
        desc.text = "扫描二维码名片"
        desc.font = ScreenAdapter.font(13)
        desc.textColor = UIColor(white: 0.6, alpha: 1)
        scanRow.addSubview(desc)
        desc.snp.makeConstraints { make in
            make.trailing.equalTo(arrow.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - 搜索结果卡片
    private func setupResultCard() {
        resultCard.backgroundColor = .white
        resultCard.layer.cornerRadius = 10
        resultCard.isHidden = true
        view.addSubview(resultCard)
        resultCard.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(52)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(76)
        }

        resultAvatar.layer.cornerRadius = 8
        resultAvatar.clipsToBounds = true
        resultAvatar.contentMode = .scaleAspectFill
        resultAvatar.backgroundColor = UIColor(white: 0.9, alpha: 1)
        resultCard.addSubview(resultAvatar)
        resultAvatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        // 按钮必须先加入视图层级，resultName/resultSub 的 trailing 约束才能引用它
        resultAddButton.setTitle("添加", for: .normal)
        resultAddButton.setTitleColor(.white, for: .normal)
        resultAddButton.titleLabel?.font = ScreenAdapter.mediumFont(14)
        resultAddButton.backgroundColor = .themeColorPrimary
        resultAddButton.layer.cornerRadius = 15
        resultAddButton.clipsToBounds = true
        resultAddButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        resultCard.addSubview(resultAddButton)
        resultAddButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.equalTo(64)
            make.height.equalTo(30)
        }

        resultName.font = ScreenAdapter.mediumFont(16)
        resultName.textColor = .label
        resultName.lineBreakMode = .byTruncatingTail
        resultCard.addSubview(resultName)
        resultName.snp.makeConstraints { make in
            make.leading.equalTo(resultAvatar.snp.trailing).offset(12)
            make.top.equalTo(resultAvatar.snp.top).offset(4)
            // 长昵称不覆盖右侧「添加」按钮
            make.trailing.lessThanOrEqualTo(resultAddButton.snp.leading).offset(-8)
        }

        resultSub.font = ScreenAdapter.font(13)
        resultSub.textColor = UIColor(white: 0.6, alpha: 1)
        resultSub.lineBreakMode = .byTruncatingTail
        resultCard.addSubview(resultSub)
        resultSub.snp.makeConstraints { make in
            make.leading.equalTo(resultName)
            make.trailing.lessThanOrEqualTo(resultAddButton.snp.leading).offset(-8)
            make.bottom.equalTo(resultAvatar.snp.bottom).offset(-4)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(resultTapped))
        resultCard.addGestureRecognizer(tap)
    }

    private func setupEmptyLabel() {
        emptyLabel.text = "未找到该用户"
        emptyLabel.font = ScreenAdapter.font(15)
        emptyLabel.textColor = UIColor(white: 0.6, alpha: 1)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(80)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - 交互
    @objc private func showMyQRCode() {
        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
        navigationController?.pushViewController(MyQRCodeViewController(uid: uid), animated: true)
    }

    @objc private func openScan() {
        let scanVC = ScanViewController()
        // 扫码页全屏：隐藏底部 TabBar（对齐安卓）
        scanVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(scanVC, animated: true)
    }

    @objc private func resultTapped() {
        guard let user = currentResult else { return }
        let detailVC = ContactDetailViewController(uid: user.uid, source: "来自搜索")
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc private func addTapped() {
        guard let user = currentResult, !applied else { return }
        applyFriend(user)
    }

    @objc private func searchUser() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !keyword.isEmpty else {
            AppUtility.showToast("请输入搜索关键词")
            return
        }
        view.endEditing(true)
        Task {
            do {
                // 后端 /v1/user/search 精确匹配，data 为单个用户对象；make_success 直接返回 {"exist":0/1,"data":...}
                let resp = try await APIClient.shared.requestRaw(.searchUser(keyword: keyword, page: 1, pageSize: 1))
                var payload: [String: Any] = resp
                if let wrapped = resp["data"] as? [String: Any], wrapped["exist"] != nil {
                    payload = wrapped
                }

                var result: AddFriendSearchResult?
                let existValue = payload["exist"]
                let exist: Int = (existValue as? Int) ?? Int((existValue as? String) ?? "") ?? 0
                if exist == 1, let dict = payload["data"] as? [String: Any] {
                    let uid = (dict["uid"] as? String) ?? ""
                    if !uid.isEmpty {
                        let shortNo: String
                        if let s = dict["short_no"] as? String {
                            shortNo = s
                        } else if let n = dict["short_no"] as? Int {
                            shortNo = String(n)
                        } else {
                            shortNo = ""
                        }
                        result = AddFriendSearchResult(
                            uid: uid,
                            username: (dict["username"] as? String) ?? "",
                            name: (dict["name"] as? String) ?? "",
                            shortNo: shortNo,
                            vercode: (dict["vercode"] as? String) ?? ""
                        )
                    }
                }
                DispatchQueue.main.async {
                    self.showResult(result)
                    if result == nil {
                        AppUtility.showToast("未找到该用户")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showResult(nil)
                    AppUtility.showToast("搜索失败")
                }
            }
        }
    }

    private func showResult(_ result: AddFriendSearchResult?) {
        currentResult = result
        applied = false
        let has = result != nil
        resultCard.isHidden = !has
        emptyLabel.isHidden = has
        entryCard.isHidden = has
        if let r = result {
            resultName.text = r.displayName
            resultSub.text = r.subTitle
            AppUtility.loadChannelAvatar(channelId: r.uid, channelType: 1, name: r.displayName, into: resultAvatar)
            resultAddButton.setTitle("添加", for: .normal)
            resultAddButton.backgroundColor = .themeColorPrimary
            resultAddButton.isEnabled = true
        }
    }

    private func applyFriend(_ user: AddFriendSearchResult) {
        Task {
            do {
                let response = try await APIClient.shared.requestRaw(.applyFriend(uid: user.uid, remark: "", vercode: user.vercode))
                // 后端成功时可能直接返回空对象，无 status 字段也视为成功
                let status = response["status"] as? Int
                if status == nil || status == 200 {
                    DispatchQueue.main.async {
                        self.applied = true
                        self.resultAddButton.setTitle("已发送", for: .normal)
                        self.resultAddButton.backgroundColor = UIColor(white: 0.7, alpha: 1)
                        self.resultAddButton.isEnabled = false
                        AppUtility.showToast("已发送好友申请")
                    }
                } else {
                    DispatchQueue.main.async {
                        AppUtility.showToast(response["msg"] as? String ?? "发送申请失败")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("发送申请失败")
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension AddFriendViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchUser()
        return true
    }
}
