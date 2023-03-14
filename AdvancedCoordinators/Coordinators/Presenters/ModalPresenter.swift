//
//  ModalPresenter.swift
//  MullvadVPN
//
//  Created by pronebird on 31/01/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/**
 Presenter implementing modal presentation style.
 */
final class ModalPresenter: PresenterProtocol {
    let presenting: UIViewController
    let presented: UIViewController

    private var configuration: ModalPresentationConfiguration
    private var dismissHandlers: [() -> Void] = []

    var presentedModal: UIViewController? {
        return presented
    }

    var supportsInteractiveDismissal: Bool {
        return true
    }

    init(
        presenting: UIViewController,
        presented: UIViewController,
        configuration: ModalPresentationConfiguration? = nil
    ) {
        self.presenting = presenting
        self.presented = presented

        self.configuration = configuration ?? ModalPresentationConfiguration()

        self.configuration.interceptDismissal { [weak self] presentationController in
            self?.presentationControllerDidDismiss(presentationController)
        }
    }

    func notifyInteractiveDismissal(_ handler: @escaping () -> Void) {
        dismissHandlers.append(handler)
    }

    func show(animated: Bool, completion: (() -> Void)?) {
        configuration.apply(to: presented)

        modalPresentationContext.present(presented, animated: animated, completion: completion)
    }

    func hide(animated: Bool, completion: (() -> Void)?) {
        dismissHandlers.removeAll()

        presented.dismiss(animated: animated, completion: completion)
    }

    private var modalPresentationContext: UIViewController {
        var current: UIViewController = presenting

        while let next = current.presentedViewController {
            assert(next != current)
            assert(!next.isBeingDismissed)

            current = next
        }

        return current
    }

    private func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        for dismissHandler in dismissHandlers {
            dismissHandler()
        }

        dismissHandlers.removeAll()
    }
}

/**
 A struct holding modal presentation configuration.
 Note that delegates are strong references and should live throughout presentation cycle.
 */
struct ModalPresentationConfiguration {
    var preferredContentSize: CGSize?
    var modalPresentationStyle: UIModalPresentationStyle?
    var isModalInPresentation: Bool?
    var transitioningDelegate: UIViewControllerTransitioningDelegate?
    var presentationControllerDelegate: UIAdaptivePresentationControllerDelegate?

    func apply(to vc: UIViewController) {
        vc.transitioningDelegate = transitioningDelegate

        if let modalPresentationStyle = modalPresentationStyle {
            vc.modalPresentationStyle = modalPresentationStyle
        }

        if let preferredContentSize = preferredContentSize {
            vc.preferredContentSize = preferredContentSize
        }

        if let isModalInPresentation = isModalInPresentation {
            vc.isModalInPresentation = isModalInPresentation
        }

        vc.presentationController?.delegate = presentationControllerDelegate
    }

    fileprivate mutating func interceptDismissal(
        dismissHandler: @escaping (UIPresentationController) -> Void
    ) {
        let forwardingTarget = presentationControllerDelegate

        presentationControllerDelegate = PresentationControllerDismissalInterceptor(
            forwardingTarget: forwardingTarget,
            dismissHandler: dismissHandler
        )
    }
}
