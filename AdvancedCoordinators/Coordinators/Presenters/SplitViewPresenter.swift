//
//  SplitViewPresenter.swift
//  MullvadVPN
//
//  Created by pronebird on 23/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/// Presenter implementing split view controller manipulations.
final class SplitViewPresenter: PresenterProtocol {
    let presenting: SplitViewContainerProtocol
    let presented: UIViewController
    let column: SplitViewColumn

    init(
        presenting: SplitViewContainerProtocol,
        presented: UIViewController,
        column: SplitViewColumn
    ) {
        self.presenting = presenting
        self.presented = presented
        self.column = column
    }

    func show(animated: Bool, completion: (() -> Void)?) {
        presenting.setViewController(presented, for: column)
        completion?()
    }

    func hide(animated: Bool, completion: (() -> Void)?) {
        presenting.setViewController(nil, for: column)
        completion?()
    }
}

extension SplitViewColumn {
    var svcColumn: UISplitViewController.Column {
        switch self {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        }
    }
}
