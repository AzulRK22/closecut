//
//  CompactEntryRowView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct CompactEntryRowView: View {
    let entry: Entry

    private var mood: Mood {
        Mood.from(entry.mood)
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

        return parts.joined(separator: " • ")
    }

    private var secondaryText: String {
        let cleanedMood = entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedMood.isEmpty {
            return entry.quickSentiment?.displayName ?? entry.watchContext.displayName
        }

        return cleanedMood
    }

    private var footerDateText: String {
        if let watchedDateApprox = entry.watchedDateApprox {
            return watchedDateApprox.displayLabel
        }

        return entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var visibilityText: String {
        if entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false {
            return entry.sharedCircleIds.count == 1 ? "Shared" : "\(entry.sharedCircleIds.count) Circles"
        }

        return "Private"
    }

    private var visibilityIcon: String {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
            ? "person.2.fill"
            : "lock.fill"
    }

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            EntryPosterThumbnailView(
                entry: entry,
                width: 48,
                height: 72,
                cornerRadius: 11
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    MoodPill(
                        mood: mood,
                        size: .small,
                        isSelected: false,
                        showLabel: false
                    )
                }

                Text(metadataText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(secondaryText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)

                    Text(footerDateText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    visibilityChip
                }
            }
        }
        .padding(12)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(metadataText), \(secondaryText), \(visibilityText)")
    }

    private var visibilityChip: some View {
        HStack(spacing: 4) {
            Image(systemName: visibilityIcon)
                .font(.caption2.weight(.semibold))

            Text(visibilityText)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isShared ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
}
