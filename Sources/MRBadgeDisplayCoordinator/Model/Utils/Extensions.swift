//
//  Extensions.swift
//  BadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for BadgeDisplayCoordinator in 20/11/2019
//  Using Swift 5.10
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import UIKit

extension UIView {
    private enum AssociatedKeys {
        @MainActor static var badgeOverlayView: UInt8 = 0
    }

    class BadgeOverlayLabel: UILabel {
        private let contentInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

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
            font = .systemFont(ofSize: 12, weight: .semibold)
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
            return CGSize(width: baseSize.width + contentInsets.left + contentInsets.right,
                          height: baseSize.height + contentInsets.top + contentInsets.bottom)
        }
    }

    private var badgeOverlayLabel: BadgeOverlayLabel? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.badgeOverlayView) as? BadgeOverlayLabel }
        set { objc_setAssociatedObject(self, &AssociatedKeys.badgeOverlayView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func showBadgeOverlay(text: String) {
        let label = ensureBadgeOverlay()
        label.text = text
        label.isHidden = false
        label.invalidateIntrinsicContentSize()
    }

    func removeBadgeOverlay() {
        badgeOverlayLabel?.removeFromSuperview()
        badgeOverlayLabel = nil
    }

    private func ensureBadgeOverlay() -> BadgeOverlayLabel {
        if let existingLabel = badgeOverlayLabel {
            return existingLabel
        }

        let label = BadgeOverlayLabel()
        addSubview(label)

        let margins = layoutMarginsGuide
        let topConstraint = label.topAnchor.constraint(equalTo: margins.topAnchor)
        topConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            topConstraint,
            label.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ])

        badgeOverlayLabel = label
        return label
    }
}
