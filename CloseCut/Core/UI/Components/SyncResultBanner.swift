//
//  SyncResultBanner.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

enum SyncResultBannerStyle {
    case success
    case warning
    case neutral

    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .neutral:
            return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success:
            return CloseCutColors.synced
        case .warning:
            return CloseCutColors.failed
        case .neutral:
            return CloseCutColors.textTertiary
        }
    }
}

struct SyncResultBanner: View {
    let message: String
    let style: SyncResultBannerStyle

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: style.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.color)
                .padding(.top, 1)

            Text(message)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}
