//
//  PushPresenter.swift
//  MullvadVPN
//
//  Created by pronebird on 23/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/**
 Simple push presenter that adds view controller into navigation stack.
 */
final class PushPresenter: PresenterProtocol, NavigationPresenterProtocol {
    let presenting: NavigatorProtocol
    let presented: UIViewController

    var navigatorContainer: UIViewController? {
        return presenting.containerController
    }

    init(presenting: NavigatorProtocol, presented: UIViewController) {
        self.presenting = presenting
        self.presented = presented
    }

    func show(animated: Bool, completion: (() -> Void)?) {
        assert(presented.parent == nil)
        presenting.pushViewController(presented, animated: animated, completion: completion)
    }

    func hide(animated: Bool, completion: (() -> Void)?) {
        var viewControllers = presenting.viewControllers
        viewControllers.removeAll { $0 == presented }

        presenting.setViewControllers(viewControllers, animated: false, completion: completion)
    }
}
