//
//  Convenience.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 15/06/2026
//  Using Swift 6.2
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import UIKit

private enum ForwarderKeys {
    nonisolated(unsafe) static var forwarder: UInt8 = 0
}

private extension NSObject {
    var badgeTapForwarder: BadgeTapForwarder? {
        get { objc_getAssociatedObject(self, &ForwarderKeys.forwarder) as? BadgeTapForwarder }
        set { objc_setAssociatedObject(self, &ForwarderKeys.forwarder, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - UIControl (UIButton, UISegmentedControl, …)

extension UIControl {
    /// Schedules a badge, shows it on this control and—by default—removes it the
    /// first time the control is triggered. Your own `addTarget`/`UIAction`
    /// handlers keep working untouched.
    ///
    /// - Parameters:
    ///   - text: Text rendered inside the badge.
    ///   - id: Identifier shared with ``MRBadgeDisplayCoordinator``. Reuse it to
    ///     keep the same badge in sync across multiple views.
    ///   - alignment: Vertical placement of the overlay. Defaults to `.center`.
    ///   - clearsOnTap: When `true` (default) the badge disappears on first
    ///     interaction and, if persistence is configured, stays gone across launches.
    public func setBadge(_ text: String, id: String, alignment: BadgeVerticalAlignment = .center, clearsOnTap: Bool = true) {
        MRBadgeDisplayCoordinator.shared.schedule(text, for: id, alignment: alignment)
        MRBadgeDisplayCoordinator.shared.bind(self, to: id)

        guard clearsOnTap else { return }

        if let existing = badgeTapForwarder {
            removeTarget(existing, action: #selector(BadgeTapForwarder.handleControl(_:)), for: .primaryActionTriggered)
        }

        let forwarder = BadgeTapForwarder(identifier: id, removePersistence: false)
        badgeTapForwarder = forwarder
        addTarget(forwarder, action: #selector(BadgeTapForwarder.handleControl(_:)), for: .primaryActionTriggered)
    }
}

// MARK: - UIBarButtonItem

extension UIBarButtonItem {
    /// Schedules a badge, shows it on this bar button item and—by default—removes
    /// it the first time the item is tapped, forwarding the tap to your handler.
    ///
    /// - Important: When `clearsOnTap` is `true` this takes over the item's
    ///   `target`/`action`, so configure your handler **before** calling this.
    ///   Items built with a `primaryAction` (`UIAction`) are not intercepted; in
    ///   that case clear the badge yourself from the action, or keep
    ///   `clearsOnTap: false`.
    public func setBadge(_ text: String, id: String, clearsOnTap: Bool = true) {
        MRBadgeDisplayCoordinator.shared.schedule(text, for: id)
        MRBadgeDisplayCoordinator.shared.bind(self, to: id)

        guard clearsOnTap, primaryAction == nil else { return }

        let forwarder = BadgeTapForwarder(identifier: id, removePersistence: false, forwardingTo: target, action: action)
        badgeTapForwarder = forwarder
        target = forwarder
        action = #selector(BadgeTapForwarder.handleBarButtonItem(_:))
    }
}

// MARK: - UIView (table view cells, image views, …)

extension UIView {
    /// Reflects the coordinator's current badge for `id` on this view, without
    /// scheduling anything. Call it while configuring reusable views (e.g. inside
    /// `tableView(_:cellForRowAt:)`); the view shows the badge when one exists for
    /// `id` and is cleared otherwise.
    public func bindBadge(to id: String) {
        MRBadgeDisplayCoordinator.shared.bind(self, to: id)
    }
}
