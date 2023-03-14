//
//  Coordinator.swift
//  MullvadVPN
//
//  Created by pronebird on 27/01/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/**
 Base coordinator class.

 Coordinators help to abstract the navigation and business logic from view controllers making them
 more manageable and reusable.

 Coordinators can be presented and adapted to changes in environment using presentation rules.
 Presentation rule, once satisfied, provides presentation handler that defines a high level
 description of desired UI composition. Based on that coordinators instantiate concrete presenters
 driving the visual presentation of the underlying view and view controller hierarchy.

 Each presentation is reversible making coordinators capable of rebuilding the UI composition in
 response to changes in environment.
 */
class Coordinator: NSObject {
    /// Weak reference to parent coordinator.
    private weak var _parent: Coordinator?

    /// Mutable collection of child coordinators.
    private var _children: [Coordinator] = []

    /// Current presenter object.
    private var _presenter: PresenterProtocol?

    /// Presentation rules.
    private var presentationRules = [PresentationRule]()

    /// Segue rules.
    private var segueRules = [SegueRule]()

    /// Flag indicating whether coordinator is reassembing view hierarchy.
    private var isReassemblingChildren = false

    /// Children added during reassembly.
    private var addedChildren: [Coordinator] = []

    /// Child coordinators.
    var childCoordinators: [Coordinator] {
        return _children
    }

    /// Parent coordinator.
    var parent: Coordinator? {
        return _parent
    }

    /// Current presenter object.
    var presenter: PresenterProtocol? {
        return _presenter
    }

    /**
     Root view controller that represents the top-most view controller that this coordinator
     manages.

     Subclasses must override this method and return their root controller.

     The result of this call is cached until the next time coordinator decides to rebuild its
     children, therefore it's possible to return a different view controller based on traits.
     */
    var rootViewController: UIViewController {
        fatalError("Implement in subclasses.")
    }

    /**
     Cached instance of view controller returned from call to `rootViewController`.
     */
    private var __cachedRootViewController: UIViewController?

    /**
     Returns a cached instance of view controller produced by `rootViewController`.
     */
    var _cachedRootViewController: UIViewController {
        if let root = __cachedRootViewController {
            return root
        } else {
            _updateCachedRootViewController()
            return __cachedRootViewController!
        }
    }

    /**
     Updates cached root view controller from `rootViewController`.
     */
    private func _updateCachedRootViewController() {
        __cachedRootViewController = rootViewController
    }

    // MARK: - Children

    /**
     Returns first child coordinator matching the given type.
     */
    func firstChild<T: Coordinator>(ofType: T.Type) -> T? {
        return _children.compactMapFirst { $0 as? T }
    }

    /**
     Returns `true` when child coordinator can be located among children.
     */
    func containsChild<T: Coordinator>(ofType: T.Type) -> Bool {
        return _children.contains { $0 is T }
    }

    /**
     Add child coordinator.

     Adding the same coordinator twice is a no-op.
     */
    func addChild(_ child: Coordinator) {
        guard !_children.contains(child) else { return }

        _children.append(child)
        child._parent = self
        print("Add child \(child)")

        didAddChild(child)
    }

    /**
     Remove child coordinator.

     Removing coordinator that's no longer a child of this coordinator is a no-op.
     */
    func removeChild(_ child: Coordinator) {
        guard let index = _children.firstIndex(where: { $0 == child }) else { return }

        _children.remove(at: index)
        child._parent = nil
        print("Remove child \(child)")

        didRemoveChild(child)
    }

    /**
     Remove coordinator from its parent.
     */
    func removeFromParent() {
        _parent?.removeChild(self)
    }

    // MARK: - Reassembly

