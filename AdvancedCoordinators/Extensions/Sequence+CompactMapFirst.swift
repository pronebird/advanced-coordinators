//
//  Sequence+CompactMapFirst.swift
//  MullvadTypes
//
//  Created by pronebird on 01/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import Foundation

extension Sequence {
    public func compactMapFirst<R>(_ transform: (Element) throws -> R?) rethrows -> R? {
        for element in self {
            if let mapped = try transform(element) {
                return mapped
            }
        }
        return nil
    }
}
