//
//  PresentationHandlerProtocol.swift
//  MullvadVPN
//
//  Created by pronebird on 18/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/**
 Enum type describing presentation that should be used for coordinator.
 */
enum PresentationDescriptor {
    /// Modal presentation.
    case modal(ModalPresentationConfiguration)

    /// Push view controller into existing navigation container.
    case push(NavigatorContainerProtocol)

    /// Reparent into existing navigation container.
    case reparent(NavigatorContainerProtocol)

    /// Move into split view.
    case splitView(SplitViewContainerProtocol, SplitViewColumn)

    /// Group presentation.
    case group([PresentationDescriptor])
}

/**
 Protocol describing objects responsible for providing the appropriate presentation for
 coordinators based on the given environment.
 */
protocol PresentationHandlerProtocol {
    func presentationDescriptor(
        for child: Coordinator,
        presenting: UIViewController,
        presented: UIViewController,
        traitCollection: UITraitCollection
    ) -> PresentationDescriptor
}
