//
//  MRBadgeDisplayCoordinator.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 21/11/2025
//  Using Swift 5.10
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import UIKit

@MainActor
open class MRBadgeDisplayCoordinator {
    public static let shared = MRBadgeDisplayCoordinator()

    private var states: [String: BadgeState] = [:]
    private var viewAttachments: [String: NSHashTable<UIView>] = [:]
    private var barButtonAttachments: [String: NSHashTable<UIBarButtonItem>] = [:]
    private var persistenceConfiguration: PersistenceConfiguration?
    private var persistedRecords: [String: PersistedBadgeRecord] = [:]

    private init() {}

    open func configurePersistence(using userDefaults: UserDefaults = .standard, storageKey: String = "MRBadgeDisplayCoordinator.states") {
        persistenceConfiguration = PersistenceConfiguration(defaults: userDefaults, statesKey: storageKey)
        loadPersistedRecords()
        persistExistingStatesIfNeeded()
    }

    open func scheduleBadge(for identifier: String, payload: BadgePayload) {
        if let status = status(for: identifier), status == .removed {
            return
        }

        states[identifier] = BadgeState(payload: payload, status: .pending)
        updatePersistedRecord(for: identifier, text: payload.text, alignment: payload.alignment, status: .pending)
        refreshAttachments(for: identifier)
    }

    open func hasBadgeScheduled(for identifier: String) -> Bool {
        states[identifier] != nil
    }

    open func status(for identifier: String) -> BadgeStatus? {
        if let state = states[identifier] {
            return state.status
        }

        return persistedRecords[identifier]?.status
    }

    open func attachBadgeIfNeeded(to view: UIView, identifier: String) {
        register(view: view, for: identifier)

        guard let state = states[identifier], state.status != .removed else {
            applyClearBadge(to: view)
            return
        }

        applyBadge(to: view, payload: state.payload)
        states[identifier]?.status = .displayed
        updatePersistedRecord(for: identifier, text: state.payload.text, alignment: state.payload.alignment, status: .displayed)
    }

    open func attachBadgeIfNeeded(to barButtonItem: UIBarButtonItem, identifier: String) {
        register(barButtonItem: barButtonItem, for: identifier)

        guard let state = states[identifier], state.status != .removed else {
            applyClearBadge(to: barButtonItem)
            return
        }

        applyBadge(to: barButtonItem, payload: state.payload)
        states[identifier]?.status = .displayed
        updatePersistedRecord(for: identifier, text: state.payload.text, alignment: state.payload.alignment, status: .displayed)
    }

    open func clearBadge(for identifier: String, shouldRemovePersistance: Bool = false) {
        let existingState = states.removeValue(forKey: identifier)
        markBadgeAsRemoved(identifier: identifier, lastKnownState: existingState, shouldRemovePersistance)
        clearAttachments(for: identifier)
    }

    open func clearAll(shouldRemovePersistance: Bool = false) {
        let identifiers = Array(states.keys)
        identifiers.forEach { markBadgeAsRemoved(identifier: $0, lastKnownState: states[$0], shouldRemovePersistance) }

        states.removeAll()
        let attachmentIdentifiers = Set(viewAttachments.keys).union(barButtonAttachments.keys)
        attachmentIdentifiers.forEach(clearAttachments(for:))
    }

    // MARK: - Private functions

    private func register(view: UIView, for identifier: String) {
        let table = viewAttachments[identifier] ?? NSHashTable<UIView>.weakObjects()
        if !table.contains(view) {
            table.add(view)
            viewAttachments[identifier] = table
        }
    }

    open func register(barButtonItem: UIBarButtonItem, for identifier: String) {
        let table = barButtonAttachments[identifier] ?? NSHashTable<UIBarButtonItem>.weakObjects()
        if !table.contains(barButtonItem) {
            table.add(barButtonItem)
            barButtonAttachments[identifier] = table
        }
    }

