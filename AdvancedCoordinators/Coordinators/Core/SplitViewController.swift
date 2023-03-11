//
//  SplitViewController.swift
//  MullvadVPN
//
//  Created by pronebird on 25/02/2023.
//  Copyright © 2023 Mullvad VPN AB. All rights reserved.
//

import UIKit

/// Enum describing split view display mode.
enum SplitViewDisplayMode {
    /// Both columns are visible.
    case both

    /// Only secondary column is visible.
    case secondaryOnly
}

/// Enum describing which edge should be used to place the primary column.
enum SplitViewPrimaryEdge {
    case leading
    case trailing
}

/// Enum describing columns supported by split view.
enum SplitViewColumn: Equatable {
    case primary
    case secondary

    fileprivate var index: Int {
        switch self {
        case .primary:
            return 0
        case .secondary:
            return 1
        }
    }
}

/**
 Split view controller container that implements one and two column layout.

 Unlike classic `UISplitViewController`, this controller permits reconfiguring columns once split
 view controller is on screen.
 */
final class SplitViewController: UIViewController {
    /// Current display mode.
    var displayMode: SplitViewDisplayMode {
        return splitView.displayMode
    }

    /// Preferred display mode.
    var preferredDisplayMode: SplitViewDisplayMode = .both {
        didSet {
            updateDisplayMode()
        }
    }

    /// The side on which the primary column is placed.
    var primaryEdge: SplitViewPrimaryEdge {
        get {
            return splitView.primaryEdge
        }
        set {
            splitView.primaryEdge = newValue
        }
    }

    /// The relative width of the primary column.
    var preferredPrimaryColumnWidthFraction: CGFloat {
        get {
            return splitView.preferredPrimaryColumnWidthFraction
        }
        set {
            splitView.preferredPrimaryColumnWidthFraction = newValue
        }
    }

    /// The minimum width, in points, for the primary column.
    var minimumPrimaryColumnWidth: CGFloat {
        get {
            return splitView.minimumPrimaryColumnWidth
        }
        set {
            splitView.minimumPrimaryColumnWidth = newValue
        }
    }

    /// The width of split view divider.
    var dividerWidth: CGFloat {
        get {
            return splitView.dividerWidth
        }
        set {
            splitView.dividerWidth = newValue
        }
    }

    /// The fill color of split view divider.
    var dividerColor: UIColor {
        get {
            return splitView.dividerColor
        }
        set {
            splitView.dividerColor = newValue
        }
    }

    // MARK: - View lifecycle

    override var childForStatusBarStyle: UIViewController? {
        return visibleViewControllers.compactMap { $0 }.first
    }

    override var childForStatusBarHidden: UIViewController? {
        return visibleViewControllers.compactMap { $0 }.first
    }

