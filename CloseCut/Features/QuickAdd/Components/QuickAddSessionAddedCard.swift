//
//  QuickAddSessionAddedCard.swift
//  CloseCut
//

import SwiftUI

struct QuickAddSessionAddedCard: View {
    let entries: [Entry]

    private var visibleEntries: [Entry] {
        Array(entries.prefix(5))
    }

    var body: some View {
        if entries.isEmpty == false {
            QuickAddSectionCard(
                title: "Added this session",
                subtitle: "\(entries.count) \(entries.count == 1 ? "memory" : "memories") added to your private history."
            ) {
                VStack(spacing: 10) {
                    ForEach(visibleEntries) { entry in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.synced)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(CloseCutColors.textPrimary)
                                    .lineLimit(1)

                                Text(metadataText(for: entry))
                                    .font(.caption)
                                    .foregroundStyle(CloseCutColors.textTertiary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }

    private func metadataText(for entry: Entry) -> String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if entry.posterPath != nil || entry.tmdbId != nil {
            parts.append("Metadata connected")
        } else {
            parts.append("Manual add")
        }

        return parts.joined(separator: " • ")
    }
}
