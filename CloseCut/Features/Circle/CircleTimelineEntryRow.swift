//
//  CircleTimelineEntryRow.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import SwiftUI

struct CircleTimelineEntryRow: View {
    let entry: Entry

    private var subtitle: String {
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

    private var moodText: String {
        if entry.mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return entry.quickSentiment?.displayName ?? "Shared memory"
        }

        return entry.mood
    }

    private var bodyText: String {
        if entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Shared from Personal Timeline."
        }

        return entry.takeaway
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Text(entry.watchedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

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
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

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
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(moodText), read-only shared entry")
    }
}
