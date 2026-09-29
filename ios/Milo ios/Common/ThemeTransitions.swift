//
//  ThemeTransitions.swift
//  Milo
//
//  自定义导航转场控制器
//  支持多种转场样式 + 手势驱动交互动画
//

import UIKit

// MARK: - 转场样式枚举
enum TransitionStyle {
    case slideRight       // 右侧滑入（默认）
    case slideBottom      // 底部滑入
    case fade             // 淡入淡出
    case zoom             // 缩放
    case flipHorizontal   // 水平翻转
    case coverVertical    // 垂直覆盖
}

// MARK: - 导航控制器转场代理
final class NavigationTransitionDelegate: NSObject, UINavigationControllerDelegate {

    static let shared = NavigationTransitionDelegate()

    /// 当前转场样式
    var transitionStyle: TransitionStyle = .slideRight

    /// 交互式转场（手势驱动）
    private var interactionController: UIPercentDrivenInteractiveTransition?

    /// 是否正在交互式返回
    var isInteractivePop = false

    /// 给导航控制器添加侧滑返回手势
    func addScreenEdgePanGesture(to navigationController: UINavigationController) {
        let panGesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleScreenEdgePan(_:))
        )
        panGesture.edges = .left
        panGesture.delegate = self
        navigationController.view.addGestureRecognizer(panGesture)
    }

    @objc private func handleScreenEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard let nav = gesture.view as? UINavigationController else { return }

        let translation = gesture.translation(in: gesture.view)
        let progress = max(0, min(translation.x / gesture.view!.bounds.width, 1))

        switch gesture.state {
        case .began:
            isInteractivePop = true
            interactionController = UIPercentDrivenInteractiveTransition()
            interactionController?.completionCurve = .easeInOut
            nav.popViewController(animated: true)

        case .changed:
            interactionController?.update(progress)

        case .ended, .cancelled:
            isInteractivePop = false
            if progress > 0.4 {
                interactionController?.finish()
            } else {
                interactionController?.cancel()
            }
            interactionController = nil

        default:
            break
        }
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        let isDismissing = operation == .pop

        switch transitionStyle {
        case .slideRight:
            return SlideRightTransition(isDismissing: isDismissing)

        case .slideBottom:
            return SlideBottomTransition(isDismissing: isDismissing)

        case .fade:
            return FadeTransition(isDismissing: isDismissing)

        case .zoom:
            return ZoomTransition(isDismissing: isDismissing)

        case .flipHorizontal:
            return FlipTransition(isDismissing: isDismissing)

        case .coverVertical:
            return CoverVerticalTransition(isDismissing: isDismissing)
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return isInteractivePop ? interactionController : nil
    }
}

