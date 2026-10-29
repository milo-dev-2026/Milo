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

        // 阴影颜色
        appearance.shadowColor = UIColor.themeSeparator.withAlphaComponent(0.5)

        // 按钮 tintColor
        navigationBar.tintColor = .themePrimary

        // 应用外观
        navigationBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationBar.scrollEdgeAppearance = appearance
        }
        navigationBar.compactAppearance = appearance

        // 使用顶部小字体标题（避免被灵动岛遮挡，对齐安卓）
        navigationBar.prefersLargeTitles = false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    // MARK: - 底部 TabBar 保护
    /// 统一在目标 VC 上开启 hidesBottomBarWhenPushed（在 self 上设置对已经显示的页面无效）
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if viewControllers.count > 0 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let popped = super.popViewController(animated: animated)
        restoreTabBarIfNeeded()
        return popped
    }

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let popped = super.popToViewController(viewController, animated: animated)
        restoreTabBarIfNeeded()
        return popped
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let popped = super.popToRootViewController(animated: animated)
        restoreTabBarIfNeeded()
        return popped
    }

    /// 回到一级页面时强制恢复底部导航栏，修复"退出后 TabBar 消失"
    private func restoreTabBarIfNeeded() {
        guard viewControllers.count == 1 else { return }
        guard let tabBar = tabBarController?.tabBar else { return }
        tabBar.isHidden = false
        tabBar.alpha = 1
        if let tabVC = tabBarController {
            tabVC.view.setNeedsLayout()
            tabVC.view.layoutIfNeeded()
        }
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
        if #available(iOS 15.0, *) {
            navigationBar.scrollEdgeAppearance = appearance
        }
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
        if #available(iOS 15.0, *) {
            navigationBar.scrollEdgeAppearance = appearance
        }
        navigationBar.tintColor = .themePrimary
    }
}
