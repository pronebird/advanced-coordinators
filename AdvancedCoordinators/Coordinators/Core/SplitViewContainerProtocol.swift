//
//  SplitViewContainerProtocol.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 11/03/2023.
//

import UIKit

protocol SplitViewContainerProtocol: UIViewController {
    func setViewController(_ vc: UIViewController?, for side: SplitViewColumn)
}

extension UISplitViewController: SplitViewContainerProtocol {
    func setViewController(_ vc: UIViewController?, for side: SplitViewColumn) {
        setViewController(vc, for: side.svcColumn)
    }
}

extension SplitViewController: SplitViewContainerProtocol {}
