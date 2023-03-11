//
//  AppCoordinator.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 11/03/2023.
//

import UIKit

enum AppState {
    case loggedOut
    case loggedIn
}

class AppCoordinator: Coordinator {
    let splitViewController = SplitViewController()
    let navigationController = UINavigationController()

    var state: AppState = .loggedOut

    override var rootViewController: UIViewController {
        switch window?.traitCollection.applicationLayout ?? .horizontalNavigation {
        case .splitView:
            return splitViewController

        case .horizontalNavigation:
            return navigationController
        }
    }

    override init() {
        super.init()

        splitViewController.primaryEdge = .trailing

        addPresentationRule(
            BlockPresentationHandler { child, presenting, presented, traitCollection in
                switch traitCollection.applicationLayout {
                case .horizontalNavigation:
                    return .reparent(self.navigationController)
                case .splitView:
                    return .modal(ModalPresentationConfiguration(
                        preferredContentSize: CGSize(width: 320, height: 480),
                        modalPresentationStyle: .formSheet,
                        isModalInPresentation: true
                    ))
                }
            },
            conditions: [.presentedCoordinator(LoginCoordinator.self)]
        )

        addPresentationRule(
            BlockPresentationHandler { child, presenting, presented, traitCollection in
                switch traitCollection.applicationLayout {
                case .horizontalNavigation:
                    return .push(self.navigationController)
                case .splitView:
                    return .splitView(self.splitViewController, .secondary)
                }
            },
            conditions: [.presentedCoordinator(TunnelCoordinator.self)]
        )

        addPresentationRule(
            BlockPresentationHandler { child, presenting, presented, traitCollection in
                switch traitCollection.applicationLayout {
                case .horizontalNavigation:
                    return .reparent(self.navigationController)
                case .splitView:
                    return .splitView(self.splitViewController, .primary)
                }
            },
            conditions: [.presentedCoordinator(SelectLocationCoordinator.self)]
        )
    }

    override func start() {
        reassembleChildren(for: _cachedRootViewController.traitCollection) {
            let loginCoordinator = LoginCoordinator()

            loginCoordinator.onFinishFlow = { coordinator in
                coordinator.hide(animated: true)

                self.state = .loggedIn

                // TODO: show tunnel
            }

            self.show(loginCoordinator, animated: false)
        }
    }

    func handleTraitCollectionChange(
        windowScene: UIWindowScene,
        previousTraitCollection: UITraitCollection
    ) {
        let traitCollection = windowScene.traitCollection

        guard traitCollection.applicationLayout != previousTraitCollection.applicationLayout else { return }

        reassembleChildren(for: traitCollection) {
            // no-op
        }
    }

    override func updateChildren(for traitCollection: UITraitCollection) {
        switch traitCollection.applicationLayout {
        case .splitView:
            if !containsChild(ofType: TunnelCoordinator.self) {
                addChild(TunnelCoordinator())
            }

            if !containsChild(ofType: SelectLocationCoordinator.self) {
                addChild(SelectLocationCoordinator())
            }

        case .horizontalNavigation:
            if let child = firstChild(ofType: TunnelCoordinator.self), state == .loggedOut {
                removeChild(child)
            }

            if let child = firstChild(ofType: SelectLocationCoordinator.self) {
                removeChild(child)
            }
        }
    }
    
}
