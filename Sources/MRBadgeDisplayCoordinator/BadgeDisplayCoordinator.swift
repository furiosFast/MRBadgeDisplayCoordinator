//
//  BadgeDisplayCoordinator.swift
//  BadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for BadgeDisplayCoordinator in 21/11/2025
//  Using Swift 5.10
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import ObjectiveC
import UIKit

@MainActor
final class MRBadgeDisplayCoordinator {
    static let shared = MRBadgeDisplayCoordinator()

    private var states: [String: BadgeState] = [:]
    private var viewAttachments: [String: NSHashTable<UIView>] = [:]
    private var barButtonAttachments: [String: NSHashTable<UIBarButtonItem>] = [:]

    private init() {}

    func scheduleBadge(for identifier: String, payload: BadgePayload) {
        states[identifier] = BadgeState(payload: payload, status: .pending)
        refreshAttachments(for: identifier)
    }

    func hasBadgeScheduled(for identifier: String) -> Bool {
        states[identifier] != nil
    }

    func attachBadgeIfNeeded(to view: UIView, identifier: String) {
        register(view: view, for: identifier)

        guard let state = states[identifier] else {
            applyClearBadge(to: view)
            return
        }

        applyBadge(to: view, payload: state.payload)
        states[identifier]?.status = .displayed
    }

    func attachBadgeIfNeeded(to barButtonItem: UIBarButtonItem, identifier: String) {
        register(barButtonItem: barButtonItem, for: identifier)

        guard let state = states[identifier] else {
            applyClearBadge(to: barButtonItem)
            return
        }

        applyBadge(to: barButtonItem, payload: state.payload)
        states[identifier]?.status = .displayed
    }

    func clearBadge(for identifier: String) {
        states.removeValue(forKey: identifier)
        clearAttachments(for: identifier)
    }

    func clearAll() {
        states.removeAll()
        let identifiers = Set(viewAttachments.keys).union(barButtonAttachments.keys)
        identifiers.forEach(clearAttachments(for:))
    }

    func register(view: UIView, for identifier: String) {
        let table = viewAttachments[identifier] ?? NSHashTable<UIView>.weakObjects()
        if !table.contains(view) {
            table.add(view)
            viewAttachments[identifier] = table
        }
    }

    func register(barButtonItem: UIBarButtonItem, for identifier: String) {
        let table = barButtonAttachments[identifier] ?? NSHashTable<UIBarButtonItem>.weakObjects()
        if !table.contains(barButtonItem) {
            table.add(barButtonItem)
            barButtonAttachments[identifier] = table
        }
    }

    func refreshAttachments(for identifier: String) {
        guard let state = states[identifier] else {
            clearAttachments(for: identifier)
            return
        }

        viewAttachments[identifier]?.allObjects.forEach { applyBadge(to: $0, payload: state.payload) }
        barButtonAttachments[identifier]?.allObjects.forEach { applyBadge(to: $0, payload: state.payload) }
        states[identifier]?.status = .displayed
    }

    func clearAttachments(for identifier: String) {
        viewAttachments[identifier]?.allObjects.forEach(applyClearBadge(to:))
        viewAttachments[identifier] = nil

        barButtonAttachments[identifier]?.allObjects.forEach(applyClearBadge(to:))
        barButtonAttachments[identifier] = nil
    }

    func applyBadge(to view: UIView, payload: BadgePayload) {
        if let cell = view as? UITableViewCell {
            applyBadge(to: cell.contentView, payload: payload)
            return
        }

        view.showBadgeOverlay(text: payload.text)
    }

    func applyBadge(to barButtonItem: UIBarButtonItem, payload: BadgePayload) {
        if #available(iOS 26, *) {
            barButtonItem.badge = .string(payload.text)
        }
    }

    func applyClearBadge(to view: UIView) {
        if let cell = view as? UITableViewCell {
            applyClearBadge(to: cell.contentView)
            return
        }

        view.removeBadgeOverlay()
    }

    func applyClearBadge(to barButtonItem: UIBarButtonItem) {
        if #available(iOS 26, *) {
            barButtonItem.badge = nil
        }
    }
}
