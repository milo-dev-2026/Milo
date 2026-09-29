//
//  ThemeAnimationIntegration.swift
//  Milo
//
//  全局动画集成模块
//  自动接入页面转场、列表入场、Tab切换等动画效果
//

import UIKit

// MARK: - 动画集成总入口
final class AnimationIntegration {

    static let shared = AnimationIntegration()
    private init() {}

    // MARK: - 配置项
    struct Config {
        /// 是否启用列表入场动画
        var enableListEntranceAnimation = true
        /// 列表入场动画延迟（每行）
        var listItemDelay: TimeInterval = 0.03
        /// 是否启用 Tab 切换动画
        var enableTabSwitchAnimation = true
        /// 是否启用按钮按压缩放
        var enableButtonPressAnimation = true
        /// 是否启用触觉反馈
        var enableHapticFeedback = true
        /// 是否启用页面转场动画
        var enablePageTransition = true
    }

    var config = Config()

    // MARK: - 全局初始化
    func setupGlobalAnimations() {
        setupNavigationAppearance()
        setupTabBarAppearance()
    }

    // MARK: - 导航栏配置
    private func setupNavigationAppearance() {
        // 导航栏过渡动画
        UINavigationBar.appearance().tintColor = .themeColorPrimary
    }

    // MARK: - TabBar 配置
    private func setupTabBarAppearance() {
        // TabBar 过渡动画配置
        UITabBar.appearance().tintColor = .themeColorPrimary
    }
}

// MARK: - 基础视图控制器动画扩展
extension UIViewController {

    /// 页面首次出现时的入场动画
    func animatePageEntrance() {
        guard AnimationIntegration.shared.config.enablePageTransition else { return }

        // 视图整体淡入 + 轻微上移（克制：10pt）
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: 10)

        UIView.animate(withDuration: AnimationDuration.slow,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.4,
                       options: .curveEaseOut) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }
}

// MARK: - 表视图控制器入场动画
extension UITableViewController {

    /// 列表视图入场动画（在 viewDidAppear 中调用）
    func animateTableEntrance() {
        guard AnimationIntegration.shared.config.enableListEntranceAnimation else { return }
        tableView.animateCellsFadeInUp(delayPerItem: AnimationIntegration.shared.config.listItemDelay)
    }
}

// MARK: - 集合视图控制器入场动画
extension UICollectionViewController {

    /// 集合视图入场动画
    func animateCollectionEntrance() {
        guard AnimationIntegration.shared.config.enableListEntranceAnimation else { return }
        collectionView?.animateWaterfallIn()
    }
}

// MARK: - TabBarController 动画扩展
extension UITabBarController {

    /// 配置 Tab 切换动画（在 delegate 中调用）
    func animateTabSelection(from fromIndex: Int, to toIndex: Int) {
        guard AnimationIntegration.shared.config.enableTabSwitchAnimation else { return }
        guard fromIndex != toIndex else { return }

        // 获取目标 Tab 视图
        guard let fromView = viewControllers?[fromIndex].view,
              let toView = viewControllers?[toIndex].view else { return }

        // 方向：向右滑表示从左边切换
        let direction: CGFloat = toIndex > fromIndex ? 1 : -1

        // 添加目标视图
        view.addSubview(toView)
        toView.frame = view.bounds
        toView.transform = CGAffineTransform(translationX: direction * view.bounds.width * 0.3, y: 0)
        toView.alpha = 0

        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            toView.transform = .identity
            toView.alpha = 1
            fromView.transform = CGAffineTransform(translationX: -direction * self.view.bounds.width * 0.1, y: 0)
            fromView.alpha = 0.5
        } completion: { _ in
            fromView.transform = .identity
            fromView.alpha = 1
            // 确保 selectedViewController 正确
            self.selectedIndex = toIndex
        }

        // 触觉反馈
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }
    }
}

// MARK: - 自定义 BaseNavigationController
class AnimatedNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = NavigationTransitionDelegate.shared

        // 添加侧滑返回手势
        NavigationTransitionDelegate.shared.addScreenEdgePanGesture(to: self)

        // 保持系统返回手势兼容
        interactivePopGestureRecognizer?.delegate = self
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
        super.pushViewController(viewController, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactLight()
        }
        return super.popViewController(animated: animated)
    }
}

extension AnimatedNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

// MARK: - 自定义 BaseTabBarController
class AnimatedTabBarController: UITabBarController {

    private var previousSelectedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let items = tabBar.items,
              let index = items.firstIndex(of: item) else { return }

        if AnimationIntegration.shared.config.enableTabSwitchAnimation {
            animateTabBarSelection(at: index)
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.selectionChanged()
        }

