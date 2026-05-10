//
//  CloseCutColors.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum CloseCutColors {
    // MARK: - Backgrounds

    static let backgroundPrimary = Color(hex: "#000000")
    static let backgroundElevated = Color(hex: "#111111")
    static let card = Color(hex: "#1C1C1E")
    static let input = Color(hex: "#2C2C2E")

    // MARK: - Borders / Separators

    static let separator = Color(hex: "#3A3A3C")
    static let subtleBorder = Color(hex: "#48484A")

    // MARK: - Text

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#EBEBF5").opacity(0.60)
    static let textTertiary = Color(hex: "#EBEBF5").opacity(0.30)
    static let inactive = Color(hex: "#8E8E93")

    // MARK: - Brand

    static let accent = Color(hex: "#6B48CC")
    static let accentLight = Color(hex: "#9D74FF")

    // MARK: - Status

    static let pending = Color(hex: "#F59E0B")
    static let synced = Color(hex: "#34D399")
    static let failed = Color(hex: "#F87171")
    static let warning = Color(hex: "#FBBF24")
    static let neutral = Color(hex: "#A1A1AA")

    // MARK: - Status Backgrounds

    static let pendingBackground = Color(hex: "#2D1F00")
    static let failedBackground = Color(hex: "#2D0000")
    static let successBackground = Color(hex: "#052E22")
    static let neutralBackground = Color(hex: "#18181B")

    // MARK: - Overlays

    static let darkOverlay = Color.black.opacity(0.55)
    static let softOverlay = Color.black.opacity(0.24)
}
