//
//  EntryDetailSignalsCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct EntryDetailSignalsCard: View {
    let entry: Entry

    private var hasCinemaRatings: Bool {
        entry.watchContext == .cinema &&
        (entry.cinemaAudio != nil || entry.cinemaScreen != nil || entry.cinemaComfort != nil)
    }

    var body: some View {
        EntryDetailSectionCard(
            title: "Signals",
            subtitle: "Context CloseCut can use for memory, rewatch, and recommendations.",
            systemImage: "slider.horizontal.3"
        ) {
            VStack(spacing: 12) {
                DetailInfoRow(
                    label: "Watched",
                    value: watchedDateText
                )

                DetailInfoRow(
                    label: "Context",
                    value: entry.watchContext.displayName
                )

                DetailInfoRow(
                    label: "Intensity",
                    value: intensityText
                )

                if let rating = entry.tmdbRating, rating > 0 {
                    DetailInfoRow(
                        label: "TMDB",
                        value: String(format: "%.1f rating", rating)
                    )
                }

                if hasCinemaRatings {
                    Divider()
                        .overlay(CloseCutColors.separator)
                        .padding(.vertical, 2)

                    CinemaRatingsView(
                        audio: entry.cinemaAudio,
                        screen: entry.cinemaScreen,
                        comfort: entry.cinemaComfort
                    )
                }

                if entry.tags.isEmpty == false {
                    Divider()
                        .overlay(CloseCutColors.separator)
                        .padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tags")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)

                        ReadOnlyTagsView(tags: entry.tags)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var watchedDateText: String {
        if let watchedDateApprox = entry.watchedDateApprox {
            return watchedDateApprox.displayLabel
        }

        return entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var intensityText: String {
        switch entry.intensity {
        case 1:
            return "Light"
        case 2:
            return "Soft"
        case 3:
            return "Memorable"
        case 4:
            return "Strong"
        case 5:
            return "Intense"
        default:
            return "\(entry.intensity)/5"
        }
    }
}
