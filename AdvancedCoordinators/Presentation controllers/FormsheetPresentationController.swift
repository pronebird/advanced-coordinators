//
//  FormsheetPresentationController.swift
//  MullvadVPN
//
//  Created by pronebird on 18/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

private let dimmingViewOpacity: CGFloat = 0.5
private let presentedViewCornerRadius: CGFloat = 8
private let animationDuration: TimeInterval = 0.5

class FormsheetPresentationController: UIPresentationController {
    private var isPresented = false

    private let dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = .black
        return dimmingView
    }()

    override var shouldRemovePresentersView: Bool {
        return false
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return super.frameOfPresentedViewInContainerView
        }

        return FormsheetPresentationAnimator.targetFrame(
            in: containerView,
            preferredContentSize: presentedViewController.preferredContentSize
        )
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { context in
            guard let containerView = self.containerView, self.isPresented else { return }

            let targetFrame = FormsheetPresentationAnimator.targetFrame(
                in: containerView,
                preferredContentSize: self.presentedViewController.preferredContentSize
            )

            self.presentedView?.frame = targetFrame
        }
    }

    override func containerViewWillLayoutSubviews() {
        dimmingView.frame = containerView?.bounds ?? .zero
    }

    override func presentationTransitionWillBegin() {
        dimmingView.alpha = 0
        containerView?.addSubview(dimmingView)

        presentedView?.layer.cornerRadius = presentedViewCornerRadius
        presentedView?.clipsToBounds = true

        if let transitionCoordinator = presentingViewController.transitionCoordinator {
            transitionCoordinator.animate { context in
                self.dimmingView.alpha = dimmingViewOpacity
            }
        } else {
            dimmingView.alpha = dimmingViewOpacity
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed {
            isPresented = true
        } else {
            dimmingView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        let fadeDimmingView = {
            self.dimmingView.alpha = 0
        }

        if let transitionCoordinator = presentingViewController.transitionCoordinator {
            transitionCoordinator.animate { context in
                fadeDimmingView()
            }
        } else {
            fadeDimmingView()
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
            isPresented = false
        }
    }
}

class FormsheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return FormsheetPresentationAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        return FormsheetPresentationAnimator()
    }

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return FormsheetPresentationController(
            presentedViewController: presented,
            presenting: source
        )
    }
}

class FormsheetPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
        -> TimeInterval
    {
        return (transitionContext?.isAnimated ?? true) ? animationDuration : 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let destination = transitionContext.viewController(forKey: .to)

        if destination?.isBeingPresented ?? false {
            animatePresentation(transitionContext)
        } else {
            animateDismissal(transitionContext)
        }
    }

    private func animatePresentation(_ transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        let containerView = transitionContext.containerView
        let destinationView = transitionContext.view(forKey: .to)!
        let destinationController = transitionContext.viewController(forKey: .to)!
        let preferredContentSize = destinationController.preferredContentSize

        containerView.addSubview(destinationView)
        destinationView.frame = Self.initialFrame(
            in: containerView,
            preferredContentSize: preferredContentSize
        )

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                destinationView.frame = Self.targetFrame(
                    in: containerView,
                    preferredContentSize: preferredContentSize
                )
            },
            completion: { _ in
                transitionContext.completeTransition(true)
            }
        )
    }

    private func animateDismissal(_ transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        let containerView = transitionContext.containerView
        let sourceView = transitionContext.view(forKey: .from)!
        let sourceController = transitionContext.viewController(forKey: .from)!
        let preferredContentSize = sourceController.preferredContentSize

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                sourceView.frame = Self.initialFrame(
                    in: containerView,
                    preferredContentSize: preferredContentSize
                )
            },
            completion: { _ in
                transitionContext.completeTransition(true)
            }
        )
    }

    fileprivate static func initialFrame(
        in containerView: UIView,
        preferredContentSize: CGSize
    ) -> CGRect {
        assert(preferredContentSize.width > 0 && preferredContentSize.height > 0)

        return CGRect(
            origin: CGPoint(
                x: containerView.bounds.midX - preferredContentSize.width * 0.5,
                y: containerView.bounds.maxY
            ),
            size: preferredContentSize
        )
    }

    fileprivate static func targetFrame(
        in containerView: UIView,
        preferredContentSize: CGSize
    ) -> CGRect {
        assert(preferredContentSize.width > 0 && preferredContentSize.height > 0)

        return CGRect(
            origin: CGPoint(
                x: containerView.bounds.midX - preferredContentSize.width * 0.5,
                y: containerView.bounds.midY - preferredContentSize.height * 0.5
            ),
            size: preferredContentSize
        )
    }
}
