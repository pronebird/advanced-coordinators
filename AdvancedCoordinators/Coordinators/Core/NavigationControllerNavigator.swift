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
        notifyCompletion(completion)
    }

    func pushViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController.pushViewController(vc, animated: animated)
        notifyCompletion(completion)
    }

    func popViewController(animated: Bool, completion: (() -> Void)?) {
        navigationController.popViewController(animated: animated)
        notifyCompletion(completion)
    }

    func popToViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController.popToViewController(vc, animated: animated)
        notifyCompletion(completion)
    }

    func popToRootViewController(animated: Bool, completion: (() -> Void)?) {
        navigationController.popToRootViewController(animated: animated)
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
}

extension UINavigationController: NavigatorContainerProtocol {
    func makeNavigator() -> NavigatorProtocol {
        return NavigationControllerNavigator(navigationController: self)
    }
}
