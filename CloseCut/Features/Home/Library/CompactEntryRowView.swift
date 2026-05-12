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

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    private var memorySignalText: String {
        let cleanedMood = entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedMood.isEmpty == false {
            return cleanedMood
        }

        if let quickSentiment = entry.quickSentiment {
            return quickSentiment.displayName
        }

        return entry.watchContext.displayName
    }

    private var dateText: String {
        if let watchedDateApprox = entry.watchedDateApprox {
            return watchedDateApprox.displayLabel
        }

        return entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    private var needsDetails: Bool {
        LibrarySearchPipeline.needsDetails(entry)
    }

    private var contextLine: String {
        var parts: [String] = [
            memorySignalText,
            dateText
        ]

        if isShared {
            parts.append("Shared")
        } else {
            parts.append("Private")
        }

        return parts.joined(separator: " • ")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            EntryPosterThumbnailView(
                entry: entry,
                width: 54,
                height: 80,
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(metadataText)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    MoodPill(
                        mood: mood,
                        size: .small,
                        isSelected: false,
                        showLabel: false
                    )
                }

                Text(contextLine)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)

                if let takeaway = cleanOptional(entry.takeaway) {
                    Text(takeaway)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }

                if needsDetails {
                    completionHint
                }
            }
        }
        .padding(12)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(metadataText), \(contextLine)")
    }

    private var completionHint: some View {
        HStack(spacing: 5) {
            Image(systemName: "wand.and.stars")
                .font(.caption2.weight(.semibold))

            Text("Ready to complete")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(CloseCutColors.accentLight)
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
