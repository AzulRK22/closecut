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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
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
                            label: "Pending actions",
                            value: "\(pendingCount)",
                            color: CloseCutColors.pending
                        )
                    }

                    if failedCount > 0 {
                        syncRow(
                            label: "Failed actions",
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
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var title: String {
        if failedCount > 0 {
            return "Some changes need attention"
        }

        if pendingCount > 0 {
            return "Changes saved locally"
        }

        return "All local changes are ready"
    }

    private var message: String {
        if failedCount > 0 {
            return "Your data is still safe on this device. Failed actions can be retried when sync is connected."
        }

        if pendingCount > 0 {
            return "CloseCut saved your changes offline. They are waiting for future sync."
        }

        return "Your local journal is up to date on this device."
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

    private var accessibilityLabel: String {
        "\(title). \(pendingCount) pending actions. \(failedCount) failed actions."
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
