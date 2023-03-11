//
//  AsyncForeach.swift
//  MullvadVPN
//
//  Created by pronebird on 21/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import Foundation

struct AsyncForeach<Element> {
    typealias Visitor = (_ current: Element, _ next: @escaping () -> Void) -> Void

    private let makeIterator: () -> AnyIterator<Element>

    init<S: Sequence>(_ sequence: S) where S.Element == Element {
        makeIterator = {
            return AnyIterator(sequence.makeIterator())
        }
    }

    func iterate(visitor: @escaping Visitor, completion: @escaping () -> Void) {
        Self.iterate(iterator: makeIterator(), visitor: visitor, completion: completion)
    }

    private static func iterate<T: IteratorProtocol>(
        iterator: T,
        visitor: @escaping Visitor,
        completion: @escaping () -> Void
    ) where T.Element == Element {
        var mutableIterator = iterator

        guard let current = mutableIterator.next() else {
            completion()
            return
        }

        visitor(current) {
            Self.iterate(iterator: mutableIterator, visitor: visitor, completion: completion)
        }
    }
}