// MARK: - UIGestureRecognizerDelegate
extension NavigationTransitionDelegate: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - 右侧滑入转场
final class SlideRightTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let isDismissing: Bool
    private let duration: TimeInterval = AnimationDuration.pageTransition

    init(isDismissing: Bool) {
        self.isDismissing = isDismissing
        super.init()
    }

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

        let screenWidth = container.bounds.width

        if isDismissing {
            container.insertSubview(toVC.view, belowSubview: fromVC.view)
            toVC.view.frame = container.bounds
            toVC.view.transform = CGAffineTransform(translationX: -screenWidth * 0.3, y: 0)
            toVC.view.alpha = 0.8

            // 阴影层
            let shadowView = UIView(frame: container.bounds)
            shadowView.backgroundColor = UIColor.black
            shadowView.alpha = 0.2
            fromVC.view.insertSubview(shadowView, at: 0)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                fromVC.view.transform = CGAffineTransform(translationX: screenWidth, y: 0)
                toVC.view.transform = .identity
                toVC.view.alpha = 1.0
                shadowView.alpha = 0
            } completion: { _ in
                fromVC.view.transform = .identity
                shadowView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            container.addSubview(toVC.view)
            toVC.view.frame = container.bounds
            toVC.view.transform = CGAffineTransform(translationX: screenWidth, y: 0)

            // 阴影层
            let shadowView = UIView(frame: container.bounds)
            shadowView.backgroundColor = UIColor.black
            shadowView.alpha = 0
            fromVC.view.insertSubview(shadowView, at: 0)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toVC.view.transform = .identity
                fromVC.view.transform = CGAffineTransform(translationX: -screenWidth * 0.3, y: 0)
                fromVC.view.alpha = 0.8
                shadowView.alpha = 0.2
            } completion: { _ in
                fromVC.view.transform = .identity
                fromVC.view.alpha = 1.0
                shadowView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - 底部滑入转场
final class SlideBottomTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let isDismissing: Bool
    private let duration: TimeInterval = AnimationDuration.bottomSheet

    init(isDismissing: Bool) {
        self.isDismissing = isDismissing
        super.init()
    }

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

        let screenHeight = container.bounds.height

        if isDismissing {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
                fromVC.view.transform = CGAffineTransform(translationX: 0, y: screenHeight)
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            container.addSubview(toVC.view)
            toVC.view.frame = container.bounds
            toVC.view.transform = CGAffineTransform(translationX: 0, y: screenHeight)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toVC.view.transform = .identity
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - 淡入淡出转场
final class FadeTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let isDismissing: Bool
    private let duration: TimeInterval = AnimationDuration.normal

    init(isDismissing: Bool) {
        self.isDismissing = isDismissing
        super.init()
    }

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

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                fromVC.view.alpha = 0
                toVC.view.alpha = 1
            } completion: { _ in
                fromVC.view.alpha = 1
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            container.addSubview(toVC.view)
            toVC.view.frame = container.bounds
            toVC.view.alpha = 0

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                toVC.view.alpha = 1
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - 缩放转场
final class ZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let isDismissing: Bool
    private let duration: TimeInterval = AnimationDuration.slow

    init(isDismissing: Bool) {
        self.isDismissing = isDismissing
        super.init()
    }

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
            toVC.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            toVC.view.alpha = 0.5

            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.3,
                           options: .curveEaseInOut) {
                fromVC.view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                fromVC.view.alpha = 0
                toVC.view.transform = .identity
                toVC.view.alpha = 1
            } completion: { _ in
                fromVC.view.transform = .identity
                fromVC.view.alpha = 1
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            container.addSubview(toVC.view)
            toVC.view.frame = container.bounds
            toVC.view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            toVC.view.alpha = 0

            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.3,
                           options: .curveEaseInOut) {
                toVC.view.transform = .identity
                toVC.view.alpha = 1
                fromVC.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                fromVC.view.alpha = 0.5
            } completion: { _ in
                fromVC.view.transform = .identity
                fromVC.view.alpha = 1
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - 水平翻转转场
final class FlipTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let isDismissing: Bool
    private let duration: TimeInterval = AnimationDuration.slow

    init(isDismissing: Bool) {
        self.isDismissing = isDismissing
        super.init()
    }

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

            // 3D 翻转
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 500
            transform = CATransform3DRotate(transform, .pi / 2, 0, 1, 0)
            toVC.view.layer.transform = transform

            UIView.animate(withDuration: duration / 2, delay: 0, options: .curveEaseIn) {
                var fromTransform = CATransform3DIdentity
                fromTransform.m34 = -1.0 / 500
                fromTransform = CATransform3DRotate(fromTransform, -.pi / 2, 0, 1, 0)
                fromVC.view.layer.transform = fromTransform
            } completion: { _ in
                UIView.animate(withDuration: self.duration / 2, delay: 0, options: .curveEaseOut) {
                    toVC.view.layer.transform = CATransform3DIdentity
                } completion: { _ in
                    fromVC.view.layer.transform = CATransform3DIdentity
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            }
        } else {
            container.addSubview(toVC.view)
            toVC.view.frame = container.bounds

            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 500
            transform = CATransform3DRotate(transform, -.pi / 2, 0, 1, 0)
            toVC.view.layer.transform = transform

            UIView.animate(withDuration: duration / 2, delay: 0, options: .curveEaseIn) {
                var fromTransform = CATransform3DIdentity
                fromTransform.m34 = -1.0 / 500
                fromTransform = CATransform3DRotate(fromTransform, .pi / 2, 0, 1, 0)
                fromVC.view.layer.transform = fromTransform
            } completion: { _ in
                UIView.animate(withDuration: self.duration / 2, delay: 0, options: .curveEaseOut) {
                    toVC.view.layer.transform = CATransform3DIdentity
                } completion: { _ in
                    fromVC.view.layer.transform = CATransform3DIdentity
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            }
        }
    }
}

// MARK: - 垂直覆盖转场
final class CoverVerticalTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let isDismissing: Bool
    private let duration: TimeInterval = AnimationDuration.slow

    init(isDismissing: Bool) {
        self.isDismissing = isDismissing
        super.init()
    }

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

        let screenHeight = container.bounds.height

        if isDismissing {
            container.insertSubview(toVC.view, belowSubview: fromVC.view)
            toVC.view.frame = container.bounds

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                fromVC.view.transform = CGAffineTransform(translationX: 0, y: -screenHeight * 0.3)
                fromVC.view.alpha = 0
            } completion: { _ in
                fromVC.view.transform = .identity
                fromVC.view.alpha = 1
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            container.addSubview(toVC.view)
            toVC.view.frame = container.bounds
            toVC.view.transform = CGAffineTransform(translationX: 0, y: screenHeight * 0.3)
            toVC.view.alpha = 0

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toVC.view.transform = .identity
                toVC.view.alpha = 1
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - UIViewController 转场便捷方法
extension UIViewController {

    /// 使用指定样式 push 页面
    func pushViewController(_ vc: UIViewController, style: TransitionStyle = .slideRight, animated: Bool = true) {
        guard let nav = navigationController else { return }

        NavigationTransitionDelegate.shared.transitionStyle = style
        nav.delegate = NavigationTransitionDelegate.shared
        nav.pushViewController(vc, animated: animated)

        // 恢复默认
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NavigationTransitionDelegate.shared.transitionStyle = .slideRight
        }
    }

    /// 使用指定样式 present 页面
    func presentWithTransition(_ vc: UIViewController, style: TransitionStyle = .slideBottom, animated: Bool = true, completion: (() -> Void)? = nil) {
        vc.modalPresentationStyle = .fullScreen
        vc.transitioningDelegate = nil
        present(vc, animated: animated, completion: completion)
    }
}
