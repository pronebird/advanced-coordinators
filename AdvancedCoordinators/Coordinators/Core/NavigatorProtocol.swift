//
//  NavigatorProtocol.swift
//  MullvadVPN
//
//  Created by pronebird on 18/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

protocol NavigatorProtocol {
    var containerController: UIViewController { get }
    var viewControllers: [UIViewController] { get set }

    func setViewControllers(_ vcs: [UIViewController], animated: Bool, completion: (() -> Void)?)
    func pushViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?)
    func popViewController(animated: Bool, completion: (() -> Void)?)
    func popToViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?)
    func popToRootViewController(animated: Bool, completion: (() -> Void)?)
}

extension NavigatorProtocol {
    func setViewControllers(_ vcs: [UIViewController], animated: Bool) {
        setViewControllers(vcs, animated: animated, completion: nil)
    }

    func pushViewController(_ vc: UIViewController, animated: Bool) {
        pushViewController(vc, animated: animated, completion: nil)
    }

    func popViewController(animated: Bool) {
        popViewController(animated: animated, completion: nil)
    }

    func popToViewController(_ vc: UIViewController, animated: Bool) {
        popToViewController(vc, animated: animated, completion: nil)
    }

    func popToRootViewController(animated: Bool) {
        popToRootViewController(animated: animated, completion: nil)
    }
}
