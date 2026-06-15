//
//  MRBadgeDisplayCoordinator.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 21/11/2025
//  Using Swift 6.2
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import UIKit

@MainActor
open class MRBadgeDisplayCoordinator {
    public static let shared = MRBadgeDisplayCoordinator()

    /// Factory used to build the overlay rendered on plain views. Replace it to
    /// use a `BadgeOverlayLabel` subclass with custom colors or fonts.
    public var overlayProvider: () -> BadgeOverlayLabel = { BadgeOverlayLabel() }

    private var states: [String: BadgeState] = [:]
    private var viewAttachments: [String: NSHashTable<UIView>] = [:]
    private var barButtonAttachments: [String: NSHashTable<UIBarButtonItem>] = [:]
    private var persistenceConfiguration: PersistenceConfiguration?
    private var persistedRecords: [String: PersistedBadgeRecord] = [:]

    private init() {}

    static func makeOverlayLabel() -> BadgeOverlayLabel {
        shared.overlayProvider()
    }

    // MARK: - Persistence

    /// Mirrors every badge mutation to `UserDefaults` so that `.removed`
    /// identifiers stay cleared across launches. Call once at launch.
    open func configurePersistence(using userDefaults: UserDefaults = .standard, storageKey: String = "MRBadgeDisplayCoordinator.states") {
        persistenceConfiguration = PersistenceConfiguration(defaults: userDefaults, statesKey: storageKey)
        loadPersistedRecords()
        persistExistingStatesIfNeeded()
    }

    // MARK: - Scheduling

    /// Schedules (or updates) the badge for `id` and refreshes every bound view.
    ///
    /// - Note: Identifiers cleared by a tap are remembered as `.removed` when
    ///   persistence is configured and will **not** be shown again. Pass a fresh
    ///   identifier for a genuinely new badge, or clear with
    ///   `shouldRemovePersistence: true` to recycle the same one.
    open func schedule(_ text: String, for id: String, alignment: BadgeVerticalAlignment = .center) {
        scheduleBadge(for: id, payload: BadgePayload(text: text, alignment: alignment))
    }

    /// Lower-level scheduling entry point that takes a fully built payload.
    open func scheduleBadge(for identifier: String, payload: BadgePayload) {
        if let status = status(for: identifier), status == .removed {
            return
        }

        states[identifier] = BadgeState(payload: payload, status: .pending)
        updatePersistedRecord(for: identifier, text: payload.text, alignment: payload.alignment, status: .pending)
        refreshAttachments(for: identifier)
    }

    // MARK: - Binding

    /// Binds a view to `id` and immediately reflects the current badge state.
    ///
    /// A view can only mirror one identifier at a time, so binding it to a new
    /// `id` detaches it from any previous one. This is what keeps reused table
    /// view cells from showing a stale badge belonging to another row.
    open func bind(_ view: UIView, to identifier: String) {
        detachViewFromOtherIdentifiers(view, keeping: identifier)
        register(view: view, for: identifier)

        guard let state = states[identifier], state.status != .removed else {
            applyClearBadge(to: view)
            return
        }

        applyBadge(to: view, payload: state.payload)
        states[identifier]?.status = .displayed
        updatePersistedRecord(for: identifier, text: state.payload.text, alignment: state.payload.alignment, status: .displayed)
    }

    /// Binds a bar button item to `id` and immediately reflects the current state.
    open func bind(_ barButtonItem: UIBarButtonItem, to identifier: String) {
        register(barButtonItem: barButtonItem, for: identifier)

        guard let state = states[identifier], state.status != .removed else {
            applyClearBadge(to: barButtonItem)
            return
        }

        applyBadge(to: barButtonItem, payload: state.payload)
        states[identifier]?.status = .displayed
        updatePersistedRecord(for: identifier, text: state.payload.text, alignment: state.payload.alignment, status: .displayed)
    }

    // MARK: - Queries

    open func hasBadge(for identifier: String) -> Bool {
        guard let state = states[identifier] else { return false }
        return state.status != .removed
    }

    open func status(for identifier: String) -> BadgeStatus? {
        if let state = states[identifier] {
            return state.status
        }

        return persistedRecords[identifier]?.status
    }

