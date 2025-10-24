//
//  BadgePayload.swift
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

import Foundation

public struct BadgePayload {
    public let text: String
    public let alignment: BadgeVerticalAlignment

    public init(text: String, alignment: BadgeVerticalAlignment = .center) {
        self.text = text
        self.alignment = alignment
    }
}
