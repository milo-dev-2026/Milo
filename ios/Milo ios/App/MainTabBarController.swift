import UIKit
import SnapKit

// MARK: - 主TabBar
class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // iPad 适配：不限制方向旋转
        if ScreenAdapter.isPad {
            UIDevice.current.setValue(UIInterfaceOrientationMask.all.rawValue, forKey: "orientation")
        }

        let chatVC = ConversationListViewController()
        chatVC.tabBarItem = UITabBarItem(title: "聊天", image: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"))

        let contactsVC = ContactsViewController()
        contactsVC.tabBarItem = UITabBarItem(title: "通讯录", image: UIImage(systemName: "person.2"), selectedImage: UIImage(systemName: "person.2.fill"))

        let myVC = MySettingViewController()
        myVC.tabBarItem = UITabBarItem(title: "我的", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))

        let chatNav = UINavigationController(rootViewController: chatVC)
        let contactsNav = UINavigationController(rootViewController: contactsVC)
        let myNav = UINavigationController(rootViewController: myVC)

        chatNav.navigationBar.prefersLargeTitles = false
        contactsNav.navigationBar.prefersLargeTitles = false
        myNav.navigationBar.prefersLargeTitles = false

        viewControllers = [chatNav, contactsNav, myNav]

        tabBar.tintColor = .themePrimary
        tabBar.backgroundColor = .systemBackground

        // iPad上TabBar字体调大
        if ScreenAdapter.isPad {
            tabBar.items?.forEach { item in
                item.setTitleTextAttributes([.font: ScreenAdapter.font(11)], for: .normal)
                item.setTitleTextAttributes([.font: ScreenAdapter.font(11)], for: .selected)
            }
        }
    }
}
