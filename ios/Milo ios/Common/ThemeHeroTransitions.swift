//
//  ThemeHeroTransitions.swift
//  Milo
//
//  Hero 转场动画 + 搜索展开动画
//  包含：图片预览 Hero 转场、搜索栏展开/收起、页面间元素共享动画
//

import UIKit

// MARK: - Hero 转场协议
protocol HeroTransitionSource {
    /// 提供转场起始视图
    func heroSourceView(for key: String) -> UIView?
    /// 提供转场起始 frame（相对于 window）
    func heroSourceFrame(for key: String) -> CGRect?
}

protocol HeroTransitionDestination {
    /// 提供转场目标视图
    func heroDestinationView(for key: String) -> UIView?
    /// 提供转场目标 frame（相对于 window）
    func heroDestinationFrame(for key: String) -> CGRect?
}

// MARK: - 图片预览 Hero 转场
final class ImageHeroTransition: NSObject, UIViewControllerAnimatedTransitioning {

    var isDismissing: Bool = false
    var duration: TimeInterval = 0.35
    var imageKey: String = "hero_image"

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        if isDismissing {
            animateDismiss(transitionContext: transitionContext,
                           from: fromVC, to: toVC, container: container)
        } else {
            animatePresent(transitionContext: transitionContext,
                           from: fromVC, to: toVC, container: container)
        }
    }

    // MARK: - Present 动画
    private func animatePresent(transitionContext: UIViewControllerContextTransitioning,
                                from fromVC: UIViewController,
                                to toVC: UIViewController,
                                container: UIView) {
        container.addSubview(toVC.view)
        toVC.view.frame = container.bounds
        toVC.view.backgroundColor = .black

        // 背景渐入
        toVC.view.alpha = 0

        // 获取源视图和 frame
        guard let source = fromVC as? HeroTransitionSource,
              let sourceFrame = source.heroSourceFrame(for: imageKey) else {
            // fallback：淡入
            UIView.animate(withDuration: duration) {
                toVC.view.alpha = 1
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            return
        }

        // 创建过渡图片视图
        let transitionImageView = UIImageView()
        transitionImageView.contentMode = .scaleAspectFill
        transitionImageView.clipsToBounds = true
        transitionImageView.frame = sourceFrame
        transitionImageView.backgroundColor = .clear
        container.addSubview(transitionImageView)

        // 设置源图片（如果能获取到）
        if let sourceView = source.heroSourceView(for: imageKey) as? UIImageView {
            transitionImageView.image = sourceView.image
        }

        // 隐藏目标视图的图片
        if let dest = toVC as? HeroTransitionDestination,
           let destView = dest.heroDestinationView(for: imageKey) {
            destView.isHidden = true
        }

        toVC.view.alpha = 0

        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            toVC.view.alpha = 1
            if let dest = toVC as? HeroTransitionDestination,
               let destFrame = dest.heroDestinationFrame(for: self.imageKey) {
                transitionImageView.frame = destFrame
            } else {
                transitionImageView.frame = container.bounds
            }
        } completion: { _ in
            transitionImageView.removeFromSuperview()
            if let dest = toVC as? HeroTransitionDestination,
               let destView = dest.heroDestinationView(for: self.imageKey) {
                destView.isHidden = false
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    // MARK: - Dismiss 动画
    private func animateDismiss(transitionContext: UIViewControllerContextTransitioning,
                                from fromVC: UIViewController,
                                to toVC: UIViewController,
                                container: UIView) {
        container.insertSubview(toVC.view, belowSubview: fromVC.view)
        toVC.view.frame = container.bounds

        // 获取目标 frame
        guard let dest = toVC as? HeroTransitionSource,
              let destFrame = dest.heroSourceFrame(for: imageKey) else {
            // fallback：淡出
            UIView.animate(withDuration: duration, animations: {
                fromVC.view.alpha = 0
            }) { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            return
        }

        // 创建过渡图片视图
        let transitionImageView = UIImageView()
        transitionImageView.contentMode = .scaleAspectFill
        transitionImageView.clipsToBounds = true
        transitionImageView.backgroundColor = .clear
        container.addSubview(transitionImageView)

        // 设置源图片和位置
        if let source = fromVC as? HeroTransitionDestination,
           let sourceView = source.heroDestinationView(for: imageKey) as? UIImageView,
           let sourceFrame = source.heroDestinationFrame(for: imageKey) {
            transitionImageView.image = sourceView.image
            transitionImageView.frame = sourceFrame
            sourceView.isHidden = true
        } else {
            transitionImageView.frame = container.bounds
        }

        fromVC.view.backgroundColor = .black

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseInOut) {
            fromVC.view.alpha = 0
            fromVC.view.backgroundColor = .clear
            transitionImageView.frame = destFrame
        } completion: { _ in
            transitionImageView.removeFromSuperview()
            if let dest = toVC as? HeroTransitionSource,
               let destView = dest.heroSourceView(for: self.imageKey) {
                destView.isHidden = false
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - 交互式图片预览 dismiss 转场（手势拖拽）
final class InteractiveImageDismissTransition: UIPercentDrivenInteractiveTransition {

    private var isInteractive = false
    private weak var viewController: UIViewController?
    private var shouldComplete = false
    private var startPoint: CGPoint = .zero

    var dismissThreshold: CGFloat = 150
    var velocityThreshold: CGFloat = 500

    func attach(to viewController: UIViewController, in view: UIView) {
        self.viewController = viewController

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }

        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            isInteractive = true
            startPoint = translation
            viewController?.dismiss(animated: true)

        case .changed:
            let progress = min(max(translation.y / 400, 0), 1)
            shouldComplete = translation.y > dismissThreshold || velocity.y > velocityThreshold
            update(progress)

            // 缩放效果
            if let vc = viewController {
                let scale = max(1 - progress * 0.2, 0.8)
                vc.view.transform = CGAffineTransform(scaleX: scale, y: scale)
                vc.view.layer.cornerRadius = progress * 20
                vc.view.layer.masksToBounds = true
            }

        case .ended, .cancelled:
            isInteractive = false

            if shouldComplete {
                finish()
            } else {
                cancel()
                // 恢复
                UIView.animate(withDuration: 0.2) {
                    self.viewController?.view.transform = .identity
                    self.viewController?.view.layer.cornerRadius = 0
                }
            }

        default:
            break
        }
    }
}

extension InteractiveImageDismissTransition: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: pan.view)
        return velocity.y > 0 && abs(velocity.y) > abs(velocity.x)
    }
}

// MARK: - 搜索栏展开动画
final class SearchExpandAnimator {

    /// 搜索栏从右侧图标展开为完整搜索框
    static func expand(searchBar: UIView,
                       from fromButton: UIView,
                       in containerView: UIView,
                       duration: TimeInterval = 0.3,
                       completion: (() -> Void)? = nil) {
        searchBar.alpha = 0
        searchBar.transform = CGAffineTransform(scaleX: 0.1, y: 1)
        searchBar.frame.origin.x = containerView.bounds.width - 60
        containerView.addSubview(searchBar)

        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            searchBar.alpha = 1
            searchBar.transform = .identity
            searchBar.frame.origin.x = 16
        } completion: { _ in
            completion?()
        }

        if AnimationIntegration.shared.config.enableHapticFeedback {
            HapticManager.shared.impactSoft()
        }
    }

    /// 搜索栏收起为图标
    static func collapse(searchBar: UIView,
                         to toButton: UIView,
                         duration: TimeInterval = 0.25,
                         completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseIn) {
            searchBar.alpha = 0
            searchBar.transform = CGAffineTransform(scaleX: 0.1, y: 1)
        } completion: { _ in
            searchBar.removeFromSuperview()
            searchBar.transform = .identity
            completion?()
        }
    }
}