    // MARK: - Clearing

    /// Clears the badge for `identifier` and removes it from every bound view.
    /// With persistence configured the identifier is remembered as `.removed`
    /// unless `shouldRemovePersistence` is `true`.
    open func clearBadge(for identifier: String, shouldRemovePersistence: Bool = false) {
        let existingState = states.removeValue(forKey: identifier)
        markBadgeAsRemoved(identifier: identifier, lastKnownState: existingState, shouldRemovePersistence)
        clearAttachments(for: identifier)
    }

    /// Clears every tracked badge. With persistence configured each identifier is
    /// recorded as `.removed` unless `shouldRemovePersistence` is `true`.
    open func clearAll(shouldRemovePersistence: Bool = false) {
        guard persistenceConfiguration != nil else {
            states.removeAll()
            let attachmentIdentifiers = Set(viewAttachments.keys).union(barButtonAttachments.keys)
            attachmentIdentifiers.forEach(clearAttachments(for:))
            return
        }

        for (identifier, state) in states {
            let alignment = state.payload.alignment
            if shouldRemovePersistence {
                persistedRecords.removeValue(forKey: identifier)
            } else {
                var record = persistedRecords[identifier] ?? PersistedBadgeRecord(text: nil, status: .removed, alignment: alignment)
                record.text = state.payload.text
                record.status = .removed
                record.alignment = alignment
                persistedRecords[identifier] = record
            }
        }
        persistRecordsToStorage()

        states.removeAll()
        let attachmentIdentifiers = Set(viewAttachments.keys).union(barButtonAttachments.keys)
        attachmentIdentifiers.forEach(clearAttachments(for:))
    }

    open func applyClearBadge(to view: UIView) {
        if let cell = view as? UITableViewCell {
            applyClearBadge(to: cell.contentView)
            return
        }

        view.removeBadgeOverlay()
    }

    open func applyClearBadge(to barButtonItem: UIBarButtonItem) {
        if #available(iOS 26.0, *) {
            barButtonItem.badge = nil
        }
    }

    // MARK: - Private functions

    private func register(view: UIView, for identifier: String) {
        let table = viewAttachments[identifier] ?? NSHashTable<UIView>.weakObjects()
        if !table.contains(view) {
            table.add(view)
            viewAttachments[identifier] = table
        }
    }

    private func register(barButtonItem: UIBarButtonItem, for identifier: String) {
        let table = barButtonAttachments[identifier] ?? NSHashTable<UIBarButtonItem>.weakObjects()
        if !table.contains(barButtonItem) {
            table.add(barButtonItem)
            barButtonAttachments[identifier] = table
        }
    }

    /// Removes `view` from the attachment tables of every identifier except
    /// `identifier`, clearing any badge it used to display there. Prevents reused
    /// views (table cells) from carrying a badge belonging to another row.
    private func detachViewFromOtherIdentifiers(_ view: UIView, keeping identifier: String) {
        var emptiedIdentifiers: [String] = []

        for (otherIdentifier, table) in viewAttachments where otherIdentifier != identifier {
            guard table.contains(view) else { continue }
            table.remove(view)
            applyClearBadge(to: view)
            if table.count == 0 {
                emptiedIdentifiers.append(otherIdentifier)
            }
        }

        emptiedIdentifiers.forEach { viewAttachments[$0] = nil }
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

        var record = persistedRecords[identifier] ?? PersistedBadgeRecord(text: text, status: status, alignment: alignment)
        if let text {
            record.text = text
        }
        record.alignment = alignment
        record.status = status
        persistedRecords[identifier] = record
        persistRecordsToStorage()
    }

    private func markBadgeAsRemoved(identifier: String, lastKnownState: BadgeState?, _ shouldRemovePersistence: Bool = false) {
        guard persistenceConfiguration != nil else { return }

        let alignment = lastKnownState?.payload.alignment ?? persistedRecords[identifier]?.alignment ?? .center
        var record = persistedRecords[identifier] ?? PersistedBadgeRecord(text: nil, status: .removed, alignment: alignment)

        if shouldRemovePersistence {
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
