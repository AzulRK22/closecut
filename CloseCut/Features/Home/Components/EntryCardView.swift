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
            if let overview = cleanOptional(entry.overview) {
                return overview
            }

            if let quickSentiment = entry.quickSentiment {
                return quickSentiment.displayName
            }

            return "Added to your history"
        }

        let cleanedTakeaway = entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleanedTakeaway.isEmpty
            ? "No takeaway added yet."
            : cleanedTakeaway
    }

    private var footerDateText: String {
        if let watchedDateApprox = entry.watchedDateApprox {
            return watchedDateApprox.displayLabel
        }

        return entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var metadataText: String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if let rating = entry.tmdbRating, rating > 0 {
            parts.append(String(format: "%.1f TMDB", rating))
        }

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    private var sharingChipText: String {
        guard entry.visibility == .circle,
              entry.sharedCircleIds.isEmpty == false else {
            return "Private"
        }

        if entry.sharedCircleIds.count == 1 {
            return "Shared"
        }

        return "\(entry.sharedCircleIds.count) Circles"
    }

    private var sharingChipIcon: String {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
            ? "person.2.fill"
            : "lock.fill"
    }

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    private var shouldShowSyncChip: Bool {
        entry.syncStatus != .synced
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CloseCutColors.card)

            mood.color
                .frame(width: 3)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 18
                    )
                )

            HStack(alignment: .top, spacing: 14) {
                EntryPosterThumbnailView(
                    entry: entry,
                    width: variant == .timeline ? 68 : 58,
                    height: variant == .timeline ? 100 : 86,
                    cornerRadius: 14
                )

                VStack(alignment: .leading, spacing: 8) {
                    headerRow

                    Text(metadataText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)

                    Text(cardSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(variant == .timeline ? 2 : 1)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    footerBlock
                }
            }
            .padding(14)
            .padding(.leading, 3)
        }
        .frame(minHeight: variant == .timeline ? 130 : 112)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(entry.title), \(metadataText), \(footerDateText), \(sharingChipText)"
        )
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            MoodPill(
                mood: mood,
                size: .small,
                showLabel: false
            )
        }
    }

    private var footerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(
                    entry.watchContext.displayName,
                    systemImage: entry.watchContext == .cinema ? "film.fill" : "house"
                )
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(footerDateText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                chip(
                    icon: sharingChipIcon,
                    text: sharingChipText,
                    isHighlighted: isShared
                )

                if shouldShowSyncChip {
                    PendingSyncBadge(status: entry.syncStatus)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func chip(
        icon: String,
        text: String,
        isHighlighted: Bool
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isHighlighted ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }
}
