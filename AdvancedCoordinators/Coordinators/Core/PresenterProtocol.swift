//
//  PresenterProtocol.swift
//  MullvadVPN
//
//  Created by pronebird on 31/01/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/// Protocol describing types that handle view controller presentation.
protocol PresenterProtocol {
    /// Returns `true` if presenter supports interactive dismissal, i.e such as using swipe gesture.
    var supportsInteractiveDismissal: Bool { get }

    /// Add handler block that's invoked after interactive dismissal.
    func notifyInteractiveDismissal(_ handler: @escaping () -> Void)

    /// Show coordinator view controller.
    func show(animated: Bool, completion: (() -> Void)?)

    /// Hide coordinator view controller.
    func hide(animated: Bool, completion: (() -> Void)?)
}

/// Default implementation of `PresenterProtocol`.
extension PresenterProtocol {
    var supportsInteractiveDismissal: Bool {
        return false
    }

    func notifyInteractiveDismissal(_ handler: @escaping () -> Void) {}

    func show(animated: Bool) {
        show(animated: animated, completion: nil)
    }

    func hide(animated: Bool) {
        hide(animated: animated, completion: nil)
    }

    /// Returns `true` when both presenters share the same container.
    func isSharingNavigationContainer(with other: PresenterProtocol) -> Bool {
        guard let lhs = self as? NavigationPresenterProtocol,
              let rhs = other as? NavigationPresenterProtocol else { return false }

        return lhs.navigatorContainer == rhs.navigatorContainer
    }
}

/// Protocol describing presenters that manipulate navigation stacks.
protocol NavigationPresenterProtocol {
    var navigatorContainer: UIViewController? { get }
}
