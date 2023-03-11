//
//  NavigationCoordinatorProtocol.swift
//  MullvadVPN
//
//  Created by pronebird on 20/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/// Protocol describing coordinators that manage a collection of view controllers.
protocol NavigationCoordinatorProtocol {
    /// Navigator used by coordinator to manipulate navigation stack
    var navigator: NavigatorProtocol { get set }

    /**
     Returns view controllers belonging to coordinator.
     Normally this method should return all view controllers within the navigation stack unless
     container is shared across multiple coordinators.
     */
    func separateViewControllersFromNavigator() -> [UIViewController]
}
