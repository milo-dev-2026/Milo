import UIKit
import SnapKit
import CoreImage
import Kingfisher

class UserQRCodeViewController: UIViewController {

    private let qrImageView = UIImageView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let shortNoLabel = UILabel()
    private let uid: String
    private let name: String

    init(uid: String, name: String) {
        self.uid = uid
        self.name = name
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
        title = "二维码"
        view.backgroundColor = .themeBackground

        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = ScreenAdapter.scaleW(16)
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = ScreenAdapter.scaleW(8)
        cardView.layer.shadowOffset = CGSize(width: 0, height: ScreenAdapter.scaleH(4))

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(30)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        AppUtility.loadChannelAvatar(channelId: uid, channelType: 1, name: name, into: avatarView)

        nameLabel.text = name
        nameLabel.font = ScreenAdapter.mediumFont(18)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center

        // 只展示 Milo 号，不再展示 uid
        let shortNo = UserDefaults.standard.string(forKey: "short_no") ?? ""
        shortNoLabel.text = "Milo号: \(shortNo)"
        shortNoLabel.font = ScreenAdapter.font(13)
        shortNoLabel.textColor = .secondaryLabel
        shortNoLabel.textAlignment = .center
        shortNoLabel.isHidden = shortNo.isEmpty

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.backgroundColor = .white
        qrImageView.layer.cornerRadius = ScreenAdapter.scaleW(8)

        // 头像 + 名称 + Milo号 居中纵向排列
        let infoStack = UIStackView(arrangedSubviews: [avatarView, nameLabel, shortNoLabel])
        infoStack.axis = .vertical
        infoStack.alignment = .center
        infoStack.spacing = ScreenAdapter.scaleH(4)
        infoStack.setCustomSpacing(ScreenAdapter.scaleH(12), after: avatarView)

        cardView.addSubviews(infoStack, qrImageView)

        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(40))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }

        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(60))
        }

        infoStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
        }

        qrImageView.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(200))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(24))
        }
    }

    private func generateQRCode() {
        let qrString = "uid:\(uid)"
        guard let data = qrString.data(using: .utf8) else { return }

        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return }

        qrImageView.image = UIImage(cgImage: cgImage)
    }
}
