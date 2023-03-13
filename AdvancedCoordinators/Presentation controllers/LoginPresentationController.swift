//
//  LoginPresentationController.swift
//  MullvadVPN
//
//  Created by pronebird on 18/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

class LoginPresentationController: FormsheetPresentationController {
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        if let containerView = containerView,
           let rootContainer = presentingViewController as? RootContainerViewController
        {
            rootContainer.addSettingsButtonToPresentationContainer(containerView)
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if let rootContainer = presentingViewController as? RootContainerViewController, completed {
            rootContainer.removeSettingsButtonFromPresentationContainer()
        }
    }
}

class LoginTransitioningDelegate: FormsheetTransitioningDelegate {
    override func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return LoginPresentationController(presentedViewController: presented, presenting: source)
    }
}
