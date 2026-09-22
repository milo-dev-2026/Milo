import UIKit
import UserNotifications
import IQKeyboardManagerSwift
import MAMapKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 0. 全局主题配置
        setupGlobalTheme()

        // 1. 先创建并显示 window（确保不会黑屏）
        let mainWindow = UIWindow(frame: UIScreen.main.bounds)
        mainWindow.backgroundColor = .themeBackground
        self.window = mainWindow

        // 2. 设置根控制器并立即显示
        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
        if uid.isEmpty {
            let vc = EntryLoginViewController()
            mainWindow.rootViewController = BaseNavigationController(rootViewController: vc)
        } else {
            let vc = MainTabBarController()
            mainWindow.rootViewController = vc
            DispatchQueue.global(qos: .userInitiated).async {
                IMManager.shared.connect()
                DataSyncManager.shared.syncAll()
            }
        }
        mainWindow.makeKeyAndVisible()

        // 3. 后台初始化 SDK（避免阻塞启动）
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupAMapPrivacy()
            COSUploadManager.shared.setup()
        }
        DispatchQueue.main.async {
            self.setupKeyboardManager()
            self.registerPushNotification(application)
            self.setupAppLockCheck()
        }

        return true
    }

    // MARK: - 全局主题配置
    private func setupGlobalTheme() {
        // 导航栏全局外观
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: ScreenAdapter.mediumFont(17)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: ScreenAdapter.boldFont(34)
        ]
        navBarAppearance.shadowColor = UIColor.themeSeparator.withAlphaComponent(0.5)

        UINavigationBar.appearance().tintColor = .themePrimary
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        }
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().prefersLargeTitles = true

        // TabBar 全局外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.shadowColor = UIColor.themeSeparator.withAlphaComponent(0.5)
        UITabBar.appearance().tintColor = .themePrimary
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        UITabBar.appearance().unselectedItemTintColor = .systemGray

        // UISwitch 全局颜色
        UISwitch.appearance().onTintColor = .themePrimary
    }

    // MARK: - 高德隐私合规
    private func setupAMapPrivacy() {
        // 高德 SDK 初始化（已在 Podfile 中配置）
        // 注意：高德地图 SDK 需要在主线程初始化
        DispatchQueue.main.async {
            _ = MAMapView() // 触发 SDK 加载
            AMapServices.shared().enableHTTPS = true
            AMapServices.shared().apiKey = APIConfig.amapKey
        }
    }

    // MARK: - 推送注册
    private func registerPushNotification(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - 应用锁屏检查
    private func setupAppLockCheck() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastBackgroundTime")
    }

    // MARK: - 键盘管理
    private func setupKeyboardManager() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
    }

    // MARK: - APNs Token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("APNs Device Token: \(tokenString)")
        UserDefaults.standard.set(tokenString, forKey: "apns_device_token")
        uploadPushTokenToServer(token: tokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs注册失败: \(error.localizedDescription)")
    }

    private func uploadPushTokenToServer(token: String) {
        let url = APIConfig.apiBaseURL + "/v1/devices/apns"
        guard let urlObj = URL(string: url) else { return }
        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
        let authToken = UserDefaults.standard.string(forKey: "token") ?? ""
        if !authToken.isEmpty {
            request.setValue(authToken, forHTTPHeaderField: "token")
        }
        let body: [String: Any] = [
            "uid": uid,
            "device_token": token,
            "bundle_id": APIConfig.apnsBundleID
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request).resume()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("收到推送点击: \(userInfo)")

        if let channelId = userInfo["channel_id"] as? String {
            let title = (userInfo["channel_name"] as? String) ?? "聊天"
            let chatVC = ChatViewController(channelId: channelId, title: title)
            if let nav = window?.rootViewController as? UINavigationController {
                nav.pushViewController(chatVC, animated: true)
            } else if let tab = window?.rootViewController as? UITabBarController,
                      let nav = tab.selectedViewController as? UINavigationController {
                nav.pushViewController(chatVC, animated: true)
            }
        }
        completionHandler()
    }
}
