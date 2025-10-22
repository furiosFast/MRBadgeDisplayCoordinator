//
//  PersistedBadgeRecord.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 22/10/25.
//

import Foundation

struct PersistedBadgeRecord: Codable {
    var text: String?
    var status: BadgeStatus
}
