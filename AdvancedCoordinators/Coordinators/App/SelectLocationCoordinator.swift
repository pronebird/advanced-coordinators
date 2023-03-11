//
//  SelectLocationCoordinator.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 11/03/2023.
//

import UIKit

class SelectLocationCoordinator: Coordinator {

    let controller = ViewController()

    override var rootViewController: UIViewController {
        return controller
    }

    override func start() {
        controller.title = "Select location"
    }

}
