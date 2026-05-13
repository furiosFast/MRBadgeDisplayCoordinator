//
//  Extensions.swift
//  MRBadgeDisplayCoordinator
//
//  Created by Marco Ricca on 20/10/2025
//
//  Created for MRBadgeDisplayCoordinator in 20/11/2025
//  Using Swift 6.2
//  Running on macOS 26.0.1
//
//  Copyright © 2025 Fast-Devs Project. All rights reserved.
//

import SnapKit
import UIKit

private class BoxedAlignment {
    let value: BadgeVerticalAlignment
    init(_ value: BadgeVerticalAlignment) { self.value = value }
}

extension UIView {
    private enum AssociatedKeys {
        @MainActor static var badgeOverlayView: UInt8 = 0
        @MainActor static var badgeOverlayAlignment: UInt8 = 0
    }

    private var badgeOverlayLabel: BadgeOverlayLabel? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.badgeOverlayView) as? BadgeOverlayLabel }
        set { objc_setAssociatedObject(self, &AssociatedKeys.badgeOverlayView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var currentBadgeAlignment: BadgeVerticalAlignment? {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.badgeOverlayAlignment) as? BoxedAlignment)?.value }
        set {
            let boxed = newValue.map { BoxedAlignment($0) }
            objc_setAssociatedObject(self, &AssociatedKeys.badgeOverlayAlignment, boxed, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func showBadgeOverlay(text: String, alignment: BadgeVerticalAlignment = .center) {
        let label = ensureBadgeOverlay(alignment: alignment)
        label.text = text
        label.isHidden = false
    }

    func removeBadgeOverlay() {
        badgeOverlayLabel?.removeFromSuperview()
        badgeOverlayLabel = nil
        currentBadgeAlignment = nil
    }

    private func ensureBadgeOverlay(alignment: BadgeVerticalAlignment) -> BadgeOverlayLabel {
        if let existingLabel = badgeOverlayLabel {
            if currentBadgeAlignment != alignment {
                applyConstraints(alignment)
            }
            return existingLabel
        }

        let label = BadgeOverlayLabel()
        badgeOverlayLabel = label
        addSubview(label)
        applyConstraints(alignment)

        return label
    }

    private func applyConstraints(_ alignment: BadgeVerticalAlignment) {
        currentBadgeAlignment = alignment
        badgeOverlayLabel?.snp.remakeConstraints { make in
            make.height.greaterThanOrEqualTo(18)

            if self.parentFocusEnvironment is UITableViewCell {
                make.trailing.equalTo(snp.trailingMargin)
            } else {
                make.centerX.equalTo(self.snp.right)
            }

            switch alignment {
                case .top: make.top.equalTo(self.snp.top).offset(-9)
                case .center: make.centerY.equalToSuperview()
                case .bottom: make.bottom.equalTo(self.snp.bottom).offset(9)
            }
        }
    }
}
