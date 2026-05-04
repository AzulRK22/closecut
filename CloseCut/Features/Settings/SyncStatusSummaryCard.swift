//
//  SyncStatusSummaryCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct SyncStatusSummaryCard: View {
    let pendingCount: Int
    let failedCount: Int
    let isSyncing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(iconColor.opacity(0.16))
                        .frame(width: 40, height: 40)

                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.82)
                            .tint(iconColor)
                    } else {
                        Image(systemName: iconName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if pendingCount > 0 || failedCount > 0 {
                VStack(spacing: 8) {
                    if pendingCount > 0 {
                        syncRow(
                            label: "Waiting to sync",
                            value: "\(pendingCount)",
                            color: CloseCutColors.pending
                        )
                    }

                    if failedCount > 0 {
                        syncRow(
                            label: "Needs retry",
                            value: "\(failedCount)",
                            color: CloseCutColors.failed
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(borderColor, lineWidth: failedCount > 0 ? 1 : 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var title: String {
        if isSyncing {
            return "Syncing local changes"
        }

        if failedCount > 0 {
            return "Some changes need retry"
        }

        if pendingCount > 0 {
            return "Changes saved on this device"
        }

        return "All changes are synced"
    }

    private var message: String {
        if isSyncing {
            return "CloseCut is sending your local changes to Firestore."
        }

        if failedCount > 0 {
            return "Your data is still safe locally. Retry when your connection is stable."
        }

        if pendingCount > 0 {
            return "You can keep using CloseCut. These changes will sync when you choose Sync now."
        }

        return "Your journal is up to date across local storage and cloud sync."
    }

    private var iconName: String {
        if failedCount > 0 {
            return "exclamationmark.triangle.fill"
        }

        if pendingCount > 0 {
            return "clock.fill"
        }

        return "checkmark.circle.fill"
    }

    private var iconColor: Color {
        if failedCount > 0 {
            return CloseCutColors.failed
        }

        if pendingCount > 0 {
            return CloseCutColors.pending
        }

        return CloseCutColors.synced
    }

    private var borderColor: Color {
        failedCount > 0 ? CloseCutColors.failed.opacity(0.65) : CloseCutColors.separator
    }

    private var accessibilityLabel: String {
        "\(title). \(pendingCount) pending changes. \(failedCount) failed changes."
    }

    private func syncRow(
        label: String,
        value: String,
        color: Color
    ) -> some View {
        HStack {
            HStack(spacing: 8) {
                SwiftUI.Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
            }

            Spacer()

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
        }
    }
}
