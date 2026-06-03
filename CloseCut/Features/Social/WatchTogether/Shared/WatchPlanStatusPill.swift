//
//  WatchPlanStatusPill.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchPlanStatusPill: View {
    let status: WatchPlanStatus

    private var foregroundColor: Color {
        switch status {
        case .draft:
            return CloseCutColors.textTertiary

        case .proposed:
            return CloseCutColors.accentLight

        case .confirmed:
            return CloseCutColors.synced

        case .watched:
            return CloseCutColors.textSecondary

        case .canceled:
            return CloseCutColors.failed
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .draft:
            return CloseCutColors.input

        case .proposed:
            return CloseCutColors.accent.opacity(0.16)

        case .confirmed:
            return CloseCutColors.synced.opacity(0.14)

        case .watched:
            return CloseCutColors.input

        case .canceled:
            return CloseCutColors.failedBackground
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.systemImage)
                .font(.caption2.weight(.semibold))

            Text(status.displayName)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.displayName)
    }
}