    override func loadView() {
        view = SplitView(frame: CGRect(x: 0, y: 0, width: 640, height: 480))
    }

    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        visibleViewControllers.forEach { vc in
            vc.beginAppearanceTransition(true, animated: animated)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visibleViewControllers.forEach { vc in
            vc.endAppearanceTransition()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        visibleViewControllers.forEach { vc in
            vc.beginAppearanceTransition(false, animated: animated)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        visibleViewControllers.forEach { vc in
            vc.endAppearanceTransition()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateDisplayMode()
        }
    }

    // MARK: - Public

    /**
     Set child view controller for the given side.

     The child will be presented immediately if split view controller is visible, otherwise it will
     be stored internally and presented at later point once split view appears on screen.

     If current display mode prevents child from being presented immediately, it will be
     stored internally and presented at later point once display mode allows for that.
     */
    func setViewController(_ vc: UIViewController?, for column: SplitViewColumn) {
        if let vc = viewControllers[column.index] {
            removeChildController(vc)
        }

        viewControllers[column.index] = vc

        if let vc = vc, isVisibleColumn(column) {
            addChildController(vc, column: column)
        }
    }

    /// Returns view controller assigned to the given column regardless of its visibility.
    func viewController(for column: SplitViewColumn) -> UIViewController? {
        return viewControllers[column.index]
    }

    /// Returns `true` if given column is currently visible, otherwise `false`.
    func isVisibleColumn(_ column: SplitViewColumn) -> Bool {
        switch splitView.displayMode {
        case .both:
            return true
        case .secondaryOnly:
            return column == .secondary
        }
    }

    // MARK: - Private

    private var viewControllers: [UIViewController?] = [nil, nil]

    fileprivate var visibleViewControllers: [UIViewController] {
        switch splitView.displayMode {
        case .secondaryOnly:
            return [viewController(for: .secondary)].compactMap { $0 }

        case .both:
            return viewControllers.compactMap { $0 }
        }
    }

    private var splitView: SplitView {
        return view as! SplitView
    }

    private func removeChildController(_ vc: UIViewController) {
        guard children.contains(vc) else { return }

        let shouldHandleAppearanceEvents = view.window != nil

        vc.willMove(toParent: nil)

        if shouldHandleAppearanceEvents {
            vc.beginAppearanceTransition(false, animated: false)
        }

        vc.view.removeFromSuperview()

        if shouldHandleAppearanceEvents {
            vc.endAppearanceTransition()
        }

        vc.removeFromParent()
    }

    private func addChildController(
        _ vc: UIViewController,
        column: SplitViewColumn,
        configureSplitView: (() -> Void)? = nil
    ) {
        let shouldHandleAppearanceEvents = view.window != nil

        addChild(vc)

        if shouldHandleAppearanceEvents {
            vc.beginAppearanceTransition(true, animated: false)
        }

        splitView.addChild(vc.view, into: column)

        configureSplitView?()

        if shouldHandleAppearanceEvents {
            vc.endAppearanceTransition()
        }

        vc.didMove(toParent: self)
    }

    private func updateDisplayMode() {
        let oldDisplayMode = splitView.displayMode
        let newDisplayMode = suitableDisplayMode(with: preferredDisplayMode)

        guard oldDisplayMode != newDisplayMode else { return }

        if let vc = viewController(for: .primary) {
            switch (oldDisplayMode, newDisplayMode) {
            case (.both, .secondaryOnly):
                removeChildController(vc)
                splitView.displayMode = newDisplayMode

            case (.secondaryOnly, .both):
                addChildController(vc, column: .primary) {
                    self.splitView.displayMode = newDisplayMode
                }

            default:
                break
            }
        } else {
            splitView.displayMode = newDisplayMode
        }
    }

    /**
     Returns suitable display mode for current environment.

     Normally preferred display mode is respected except when in horizontally compact environment,
     since usually there isn't much space to accommodate for both columns.
     */
    private func suitableDisplayMode(with preferredDisplayMode: SplitViewDisplayMode)
        -> SplitViewDisplayMode
    {
        let horizontalSizeClass = traitCollection.horizontalSizeClass

        if horizontalSizeClass == .compact {
            return .secondaryOnly
        } else {
            return preferredDisplayMode
        }
    }
}

private class SplitView: UIView {
    private let primaryColumn = UIView()
    private let secondaryColumn = UIView()
    private let dividerView = UIView()

    var dividerWidth: CGFloat = 1 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    var dividerColor: UIColor = .black {
        didSet {
            updateDividerColor()
        }
    }

    var primaryEdge: SplitViewPrimaryEdge = .leading {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    var preferredPrimaryColumnWidthFraction: CGFloat = 0.3 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    var minimumPrimaryColumnWidth: CGFloat = 300 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    var displayMode: SplitViewDisplayMode = .both {
        didSet {
            if oldValue != displayMode {
                updateVisibleColumns()
            }
        }
    }

    private var installedConstraints = [NSLayoutConstraint]()

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupAutolayoutProperties()
        updateDividerColor()
        updateVisibleColumns()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        let oldConstraints = installedConstraints
        let newConstraints = createConstraints()

        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(newConstraints)

        installedConstraints = newConstraints

        super.updateConstraints()
    }

    func addChild(_ child: UIView, into side: SplitViewColumn) {
        let column = columnView(for: side)

        embedChild(child, intoColumn: column)
    }

    private func createConstraints() -> [NSLayoutConstraint] {
        switch displayMode {
        case .both:
            return createTwoColumnLayoutConstraints()

        case .secondaryOnly:
            return createSecondaryOnlyLayoutConstraints()
        }
    }

    private func createTwoColumnLayoutConstraints() -> [NSLayoutConstraint] {
        var constraints = [
            primaryColumn.widthAnchor
                .constraint(
                    equalTo: widthAnchor,
                    multiplier: preferredPrimaryColumnWidthFraction
                )
                .withPriority(.defaultHigh),

            primaryColumn.widthAnchor
                .constraint(greaterThanOrEqualToConstant: minimumPrimaryColumnWidth)
                .withPriority(.defaultHigh + 1),

            primaryColumn.topAnchor.constraint(equalTo: topAnchor),
            primaryColumn.bottomAnchor.constraint(equalTo: bottomAnchor),
            secondaryColumn.topAnchor.constraint(equalTo: topAnchor),
            secondaryColumn.bottomAnchor.constraint(equalTo: bottomAnchor),

            dividerView.topAnchor.constraint(equalTo: topAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: dividerWidth),
        ]

        switch primaryEdge {
        case .leading:
            constraints.append(contentsOf: [
                primaryColumn.leadingAnchor.constraint(equalTo: leadingAnchor),
                primaryColumn.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor),
                secondaryColumn.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
                secondaryColumn.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])

        case .trailing:
            constraints.append(contentsOf: [
                primaryColumn.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
                primaryColumn.trailingAnchor.constraint(equalTo: trailingAnchor),
                secondaryColumn.leadingAnchor.constraint(equalTo: leadingAnchor),
                secondaryColumn.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor),
            ])
        }

        return constraints
    }

