import UIKit
import SnapKit

// MARK: - 主TabBar
class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarAppearance()
        setupViewControllers()
    }

    private func setupTabBarAppearance() {
        // iPad 适配：不限制方向旋转
        if ScreenAdapter.isPad {
            UIDevice.current.setValue(UIInterfaceOrientationMask.all.rawValue, forKey: "orientation")
        }

        // 毛玻璃效果（使用 UITabBarAppearance 的系统材质）
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // 选中色和未选中色
        tabBar.tintColor = .themePrimary
        tabBar.unselectedItemTintColor = .systemGray

        // 应用外观
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        // iPad上TabBar字体调大
        if ScreenAdapter.isPad {
            tabBar.items?.forEach { item in
                item.setTitleTextAttributes([.font: ScreenAdapter.font(11)], for: .normal)
                item.setTitleTextAttributes([.font: ScreenAdapter.font(11)], for: .selected)
            }
        }
    }

    private func setupViewControllers() {
        let chatVC = ConversationListViewController()
        chatVC.tabBarItem = UITabBarItem(
            title: "聊天",
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )

        let contactsVC = ContactsViewController()
        contactsVC.tabBarItem = UITabBarItem(
            title: "通讯录",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )

        let myVC = MySettingViewController()
        myVC.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        // 使用自定义导航控制器（带毛玻璃效果）
        let chatNav = BaseNavigationController(rootViewController: chatVC)
        let contactsNav = BaseNavigationController(rootViewController: contactsVC)
        let myNav = BaseNavigationController(rootViewController: myVC)

        // 一级页面启用大标题
        chatNav.navigationBar.prefersLargeTitles = true
        contactsNav.navigationBar.prefersLargeTitles = true
        myNav.navigationBar.prefersLargeTitles = true

        viewControllers = [chatNav, contactsNav, myNav]
    }
}