    /**
     Instruct coordinator to rebuild UI composition by performing the following steps:

     1. Dismiss all presented view controllers in reverse order without animation.
     2. Call `updateChildren` to give coordinator a chance to modify its children.
     3. Present all children, all newly added children will recieve a call to `start()`.

     This operation is asynchronous since modal presenters require caller to wait for completion
     when presenting or dismissing view controllers to avoid view hierarchy inconsistency, even when
     animations disabled.
     */
    final func reassembleChildren(
        for traitCollection: UITraitCollection,
        completion: @escaping () -> Void
    ) {
        print("Reassemble children for \(traitCollection.applicationLayout)")

        let currentRoot = _cachedRootViewController

        willReassembleChildren()

        disassembleChildren {
            self.updateChildren(for: traitCollection)

            // Support changing reparenting root view controller on top-most coordinator.
            self._updateCachedRootViewController()
            let newRoot = self._cachedRootViewController

            if let window = self.window, currentRoot != newRoot {
                print("Reparenting root view controller.")
                window.rootViewController = newRoot
            }

            self.assembleChildren(for: traitCollection) {
                print("Finished reassembly!")

                self.didReassembleChildren()

                completion()
            }
        }
    }

    /**
     Coordinators should override this method and reconfigure their children if they wish to react
     to trait collection changes.

     Note that only `addChild` and `removeChild` should be used to reconfigure the child hierarchy.
     Once done all new children will receive a call to `start()` and appropriate presenter will be
     instantiated to complete presentation without animations.
     */
    func updateChildren(for traitCollection: UITraitCollection) {
        // Implement in subclass
    }

    private func willReassembleChildren() {
        assert(!isReassemblingChildren)
        isReassemblingChildren = true
    }

    private func didReassembleChildren() {
        assert(isReassemblingChildren)
        isReassemblingChildren = false
        addedChildren.removeAll()
    }

    /**
     Walks children in reverse order and tells presenters to dismiss presented view controllers.
     */
    private func disassembleChildren(completion: @escaping () -> Void) {
        let walker = AsyncForeach(_children.reversed())

        walker.iterate(
            visitor: { coordinator, next in
                coordinator.disassembleChildren {
                    guard let presenterObject = coordinator._presenter else {
                        next()
                        return
                    }

                    presenterObject.hide(animated: false) {
                        coordinator._presenter = nil
                        next()
                    }
                }
            },
            completion: {
                completion()
            }
        )
    }

    /**
     Walks children and creates new presenters, then presents view controllers.
     New children added during `updateChildren` call receive a call to `start()` too.
     */
    private func assembleChildren(
        for traitCollection: UITraitCollection,
        completion: @escaping () -> Void
    ) {
        let walker = AsyncForeach(_children)

        walker.iterate(
            visitor: { coordinator, next in
                assert(coordinator._presenter == nil)

                let presenter = self.makePresenter(
                    for: coordinator,
                    traitCollection: traitCollection
                )
                coordinator._presenter = presenter

                if self.addedChildren.contains(coordinator) {
                    coordinator.start()
                }

                presenter.show(animated: false) {
                    coordinator.assembleChildren(for: traitCollection) {
                        next()
                    }
                }
            },
            completion: {
                completion()
            }
        )
    }

    private func didAddChild(_ child: Coordinator) {
        if isReassemblingChildren {
            addedChildren.append(child)
        }
        child._updateCachedRootViewController()
    }

    private func didRemoveChild(_ child: Coordinator) {
        if isReassemblingChildren, let index = addedChildren.firstIndex(of: child) {
            addedChildren.remove(at: index)
        }
    }

    // MARK: - Presentation

    /**
     Add child coordinator and present it using associated presenter.
     */
    func show(_ child: Coordinator, animated: Bool, completion: (() -> Void)? = nil) {
        assert(!isReassemblingChildren)

        addChild(child)

        let presenter = makePresenter(
            for: child,
            traitCollection: _cachedRootViewController.traitCollection
        )
        child._presenter = presenter
        child.start()

        presenter.show(animated: animated, completion: completion)
    }

