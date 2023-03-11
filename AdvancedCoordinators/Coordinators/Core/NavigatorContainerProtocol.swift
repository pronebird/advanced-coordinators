//
//  NavigatorContainerProtocol.swift
//  MullvadVPN
//
//  Created by pronebird on 19/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

protocol NavigatorContainerProtocol: UIViewController {
    func makeNavigator() -> NavigatorProtocol
}
