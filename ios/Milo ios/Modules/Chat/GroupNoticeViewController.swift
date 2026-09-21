import UIKit
import SnapKit

class GroupNoticeViewController: UIViewController {

    private let groupId: String
    private var oldNotice: String
    private let textView = UITextView()

    init(groupId: String, notice: String) {
        self.groupId = groupId
        self.oldNotice = notice
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
        title = "群公告"
        view.backgroundColor = .themeBackground

        textView.font = ScreenAdapter.font(16)
        textView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        textView.backgroundColor = .systemBackground
        textView.text = oldNotice
        if !oldNotice.isEmpty {
            textView.selectedRange = NSRange(location: oldNotice.count, length: 0)
        }

        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(16))
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "保存",
            style: .done,
            target: self,
            action: #selector(save)
        )
    }

    @objc private func save() {
        let content = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if content == oldNotice { return }

        navigationItem.rightBarButtonItem?.isEnabled = false
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.updateGroupAnnouncement(groupId: groupId, notice: content))
                DispatchQueue.main.async {
                    self.oldNotice = content
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    AppUtility.showToast("群公告已更新")
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    AppUtility.showToast("更新失败")
                }
            }
        }
    }
}