    private func refreshAttachments(for identifier: String) {
        guard let state = states[identifier], state.status != .removed else {
            clearAttachments(for: identifier)
            return
        }

        viewAttachments[identifier]?.allObjects.forEach { applyBadge(to: $0, payload: state.payload) }
        barButtonAttachments[identifier]?.allObjects.forEach { applyBadge(to: $0, payload: state.payload) }
        states[identifier]?.status = .displayed
        updatePersistedRecord(for: identifier, text: state.payload.text, alignment: state.payload.alignment, status: .displayed)
    }

    private func clearAttachments(for identifier: String) {
        viewAttachments[identifier]?.allObjects.forEach(applyClearBadge(to:))
        viewAttachments[identifier] = nil

        barButtonAttachments[identifier]?.allObjects.forEach(applyClearBadge(to:))
        barButtonAttachments[identifier] = nil
    }

    private func applyBadge(to view: UIView, payload: BadgePayload) {
        if let cell = view as? UITableViewCell {
            applyBadge(to: cell.contentView, payload: payload)
            return
        }

        view.showBadgeOverlay(text: payload.text, alignment: payload.alignment)
    }

    private func applyBadge(to barButtonItem: UIBarButtonItem, payload: BadgePayload) {
        if #available(iOS 26, *) {
            barButtonItem.badge = .string(payload.text)
        }
    }

    private func applyClearBadge(to view: UIView) {
        if let cell = view as? UITableViewCell {
            applyClearBadge(to: cell.contentView)
            return
        }

        view.removeBadgeOverlay()
    }

    private func applyClearBadge(to barButtonItem: UIBarButtonItem) {
        if #available(iOS 26, *) {
            barButtonItem.badge = nil
        }
    }

    private func loadPersistedRecords() {
        guard let configuration = persistenceConfiguration else { return }

        persistedRecords.removeAll()

        guard let data = configuration.defaults.data(forKey: configuration.statesKey) else { return }

        do {
            let decoded = try JSONDecoder().decode([String: PersistedBadgeRecord].self, from: data)
            persistedRecords = decoded

            for (identifier, record) in decoded where states[identifier] == nil {
                guard record.status != .removed, let text = record.text else { continue }
                let payload = BadgePayload(text: text, alignment: record.alignment ?? .center)
                states[identifier] = BadgeState(payload: payload, status: record.status)
            }
        } catch {
            persistedRecords = [:]
        }
    }

    private func persistExistingStatesIfNeeded() {
        guard persistenceConfiguration != nil else { return }

        for (identifier, state) in states {
            updatePersistedRecord(for: identifier, text: state.payload.text, alignment: state.payload.alignment, status: state.status)
        }
    }

    private func updatePersistedRecord(for identifier: String, text: String?, alignment: BadgeVerticalAlignment, status: BadgeStatus) {
        guard persistenceConfiguration != nil else { return }

        var record = persistedRecords[identifier] ?? PersistedBadgeRecord(text: text,
                                                                          status: status, alignment: alignment)
        if let text {
            record.text = text
        }
        record.alignment = alignment
        record.status = status
        persistedRecords[identifier] = record
        persistRecordsToStorage()
    }

    private func markBadgeAsRemoved(identifier: String, lastKnownState: BadgeState?, _ shouldRemovePersistance: Bool = false) {
        guard persistenceConfiguration != nil else { return }

        let alignment = lastKnownState?.payload.alignment ?? persistedRecords[identifier]?.alignment ?? .center
        var record = persistedRecords[identifier] ?? PersistedBadgeRecord(text: nil, status: .removed, alignment: alignment)

        if shouldRemovePersistance {
            persistedRecords.removeValue(forKey: identifier)
        } else {
            if let text = lastKnownState?.payload.text {
                record.text = text
            }
            record.status = .removed
            record.alignment = alignment
            persistedRecords[identifier] = record
        }

        persistRecordsToStorage()
    }

    private func persistRecordsToStorage() {
        guard let configuration = persistenceConfiguration else { return }

        do {
            let data = try JSONEncoder().encode(persistedRecords)
            configuration.defaults.set(data, forKey: configuration.statesKey)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}
