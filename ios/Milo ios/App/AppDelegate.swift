import UIKit
import UserNotifications
import IQKeyboardManagerSwift
import MAMapKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 0. 最早初始化崩溃日志捕获
        _ = CrashLogger.shared
        CrashLogger.shared.log("didFinishLaunchingWithOptions started")

        // 1. 全局主题配置
        CrashLogger.shared.log("Step 1: setupGlobalTheme")
        setupGlobalTheme()
        CrashLogger.shared.log("Step 1: done")

        // 2. 创建 window
        CrashLogger.shared.log("Step 2: creating window")
        let mainWindow = UIWindow(frame: UIScreen.main.bounds)
        mainWindow.backgroundColor = .themeBackground
        self.window = mainWindow
        CrashLogger.shared.log("Step 2: done")

        // 3. 设置根控制器
        CrashLogger.shared.log("Step 3: setting root VC")
        let uid = UserDefaults.standard.string(forKey: "uid") ?? ""
        CrashLogger.shared.log("Step 3: uid.isEmpty=\(uid.isEmpty)")
        if uid.isEmpty {
            CrashLogger.shared.log("Step 3: creating EntryLoginViewController")
            let vc = EntryLoginViewController()
            CrashLogger.shared.log("Step 3: creating BaseNavigationController")
            mainWindow.rootViewController = BaseNavigationController(rootViewController: vc)
        } else {
            CrashLogger.shared.log("Step 3: creating MainTabBarController")
            let vc = MainTabBarController()
            mainWindow.rootViewController = vc
            DispatchQueue.global(qos: .userInitiated).async {
                CrashLogger.shared.log("Step 3 bg: IMManager connect")
                IMManager.shared.connect()
                CrashLogger.shared.log("Step 3 bg: DataSyncManager sync")
                DataSyncManager.shared.syncAll()
            }
        }
        CrashLogger.shared.log("Step 3: done")

        // 4. 显示窗口
        CrashLogger.shared.log("Step 4: makeKeyAndVisible")
        mainWindow.makeKeyAndVisible()
        CrashLogger.shared.log("Step 4: done - app should be visible now")

        // 5. 延迟初始化 SDK
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            CrashLogger.shared.log("Step 5: delayed SDK init starting")
            self.setupKeyboardManager()
            self.registerPushNotification(application)
            self.setupAppLockCheck()
            self.setupAMapPrivacy()
            CrashLogger.shared.log("Step 5: COSUploadManager setup")
            COSUploadManager.shared.setup()
            CrashLogger.shared.log("Step 5: all SDK init complete")
        }

        CrashLogger.shared.log("didFinishLaunchingWithOptions returning true")
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
