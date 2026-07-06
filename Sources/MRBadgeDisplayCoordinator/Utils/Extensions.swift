//
//  Extensions.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 20/11/2025
//  Using Swift 6.2
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import UIKit

private final class BoxedAlignment {
    let value: BadgeVerticalAlignment
    init(_ value: BadgeVerticalAlignment) { self.value = value }
}

/// Custom anchors that override the default badge placement.
///
/// Provide either or both anchors: the missing one falls back to the default
/// placement (trailing edge of the container / `alignment` on the vertical axis).
/// The referenced views are held weakly so they don't leak the host cell/view.
public struct BadgeAnchors: @unchecked Sendable {
    public weak var horizontalAnchorView: UIView?
    public weak var verticalAnchorView: UIView?

    public init(horizontalAnchorView: UIView? = nil, verticalAnchorView: UIView? = nil) {
        self.horizontalAnchorView = horizontalAnchorView
        self.verticalAnchorView = verticalAnchorView
    }
}

extension UIView {
    private enum AssociatedKeys {
        @MainActor static var badgeOverlayView: UInt8 = 0
        @MainActor static var badgeOverlayAlignment: UInt8 = 0
        @MainActor static var badgeOverlayAnchors: UInt8 = 0
    }

    private var badgeOverlayLabel: BadgeOverlayLabel? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.badgeOverlayView) as? BadgeOverlayLabel }
        set { objc_setAssociatedObject(self, &AssociatedKeys.badgeOverlayView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var currentBadgeAlignment: BadgeVerticalAlignment? {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.badgeOverlayAlignment) as? BoxedAlignment)?.value }
        set {
            let boxed = newValue.map { BoxedAlignment($0) }
            objc_setAssociatedObject(self, &AssociatedKeys.badgeOverlayAlignment, boxed, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Custom anchors used to override the default badge placement on this view.
    ///
    /// Set before calling ``showBadgeOverlay(text:alignment:)`` (or before binding
    /// the view to the coordinator) to align the overlay to arbitrary views —
    /// e.g. the trailing edge of a segmented control and the vertical center of
    /// a title label. Assign `nil` to restore the default placement.
    public var badgeAnchors: BadgeAnchors? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.badgeOverlayAnchors) as? BadgeAnchors }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.badgeOverlayAnchors, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let label = badgeOverlayLabel {
                applyConstraints(to: label, alignment: currentBadgeAlignment ?? .center)
            }
        }
    }

    /// Shows (or updates) the badge overlay on this view.
    ///
    /// Call this directly only when you want to render a badge without going
    /// through ``MRBadgeDisplayCoordinator``. For shared, persisted state use
    /// the coordinator instead.
    public func showBadgeOverlay(text: String, alignment: BadgeVerticalAlignment = .center) {
        let label = ensureBadgeOverlay(alignment: alignment)
        label.text = text
        label.isHidden = false
    }

    /// Removes any badge overlay previously added by ``showBadgeOverlay(text:alignment:)``.
    public func removeBadgeOverlay() {
        badgeOverlayLabel?.removeFromSuperview()
        badgeOverlayLabel = nil
        currentBadgeAlignment = nil
    }

    private func ensureBadgeOverlay(alignment: BadgeVerticalAlignment) -> BadgeOverlayLabel {
        if let existingLabel = badgeOverlayLabel {
            if currentBadgeAlignment != alignment {
                applyConstraints(to: existingLabel, alignment: alignment)
            } else if badgeAnchors != nil {
                applyConstraints(to: existingLabel, alignment: alignment)
            }
            return existingLabel
        }

        let label = MRBadgeDisplayCoordinator.makeOverlayLabel()
        badgeOverlayLabel = label
        addSubview(label)
        applyConstraints(to: label, alignment: alignment)

        return label
    }

    private func applyConstraints(to label: BadgeOverlayLabel, alignment: BadgeVerticalAlignment) {
        currentBadgeAlignment = alignment

        // Drop the constraints we previously installed for this overlay so a
        // change of alignment/anchors doesn't stack contradictory constraints.
        NSLayoutConstraint.deactivate(label.constraints.filter { $0.firstItem === label })
        for constraint in constraints where constraint.firstItem === label || constraint.secondItem === label {
            constraint.isActive = false
        }

        let anchors = badgeAnchors
        let isInsideCell = self is UITableViewCell || superview is UITableViewCell

        var constraints: [NSLayoutConstraint] = [
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ]

        if let horizontalAnchorView = anchors?.horizontalAnchorView, horizontalAnchorView.isDescendant(of: self) {
            constraints.append(label.trailingAnchor.constraint(equalTo: horizontalAnchorView.trailingAnchor))
        } else if isInsideCell {
            constraints.append(label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor))
        } else {
            constraints.append(label.centerXAnchor.constraint(equalTo: trailingAnchor))
        }

        if let verticalAnchorView = anchors?.verticalAnchorView, verticalAnchorView.isDescendant(of: self) {
            constraints.append(label.centerYAnchor.constraint(equalTo: verticalAnchorView.centerYAnchor))
        } else {
            switch alignment {
                case .top: constraints.append(label.topAnchor.constraint(equalTo: topAnchor, constant: -9))
                case .center: constraints.append(label.centerYAnchor.constraint(equalTo: centerYAnchor))
                case .bottom: constraints.append(label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 9))
            }
        }

        NSLayoutConstraint.activate(constraints)
    }
}
