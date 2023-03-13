//
//  AppCoordinator.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 11/03/2023.
//

import UIKit

struct AppState {
    var isAgreedTOS = false
    var deviceState = DeviceState.revoked
}

enum DeviceState {
    case loggedOut
    case loggedIn
    case revoked
}

class AppCoordinator: Coordinator, RootContainerViewControllerDelegate {
    let splitViewController = SplitViewController()
    let navigationController = RootContainerViewController()

    var appState = AppState() {
        didSet {
            propagateState()
        }
    }

    override var rootViewController: UIViewController {
        return navigationController
    }

    override init() {
        super.init()

        splitViewController.primaryEdge = .trailing
        splitViewController.dividerColor = UIColor.MainSplitView.dividerColor

        navigationController.delegate = self

        addPresentationRule(
            BlockPresentationHandler { child, presenting, presented, traitCollection in
                switch traitCollection.applicationLayout {
                case .splitView:
                    return .modal(ModalPresentationConfiguration(
                        preferredContentSize: CGSize(width: 320, height: 480),
                        modalPresentationStyle: .custom,
                        isModalInPresentation: true,
                        transitioningDelegate: LoginTransitioningDelegate()
                    ))

                case .horizontalNavigation:
                    return .push(self.navigationController)
                }
            },
            conditions: [.presentedCoordinator(TermsOfServiceCoordinator.self)]
        )

        addPresentationRule(
            BlockPresentationHandler { child, presenting, presented, traitCollection in
                switch traitCollection.applicationLayout {
                case .splitView:
                    return .modal(ModalPresentationConfiguration(
                        preferredContentSize: CGSize(width: 320, height: 480),
                        modalPresentationStyle: .custom,
                        isModalInPresentation: true,
                        transitioningDelegate: LoginTransitioningDelegate()
                    ))

                case .horizontalNavigation:
                    return .push(self.navigationController)
                }
            },
            conditions: [.presentedCoordinator(RevokedCoordinator.self)]
        )

        addPresentationRule(
            BlockPresentationHandler { child, presenting, presented, traitCollection in
                switch traitCollection.applicationLayout {
                case .horizontalNavigation:
                    return .reparent(self.navigationController)

                case .splitView:
                    return .modal(ModalPresentationConfiguration(
                        preferredContentSize: CGSize(width: 320, height: 480),
                        modalPresentationStyle: .custom,
                        isModalInPresentation: true,
                        transitioningDelegate: LoginTransitioningDelegate()
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
                    return .group([
                        .reparent(UINavigationController()),
                        .modal(ModalPresentationConfiguration()),
                    ])
                case .splitView:
                    return .splitView(self.splitViewController, .primary)
                }
            },
            conditions: [.presentedCoordinator(SelectLocationCoordinator.self)]
        )

        addPresentationRule(
            BlockPresentationHandler { child, presenting, presented, traitCollection in
                switch traitCollection.applicationLayout {
                case .horizontalNavigation:
                    return .modal(ModalPresentationConfiguration())

                case .splitView:
                    return .modal(
                        ModalPresentationConfiguration(
                            preferredContentSize: CGSize(width: 320, height: 480),
                            modalPresentationStyle: .formSheet
                        )
                    )
                }
            },
            conditions: [.presentedCoordinator(SettingsCoordinator.self)]
        )

        addSegueProvider(
            BlockSegueProvider { source, target, context, traitCollection in
                switch traitCollection.applicationLayout {
                case .splitView:
                    let coordinatorsToHide = self.childCoordinators.filter { coordinator in
                        return coordinator is RevokedCoordinator
                    }

                    var actions: [SegueDescriptor] = [.hide(source)]
                    actions.append(contentsOf: coordinatorsToHide.map { .hide($0) })
                    actions.append(.show(presenting: context, presented: target))

                    return .sequence(actions)

                case .horizontalNavigation:
                    let coordinatorsToHide = self.childCoordinators.filter { coordinator in
                        return coordinator is RevokedCoordinator || coordinator is TunnelCoordinator
                    }

                    var actions: [SegueDescriptor] = [
                        .show(presenting: context, presented: target),
                    ]

                    actions.append(contentsOf: coordinatorsToHide.map { .hide($0) })

                    return .parallel([
                        .hide(source),
                        .sequence(actions),
                    ])
                }

            }, conditions: [
                .sourceCoordinator(SettingsCoordinator.self),
                .targetCoordinator(LoginCoordinator.self),
            ]
        )
    }

    override func start() {
        let traitCollection = window?.traitCollection ?? UITraitCollection()

        reassembleChildren(for: traitCollection) {
            self.continueFlow()
        }
    }

    private func continueFlow(from coordinator: Coordinator? = nil, animated: Bool = false) {
        guard appState.isAgreedTOS else {
            performSegue(from: coordinator, to: makeTOSCoordinator(), animated: animated)
            return
        }

        switch appState.deviceState {
        case .loggedOut:
            performSegue(from: coordinator, to: makeLoginCoordinator(), animated: animated)

        case .loggedIn:
            let traitCollection = window?.traitCollection ?? UITraitCollection()

            switch traitCollection.applicationLayout {
            case .horizontalNavigation:
                performSegue(from: coordinator, to: makeTunnelCoordinator(), animated: animated)

            case .splitView:
                coordinator?.hide(animated: animated)
            }

        case .revoked:
            performSegue(from: coordinator, to: makeRevokedCoordinator(), animated: animated)
        }
    }

    func handleTraitCollectionChange(
        windowScene: UIWindowScene,
        previousTraitCollection: UITraitCollection
    ) {
        let traitCollection = windowScene.traitCollection

        guard traitCollection.applicationLayout != previousTraitCollection.applicationLayout
        else { return }

        reassembleChildren(for: traitCollection) {
            // no-op
        }
    }

    override func updateChildren(for traitCollection: UITraitCollection) {
        switch traitCollection.applicationLayout {
        case .splitView:
            if !containsChild(ofType: TunnelCoordinator.self) {
                addChild(makeTunnelCoordinator())
            }

            if !containsChild(ofType: SelectLocationCoordinator.self) {
                addChild(makeSelectLocationCoordinator())
            }

            var viewControllers = navigationController.viewControllers
            viewControllers.insert(splitViewController, at: 0)
            navigationController.setViewControllers(viewControllers, animated: false)

        case .horizontalNavigation:
            if let child = firstChild(ofType: TunnelCoordinator.self),
               appState.deviceState == .loggedOut
            {
                removeChild(child)
            }

            if let child = firstChild(ofType: SelectLocationCoordinator.self) {
                removeChild(child)
            }

            let viewControllers = navigationController.viewControllers
                .filter { $0 != splitViewController }
            navigationController.setViewControllers(viewControllers, animated: false)
        }
    }

    // MARK: -

    private func propagateState() {
        firstChild(ofType: SettingsCoordinator.self)?.appState = appState
    }

    private func makeTOSCoordinator() -> TermsOfServiceCoordinator {
        let tosCoordinator = TermsOfServiceCoordinator()

        tosCoordinator.onFinishFlow = { [weak self] coordinator in
            self?.appState.isAgreedTOS = true

            self?.continueFlow(from: coordinator, animated: true)
        }

        return tosCoordinator
    }

    private func makeTunnelCoordinator() -> TunnelCoordinator {
        let tunnelCoordinator = TunnelCoordinator()

        tunnelCoordinator.onShowSelectLocation = { [weak self] coordinator in
            guard let self = self else { return }

            self.show(self.makeSelectLocationCoordinator(), animated: true)
        }

        return tunnelCoordinator
    }

    private func makeSelectLocationCoordinator() -> SelectLocationCoordinator {
        let selectLocationCoordinator = SelectLocationCoordinator()

        return selectLocationCoordinator
    }

    private func makeRevokedCoordinator() -> RevokedCoordinator {
        let revokedCoordinator = RevokedCoordinator()

        revokedCoordinator.onFinishFlow = { [weak self] coordinator in
            guard let self = self else { return }

            self.appState.deviceState = .loggedOut

            self.continueFlow(from: coordinator, animated: true)
        }

        return revokedCoordinator
    }

    private func makeSettingsCoordinator() -> SettingsCoordinator {
        let settingsCoordinator = SettingsCoordinator()

        settingsCoordinator.appState = appState

        settingsCoordinator.onLogout = { [weak self] coordinator in
            self?.doLogout(from: coordinator)
        }

        return settingsCoordinator
    }

    private func makeLoginCoordinator() -> LoginCoordinator {
        let loginCoordinator = LoginCoordinator()

        loginCoordinator.onFinishFlow = { [weak self] coordinator in
            self?.didLogin(from: coordinator)
        }

        return loginCoordinator
    }

    private func didLogin(from loginCoordinator: LoginCoordinator) {
        appState.deviceState = .loggedIn

        let traitCollection = window?.traitCollection ?? UITraitCollection()

        switch traitCollection.applicationLayout {
        case .horizontalNavigation:
            performSegue(from: loginCoordinator, to: makeTunnelCoordinator(), animated: true)

        case .splitView:
            loginCoordinator.hide(animated: true)
        }
    }

    private func doLogout(from settingsCoordinator: SettingsCoordinator) {
        appState.deviceState = .loggedOut

        let loginCoordinator = makeLoginCoordinator()

        performSegue(from: settingsCoordinator, to: loginCoordinator, animated: true)
    }

    // MARK: - RootContainerViewControllerDelegate

    func rootContainerViewControllerShouldShowSettings(
        _ controller: RootContainerViewController,
        navigateTo route: SettingsNavigationRoute?,
        animated: Bool
    ) {
        guard !containsChild(ofType: SettingsCoordinator.self) else { return }

        show(makeSettingsCoordinator(), animated: true)
    }

    func rootContainerViewSupportedInterfaceOrientations(_ controller: RootContainerViewController)
        -> UIInterfaceOrientationMask
    {
        switch controller.traitCollection.userInterfaceIdiom {
        case .phone:
            return .portrait
        default:
            return .all
        }
    }

    func rootContainerViewAccessibilityPerformMagicTap(_ controller: RootContainerViewController)
        -> Bool
    {
        return false
    }
}
