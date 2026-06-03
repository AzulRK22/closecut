//
//  CircleTimelineEntryRow.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import SwiftUI

struct CircleTimelineEntryRow: View {
    let entry: Entry
    let currentUserId: String

    private var sharedByText: String {
        entry.ownerId == currentUserId ? "Shared by you" : "Shared by Circle member"
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

    private var moodText: String {
        let cleanedMood = entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedMood.isEmpty {
            return entry.quickSentiment?.displayName ?? "Shared memory"
        }

        return cleanedMood
    }

    private var bodyText: String {
        let cleanedTakeaway = entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedTakeaway.isEmpty == false {
            return cleanedTakeaway
        }

        if let overview = cleanOptional(entry.overview) {
            return overview
        }

        return "Shared from Personal Timeline."
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            EntryPosterThumbnailView(
                entry: entry,
                width: 58,
                height: 86,
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 8) {
                topRow

                Text(entry.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(metadataText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                moodRow

                Text(bodyText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                readOnlyRow
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(metadataText), \(moodText), \(sharedByText), read-only shared entry")
    }

    private var topRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(sharedByText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .textCase(.uppercase)
                .tracking(0.6)
                .lineLimit(1)

            Spacer()

            Text(entry.watchedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)
        }
    }

    private var moodRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)

            Text(moodText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(1)
        }
    }

    private var readOnlyRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text("Read-only shared entry")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)

            Spacer()
        }
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
