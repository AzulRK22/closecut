//
//  CircleTimelineEntryCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct CircleTimelineEntryCard: View {
    let entry: Entry
    let currentUserId: String

    private var sharedByText: String {
        entry.ownerId == currentUserId ? "Shared by you" : "Shared by Circle member"
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CircleSharedPosterView(
                entry: entry,
                width: 62,
                height: 92,
                cornerRadius: 13
            )

            VStack(alignment: .leading, spacing: 8) {
                topRow

                Text(entry.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(metadataText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)

                    Text(moodText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)
                }

                Text(bodyText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                footerRow
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.displayTitle), \(metadataText), \(moodText), \(sharedByText)")
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

            Text(entry.displayDateText)
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)
        }
    }

    private var footerRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text("Read-only shared memory")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
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
