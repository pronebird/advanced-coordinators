//
//  ReparentPresenter.swift
//  MullvadVPN
//
//  Created by pronebird on 18/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/**
 Presenter implementing reparenting of coordinator's children into a different navigation stack.

 Coordinators using this presenter should implement `NavigationCoordinatorProtocol`.
 */
final class ReparentPresenter: PresenterProtocol, NavigationPresenterProtocol {
    private(set) var presenting: NavigatorProtocol
    private let child: Coordinator
    private var previousNavigator: NavigatorProtocol?

    var navigatorContainer: UIViewController? {
        return presenting.containerController
    }

    init(presenting: NavigatorProtocol, child: Coordinator) {
        self.presenting = presenting
        self.child = child
    }

    func show(animated: Bool, completion: (() -> Void)?) {
        if var child = child as? NavigationCoordinatorProtocol {
            assert(child.navigator.containerController != presenting.containerController)

            let children = separateChildren(from: child)

            previousNavigator = child.navigator
            child.navigator = presenting

            presenting.setViewControllers(children, animated: animated, completion: completion)

        } else {
            let children = presenting.viewControllers + [child._cachedRootViewController]

            presenting.setViewControllers(children, animated: animated, completion: completion)
        }
    }

    func hide(animated: Bool, completion: (() -> Void)?) {
        if var child = child as? NavigationCoordinatorProtocol {
            assert(previousNavigator?.containerController != presenting.containerController)

            let children = separateChildren(from: child)
            let newChildren = previousNavigator!.viewControllers + children
            child.navigator = previousNavigator!
            previousNavigator!.setViewControllers(
                newChildren,
                animated: animated,
                completion: completion
            )
        } else {
            let childController = child._cachedRootViewController
            let filteredControllers = presenting.viewControllers.filter { vc in
                return vc != childController
            }
            presenting.setViewControllers(
                filteredControllers,
                animated: animated,
                completion: completion
            )
        }
    }

    private func separateChildren(from child: NavigationCoordinatorProtocol) -> [UIViewController] {
        let children = child.separateViewControllersFromNavigator()
        let remainingControllers = child.navigator.viewControllers.filter { vc in
            return !children.contains(vc)
        }
        child.navigator.setViewControllers(remainingControllers, animated: false)
        return children
    }
}
