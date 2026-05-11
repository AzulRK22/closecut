//
//  ArchiveHealthCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 10/05/26.
//

import SwiftUI

struct ArchiveHealthCard: View {
    let entries: [Entry]
    let pendingCount: Int
    let failedCount: Int

    private var activeEntries: [Entry] {
        entries.filter { $0.deletedAt == nil }
    }

    private var totalCount: Int {
        activeEntries.count
    }

    private var sharedCount: Int {
        activeEntries.filter {
            $0.visibility == .circle && $0.sharedCircleIds.isEmpty == false
        }.count
    }

    private var privateCount: Int {
        max(totalCount - sharedCount, 0)
    }

    private var quickAddCount: Int {
        activeEntries.filter { $0.sourceType == .quickAdd }.count
    }

    private var tmdbEnrichedCount: Int {
        activeEntries.filter { entry in
            entry.tmdbId != nil ||
            entry.posterPath?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }.count
    }

    private var enrichmentProgress: Double {
        guard totalCount > 0 else {
            return 0
        }

        return Double(tmdbEnrichedCount) / Double(totalCount)
    }

    private var healthTitle: String {
        if failedCount > 0 {
            return "Archive needs attention"
        }

        if pendingCount > 0 {
            return "Archive has local changes"
        }

        if totalCount == 0 {
            return "Archive not started"
        }

        if totalCount < 3 {
            return "Archive is starting"
        }

        return "Archive is healthy"
    }

    private var healthMessage: String {
        if failedCount > 0 {
            return "Your data is still safe locally, but some changes need a retry."
        }

        if pendingCount > 0 {
            return "You have local changes waiting to sync with the cloud."
        }

        if totalCount == 0 {
            return "Add a few past watches to activate Timeline and QuickPick."
        }

        if totalCount < 3 {
            return "Add a few more memories to make QuickPick more useful."
        }

        return "Your private taste history is active and ready for Timeline, QuickPick, and selective sharing."
    }

    private var healthIcon: String {
        if failedCount > 0 {
            return "exclamationmark.triangle.fill"
        }

        if pendingCount > 0 {
            return "clock.fill"
        }

        if totalCount == 0 {
            return "archivebox.fill"
        }

        return "checkmark.circle.fill"
    }

    private var healthColor: Color {
        if failedCount > 0 {
            return CloseCutColors.failed
        }

        if pendingCount > 0 {
            return CloseCutColors.pending
        }

        if totalCount == 0 {
            return CloseCutColors.textTertiary
        }

        return CloseCutColors.synced
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            HStack(spacing: 10) {
                statPill(
                    value: "\(totalCount)",
                    label: totalCount == 1 ? "memory" : "memories",
                    icon: "film.stack"
                )

                statPill(
                    value: "\(privateCount)",
                    label: "private",
                    icon: "lock.fill"
                )

                statPill(
                    value: "\(sharedCount)",
                    label: "shared",
                    icon: "person.2.fill"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("TMDB enrichment")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)

                    Spacer()

                    Text("\(tmdbEnrichedCount)/\(totalCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(CloseCutColors.input)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(CloseCutColors.accent)
                            .frame(width: proxy.size.width * enrichmentProgress)
                    }
                }
                .frame(height: 8)

                HStack(spacing: 8) {
                    signalPill(
                        icon: "bolt.fill",
                        text: "\(quickAddCount) Quick Add"
                    )

                    signalPill(
                        icon: "photo.on.rectangle",
                        text: "\(tmdbEnrichedCount) enriched"
                    )
                }
            }
            .padding(12)
            .background(CloseCutColors.input.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(healthColor.opacity(failedCount > 0 ? 0.7 : 0.22), lineWidth: failedCount > 0 ? 1 : 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(healthTitle). \(healthMessage). \(totalCount) memories.")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                SwiftUI.Circle()
                    .fill(healthColor.opacity(0.16))
                    .frame(width: 42, height: 42)

                Image(systemName: healthIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(healthColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(healthTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(healthMessage)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func signalPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.card)
        .clipShape(Capsule())
    }
}
