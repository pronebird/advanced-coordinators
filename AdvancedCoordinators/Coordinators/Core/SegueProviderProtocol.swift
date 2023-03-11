//
//  SegueProviderProtocol.swift
//  MullvadVPN
//
//  Created by pronebird on 07/03/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/**
 Protocol describing objects responsible for providing the instructions for transitioning between
 coordinators.
 */
protocol SegueProviderProtocol {
    func segueDescriptor(
        from source: Coordinator,
        to target: Coordinator,
        context: Coordinator,
        traitCollection: UITraitCollection
    ) -> SegueDescriptor
}

/**
 Protocol describing objects that implement transition between two coordinators.
 */
protocol SegueProtocol {
    func perform(animated: Bool, completion: @escaping () -> Void)
}

/**
 Type providing abstraction for creating common segues.
 */
indirect enum SegueDescriptor {
    case show(presenting: Coordinator, presented: Coordinator)
    case hide(Coordinator)
    case sequence([SegueDescriptor])
    case parallel([SegueDescriptor])
    case ignoreAnimations(SegueDescriptor)

    func makeSegue() -> SegueProtocol {
        switch self {
        case let .show(presenting, presented):
            return ShowSegue(presenting: presenting, presented: presented)

        case let .hide(coordinator):
            return HideSegue(coordinator: coordinator)

        case let .sequence(subActions):
            return SequenceSegue(children: subActions.map { $0.makeSegue() })

        case let .parallel(subActions):
            return ParallelSegue(children: subActions.map { $0.makeSegue() })

        case let .ignoreAnimations(subAction):
            return IgnoreAnimationsSegue(subAction.makeSegue())
        }
    }
}

private struct IgnoreAnimationsSegue: SegueProtocol {
    let wrapped: SegueProtocol

    init(_ wrapped: SegueProtocol) {
        self.wrapped = wrapped
    }

    func perform(animated: Bool, completion: @escaping () -> Void) {
        wrapped.perform(animated: false, completion: completion)
    }
}

private struct HideSegue: SegueProtocol {
    let coordinator: Coordinator

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    func perform(animated: Bool, completion: @escaping () -> Void) {
        coordinator.hide(animated: animated, completion: completion)
    }
}

private struct ShowSegue: SegueProtocol {
    let presenting: Coordinator
    let presented: Coordinator

    init(presenting: Coordinator, presented: Coordinator) {
        self.presenting = presenting
        self.presented = presented
    }

    func perform(animated: Bool, completion: @escaping () -> Void) {
        presenting.show(presented, animated: animated, completion: completion)
    }
}

private struct SequenceSegue: SegueProtocol {
    let children: [SegueProtocol]

    init(children: [SegueProtocol]) {
        self.children = children
    }

    func perform(animated: Bool, completion: @escaping () -> Void) {
        let iterator = AsyncForeach(children)

        iterator.iterate { current, next in
            current.perform(animated: animated, completion: next)
        } completion: {
            completion()
        }
    }
}

private struct ParallelSegue: SegueProtocol {
    let children: [SegueProtocol]

    init(children: [SegueProtocol]) {
        self.children = children
    }

    func perform(animated: Bool, completion: @escaping () -> Void) {
        guard !children.isEmpty else {
            completion()
            return
        }

        var completedCount = 0

        for child in children {
            child.perform(animated: animated) {
                dispatchPrecondition(condition: .onQueue(.main))

                completedCount += 1

                if children.count == completedCount {
                    completion()
                }
            }
        }
    }
}
