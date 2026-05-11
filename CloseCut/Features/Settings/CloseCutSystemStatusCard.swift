//
//  CloseCutSystemStatusCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 10/05/26.
//

import SwiftUI

struct CloseCutSystemStatusCard: View {
    let entriesCount: Int
    let circleCount: Int
    let pendingCount: Int
    let failedCount: Int

    private var quickPickStatus: String {
        entriesCount >= 3 ? "Ready" : "Needs history"
    }

    private var circleStatus: String {
        circleCount > 0 ? "Active" : "Not started"
    }

    private var syncStatus: String {
        if failedCount > 0 {
            return "Needs retry"
        }

        if pendingCount > 0 {
            return "Pending"
        }

        return "Healthy"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 12) {
                statusRow(
                    icon: "film.stack",
                    title: "Personal Timeline",
                    value: entriesCount > 0 ? "Active" : "Empty",
                    message: entriesCount > 0
                        ? "Your private watch history is available."
                        : "Add past watches or log a new entry to start."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                statusRow(
                    icon: "sparkles",
                    title: "Personal QuickPick",
                    value: quickPickStatus,
                    message: entriesCount >= 3
                        ? "Recommendations can use your local history."
                        : "Add \(max(3 - entriesCount, 0)) more \(max(3 - entriesCount, 0) == 1 ? "memory" : "memories") to improve picks."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                statusRow(
                    icon: "person.2.fill",
                    title: "Circle sharing",
                    value: circleStatus,
                    message: circleCount > 0
                        ? "You have trusted private spaces available."
                        : "Create or join a Circle to share selectively."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                statusRow(
                    icon: syncIcon,
                    title: "Sync pipeline",
                    value: syncStatus,
                    message: syncMessage
                )
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 38, height: 38)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("Product status")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("A quick view of what is active in your CloseCut experience.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    private var syncIcon: String {
        if failedCount > 0 {
            return "exclamationmark.triangle.fill"
        }

        if pendingCount > 0 {
            return "clock.fill"
        }

        return "checkmark.circle.fill"
    }

    private var syncMessage: String {
        if failedCount > 0 {
            return "\(failedCount) failed \(failedCount == 1 ? "action needs" : "actions need") retry."
        }

        if pendingCount > 0 {
            return "\(pendingCount) local \(pendingCount == 1 ? "change is" : "changes are") waiting to sync."
        }

        return "No pending or failed local changes."
    }

    private func statusRow(
        icon: String,
        title: String,
        value: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 12)

                    Text(value)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(statusColor(for: value))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(CloseCutColors.input)
                        .clipShape(Capsule())
                }

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func statusColor(for value: String) -> Color {
        switch value {
        case "Ready", "Active", "Healthy":
            return CloseCutColors.synced
        case "Pending", "Needs history", "Not started", "Empty":
            return CloseCutColors.pending
        case "Needs retry":
            return CloseCutColors.failed
        default:
            return CloseCutColors.textTertiary
        }
    }
}