    private func createSecondaryOnlyLayoutConstraints() -> [NSLayoutConstraint] {
        return [
            secondaryColumn.topAnchor.constraint(equalTo: topAnchor),
            secondaryColumn.bottomAnchor.constraint(equalTo: bottomAnchor),
            secondaryColumn.leadingAnchor.constraint(equalTo: leadingAnchor),
            secondaryColumn.trailingAnchor.constraint(equalTo: trailingAnchor),
        ]
    }

    private func columnView(for side: SplitViewColumn) -> UIView {
        switch side {
        case .primary:
            return primaryColumn
        case .secondary:
            return secondaryColumn
        }
    }

    private func updateVisibleColumns() {
        switch displayMode {
        case .both:
            addSubview(primaryColumn)
            addSubview(secondaryColumn)
            addSubview(dividerView)

        case .secondaryOnly:
            addSubview(secondaryColumn)
            primaryColumn.removeFromSuperview()
            dividerView.removeFromSuperview()
        }
        setNeedsUpdateConstraints()
    }

    private func updateDividerColor() {
        dividerView.backgroundColor = dividerColor
    }

    private func embedChild(_ child: UIView, intoColumn column: UIView) {
        child.translatesAutoresizingMaskIntoConstraints = false

        column.addSubview(child)

        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: column.topAnchor),
            child.leadingAnchor.constraint(equalTo: column.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: column.trailingAnchor),
            child.bottomAnchor.constraint(equalTo: column.bottomAnchor),
        ])
    }

    private func setupAutolayoutProperties() {
        primaryColumn.translatesAutoresizingMaskIntoConstraints = false
        secondaryColumn.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false

        primaryColumn.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        primaryColumn.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        secondaryColumn.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        secondaryColumn.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)

        dividerView.setContentHuggingPriority(.required, for: .horizontal)
        dividerView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}
