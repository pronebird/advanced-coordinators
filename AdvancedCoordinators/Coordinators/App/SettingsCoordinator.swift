//
//  SettingsCoordinator.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 13/03/2023.
//

import UIKit

enum SettingsNavigationRoute: Equatable {
    case root
    case account
    case preferences
    case problemReport
    case faq
}

class SettingsCoordinator: Coordinator {
    let navigationController = UINavigationController()

    var onLogout: ((SettingsCoordinator) -> Void)?

    var appState = AppState() {
        didSet {
            updateLayout()
        }
    }

    override var rootViewController: UIViewController {
        return navigationController
    }

    override func start() {
        let vc = SettingsRootViewController()
        vc.title = "Settings root"
        vc.buttonAction = { [weak self] in
            guard let self = self else { return }

            self.onLogout?(self)
        }
        vc.appState = appState

        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissSettings)
        )

        navigationController.pushViewController(vc, animated: false)
    }

    @objc func dismissSettings() {
        hide(animated: true)
    }

    private func updateLayout() {
        guard let vc = navigationController.viewControllers.first as? SettingsRootViewController
        else { return }

        vc.appState = appState
    }
}

class SettingsRootViewController: ViewController {
    var appState = AppState() {
        didSet {
            switch appState.deviceState {
            case .loggedIn:
                buttonTitle = "Log out"
            default:
                buttonTitle = nil
            }
        }
    }
}