    /**
     Remove coordinator from parent and dismiss it using associated presenter.
     */
    func hide(animated: Bool, completion: (() -> Void)? = nil) {
        assert(!isReassemblingChildren)

        removeFromParent()

        if let presenter = _presenter {
            presenter.hide(animated: animated) {
                self._presenter = nil
                completion?()
            }
        } else {
            completion?()
        }
    }

    /**
     Transition between coordinators.
     */
    func performSegue(
        from source: Coordinator?,
        to destination: Coordinator,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        assert(!isReassemblingChildren)

        guard let source = source else {
            show(destination, animated: animated, completion: completion)
            return
        }

        let traitCollection = _cachedRootViewController.traitCollection

        let segueRule = segueRules.first { rule in
            return rule.evaluate(from: source, to: destination, traitCollection: traitCollection)
        }

        let segueDescriptor = segueRule?.segueProvider.segueDescriptor(
            from: source,
            to: destination,
            context: self,
            traitCollection: traitCollection
        )

        if let segueDescriptor = segueDescriptor {
            segueDescriptor.makeSegue().perform(animated: animated) {
                completion?()
            }
            return
        }

        addChild(destination)

        let destinationPresenter = makePresenter(
            for: destination,
            traitCollection: _cachedRootViewController.traitCollection
        )
        destination._presenter = destinationPresenter

        let showDestination = { (_ completion: (() -> Void)?) in
            destination.start()
            destinationPresenter.show(animated: animated, completion: completion)
        }

        if let sourcePresenter = source._presenter {
            if destinationPresenter.isSharingNavigationContainer(with: sourcePresenter) {
                showDestination {
                    sourcePresenter.hide(animated: false, completion: completion)
                }
            } else {
                sourcePresenter.hide(animated: animated) {
                    showDestination(completion)
                }
            }
        } else {
            showDestination(completion)
        }

        source.removeFromParent()
    }

    /// Add presentation rule.
    func addPresentationRule(
        _ handler: PresentationHandlerProtocol,
        conditions: [PresentationCondition]
    ) {
        let rule = PresentationRule(presentationHandler: handler, conditions: conditions)

        presentationRules.append(rule)
    }

    /**
     Returns a concrete presenter object for the given child and environment.
     */
    private func makePresenter(
        for child: Coordinator,
        traitCollection: UITraitCollection
    ) -> PresenterProtocol {
        let presenting = _cachedRootViewController

        let matchingRule = presentationRules.first { rule in
            return rule.evaluate(for: child, traitCollection: traitCollection)
        }

        let presenter: PresenterProtocol

        if let presentationHandler = matchingRule?.presentationHandler {
            presenter = processPresentationHandler(
                presentationHandler,
                child: child,
                presenting: presenting,
                traitCollection: traitCollection
            )
        } else {
            presenter = ModalPresenter(
                presenting: presenting,
                presented: child._cachedRootViewController
            )
        }

        /**
         Some presenters support interactive dismissal. For instance certain modal controllers can
         be dismissed with a swipe gesture.

         Set closure to automatically remove coordinator from parent when it's dismissed by UIKit
         and not via a `hide()` call to presenter.
         */
        if presenter.supportsInteractiveDismissal {
            presenter.notifyInteractiveDismissal { [weak child] in
                child?.removeFromParent()
                child?._presenter = nil
            }
        }

        return presenter
    }

    /**
     Requests presentation description from handler, then turnns it into concrete presenter object.
     */
    private func processPresentationHandler(
        _ presentationHandler: PresentationHandlerProtocol,
        child: Coordinator,
        presenting: UIViewController,
        traitCollection: UITraitCollection
    ) -> PresenterProtocol {
        let presented = child._cachedRootViewController

        let presentationDescriptor = presentationHandler.presentationDescriptor(
            for: child,
            presenting: presenting,
            presented: presented,
            traitCollection: traitCollection
        )

        return makePresenter(
            from: presentationDescriptor,
            child: child,
            presenting: presenting,
            presented: presented
        )
    }

