//
//  WrapShareCardView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import SwiftUI

struct WrapShareCardView: View {
    let summary: WrapSummary
    let options: WrapShareOptions

    var body: some View {
        ZStack {
            cardBackground

            VStack(alignment: .leading, spacing: 20) {
                header

                Spacer(minLength: 10)

                mainContent

                Spacer(minLength: 10)

                if options.includeBranding {
                    brandingFooter
                }
            }
            .padding(26)
        }
        .frame(width: 320, height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 22, x: 0, y: 12)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CLOSECUT")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
                .tracking(1.4)

            Text(summary.period.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(summary.shareTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            if options.includePosterStrip && summary.posterHighlights.isEmpty == false {
                posterStrip
            }

            if options.includeWatchedCount {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(summary.watchedCount)")
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(summary.wrappedCountText)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.80))
                }
            }

            if options.includeMediaSplit {
                shareMetricRow(
                    icon: "rectangle.split.2x1.fill",
                    title: "Split",
                    value: summary.movieSeriesText
                )
            }

            if options.includeMoodSignal, let mood = summary.dominantMood {
                shareMetricRow(
                    icon: mood.systemImage,
                    title: "Top signal",
                    value: mood.title
                )
            }

            if options.includeTopGenres && summary.topGenres.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top genres")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .textCase(.uppercase)
                        .tracking(1.0)

                    Text(summary.topGenres.prefix(3).map(\.title).joined(separator: " · "))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if options.includeTopTitle, let topEntry = summary.strongestEntry ?? summary.topEntry {
                shareMetricRow(
                    icon: "star.fill",
                    title: "Strongest memory",
                    value: topEntry.title
                )
            }
        }
    }

    private var posterStrip: some View {
        HStack(spacing: -10) {
            ForEach(summary.posterHighlights.prefix(4)) { poster in
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.12))

                    if let url = TMDBImageURLBuilder.imageURL(
                        path: poster.posterPath,
                        size: .posterMedium
                    ) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.white)

                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()

                            case .failure:
                                Image(systemName: "film.fill")
                                    .foregroundStyle(.white.opacity(0.75))

                            @unknown default:
                                Image(systemName: "film.fill")
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                    } else {
                        Image(systemName: "film.fill")
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .frame(width: 58, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                }
            }
        }
    }

    private func shareMetricRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.white.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var brandingFooter: some View {
        HStack {
            Text("private taste journal")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.52))

            Spacer()

            Text("CloseCut")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.82))
        }
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    CloseCutColors.backgroundPrimary,
                    CloseCutColors.accent.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.34),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 260
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.26),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 260
            )
        }
    }
}
