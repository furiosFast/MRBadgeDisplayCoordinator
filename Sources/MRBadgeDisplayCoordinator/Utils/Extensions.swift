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

extension UIView {
    private enum AssociatedKeys {
        @MainActor static var badgeOverlayView: UInt8 = 0
        @MainActor static var badgeOverlayAlignment: UInt8 = 0
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
        // change of alignment doesn't stack contradictory constraints.
        NSLayoutConstraint.deactivate(label.constraints.filter { $0.firstItem === label })
        for constraint in constraints where constraint.firstItem === label || constraint.secondItem === label {
            constraint.isActive = false
        }

        let isInsideCell = self is UITableViewCell || superview is UITableViewCell

        var constraints: [NSLayoutConstraint] = [
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ]

        if isInsideCell {
            constraints.append(label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor))
        } else {
            constraints.append(label.centerXAnchor.constraint(equalTo: trailingAnchor))
        }

        switch alignment {
            case .top: constraints.append(label.topAnchor.constraint(equalTo: topAnchor, constant: -9))
            case .center: constraints.append(label.centerYAnchor.constraint(equalTo: centerYAnchor))
            case .bottom: constraints.append(label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 9))
        }

        NSLayoutConstraint.activate(constraints)
    }
}