        previousSelectedIndex = index
    }

    private func animateTabBarSelection(at index: Int) {
        let tabBarButtons = tabBar.subviews.filter { $0 is UIControl }
        guard index < tabBarButtons.count else { return }

        let button = tabBarButtons[index]

        // 缩放弹跳（克制：0.9）
        button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.4,
                       options: .curveEaseInOut) {
            button.transform = .identity
        }

        // 图标轻微上跳（克制：2pt）
        if let iconView = button.subviews.first(where: { $0 is UIImageView }) {
            iconView.transform = CGAffineTransform(translationX: 0, y: -2)
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.6,
                           options: .curveEaseInOut) {
                iconView.transform = .identity
            }
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension AnimatedTabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController,
                          didSelect viewController: UIViewController) {
        // 已在 tabBar:didSelect: 中处理
    }

    func tabBarController(_ tabBarController: UITabBarController,
                          animationControllerForTransitionFrom fromVC: UIViewController,
                          to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard AnimationIntegration.shared.config.enableTabSwitchAnimation else { return nil }

        guard let fromIndex = viewControllers?.firstIndex(of: fromVC),
              let toIndex = viewControllers?.firstIndex(of: toVC) else { return nil }

        return TabBarTransition(fromIndex: fromIndex, toIndex: toIndex)
    }
}

// MARK: - TabBar 转场动画
final class TabBarTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let fromIndex: Int
    private let toIndex: Int

    init(fromIndex: Int, toIndex: Int) {
        self.fromIndex = fromIndex
        self.toIndex = toIndex
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let direction: CGFloat = toIndex > fromIndex ? 1 : -1
        let width = container.bounds.width

        container.addSubview(toView)
        toView.frame = container.bounds
        toView.transform = CGAffineTransform(translationX: direction * width * 0.3, y: 0)
        toView.alpha = 0.5

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            toView.transform = .identity
            toView.alpha = 1
            fromView.transform = CGAffineTransform(translationX: -direction * width * 0.2, y: 0)
            fromView.alpha = 0.3
        } completion: { _ in
            fromView.transform = .identity
            fromView.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - 自定义 BaseTableViewController
class AnimatedTableViewController: UITableViewController {

    private var hasAnimatedEntrance = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .themeBg
        tableView.separatorColor = .themeSeparatorLight
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !hasAnimatedEntrance && AnimationIntegration.shared.config.enableListEntranceAnimation {
            hasAnimatedEntrance = true
            tableView.animateCellsFadeInUp()
        }
    }

    /// 重新触发入场动画（下拉刷新后可调用）
    func replayEntranceAnimation() {
        tableView.animateCellsFadeInUp()
    }
}

// MARK: - 自定义 BaseCollectionViewController
class AnimatedCollectionViewController: UICollectionViewController {

    private var hasAnimatedEntrance = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !hasAnimatedEntrance && AnimationIntegration.shared.config.enableListEntranceAnimation {
            hasAnimatedEntrance = true
            collectionView?.animateWaterfallIn()
        }
    }
}

// MARK: - 带下拉刷新的 TableViewController
class RefreshableTableViewController: AnimatedTableViewController {

    let refreshControl = PullToRefreshControl()
    let loadMoreFooter = LoadMoreFooterView()

    var isLoadingMore = false
    var hasMoreData = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefresh()
    }

    private func setupRefresh() {
        // 下拉刷新
        refreshControl.attach(to: tableView)
        refreshControl.onRefresh = { [weak self] in
            self?.handleRefresh()
        }

        // 上拉加载
        loadMoreFooter.setState(.idle)
        tableView.tableFooterView = loadMoreFooter
    }

    /// 子类重写：下拉刷新
    @objc func handleRefresh() {
        // 子类重写
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    /// 子类重写：上拉加载更多
    @objc func handleLoadMore() {
        guard !isLoadingMore && hasMoreData else { return }
        isLoadingMore = true
        loadMoreFooter.setState(.loading)

        // 子类重写
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isLoadingMore = false
            self.loadMoreFooter.setState(self.hasMoreData ? .idle : .noMore)
        }
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        // 滚动到底部加载更多
        if offsetY > contentHeight - frameHeight - 50, contentHeight > frameHeight {
            handleLoadMore()
        }
    }
}

// MARK: - 应用启动时统一配置
extension AppDelegate {

    func setupAnimationSystem() {
        // 初始化动画集成
        AnimationIntegration.shared.setupGlobalAnimations()

        // 默认配置
        var config = AnimationIntegration.Config()
        config.enableListEntranceAnimation = true
        config.enableTabSwitchAnimation = true
        config.enableButtonPressAnimation = true
        config.enableHapticFeedback = true
        config.enablePageTransition = true
        AnimationIntegration.shared.config = config

        // 初始化触觉引擎
        _ = HapticManager.shared
    }
}
