import UIKit

// MARK: - 基础导航控制器
/// 统一导航栏毛玻璃效果、蓝色主题 tintColor、返回按钮样式
class BaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarAppearance()
        delegate = self
    }

    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        // 标题文字样式
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: ScreenAdapter.mediumFont(17)
        ]

        // 大标题样式
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: ScreenAdapter.boldFont(34)
        ]

        // 按钮 tintColor
        navigationBar.tintColor = .themePrimary

        // 应用外观
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        // 启用大标题（一级页面使用）
        navigationBar.prefersLargeTitles = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

// MARK: - UINavigationControllerDelegate
extension BaseNavigationController: UINavigationControllerDelegate {

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        // 统一返回按钮样式：蓝色 iOS 原生箭头，隐藏文字
        if viewControllers.count > 1 {
            let backButton = UIBarButtonItem(
                title: "",
                style: .plain,
                target: nil,
                action: nil
            )
            viewController.navigationItem.backBarButtonItem = backButton
        }
    }
}

// MARK: - UINavigationController 扩展
extension UINavigationController {

    /// 配置导航栏为透明毛玻璃效果（用于滚动时与内容融合）
    func configureTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: ScreenAdapter.mediumFont(17)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: ScreenAdapter.boldFont(34)
        ]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.tintColor = .themePrimary
    }

    /// 恢复默认毛玻璃导航栏
    func restoreDefaultNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: ScreenAdapter.mediumFont(17)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: ScreenAdapter.boldFont(34)
        ]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.tintColor = .themePrimary
    }
}
