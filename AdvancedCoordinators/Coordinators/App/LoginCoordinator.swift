//
//  LoginCoordinator.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 11/03/2023.
//

import UIKit

class LoginCoordinator: Coordinator, NavigationCoordinatorProtocol {

    var onFinishFlow: ((LoginCoordinator) -> Void)?

    var navigator: NavigatorProtocol = NavigationControllerNavigator()

    func separateViewControllersFromNavigator() -> [UIViewController] {
        return navigator.viewControllers.filter { vc in
            let identifier = (vc as? ViewController)?.identifier
            return identifier == "Login" || identifier == "Too many devices"
        }
    }

    override var rootViewController: UIViewController {
        return navigator.containerController
    }

    override func start() {
        let viewController = LoginViewController()
        viewController.identifier = "Login"
        viewController.title = "Log in"
        viewController.buttonTitle = "OK"
        viewController.buttonAction = { [weak self] in
            self?.next()
        }

        navigator.pushViewController(viewController, animated: false)
    }

    func next() {
        let viewController = DeviceListViewController()
        viewController.identifier = "Too many devices"
        viewController.title = "Too many devices!"
        viewController.buttonTitle = "OK"
        viewController.buttonAction = { [weak self] in
            guard let self = self else { return }

            self.onFinishFlow?(self)
        }

        navigator.pushViewController(viewController, animated: true)
    }

}

class LoginViewController: ViewController {}
class DeviceListViewController: ViewController {}
