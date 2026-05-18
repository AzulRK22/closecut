//
//  SettingsHeroCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 15/05/26.
//

import SwiftUI

struct SettingsHeroCard: View {
    let entriesCount: Int
    let circleCount: Int
    let pendingCount: Int
    let failedCount: Int

    private var statusTitle: String {
        if failedCount > 0 {
            return "A few changes need attention"
        }

        if pendingCount > 0 {
            return "Your archive has local changes"
        }

        if entriesCount == 0 {
            return "Start building your archive"
        }

        return "Your CloseCut space is active"
    }

    private var statusMessage: String {
        if failedCount > 0 {
            return "Your memories are safe locally. Retry sync when your connection is stable."
        }

        if pendingCount > 0 {
            return "You can keep using CloseCut. Your pending changes are waiting to sync."
        }

        if entriesCount == 0 {
            return "Add a few watched titles to unlock Timeline, QuickPick, Battle, and Circles."
        }

        return "Your private taste journal, recommendations, and sharing controls are ready."
    }

    private var statusIcon: String {
        if failedCount > 0 {
            return "exclamationmark.triangle.fill"
        }

        if pendingCount > 0 {
            return "clock.fill"
        }

        if entriesCount == 0 {
            return "sparkles"
        }

        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if failedCount > 0 {
            return CloseCutColors.failed
        }

        if pendingCount > 0 {
            return CloseCutColors.pending
        }

        if entriesCount == 0 {
            return CloseCutColors.accentLight
        }

        return CloseCutColors.synced
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Control center")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Manage your identity, privacy, archive health, and sync without exposing your taste publicly.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    SwiftUI.Circle()
                        .fill(statusColor.opacity(0.16))
                        .frame(width: 50, height: 50)

                    Image(systemName: statusIcon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(statusColor)
                }
            }

            HStack(spacing: 10) {
                statPill(
                    value: "\(entriesCount)",
                    label: "memories",
                    icon: "film.stack"
                )

                statPill(
                    value: "\(circleCount)",
                    label: "circles",
                    icon: "person.2.fill"
                )

                statPill(
                    value: failedCount > 0 ? "\(failedCount)" : "\(pendingCount)",
                    label: failedCount > 0 ? "needs retry" : "pending",
                    icon: failedCount > 0 ? "exclamationmark.triangle.fill" : "clock.fill"
                )
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: statusIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(statusTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(CloseCutColors.input.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    CloseCutColors.card,
                    CloseCutColors.card.opacity(0.94),
                    CloseCutColors.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func statPill(
        value: String,
        label: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.input.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
