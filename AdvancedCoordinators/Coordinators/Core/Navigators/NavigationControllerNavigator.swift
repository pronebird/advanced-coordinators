//
//  NavigationControllerNavigator.swift
//  MullvadVPN
//
//  Created by pronebird on 18/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

class NavigationControllerNavigator: NavigatorProtocol {
    let navigationController: UINavigationController

    var containerController: UIViewController {
        return navigationController
    }

    var viewControllers: [UIViewController] {
        get {
            return navigationController.viewControllers
        }
        set {
            navigationController.viewControllers = newValue
        }
    }

    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }

    func setViewControllers(_ vcs: [UIViewController], animated: Bool, completion: (() -> Void)?) {
        navigationController.setViewControllers(vcs, animated: animated)

        pumpEventsIfNeeded(animated: animated)
        notifyCompletion(completion)
    }

    func pushViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController.pushViewController(vc, animated: animated)

        pumpEventsIfNeeded(animated: animated)
        notifyCompletion(completion)
    }

    func popViewController(animated: Bool, completion: (() -> Void)?) {
        navigationController.popViewController(animated: animated)

        pumpEventsIfNeeded(animated: animated)
        notifyCompletion(completion)
    }

    func popToViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController.popToViewController(vc, animated: animated)

        pumpEventsIfNeeded(animated: animated)
        notifyCompletion(completion)
    }

    func popToRootViewController(animated: Bool, completion: (() -> Void)?) {
        navigationController.popToRootViewController(animated: animated)

        pumpEventsIfNeeded(animated: animated)
        notifyCompletion(completion)
    }

    private func notifyCompletion(_ completion: (() -> Void)?) {
        if let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                completion?()
            }
        } else {
            completion?()
        }
    }

    /**
     Navigation controllers rely on layout events to add or remove child controllers.

     Removing child controller from navigation controller does not guarantee that this will happen
     immediately.

     This is a problem when reparenting between navigation controllers as trying to reparent a
     child that isn't fully detached causes a crash.

     This function attempts to pump layout events to speed up that process.
     */
    private func pumpEventsIfNeeded(animated: Bool) {
        guard !animated || navigationController.view.window == nil else { return }

        navigationController.view.setNeedsLayout()
        navigationController.view.layoutIfNeeded()
    }
}

extension UINavigationController: NavigatorContainerProtocol {
    func makeNavigator() -> NavigatorProtocol {
        return NavigationControllerNavigator(navigationController: self)
    }
}
