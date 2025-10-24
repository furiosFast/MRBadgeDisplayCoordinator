//
//  PersistedBadgeRecord.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 22/11/2025
//  Using Swift 5.10
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import Foundation

struct PersistedBadgeRecord: Codable {
    var text: String?
    var status: BadgeStatus
    var alignment: BadgeVerticalAlignment?
}
