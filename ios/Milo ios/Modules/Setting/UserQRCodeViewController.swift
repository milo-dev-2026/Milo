import UIKit
import SnapKit
import CoreImage
import Kingfisher

class UserQRCodeViewController: UIViewController {

    private let qrImageView = UIImageView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let uidLabel = UILabel()
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
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

        if let avatarPath = LocalStore.shared.avatar {
            let url = URL(string: avatarPath.hasPrefix("http") ? avatarPath : APIConfig.apiBaseURL + "/" + avatarPath)
            if let url = url {
                avatarView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
            }
        }

        nameLabel.text = name
        nameLabel.font = ScreenAdapter.mediumFont(18)
        nameLabel.textColor = .label

        uidLabel.text = "ID: \(uid)"
        uidLabel.font = ScreenAdapter.font(13)
        uidLabel.textColor = .secondaryLabel

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.backgroundColor = .white
        qrImageView.layer.cornerRadius = ScreenAdapter.scaleW(8)

        cardView.addSubviews(avatarView, nameLabel, uidLabel, qrImageView)

        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(40))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(24))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(24))
        }

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(60))
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.centerX.equalToSuperview()
        }

        uidLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
            make.centerX.equalToSuperview()
        }

        qrImageView.snp.makeConstraints { make in
            make.top.equalTo(uidLabel.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(200))
        }

        cardView.snp.makeConstraints { make in
            make.bottom.equalTo(qrImageView).offset(ScreenAdapter.scaleH(24))
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
