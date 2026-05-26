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
    static let cardElevated = Color(hex: "#242426")
    static let input = Color(hex: "#2C2C2E")
    static let inputElevated = Color(hex: "#343437")

    // MARK: - Borders / Separators

    static let separator = Color(hex: "#3A3A3C")
    static let subtleBorder = Color(hex: "#48484A")
    static let strongBorder = Color(hex: "#5A5A5F")

    // MARK: - Text

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#EBEBF5").opacity(0.60)
    static let textTertiary = Color(hex: "#EBEBF5").opacity(0.30)
    static let textMuted = Color(hex: "#EBEBF5").opacity(0.18)
    static let inactive = Color(hex: "#8E8E93")

    // MARK: - Brand

    static let accent = Color(hex: "#6B48CC")
    static let accentLight = Color(hex: "#9D74FF")
    static let accentSoft = Color(hex: "#6B48CC").opacity(0.16)
    static let accentFaint = Color(hex: "#6B48CC").opacity(0.08)

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
    static let cardOverlay = Color.black.opacity(0.12)

    // MARK: - Gradients

    static let brandGradient = LinearGradient(
        colors: [
            accent,
            accentLight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            card,
            card.opacity(0.94),
            accent.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let elevatedCardGradient = LinearGradient(
        colors: [
            cardElevated,
            card.opacity(0.96),
            accent.opacity(0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fallbackPosterGradient = LinearGradient(
        colors: [
            accent.opacity(0.22),
            card.opacity(0.96)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
