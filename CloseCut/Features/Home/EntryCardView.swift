//
//  EntryCardView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum EntryCardVariant {
    case timeline
    case circle
}

struct EntryCardView: View {
    let entry: Entry
    var variant: EntryCardVariant = .timeline

    private var mood: Mood {
        Mood.from(entry.mood)
    }

    private var cardSubtitle: String {
        if entry.sourceType == .quickAdd {
            if let quickSentiment = entry.quickSentiment {
                return quickSentiment.displayName
            }

            return "Added to your history"
        }

        return entry.takeaway.isEmpty ? "No takeaway added yet." : entry.takeaway
    }

    private var footerDateText: String {
        if let watchedDateApprox = entry.watchedDateApprox {
            return watchedDateApprox.displayLabel
        }

        return entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    private var sharingChipText: String {
        if entry.sharedCircleIds.count == 1 {
            return "Shared with 1 Circle"
        }

        return "Shared with \(entry.sharedCircleIds.count) Circles"
    }

    private var shouldShowSyncChip: Bool {
        entry.syncStatus != .synced
    }

    private var syncChipText: String {
        switch entry.syncStatus {
        case .pending:
            return "Pending sync"
        case .synced:
            return "Synced"
        case .failed:
            return "Sync failed"
        }
    }

    private var syncChipIcon: String {
        switch entry.syncStatus {
        case .pending:
            return "clock.fill"
        case .synced:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var shouldShowStatusChips: Bool {
        entry.sourceType == .quickAdd ||
        isShared ||
        shouldShowSyncChip
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CloseCutColors.card)

            mood.color
                .frame(width: 3)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 16
                    )
                )

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top, spacing: 12) {
                    Text(entry.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    MoodPill(
                        mood: mood,
                        size: .small,
                        showLabel: false
                    )
                }

                if shouldShowStatusChips {
                    statusChipsRow
                }

                Text(cardSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                footerRow
            }
            .padding(16)
            .padding(.leading, 3)
        }
        .frame(minHeight: variant == .timeline ? 148 : 128)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var statusChipsRow: some View {
        HStack(spacing: 6) {
            if entry.sourceType == .quickAdd {
                EntryStatusChip(
                    icon: "bolt.fill",
                    text: "Quick Add",
                    isHighlighted: true
                )
            }

            if isShared {
                EntryStatusChip(
                    icon: "person.2.fill",
                    text: sharingChipText,
                    isHighlighted: true
                )
            }

            if shouldShowSyncChip {
                EntryStatusChip(
                    icon: syncChipIcon,
                    text: syncChipText,
                    isWarning: entry.syncStatus == .failed
                )
            }
        }
    }

    private var footerRow: some View {
        HStack(spacing: 8) {
            Label(
                entry.watchContext.displayName,
                systemImage: entry.watchContext == .cinema ? "film.fill" : "house"
            )
            .font(.caption)
            .foregroundStyle(CloseCutColors.textTertiary)

            Text("•")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)

            Text(footerDateText)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)

            Spacer()
        }
    }

    private var accessibilityText: String {
        var parts: [String] = [
            entry.title,
            "feeling \(mood.label)",
            footerDateText
        ]

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        if isShared {
            parts.append(sharingChipText)
        }

        if shouldShowSyncChip {
            parts.append(syncChipText)
        }

        return parts.joined(separator: ", ")
    }
}

private struct EntryStatusChip: View {
    let icon: String
    let text: String
    var isHighlighted: Bool = false
    var isWarning: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        if isWarning {
            return CloseCutColors.failed
        }

        if isHighlighted {
            return CloseCutColors.accentLight
        }

        return CloseCutColors.textTertiary
    }
}
