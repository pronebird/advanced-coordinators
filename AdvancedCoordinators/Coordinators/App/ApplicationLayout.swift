//
//  ApplicationLayout.swift
//  MullvadVPN
//
//  Created by pronebird on 07/03/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/**
 Application layout based on traits.
 */
enum ApplicationLayout: Equatable {
    /**
     Horizontal navigation layout where navigation controller is at the top of view hierarchy
     and majority of view controllers pushed into it or overlay it using modal presentation.

     This layout is used in compact presentation on iPad and on iPhone.
     */
    case horizontalNavigation

    /**
     Split view layout where navigation controller is at the top of view hierarchy with split view
     controller set as its only child.

     Majority of view controllers are presented modally on their own or within other navigation
     controllers.

     This layout is only used on iPad in regular size presentation.
     */
    case splitView
}

extension UITraitCollection {
    /// Computes application layout based off current traits.
    var applicationLayout: ApplicationLayout {
        switch userInterfaceIdiom {
        case .pad:
            return horizontalSizeClass == .compact ? .horizontalNavigation : .splitView
        default:
            return .horizontalNavigation
        }
    }
}
