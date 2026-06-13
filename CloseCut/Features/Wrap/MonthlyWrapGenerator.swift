//
//  MonthlyWrapGenerator.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

final class MonthlyWrapGenerator {
    func generate(
        period: WrapPeriod,
        entries: [Entry],
        watchlistItems: [WatchlistItem],
        now: Date = Date()
    ) -> WrapSummary {
        let periodEntries = entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmed.isEmpty == false }
            .filter { period.contains($0.watchedAt) }
            .sorted { $0.watchedAt > $1.watchedAt }

        let periodSavedItems = watchlistItems
            .filter { $0.deletedAt == nil }
            .filter { $0.status == .saved }
            .filter { period.contains($0.createdAt) }
            .sorted { $0.createdAt > $1.createdAt }

        return buildSummary(
            period: period,
            entries: periodEntries,
            watchlistItems: periodSavedItems,
            now: now
        )
    }

    func generateAllTime(
        entries: [Entry],
        watchlistItems: [WatchlistItem],
        now: Date = Date()
    ) -> WrapSummary? {
        guard let period = WrapPeriodFactory.allTime(
            entries: entries,
            now: now
        ) else {
            return nil
        }

        let activeEntries = entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmed.isEmpty == false }
            .sorted { $0.watchedAt > $1.watchedAt }

        let savedItems = watchlistItems
            .filter { $0.deletedAt == nil }
            .filter { $0.status == .saved }
            .sorted { $0.createdAt > $1.createdAt }

        return buildSummary(
            period: period,
            entries: activeEntries,
            watchlistItems: savedItems,
            now: now
        )
    }

    // MARK: - Build

    private func buildSummary(
        period: WrapPeriod,
        entries: [Entry],
        watchlistItems: [WatchlistItem],
        now: Date
    ) -> WrapSummary {
        let watchedCount = entries.count
        let movieCount = entries.filter { $0.type == .movie }.count
        let seriesCount = entries.filter { $0.type == .series }.count

        let sharedCount = entries.filter {
            $0.visibility == .circle &&
            $0.sharedCircleIds.isEmpty == false
        }.count

        let cinemaCount = entries.filter {
            $0.watchContext == .cinema
        }.count

        let quickAddCount = entries.filter {
            $0.sourceType == .quickAdd
        }.count

        let fullEntryCount = entries.filter {
            $0.sourceType == .fullEntry
        }.count

        let intensityValues = entries
            .map { $0.intensity }
            .filter { $0 > 0 }

        let averageIntensity: Double

        if intensityValues.isEmpty {
            averageIntensity = 0
        } else {
            averageIntensity = Double(intensityValues.reduce(0, +)) / Double(intensityValues.count)
        }

        let highIntensityCount = entries.filter {
            $0.intensity >= 4
        }.count

        let topGenres = buildGenreItems(
            entries: entries,
            total: max(watchedCount, 1)
        )

        let savedGenres = buildSavedGenreItems(
            items: watchlistItems,
            total: max(watchlistItems.count, 1)
        )

        let moodSignals = buildMoodSignals(
            entries: entries,
            total: max(watchedCount, 1)
        )

        let watchContexts = buildWatchContextItems(
            entries: entries,
            total: max(watchedCount, 1)
        )

        let topEntry = buildTopEntry(
            entries: entries
        )

        let strongestEntry = buildStrongestEntry(
            entries: entries
        )

        let posterHighlights = buildPosterHighlights(
            entries: entries
        )

        let emotionalCopy = buildEmotionalCopy(
            period: period,
            watchedCount: watchedCount,
            savedCount: watchlistItems.count,
            movieCount: movieCount,
            seriesCount: seriesCount,
            cinemaCount: cinemaCount,
            averageIntensity: averageIntensity,
            topGenre: topGenres.first,
            dominantMood: moodSignals.first
        )

        return WrapSummary(
            period: period,
            watchedCount: watchedCount,
            movieCount: movieCount,
            seriesCount: seriesCount,
            savedCount: watchlistItems.count,
            sharedCount: sharedCount,
            cinemaCount: cinemaCount,
            quickAddCount: quickAddCount,
            fullEntryCount: fullEntryCount,
            topGenres: topGenres,
            savedGenres: savedGenres,
            moodSignals: moodSignals,
            watchContexts: watchContexts,
            dominantMood: moodSignals.first,
            topGenre: topGenres.first,
            topEntry: topEntry,
            strongestEntry: strongestEntry,
            posterHighlights: posterHighlights,
            averageIntensity: averageIntensity,
            highIntensityCount: highIntensityCount,
            emotionalTitle: emotionalCopy.title,
            emotionalSummary: emotionalCopy.summary,
            shareTitle: emotionalCopy.shareTitle
        )
    }

    // MARK: - Genres

    private func buildGenreItems(
        entries: [Entry],
        total: Int
    ) -> [WrapRankedItem] {
        let genreNames = entries.flatMap { entry in
            TMDBGenreResolver.names(
                for: entry.tmdbGenreIds,
                type: entry.type
            )
        }

        return buildRankedItems(
            values: genreNames,
            total: total,
            iconProvider: { _ in "sparkles.rectangle.stack.fill" }
        )
    }

    private func buildSavedGenreItems(
        items: [WatchlistItem],
        total: Int
    ) -> [WrapRankedItem] {
        let genreNames = items.flatMap { item in
            TMDBGenreResolver.names(
                for: item.tmdbGenreIds,
                type: item.type
            )
        }

        return buildRankedItems(
            values: genreNames,
            total: total,
            iconProvider: { _ in "bookmark.fill" }
        )
    }

    // MARK: - Mood

    private func buildMoodSignals(
        entries: [Entry],
        total: Int
    ) -> [WrapRankedItem] {
        let values = entries.compactMap { entry -> String? in
            if let sentiment = entry.quickSentiment {
                return sentiment.displayName
            }

            let mood = entry.mood.trimmed
            return mood.isEmpty ? nil : mood
        }

        return buildRankedItems(
            values: values,
            total: total,
            iconProvider: { value in
                let lowered = value.lowercased()

                if lowered.contains("love") {
                    return "heart.fill"
                }

                if lowered.contains("stay") {
                    return "sparkles"
                }

                if lowered.contains("not") || lowered.contains("no") {
                    return "hand.thumbsdown.fill"
                }

                if lowered.contains("mixed") || lowered.contains("maybe") {
                    return "circle.lefthalf.filled"
                }

                return "face.smiling.fill"
            }
        )
    }

    // MARK: - Watch Context

    private func buildWatchContextItems(
        entries: [Entry],
        total: Int
    ) -> [WrapRankedItem] {
        let values = entries.map {
            $0.watchContext.rawValue.readableIdentifier
        }

        return buildRankedItems(
            values: values,
            total: total,
            iconProvider: { value in
                let lowered = value.lowercased()

                if lowered.contains("cinema") || lowered.contains("theater") {
                    return "popcorn.fill"
                }

                if lowered.contains("home") {
                    return "house.fill"
                }

                if lowered.contains("travel") {
                    return "airplane"
                }

                return "play.rectangle.fill"
            }
        )
    }

    // MARK: - Entry Highlights

    private func buildTopEntry(
        entries: [Entry]
    ) -> WrapEntryHighlight? {
        entries
            .sorted { first, second in
                scoreEntry(first) > scoreEntry(second)
            }
            .first
            .map { entry in
                WrapEntryHighlight(
                    id: entry.id,
                    entryId: entry.id,
                    title: entry.displayTitle,
                    subtitle: entry.metadataText,
                    reason: topEntryReason(for: entry),
                    posterPath: entry.posterPath,
                    intensity: entry.intensity
                )
            }
    }

    private func buildStrongestEntry(
        entries: [Entry]
    ) -> WrapEntryHighlight? {
        entries
            .filter { entry in
                entry.intensity >= 4 ||
                entry.quickSentiment == .loved ||
                entry.quickSentiment == .stayedWithMe
            }
            .sorted { first, second in
                scoreEntry(first) > scoreEntry(second)
            }
            .first
            .map { entry in
                WrapEntryHighlight(
                    id: entry.id,
                    entryId: entry.id,
                    title: entry.displayTitle,
                    subtitle: entry.metadataText,
                    reason: strongestEntryReason(for: entry),
                    posterPath: entry.posterPath,
                    intensity: entry.intensity
                )
            }
    }

    private func buildPosterHighlights(
        entries: [Entry]
    ) -> [WrapPosterHighlight] {
        entries
            .filter { $0.posterPath?.trimmed.nilIfBlank != nil }
            .sorted { first, second in
                scoreEntry(first) > scoreEntry(second)
            }
            .prefix(6)
            .map { entry in
                WrapPosterHighlight(
                    id: entry.id,
                    title: entry.displayTitle,
                    posterPath: entry.posterPath,
                    type: entry.type
                )
            }
    }

    private func scoreEntry(
        _ entry: Entry
    ) -> Int {
        var score = 0

        if entry.quickSentiment == .loved {
            score += 35
        }

        if entry.quickSentiment == .stayedWithMe {
            score += 30
        }

        if entry.intensity >= 4 {
            score += 20
        }

        if entry.takeaway.trimmed.isEmpty == false {
            score += 12
        }

        if entry.quote?.trimmed.nilIfBlank != nil {
            score += 8
        }

        if (entry.tmdbRating ?? 0) >= 7.5 {
            score += 8
        }

        if entry.posterPath?.trimmed.nilIfBlank != nil {
            score += 5
        }

        return score
    }

    private func topEntryReason(
        for entry: Entry
    ) -> String {
        if entry.quickSentiment == .loved {
            return "You loved this one."
        }

        if entry.quickSentiment == .stayedWithMe {
            return "This one stayed with you."
        }

        if entry.intensity >= 4 {
            return "It had one of your strongest signals."
        }

        return "It was one of the clearest memories from this period."
    }

    private func strongestEntryReason(
        for entry: Entry
    ) -> String {
        if entry.quickSentiment == .stayedWithMe {
            return "The one that stayed with you."
        }

        if entry.quickSentiment == .loved {
            return "The one you loved most."
        }

        if entry.intensity >= 4 {
            return "One of your most intense watches."
        }

        return "One of your strongest memories."
    }

    // MARK: - Emotional Copy

    private func buildEmotionalCopy(
        period: WrapPeriod,
        watchedCount: Int,
        savedCount: Int,
        movieCount: Int,
        seriesCount: Int,
        cinemaCount: Int,
        averageIntensity: Double,
        topGenre: WrapRankedItem?,
        dominantMood: WrapRankedItem?
    ) -> (title: String, summary: String, shareTitle: String) {
        if watchedCount == 0 && savedCount == 0 {
            return (
                "Your stories are waiting",
                "Add watches or save titles to unlock your next Wrap.",
                period.title
            )
        }

        if watchedCount == 0 && savedCount > 0 {
            return (
                "A month of saving for later",
                "You saved \(savedCount) titles for the right moment.",
                period.title
            )
        }

        if let dominantMood {
            let loweredMood = dominantMood.title.lowercased()

            if loweredMood.contains("stay") {
                return (
                    "A month that lingered",
                    "Your strongest signal was \(dominantMood.title), with stories that stayed with you after watching.",
                    period.title
                )
            }

            if loweredMood.contains("love") {
                return (
                    "A month of favorites",
                    "Your strongest signal was \(dominantMood.title), with stories you clearly connected with.",
                    period.title
                )
            }
        }

        if averageIntensity >= 4 {
            return (
                "An intense watch month",
                "Your watches carried a strong emotional signal, with an average intensity of \(String(format: "%.1f", averageIntensity))/5.",
                period.title
            )
        }

        if cinemaCount >= 2 {
            return (
                "A cinematic month",
                "\(cinemaCount) cinema watches helped shape this period.",
                period.title
            )
        }

        if seriesCount > movieCount {
            return (
                "A long-form month",
                "Series led your viewing this period, with \(seriesCount) shows in your history.",
                period.title
            )
        }

        if let topGenre {
            return (
                "A \(topGenre.title.lowercased())-leaning month",
                "\(topGenre.title) showed up more than anything else in your watch history.",
                period.title
            )
        }

        return (
            "Your month in stories",
            "You watched \(watchedCount) \(watchedCount == 1 ? "story" : "stories") and kept building your private taste archive.",
            period.title
        )
    }

    // MARK: - Generic Helpers

    private func buildRankedItems(
        values: [String],
        total: Int,
        iconProvider: (String) -> String
    ) -> [WrapRankedItem] {
        let grouped = Dictionary(grouping: values, by: { $0 })

        return grouped
            .map { value, groupedValues in
                WrapRankedItem(
                    id: value.normalizedTitleKey,
                    title: value,
                    count: groupedValues.count,
                    percentage: percentage(
                        count: groupedValues.count,
                        total: total
                    ),
                    systemImage: iconProvider(value)
                )
            }
            .sorted { first, second in
                if first.count != second.count {
                    return first.count > second.count
                }

                return first.title < second.title
            }
            .prefix(5)
            .map { $0 }
    }

    private func percentage(
        count: Int,
        total: Int
    ) -> Double {
        guard total > 0 else {
            return 0
        }

        return (Double(count) / Double(total)) * 100
    }
}

private extension String {
    var readableIdentifier: String {
        replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalizedSentence
    }

    var capitalizedSentence: String {
        guard let first else {
            return self
        }

        return String(first).uppercased() + dropFirst()
    }
}
