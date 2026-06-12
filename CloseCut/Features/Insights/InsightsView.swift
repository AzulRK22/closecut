//
//  InsightsView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import SwiftUI

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss

    let entries: [Entry]
    let watchlistItems: [WatchlistItem]

    private var summary: InsightsSummary {
        InsightsGenerator().generate(
            entries: entries,
            watchlistItems: watchlistItems
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heroSection

                        bigStatsGrid

                        tasteSignatureSection

                        mediaTypeSection

                        if summary.genrePattern.watchedGenres.isEmpty == false ||
                            summary.genrePattern.watchlistGenres.isEmpty == false {
                            genreSection
                        }

                        moodSection

                        intensitySection

                        watchContextSection

                        rewatchRadarSection

                        watchlistDirectionSection

                        privacySection

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(CloseCutColors.accent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(CloseCutColors.accent.opacity(0.18))
                        .frame(width: 58, height: 58)

                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Your Taste Dashboard")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("A private visual map of what you watch, save, feel, and revisit.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(summary.overviewStats.watchedCount)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .contentTransition(.numericText())

                Text(summary.overviewStats.watchedLabel)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                Text(summary.overviewStats.movieSeriesText)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            if summary.hasEnoughData == false {
                Text("Add a few more watches or saved picks to make these insights sharper.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CloseCutColors.input.opacity(0.68))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(premiumBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
    }

    private var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.cardElevated,
                    CloseCutColors.card,
                    CloseCutColors.accent.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.18),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 16,
                endRadius: 260
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.12),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 240
            )
        }
    }

    // MARK: - Big Stats

    private var bigStatsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            bigStatCard(
                value: "\(summary.overviewStats.movieCount)",
                title: "Movies",
                subtitle: "watched",
                icon: "film.fill"
            )

            bigStatCard(
                value: "\(summary.overviewStats.seriesCount)",
                title: "Series",
                subtitle: "watched",
                icon: "tv.fill"
            )

            bigStatCard(
                value: "\(summary.overviewStats.savedCount)",
                title: "Saved",
                subtitle: "for later",
                icon: "bookmark.fill"
            )

            bigStatCard(
                value: summary.overviewStats.averageIntensityText,
                title: "Intensity",
                subtitle: "average",
                icon: "waveform.path.ecg"
            )
        }
    }

    private func bigStatCard(
        value: String,
        title: String,
        subtitle: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    // MARK: - Taste Signature

    private var tasteSignatureSection: some View {
        premiumCard(
            eyebrow: "Taste Signature",
            icon: "person.crop.square.filled.and.at.rectangle"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(summary.tasteProfile.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary.tasteProfile.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if summary.tasteProfile.traits.isEmpty == false {
                    VStack(spacing: 10) {
                        ForEach(summary.tasteProfile.traits) { trait in
                            traitRow(trait)
                        }
                    }
                }
            }
        }
    }

    private func traitRow(
        _ trait: TasteTrait
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: trait.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(trait.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(trait.subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Media Type

    private var mediaTypeSection: some View {
        premiumCard(
            eyebrow: "Movies vs Series",
            icon: "rectangle.split.2x1.fill"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(summary.mediaTypeBreakdown.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summary.mediaTypeBreakdown.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                segmentedDistributionBar(
                    items: summary.mediaTypeBreakdown.items
                )

                VStack(spacing: 10) {
                    ForEach(summary.mediaTypeBreakdown.items) { item in
                        breakdownRow(item)
                    }
                }
            }
        }
    }

    private func segmentedDistributionBar(
        items: [InsightBreakdownItem]
    ) -> some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let totalCount = max(items.map { $0.count }.reduce(0, +), 1)

            HStack(spacing: 4) {
                ForEach(items) { item in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(item.id == "movies" ? CloseCutColors.accent : CloseCutColors.accentLight.opacity(0.72))
                        .frame(width: max(8, totalWidth * CGFloat(item.count) / CGFloat(totalCount)))
                }
            }
        }
        .frame(height: 16)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Genres

    private var genreSection: some View {
        premiumCard(
            eyebrow: "Top Genres",
            icon: "square.stack.3d.up.fill"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(summary.genrePattern.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summary.genrePattern.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if summary.genrePattern.watchedGenres.isEmpty == false {
                    barChartSection(
                        title: "Watched",
                        genres: summary.genrePattern.watchedGenres
                    )
                }

                if summary.genrePattern.watchlistGenres.isEmpty == false {
                    barChartSection(
                        title: "Saved for later",
                        genres: summary.genrePattern.watchlistGenres
                    )
                }

                if summary.genrePattern.overlapGenres.isEmpty == false {
                    Text("Overlap: \(summary.genrePattern.overlapGenres.prefix(3).joined(separator: ", "))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CloseCutColors.input.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private func barChartSection(
        title: String,
        genres: [GenreCount]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(spacing: 10) {
                ForEach(genres) { genre in
                    genreBarRow(
                        genre: genre,
                        maxCount: max(genres.map { $0.count }.max() ?? 1, 1)
                    )
                }
            }
        }
    }

    private func genreBarRow(
        genre: GenreCount,
        maxCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(genre.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Spacer()

                Text("\(genre.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(CloseCutColors.input)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(CloseCutColors.accent)
                        .frame(
                            width: proxy.size.width * CGFloat(genre.count) / CGFloat(maxCount)
                        )
                }
            }
            .frame(height: 10)
        }
    }

    // MARK: - Mood

    private var moodSection: some View {
        premiumCard(
            eyebrow: "Emotional Pattern",
            icon: "heart.text.square.fill"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(summary.moodBreakdown.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summary.moodBreakdown.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if summary.moodBreakdown.items.isEmpty {
                    emptyChartText("Add quick reactions or moods to see your emotional breakdown.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(summary.moodBreakdown.items) { item in
                            breakdownRow(item)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Intensity

    private var intensitySection: some View {
        premiumCard(
            eyebrow: "Intensity",
            icon: "waveform.path.ecg"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(summary.intensityInsight.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summary.intensityInsight.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    compactStat(
                        value: summary.overviewStats.averageIntensityText,
                        label: "Average"
                    )

                    compactStat(
                        value: "\(summary.intensityInsight.highIntensityCount)",
                        label: "High intensity"
                    )

                    compactStat(
                        value: "\(summary.intensityInsight.totalSignalCount)",
                        label: "Signals"
                    )
                }
            }
        }
    }

    private func compactStat(
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(CloseCutColors.input.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    // MARK: - Watch Context

    private var watchContextSection: some View {
        premiumCard(
            eyebrow: "Where You Watch",
            icon: "play.rectangle.fill"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(summary.watchContextBreakdown.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summary.watchContextBreakdown.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if summary.watchContextBreakdown.items.isEmpty {
                    emptyChartText("Log watch context to understand where your memories happen.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(summary.watchContextBreakdown.items) { item in
                            breakdownRow(item)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Rewatch

    private var rewatchRadarSection: some View {
        premiumCard(
            eyebrow: "Rewatch Radar",
            icon: "arrow.clockwise.heart.fill"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                if let topCandidate = summary.rewatchCandidates.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(summary.rewatchCandidates.count) titles are worth revisiting")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text("Top pick: \(topCandidate.title)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)

                        Text(topCandidate.reason)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 10) {
                        ForEach(summary.rewatchCandidates.prefix(4)) { candidate in
                            rewatchCandidateRow(candidate)

                            if candidate.id != summary.rewatchCandidates.prefix(4).last?.id {
                                Divider()
                                    .overlay(CloseCutColors.separator)
                            }
                        }
                    }
                } else {
                    Text("No strong rewatch candidates yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("CloseCut looks for older watches with strong emotional signals, high ratings, or tags like comfort, favorite, or rewatch.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func rewatchCandidateRow(
        _ candidate: RewatchCandidateInsight
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(CloseCutColors.input)

                if let url = TMDBImageURLBuilder.imageURL(
                    path: candidate.posterPath,
                    size: .posterMedium
                ) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.65)

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()

                        case .failure:
                            Image(systemName: "film.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CloseCutColors.accentLight)

                        @unknown default:
                            Image(systemName: "film.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CloseCutColors.accentLight)
                        }
                    }
                } else {
                    Image(systemName: "film.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }
            .frame(width: 44, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)

                Text(candidate.subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                Text(candidate.reason)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Watchlist

    private var watchlistDirectionSection: some View {
        premiumCard(
            eyebrow: "Watchlist Direction",
            icon: "bookmark.fill"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(summary.watchlistPattern.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summary.watchlistPattern.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    compactStat(
                        value: "\(summary.watchlistPattern.savedCount)",
                        label: "Saved"
                    )

                    compactStat(
                        value: "\(summary.watchlistPattern.movieCount)",
                        label: "Movies"
                    )

                    compactStat(
                        value: "\(summary.watchlistPattern.seriesCount)",
                        label: "Series"
                    )
                }

                if let highestRatedTitle = summary.watchlistPattern.highestRatedTitle {
                    detailCallout(
                        icon: "star.fill",
                        text: "Highest-rated saved title: \(highestRatedTitle)"
                    )
                }

                if let oldestSavedTitle = summary.watchlistPattern.oldestSavedTitle {
                    detailCallout(
                        icon: "clock.fill",
                        text: "Waiting the longest: \(oldestSavedTitle)"
                    )
                }
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        premiumCard(
            eyebrow: "Private by default",
            icon: "lock.fill"
        ) {
            Text("These insights are generated from your local Personal library and saved picks. They are not shared with Circles unless you explicitly share something later.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Components

    private func premiumCard<Content: View>(
        eyebrow: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 30, height: 30)
                    .background(CloseCutColors.input)
                    .clipShape(Circle())

                Text(eyebrow)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer(minLength: 0)
            }

            content()
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func breakdownRow(
        _ item: InsightBreakdownItem
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 9) {
                Image(systemName: item.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 26, height: 26)
                    .background(CloseCutColors.input)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                }

                Spacer()

                Text("\(item.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(item.percentageText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .frame(width: 38, alignment: .trailing)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(CloseCutColors.input)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(CloseCutColors.accent)
                        .frame(
                            width: proxy.size.width * CGFloat(item.percentage / 100)
                        )
                }
            }
            .frame(height: 9)
        }
    }

    private func emptyChartText(
        _ text: String
    ) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(CloseCutColors.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.input.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func detailCallout(
        icon: String,
        text: String
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 2)

            Text(text)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
