//
//  BadgeTapForwarder.swift
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

/// Clears a badge the first time the control it is attached to is triggered,
/// then forwards the original action so the host's own handler still runs.
///
/// One forwarder is retained per control/bar button item through an associated
/// object, so the auto-clear behaviour survives without the caller keeping a
/// reference.
@MainActor
final class BadgeTapForwarder: NSObject {
    private let identifier: String
    private let removePersistence: Bool

    // Preserved so we can forward taps coming from a `UIBarButtonItem`, whose
    // single target/action slot we have to take over to observe the tap.
    private weak var originalTarget: AnyObject?
    private let originalAction: Selector?

    init(identifier: String, removePersistence: Bool, forwardingTo originalTarget: AnyObject? = nil, action originalAction: Selector? = nil) {
        self.identifier = identifier
        self.removePersistence = removePersistence
        self.originalTarget = originalTarget
        self.originalAction = originalAction
    }

    @objc func handleControl(_ sender: UIControl) {
        MRBadgeDisplayCoordinator.shared.clearBadge(for: identifier, shouldRemovePersistence: removePersistence)
    }

    @objc func handleBarButtonItem(_ sender: UIBarButtonItem) {
        MRBadgeDisplayCoordinator.shared.clearBadge(for: identifier, shouldRemovePersistence: removePersistence)

        guard let action = originalAction else { return }
        UIApplication.shared.sendAction(action, to: originalTarget, from: sender, for: nil)
    }
}
