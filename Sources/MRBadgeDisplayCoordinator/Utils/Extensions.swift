//
//  Extensions.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 20/11/2025
//  Using Swift 5.10
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import SnapKit
import UIKit

extension UIView {
    private enum AssociatedKeys {
        @MainActor static var badgeOverlayView: UInt8 = 0
        @MainActor static var badgeOverlayConstraintSet: UInt8 = 0
    }

    private var badgeOverlayLabel: BadgeOverlayLabel? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.badgeOverlayView) as? BadgeOverlayLabel }
        set { objc_setAssociatedObject(self, &AssociatedKeys.badgeOverlayView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func showBadgeOverlay(text: String, alignment: BadgeVerticalAlignment = .center) {
        let label = ensureBadgeOverlay(alignment: alignment)
        label.text = text
        label.isHidden = false
    }

    func removeBadgeOverlay() {
        badgeOverlayLabel?.removeFromSuperview()
        badgeOverlayLabel = nil
    }

    private func ensureBadgeOverlay(alignment: BadgeVerticalAlignment) -> BadgeOverlayLabel {
        if let existingLabel = badgeOverlayLabel {
            addConstraints(alignment)
            return existingLabel
        }

        let label = BadgeOverlayLabel()
        badgeOverlayLabel = label
        addSubview(label)
        addConstraints(alignment)

        return label
    }

    private func addConstraints(_ alignment: BadgeVerticalAlignment) {
        badgeOverlayLabel?.snp.remakeConstraints { make in
            make.height.equalTo(18)

            if self.parentFocusEnvironment is UITableViewCell {
                make.trailing.equalTo(snp.trailingMargin)
            } else {
                make.centerX.equalTo(self.snp.right)
            }

            switch alignment {
                case .top: make.top.equalTo(self.snp.top).offset(-self.frame.height / 2)
                case .center: make.centerY.equalToSuperview()
                case .bottom: make.centerY.equalTo(self.layoutMargins.bottom)
            }
        }
    }
}
