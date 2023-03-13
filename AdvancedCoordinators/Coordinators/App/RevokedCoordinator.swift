//
//  RevokedCoordinator.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 13/03/2023.
//

import UIKit

class RevokedCoordinator: Coordinator {
    var onFinishFlow: ((RevokedCoordinator) -> Void)?

    let controller = ViewController()

    override var rootViewController: UIViewController {
        return controller
    }

    override func start() {
        controller.title = "Revoked device"
        controller.buttonTitle = "Log out"
        controller.buttonAction = { [weak self] in
            guard let self = self else { return }

            self.onFinishFlow?(self)
        }
    }
}
