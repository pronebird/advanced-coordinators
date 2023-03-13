//
//  BlockPresentationHandler.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 11/03/2023.
//

import UIKit

final class BlockPresentationHandler: PresentationHandlerProtocol {
    typealias Block = (
        _ child: Coordinator,
        _ presenting: UIViewController,
        _ presented: UIViewController,
        _ traitCollection: UITraitCollection
    ) -> PresentationDescriptor

    let block: Block

    init(_ block: @escaping Block) {
        self.block = block
    }

    func presentationDescriptor(
        for child: Coordinator,
        presenting: UIViewController,
        presented: UIViewController,
        traitCollection: UITraitCollection
    ) -> PresentationDescriptor {
        return block(child, presenting, presented, traitCollection)
    }
}
