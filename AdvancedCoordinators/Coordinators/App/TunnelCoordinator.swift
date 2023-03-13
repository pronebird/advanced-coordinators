//
//  TunnelCoordinator.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 11/03/2023.
//

import UIKit

class TunnelCoordinator: Coordinator {
    let controller = TunnelController()

    var onShowSelectLocation: ((TunnelCoordinator) -> Void)?

    override var rootViewController: UIViewController {
        return controller
    }

    override func start() {
        controller.title = "Tunnel coordinator"

        controller.buttonAction = { [weak self] in
            guard let self = self else { return }

            self.onShowSelectLocation?(self)
        }
    }
}

class TunnelController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        updateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.applicationLayout != previousTraitCollection?.applicationLayout else {
            return
        }

        updateLayout()
    }

    private func updateLayout() {
        switch traitCollection.applicationLayout {
        case .horizontalNavigation:
            buttonTitle = "Select location"

        case .splitView:
            buttonTitle = nil
        }
    }
}
