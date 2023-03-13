//
//  TermsOfServiceCoordinator.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 13/03/2023.
//

import UIKit

class TermsOfServiceCoordinator: Coordinator {
    let controller = ViewController()

    var onFinishFlow: ((TermsOfServiceCoordinator) -> Void)?

    override var rootViewController: UIViewController {
        return controller
    }

    override func start() {
        controller.title = "Terms of Service"
        controller.buttonTitle = "Agree and continue"
        controller.buttonAction = { [weak self] in
            guard let self = self else { return }

            self.onFinishFlow?(self)
        }
    }
}
