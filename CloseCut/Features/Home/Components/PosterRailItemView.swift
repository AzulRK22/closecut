//
//  PosterRailItemView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct PosterRailItemView: View {
    let entry: Entry

    private var mood: Mood {
        Mood.from(entry.mood)
    }

    private var metadataText: String {
        if let releaseYear = entry.releaseYear {
            return "\(releaseYear) • \(entry.type.displayName)"
        }

        return entry.type.displayName
    }

    private var footerText: String {
        if entry.sourceType == .quickAdd {
            return "Quick Add"
        }

        if entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false {
            return "Shared"
        }

        return entry.watchContext.displayName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                EntryPosterThumbnailView(
                    entry: entry,
                    width: 116,
                    height: 172,
                    cornerRadius: 16
                )

                MoodPill(
                    mood: mood,
                    size: .small,
                    isSelected: false,
                    showLabel: false
                )
                .padding(7)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(metadataText)
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                Text(footerText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 116, alignment: .leading)
        }
        .frame(width: 116, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(metadataText), \(footerText)")
    }
}
