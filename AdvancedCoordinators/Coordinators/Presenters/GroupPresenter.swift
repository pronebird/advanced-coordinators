//
//  GroupPresenter.swift
//  MullvadVPN
//
//  Created by pronebird on 21/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/**
 Group presenter that executes presenters in succession.
 */
final class GroupPresenter: PresenterProtocol, NavigationPresenterProtocol {
    let presenters: [PresenterProtocol]

    init(presenters: [PresenterProtocol]) {
        self.presenters = presenters
    }

    func show(animated: Bool, completion: (() -> Void)?) {
        let walker = AsyncForeach(presenters)

        walker.iterate(
            visitor: { presenter, next in
                presenter.show(animated: animated, completion: next)
            },
            completion: {
                completion?()
            }
        )
    }

    func hide(animated: Bool, completion: (() -> Void)?) {
        let walker = AsyncForeach(presenters.reversed())

        walker.iterate(
            visitor: { presenter, next in
                presenter.hide(animated: animated, completion: next)
            },
            completion: {
                completion?()
            }
        )
    }

    var navigatorContainer: UIViewController? {
        return presenters.compactMapFirst { presenter in
            return (presenter as? NavigationPresenterProtocol)?.navigatorContainer
        }
    }

    var supportsInteractiveDismissal: Bool {
        return presenters.contains { $0.supportsInteractiveDismissal }
    }

    func notifyInteractiveDismissal(_ handler: @escaping () -> Void) {
        let presenter = presenters.first { $0.supportsInteractiveDismissal }

        presenter?.notifyInteractiveDismissal(handler)
    }
}