// MARK: - 搜索结果渐入动画
final class SearchResultAnimator {

    /// 搜索结果逐个淡入
    static func animateResults(_ cells: [UITableViewCell],
                               delayPerItem: TimeInterval = 0.03,
                               duration: TimeInterval = 0.25) {
        for (index, cell) in cells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: -10, y: 0)

            UIView.animate(withDuration: duration,
                           delay: delayPerItem * Double(index),
                           options: .curveEaseOut) {
                cell.alpha = 1
                cell.transform = .identity
            }
        }
    }

    /// 搜索高亮动画（关键词高亮闪烁）
    static func animateHighlight(_ label: UILabel, keyword: String) {
        guard let text = label.text, let range = text.range(of: keyword) else { return }

        let nsRange = NSRange(range, in: text)
        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttribute(.backgroundColor, value: UIColor.themeWarning.withAlphaComponent(0.3), range: nsRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.themeTextPrimary, range: nsRange)

        label.attributedText = attributed

        // 闪烁一下
        label.alpha = 0.5
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: [.curveEaseInOut, .autoreverse]) {
            label.alpha = 1
        }
    }
}

// MARK: - 页面间共享元素转场
final class SharedElementTransition: NSObject, UIViewControllerAnimatedTransitioning {

    var isDismissing: Bool = false
    var duration: TimeInterval = 0.4
    var elementKey: String = "shared_element"

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        if isDismissing {
            container.insertSubview(toVC.view, belowSubview: fromVC.view)
            toVC.view.frame = container.bounds
            toVC.view.alpha = 0

            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseInOut) {
                toVC.view.alpha = 1
                fromVC.view.alpha = 0
            } completion: { _ in
                fromVC.view.alpha = 1
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            container.addSubview(toVC.view)
            toVC.view.frame = container.bounds
            toVC.view.alpha = 0

            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseInOut) {
                toVC.view.alpha = 1
                fromVC.view.alpha = 0.3
            } completion: { _ in
                fromVC.view.alpha = 1
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - 下拉放大头图效果
final class StretchHeaderAnimator {

    /// 处理 ScrollView 下拉时头图放大效果
    static func handleScroll(_ scrollView: UIScrollView,
                             headerView: UIView,
                             headerHeight: CGFloat,
                             maxScale: CGFloat = 1.5) {
        let offsetY = scrollView.contentOffset.y + scrollView.contentInset.top

        if offsetY < 0 {
            // 下拉放大
            let scale = min(1 + (-offsetY / headerHeight), maxScale)
            let translationY = offsetY / 2

            headerView.transform = CGAffineTransform(scaleX: scale, y: scale)
                .translatedBy(x: 0, y: translationY)
        } else {
            // 上推视差
            let progress = min(offsetY / headerHeight, 1)
            let translationY = -offsetY * 0.3
            headerView.transform = CGAffineTransform(translationX: 0, y: translationY)

            // 渐隐
            headerView.alpha = 1 - progress
        }
    }
}
