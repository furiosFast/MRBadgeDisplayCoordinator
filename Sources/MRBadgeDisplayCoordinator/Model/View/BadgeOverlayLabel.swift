//
//  BadgeOverlayLabel.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 24/11/2025
//  Using Swift 6.2
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import UIKit

/// The default rounded "pill" used to render badges over arbitrary views.
///
/// Subclass it inside your app to tweak colors or fonts, then register your
/// subclass through ``MRBadgeDisplayCoordinator/overlayProvider`` so every
/// overlay the coordinator creates uses it.
open class BadgeOverlayLabel: UILabel {
    private let contentInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    /// Visual configuration applied once at creation. Override to customise
    /// colors, fonts or corner styling while keeping the layout behaviour.
    open func setUp() {
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

    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    open override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    open override var intrinsicContentSize: CGSize {
        let baseSize = super.intrinsicContentSize
        return CGSize(width: baseSize.width + contentInsets.left + contentInsets.right, height: baseSize.height + contentInsets.top + contentInsets.bottom)
    }
}
