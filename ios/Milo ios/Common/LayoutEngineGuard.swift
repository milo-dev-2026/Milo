import UIKit

/// iOS 26/27 起，在 Core Animation 布局过程中修改 Auto Layout 约束会触发
/// NSISEngine 的重入断言：`-[NSISEngine setShouldIntegralize:]` 抛出
/// NSInternalInconsistencyException，进而 abort（SIGABRT）闪退。
///
/// 典型触发场景：UINavigationController / UITabBarController 在首次布局
/// （UIApplication _firstCommitBlock）时才懒加载子控制器的视图，其 viewDidLoad
/// 中的约束（SnapKit / NSLayoutConstraint.activate）就在布局引擎忙碌时被激活。
///
/// 保护策略：记录当前线程是否处于视图布局过程中；若在布局过程中调用
/// 约束的激活/停用接口，则推迟到下一个 runloop 执行，避免在布局引擎
/// 忙碌时修改约束。
final class LayoutEngineGuard {

    private static var installed = false

    /// 必须在创建任何视图之前调用（AppDelegate 启动最早期）。
    static func install() {
        guard !installed else { return }
        installed = true
        swizzleLayoutSublayers()
        swizzleConstraintActivation()
    }

    // MARK: - 布局状态（线程局部，避免跨线程误判）

    private static let depthKey = "com.milo.layoutEngineGuard.depth"

    static var isInLayoutPass: Bool {
        (Thread.current.threadDictionary[depthKey] as? Int ?? 0) > 0
    }

    static func beginLayout() {
        let dict = Thread.current.threadDictionary
        dict[depthKey] = (dict[depthKey] as? Int ?? 0) + 1
    }

    static func endLayout() {
        let dict = Thread.current.threadDictionary
        let depth = dict[depthKey] as? Int ?? 0
        if depth <= 1 {
            dict.removeObject(forKey: depthKey)
        } else {
            dict[depthKey] = depth - 1
        }
    }

    // MARK: - Swizzle 安装

    private static func swizzleLayoutSublayers() {
        let originalSel = NSSelectorFromString("layoutSublayersOfLayer:")
        let swizzledSel = NSSelectorFromString("milo_layoutSublayersOfLayer:")
        guard let original = class_getInstanceMethod(UIView.self, originalSel),
              let swizzled = class_getInstanceMethod(UIView.self, swizzledSel) else { return }
        method_exchangeImplementations(original, swizzled)
    }

    private static func swizzleConstraintActivation() {
        let pairs = [
            ("activateConstraints:", "milo_activateConstraints:"),
            ("deactivateConstraints:", "milo_deactivateConstraints:")
        ]
        for (originalName, swizzledName) in pairs {
            guard let original = class_getClassMethod(NSLayoutConstraint.self, NSSelectorFromString(originalName)),
                  let swizzled = class_getClassMethod(NSLayoutConstraint.self, NSSelectorFromString(swizzledName)) else { continue }
            method_exchangeImplementations(original, swizzled)
        }
    }
}

extension UIView {

    @objc func milo_layoutSublayersOfLayer(_ layer: CALayer) {
        LayoutEngineGuard.beginLayout()
        milo_layoutSublayersOfLayer(layer)
        LayoutEngineGuard.endLayout()
    }
}

extension NSLayoutConstraint {

    @objc static func milo_activateConstraints(_ constraints: [NSLayoutConstraint]) {
        guard LayoutEngineGuard.isInLayoutPass else {
            milo_activateConstraints(constraints)
            return
        }
        DispatchQueue.main.async { milo_activateConstraints(constraints) }
    }

    @objc static func milo_deactivateConstraints(_ constraints: [NSLayoutConstraint]) {
        guard LayoutEngineGuard.isInLayoutPass else {
            milo_deactivateConstraints(constraints)
            return
        }
        DispatchQueue.main.async { milo_deactivateConstraints(constraints) }
    }
}
