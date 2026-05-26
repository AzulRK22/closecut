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

    var background: Color {
        switch self {
        case .success:
            return CloseCutColors.synced.opacity(0.10)
        case .warning:
            return CloseCutColors.failed.opacity(0.10)
        case .neutral:
            return CloseCutColors.input
        }
    }
}

struct SyncResultBanner: View {
    let message: String
    let style: SyncResultBannerStyle

    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: style.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.color)
                .padding(.top, 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle, let action {
                    Button {
                        action()
                    } label: {
                        Text(actionTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(style.color)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(style.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(style.color.opacity(style == .neutral ? 0.0 : 0.25), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}
