//
//  RootControllerNavigator.swift
//  MullvadVPN
//
//  Created by pronebird on 18/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

class RootControllerNavigator: NavigatorProtocol {
    let rootController: RootContainerViewController

    var containerController: UIViewController {
        return rootController
    }

    var viewControllers: [UIViewController] {
        get {
            return rootController.viewControllers
        }
        set {
            rootController.setViewControllers(newValue, animated: false)
        }
    }

    init(rootController: RootContainerViewController = RootContainerViewController()) {
        self.rootController = rootController
    }

    func setViewControllers(_ vcs: [UIViewController], animated: Bool, completion: (() -> Void)?) {
        rootController.setViewControllers(vcs, animated: animated, completion: completion)
    }

    func pushViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        rootController.pushViewController(vc, animated: animated, completion: completion)
    }

    func popViewController(animated: Bool, completion: (() -> Void)?) {
        rootController.popViewController(animated: animated, completion: completion)
    }

    func popToViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        rootController.popToViewController(vc, animated: animated, completion: completion)
    }

    func popToRootViewController(animated: Bool, completion: (() -> Void)?) {
        rootController.popToRootViewController(animated: animated, completion: completion)
    }
}

extension RootContainerViewController: NavigatorContainerProtocol {
    func makeNavigator() -> NavigatorProtocol {
        return RootControllerNavigator(rootController: self)
    }
}
