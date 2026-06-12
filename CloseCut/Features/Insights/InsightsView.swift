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
                    VStack(alignment: .leading, spacing: 18) {
                        headerSection

                        if summary.hasEnoughData {
                            tasteProfileSection

                            moodPatternSection

                            genrePatternSection

                            rewatchCandidatesSection

                            watchlistPatternSection

                            privacySection
                        } else {
                            earlyStateSection

                            tasteProfileSection

                            watchlistPatternSection

                            privacySection
                        }

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

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(CloseCutColors.accent.opacity(0.18))
                    .frame(width: 54, height: 54)

                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Your taste is taking shape.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("CloseCut reads your private history locally to find patterns in what you watch, save, feel, and revisit.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                metricPill(
                    value: "\(summary.totalWatchedCount)",
                    label: "Watched"
                )

                metricPill(
                    value: "\(summary.savedWatchlistCount)",
                    label: "Saved"
                )
            }
        }
        .padding(18)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func metricPill(
        value: String,
        label: String
    ) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(CloseCutColors.input.opacity(0.8))
        .clipShape(Capsule())
    }

    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.cardElevated,
                    CloseCutColors.card,
                    CloseCutColors.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.16),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 250
            )
        }
    }

    // MARK: - Early State

    private var earlyStateSection: some View {
        insightCard(
            title: "Add a few more signals",
            icon: "chart.line.uptrend.xyaxis"
        ) {
            Text("Insights get sharper after a few watched titles, saved picks, moods, or quick reactions. Your data stays private and local.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Taste

    private var tasteProfileSection: some View {
        insightCard(
            title: "Taste Profile",
            icon: "person.crop.square.filled.and.at.rectangle"
        ) {
            VStack(alignment: .leading, spacing: 13) {
                Text(summary.tasteProfile.title)
                    .font(.headline.weight(.semibold))
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
                    .padding(.top, 2)
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

    // MARK: - Mood

    private var moodPatternSection: some View {
        insightCard(
            title: "Mood Patterns",
            icon: "heart.text.square.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(summary.moodPattern.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary.moodPattern.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    if let dominantMood = summary.moodPattern.dominantMood {
                        miniMetricRow(
                            icon: "face.smiling.fill",
                            title: "Dominant mood",
                            value: dominantMood
                        )
                    }

                    if let dominantSentiment = summary.moodPattern.dominantSentiment {
                        miniMetricRow(
                            icon: "bolt.heart.fill",
                            title: "Dominant reaction",
                            value: dominantSentiment
                        )
                    }

                    miniMetricRow(
                        icon: "waveform.path.ecg",
                        title: "Emotional signals",
                        value: "\(summary.moodPattern.emotionalSignalCount)"
                    )
                }
            }
        }
    }

    // MARK: - Genre

    private var genrePatternSection: some View {
        insightCard(
            title: "Genre Patterns",
            icon: "square.stack.3d.up.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(summary.genrePattern.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary.genrePattern.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if summary.genrePattern.watchedGenres.isEmpty == false {
                    genreList(
                        title: "Watched",
                        genres: summary.genrePattern.watchedGenres
                    )
                }

                if summary.genrePattern.watchlistGenres.isEmpty == false {
                    genreList(
                        title: "Saved",
                        genres: summary.genrePattern.watchlistGenres
                    )
                }

                if summary.genrePattern.overlapGenres.isEmpty == false {
                    Text("Overlap: \(summary.genrePattern.overlapGenres.prefix(3).joined(separator: ", "))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CloseCutColors.input.opacity(0.74))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
            }
        }
    }

    private func genreList(
        title: String,
        genres: [GenreCount]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)

            FlowLayout(spacing: 8) {
                ForEach(genres) { genre in
                    Text("\(genre.name) \(genre.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(CloseCutColors.input)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Rewatch

    private var rewatchCandidatesSection: some View {
        insightCard(
            title: "Rewatch Candidates",
            icon: "arrow.clockwise.heart.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if summary.rewatchCandidates.isEmpty {
                    Text("No strong rewatch candidates yet.")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("CloseCut looks for older watches with strong emotional signals, high ratings, or tags like comfort, favorite, or rewatch.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(summary.rewatchCandidates.prefix(4)) { candidate in
                        rewatchCandidateRow(candidate)

                        if candidate.id != summary.rewatchCandidates.prefix(4).last?.id {
                            Divider()
                                .overlay(CloseCutColors.separator)
                        }
                    }
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
                    size: .posterSmall
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

    private var watchlistPatternSection: some View {
        insightCard(
            title: "Watchlist Patterns",
            icon: "bookmark.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(summary.watchlistPattern.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary.watchlistPattern.summary)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    miniMetricRow(
                        icon: "film.fill",
                        title: "Movies",
                        value: "\(summary.watchlistPattern.movieCount)"
                    )

                    miniMetricRow(
                        icon: "tv.fill",
                        title: "Series",
                        value: "\(summary.watchlistPattern.seriesCount)"
                    )

                    if let oldestSavedTitle = summary.watchlistPattern.oldestSavedTitle {
                        miniMetricRow(
                            icon: "clock.fill",
                            title: "Oldest saved",
                            value: oldestSavedTitle
                        )
                    }

                    if let highestRatedTitle = summary.watchlistPattern.highestRatedTitle {
                        miniMetricRow(
                            icon: "star.fill",
                            title: "Highest rated saved",
                            value: highestRatedTitle
                        )
                    }
                }
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        insightCard(
            title: "Privacy",
            icon: "lock.fill"
        ) {
            Text("Insights are generated from your local Personal library and saved picks. They are not shared with Circles unless you explicitly share something later.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Components

    private func insightCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 30, height: 30)
                    .background(CloseCutColors.input)
                    .clipShape(Circle())

                Text(title)
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
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func miniMetricRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.7)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 96), spacing: spacing)
            ],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
    }
}
