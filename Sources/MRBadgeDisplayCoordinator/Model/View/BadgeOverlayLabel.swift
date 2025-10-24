//
//  BadgeOverlayLabel.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 24/11/2025
//  Using Swift 5.10
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import UIKit

class BadgeOverlayLabel: UILabel {
    private let contentInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemRed
        textColor = .white
        font = .systemFont(ofSize: 12, weight: .medium)
        textAlignment = .center
        clipsToBounds = true
        adjustsFontForContentSizeCategory = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let baseSize = super.intrinsicContentSize
        return CGSize(width: baseSize.width + contentInsets.left + contentInsets.right, height: baseSize.height + contentInsets.top + contentInsets.bottom)
    }
}
