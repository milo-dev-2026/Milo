import UIKit
import SnapKit

// MARK: - 启动屏
class LaunchScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let logoLabel = UILabel()
        logoLabel.text = "闲雷虎虎"
        logoLabel.font = ScreenAdapter.boldFont(36)
        logoLabel.textColor = .themePrimary
        logoLabel.textAlignment = .center
        view.addSubview(logoLabel)

        logoLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