    /**
     Instantiates a concrete presenter object based on presentation descriptor.
     */
    private func makePresenter(
        from presentationDescriptor: PresentationDescriptor,
        child: Coordinator,
        presenting: UIViewController,
        presented: UIViewController
    ) -> PresenterProtocol {
        switch presentationDescriptor {
        case let .push(container):
            return PushPresenter(
                presenting: container.makeNavigator(),
                presented: presented
            )

        case let .reparent(newParent):
            return ReparentPresenter(
                presenting: newParent.makeNavigator(),
                child: child
            )

        case let .modal(configuration):
            return ModalPresenter(
                presenting: presenting,
                presented: presented,
                configuration: configuration
            )

        case let .splitView(splitViewManager, column):
            return SplitViewPresenter(
                presenting: splitViewManager,
                presented: presented,
                column: column
            )

        case let .group(children):
            var nextPresented = presented

            let presenters = children.map { presentationDescriptor in
                let presenterObject = makePresenter(
                    from: presentationDescriptor,
                    child: child,
                    presenting: presenting,
                    presented: nextPresented
                )

                if case let .reparent(wrapper) = presentationDescriptor {
                    nextPresented = wrapper
                }

                return presenterObject
            }

            return GroupPresenter(presenters: presenters)
        }
    }

    // MARK: - Segues

    func addSegueProvider(
        _ handler: SegueProviderProtocol,
        conditions: [SegueCondition]
    ) {
        segueRules.append(SegueRule(segueProvider: handler, conditions: conditions))
    }

    // MARK: -

    /**
     Returns `UIWindow` object this coordinator is attached to.
     */
    private(set) var window: UIWindow?

    /**
     Assigns root view controller on window and start coordinator.

     Normally this should only be used once during application startup.
     */
    func mount(into window: UIWindow) {
        self.window = window
        window.rootViewController = _cachedRootViewController
        start()
    }

    /**
     This method defines the starting point for coordinator.

     Subclasses should override this method to perform all necessary initialization before
     coordinator is presented.

     It's called exactly once and you should not call this method directly.
     */
    func start() {}
}

/**
 Enum type describing types of conditions available in presentation rules.
 */
enum PresentationCondition {
    case presentedCoordinator(Any.Type)
    case traitCollection(UITraitCollection)

    func evaluate(for child: Coordinator, traitCollection: UITraitCollection) -> Bool {
        switch self {
        case let .presentedCoordinator(type):
            return Swift.type(of: child) == type

        case let .traitCollection(matchTraits):
            return traitCollection.containsTraits(in: matchTraits)
        }
    }
}

/**
 Presentation rule type used internally as a container type.
 */
private struct PresentationRule {
    var presentationHandler: PresentationHandlerProtocol
    var conditions: [PresentationCondition]

    func evaluate(for child: Coordinator, traitCollection: UITraitCollection) -> Bool {
        return conditions.allSatisfy { condition in
            return condition.evaluate(for: child, traitCollection: traitCollection)
        }
    }
}

/**
 Enum type describing types of conditions available in segue rules.
 */
enum SegueCondition {
    case sourceCoordinator(Any.Type)
    case targetCoordinator(Any.Type)
    case traitCollection(UITraitCollection)

    func evaluate(
        from source: Coordinator,
        to target: Coordinator,
        traitCollection: UITraitCollection
    ) -> Bool {
        switch self {
        case let .sourceCoordinator(type):
            return Swift.type(of: source) == type

        case let .targetCoordinator(type):
            return Swift.type(of: target) == type

        case let .traitCollection(matchTraits):
            return traitCollection.containsTraits(in: matchTraits)
        }
    }
}

private struct SegueRule {
    var segueProvider: SegueProviderProtocol
    var conditions: [SegueCondition]

    func evaluate(
        from source: Coordinator,
        to target: Coordinator,
        traitCollection: UITraitCollection
    ) -> Bool {
        return conditions.allSatisfy { condition in
            return condition.evaluate(from: source, to: target, traitCollection: traitCollection)
        }
    }
}
