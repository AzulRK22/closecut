//
//  InsightsGenerator.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

final class InsightsGenerator {
    func generate(
        entries: [Entry],
        watchlistItems: [WatchlistItem],
        now: Date = Date()
    ) -> InsightsSummary {
        let activeEntries = entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmed.isEmpty == false }

        let savedItems = watchlistItems
            .filter { $0.deletedAt == nil }
            .filter { $0.status == .saved }

        let overviewStats = buildOverviewStats(
            entries: activeEntries,
            watchlistItems: savedItems
        )

        let tasteProfile = buildTasteProfile(
            entries: activeEntries,
            watchlistItems: savedItems
        )

        let moodPattern = buildMoodPattern(
            entries: activeEntries
        )

        let genrePattern = buildGenrePattern(
            entries: activeEntries,
            watchlistItems: savedItems
        )

        let watchlistPattern = buildWatchlistPattern(
            watchlistItems: savedItems
        )

        let rewatchCandidates = buildRewatchCandidates(
            entries: activeEntries,
            now: now
        )

        let mediaTypeBreakdown = buildMediaTypeBreakdown(
            overviewStats: overviewStats
        )

        let moodBreakdown = buildMoodBreakdown(
            entries: activeEntries
        )

        let watchContextBreakdown = buildWatchContextBreakdown(
            entries: activeEntries
        )

        let intensityInsight = buildIntensityInsight(
            entries: activeEntries,
            overviewStats: overviewStats
        )

        return InsightsSummary(
            overviewStats: overviewStats,
            totalWatchedCount: activeEntries.count,
            savedWatchlistCount: savedItems.count,
            tasteProfile: tasteProfile,
            moodPattern: moodPattern,
            genrePattern: genrePattern,
            watchlistPattern: watchlistPattern,
            rewatchCandidates: rewatchCandidates,
            mediaTypeBreakdown: mediaTypeBreakdown,
            moodBreakdown: moodBreakdown,
            watchContextBreakdown: watchContextBreakdown,
            intensityInsight: intensityInsight
        )
    }

    // MARK: - Overview

    private func buildOverviewStats(
        entries: [Entry],
        watchlistItems: [WatchlistItem]
    ) -> InsightOverviewStats {
        let movieCount = entries.filter { $0.type == .movie }.count
        let seriesCount = entries.filter { $0.type == .series }.count

        let quickAddCount = entries.filter { $0.sourceType == .quickAdd }.count
        let fullEntryCount = entries.filter { $0.sourceType == .fullEntry }.count

        let sharedMemoryCount = entries.filter {
            $0.visibility == .circle &&
            $0.sharedCircleIds.isEmpty == false
        }.count

        let cinemaWatchCount = entries.filter {
            $0.watchContext == .cinema
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

        let highIntensityCount = entries.filter { $0.intensity >= 4 }.count

        return InsightOverviewStats(
            watchedCount: entries.count,
            movieCount: movieCount,
            seriesCount: seriesCount,
            savedCount: watchlistItems.count,
            quickAddCount: quickAddCount,
            fullEntryCount: fullEntryCount,
            sharedMemoryCount: sharedMemoryCount,
            cinemaWatchCount: cinemaWatchCount,
            averageIntensity: averageIntensity,
            highIntensityCount: highIntensityCount
        )
    }

    // MARK: - Taste Profile

    private func buildTasteProfile(
        entries: [Entry],
        watchlistItems: [WatchlistItem]
    ) -> TasteProfileInsight {
        guard entries.isEmpty == false || watchlistItems.isEmpty == false else {
            return TasteProfileInsight(
                title: "Your taste is ready to take shape",
                summary: "Add a few watched titles or saved picks and CloseCut will start finding your taste patterns.",
                traits: []
            )
        }

        var traits: [TasteTrait] = []

        let emotionalEntries = entries.filter { entry in
            entry.quickSentiment == .loved ||
            entry.quickSentiment == .stayedWithMe ||
            entry.intensity >= 4
        }

        if emotionalEntries.count >= max(2, entries.count / 3) {
            traits.append(
                TasteTrait(
                    id: "emotionally-intense",
                    title: "Emotionally intense",
                    subtitle: "Strong reactions show up often in your history.",
                    systemImage: "heart.text.square.fill"
                )
            )
        }

        let rewatchSignals = entries.filter { entry in
            entry.quickSentiment == .loved ||
            entry.tags.contains("rewatch") ||
            entry.tags.contains("comfort") ||
            entry.tags.contains("favorite")
        }

        if rewatchSignals.count >= 2 {
            traits.append(
                TasteTrait(
                    id: "rewatch-friendly",
                    title: "Rewatch-friendly",
                    subtitle: "Some stories look like they are worth coming back to.",
                    systemImage: "arrow.clockwise.heart.fill"
                )
            )
        }

        let cinemaEntries = entries.filter { $0.watchContext == .cinema }

        if cinemaEntries.count >= 2 {
            traits.append(
                TasteTrait(
                    id: "cinema-first",
                    title: "Cinema-first moments",
                    subtitle: "The theater experience is part of your taste history.",
                    systemImage: "popcorn.fill"
                )
            )
        }

        let seriesItems = entries.filter { $0.type == .series }.count +
            watchlistItems.filter { $0.type == .series }.count

        if seriesItems >= 3 {
            traits.append(
                TasteTrait(
                    id: "series-explorer",
                    title: "Series explorer",
                    subtitle: "Long-form stories have a meaningful place in your library.",
                    systemImage: "tv.fill"
                )
            )
        }

        let genreCounts = countGenres(
            fromEntries: entries,
            fromWatchlist: watchlistItems
        )

        if let topGenre = genreCounts.first, topGenre.count >= 3 {
            traits.append(
                TasteTrait(
                    id: "genre-signal-\(topGenre.name)",
                    title: "\(topGenre.name) signal",
                    subtitle: "This genre keeps appearing across your taste.",
                    systemImage: "sparkles.rectangle.stack.fill"
                )
            )
        }

        let finalTraits = Array(traits.prefix(4))

        let title: String
        let summary: String

        if finalTraits.isEmpty {
            title = "Your taste is still forming"
            summary = "CloseCut found early signals, but a few more watched titles will make your profile sharper."
        } else {
            let signature = finalTraits
                .map { $0.title.lowercased() }
                .prefix(3)
                .joined(separator: ", ")

            title = "Your taste signature is forming"
            summary = "\(signature.capitalizedSentence) are shaping your CloseCut identity."
        }

        return TasteProfileInsight(
            title: title,
            summary: summary,
            traits: finalTraits
        )
    }

    // MARK: - Mood

    private func buildMoodPattern(
        entries: [Entry]
    ) -> MoodPatternInsight {
        guard entries.isEmpty == false else {
            return MoodPatternInsight(
                title: "No mood pattern yet",
                summary: "Log a few watches with moods or reactions to reveal your emotional pattern.",
                dominantMood: nil,
                dominantSentiment: nil,
                emotionalSignalCount: 0
            )
        }

        let moods = entries
            .map { $0.mood.trimmed }
            .filter { $0.isEmpty == false }

        let dominantMood = mostCommonString(moods)

        let sentiments = entries
            .compactMap { $0.quickSentiment?.displayName }

        let dominantSentiment = mostCommonString(sentiments)

        let emotionalSignalCount = entries.filter { entry in
            entry.quickSentiment == .loved ||
            entry.quickSentiment == .stayedWithMe ||
            entry.intensity >= 4 ||
            entry.takeaway.trimmed.isEmpty == false
        }.count

        let title: String
        let summary: String

        if let dominantMood {
            title = "Your strongest mood is \(dominantMood)"
            summary = "This mood shows up repeatedly in your personal history."
        } else if let dominantSentiment {
            title = "\(dominantSentiment) is your strongest signal"
            summary = "Your quick reactions are already revealing what stays with you."
        } else if emotionalSignalCount > 0 {
            title = "Your emotional signal is building"
            summary = "\(emotionalSignalCount) watches have enough personal signal to shape future recommendations."
        } else {
            title = "Mood patterns need more detail"
            summary = "Add moods, notes, or quick reactions to make this insight more personal."
        }

        return MoodPatternInsight(
            title: title,
            summary: summary,
            dominantMood: dominantMood,
            dominantSentiment: dominantSentiment,
            emotionalSignalCount: emotionalSignalCount
        )
    }

    private func buildMoodBreakdown(
        entries: [Entry]
    ) -> MoodBreakdownInsight {
        let sentimentValues = entries.compactMap { entry -> String? in
            if let quickSentiment = entry.quickSentiment {
                return quickSentiment.displayName
            }

            let mood = entry.mood.trimmed
            return mood.isEmpty ? nil : mood
        }

        let items = buildBreakdownItems(
            values: sentimentValues,
            total: max(sentimentValues.count, entries.count),
            iconProvider: { value in
                let lowered = value.lowercased()

                if lowered.contains("love") {
                    return "heart.fill"
                }

                if lowered.contains("stay") {
                    return "sparkles"
                }

                if lowered.contains("no") || lowered.contains("not") {
                    return "hand.thumbsdown.fill"
                }

                if lowered.contains("mixed") || lowered.contains("maybe") {
                    return "circle.lefthalf.filled"
                }

                return "face.smiling.fill"
            }
        )

        let title: String
        let summary: String

        if let top = items.first {
            title = "\(top.title) leads your reactions"
            summary = "Your emotional pattern is strongest around \(top.title.lowercased())."
        } else {
            title = "No reaction breakdown yet"
            summary = "Add quick reactions, moods, or takeaways to make this chart meaningful."
        }

        return MoodBreakdownInsight(
            title: title,
            summary: summary,
            items: items
        )
    }

    // MARK: - Genres

    private func buildGenrePattern(
        entries: [Entry],
        watchlistItems: [WatchlistItem]
    ) -> GenrePatternInsight {
        let watchedGenres = countEntryGenres(entries)
        let watchlistGenres = countWatchlistGenres(watchlistItems)

        let watchedNames = Set(watchedGenres.map { $0.name })
        let watchlistNames = Set(watchlistGenres.map { $0.name })

        let overlapGenres = Array(watchedNames.intersection(watchlistNames))
            .sorted()

        let title: String
        let summary: String

        if let topWatched = watchedGenres.first {
            title = "\(topWatched.name) leads your watched history"

            if overlapGenres.isEmpty == false {
                summary = "\(overlapGenres.prefix(2).joined(separator: " and ")) appear in both your watched history and saved picks."
            } else {
                summary = "Your watched history has a clear \(topWatched.name.lowercased()) signal."
            }
        } else if let topSaved = watchlistGenres.first {
            title = "\(topSaved.name) is waiting in your watchlist"
            summary = "Your saved titles are already giving CloseCut a direction."
        } else {
            title = "Genre patterns need more metadata"
            summary = "Refresh or add TMDB metadata to reveal stronger genre patterns."
        }

        return GenrePatternInsight(
            title: title,
            summary: summary,
            watchedGenres: watchedGenres,
            watchlistGenres: watchlistGenres,
            overlapGenres: overlapGenres
        )
    }

    // MARK: - Media Type

    private func buildMediaTypeBreakdown(
        overviewStats: InsightOverviewStats
    ) -> MediaTypeBreakdownInsight {
        let total = max(overviewStats.watchedCount, 1)

        let items = [
            InsightBreakdownItem(
                id: "movies",
                title: "Movies",
                subtitle: "Watched films",
                count: overviewStats.movieCount,
                percentage: percentage(
                    count: overviewStats.movieCount,
                    total: total
                ),
                systemImage: "film.fill"
            ),
            InsightBreakdownItem(
                id: "series",
                title: "Series",
                subtitle: "Watched shows",
                count: overviewStats.seriesCount,
                percentage: percentage(
                    count: overviewStats.seriesCount,
                    total: total
                ),
                systemImage: "tv.fill"
            )
        ]

        let title: String
        let summary: String

        if overviewStats.watchedCount == 0 {
            title = "No watched titles yet"
            summary = "Add movies or series to start building your visual taste profile."
        } else if overviewStats.movieCount > overviewStats.seriesCount {
            title = "Your library leans movie-first"
            summary = "\(overviewStats.movieCount) of your watched stories are movies."
        } else if overviewStats.seriesCount > overviewStats.movieCount {
            title = "Your library leans series-first"
            summary = "\(overviewStats.seriesCount) of your watched stories are series."
        } else {
            title = "Your library is balanced"
            summary = "Movies and series are showing up evenly in your history."
        }

        return MediaTypeBreakdownInsight(
            title: title,
            summary: summary,
            items: items
        )
    }

    // MARK: - Watch Context

    private func buildWatchContextBreakdown(
        entries: [Entry]
    ) -> WatchContextBreakdownInsight {
        let values = entries.map { entry in
            entry.watchContext.rawValue.readableIdentifier
        }

        let items = buildBreakdownItems(
            values: values,
            total: max(entries.count, 1),
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

        let title: String
        let summary: String

        if let top = items.first {
            title = "\(top.title) is your main watch context"
            summary = "\(top.count) watches happened in this context."
        } else {
            title = "No watch context yet"
            summary = "Log where you watch to unlock better context insights."
        }

        return WatchContextBreakdownInsight(
            title: title,
            summary: summary,
            items: items
        )
    }

    // MARK: - Intensity

    private func buildIntensityInsight(
        entries: [Entry],
        overviewStats: InsightOverviewStats
    ) -> IntensityInsight {
        let signalCount = entries.filter {
            $0.intensity > 0 ||
            $0.quickSentiment != nil ||
            $0.takeaway.trimmed.isEmpty == false
        }.count

        let title: String
        let summary: String

        if overviewStats.averageIntensity >= 4 {
            title = "Your watches leave a strong impression"
            summary = "Your average intensity is \(overviewStats.averageIntensityText), with \(overviewStats.highIntensityCount) high-intensity memories."
        } else if overviewStats.averageIntensity > 0 {
            title = "Your emotional intensity is building"
            summary = "Your average intensity is \(overviewStats.averageIntensityText). Add more reactions to sharpen this signal."
        } else {
            title = "No intensity signal yet"
            summary = "Add intensity ratings or quick reactions to reveal what hits hardest."
        }

        return IntensityInsight(
            title: title,
            summary: summary,
            averageIntensity: overviewStats.averageIntensity,
            highIntensityCount: overviewStats.highIntensityCount,
            totalSignalCount: signalCount
        )
    }

    // MARK: - Watchlist

    private func buildWatchlistPattern(
        watchlistItems: [WatchlistItem]
    ) -> WatchlistPatternInsight {
        let movieCount = watchlistItems.filter { $0.type == .movie }.count
        let seriesCount = watchlistItems.filter { $0.type == .series }.count

        let topGenres = countWatchlistGenres(watchlistItems)

        let oldestSavedTitle = watchlistItems
            .sorted { $0.createdAt < $1.createdAt }
            .first?
            .displayTitle

        let highestRatedTitle = watchlistItems
            .filter { ($0.tmdbRating ?? 0) > 0 }
            .sorted { ($0.tmdbRating ?? 0) > ($1.tmdbRating ?? 0) }
            .first?
            .displayTitle

        let title: String
        let summary: String

        if watchlistItems.isEmpty {
            title = "Your watchlist is empty"
            summary = "Save titles from Discover to build future taste patterns."
        } else if movieCount > seriesCount {
            title = "Your watchlist leans movie-first"
            summary = topGenres.first.map {
                "You are saving mostly movies, with \($0.name) showing up the most."
            } ?? "You are saving mostly movies for later."
        } else if seriesCount > movieCount {
            title = "Your watchlist leans series-first"
            summary = topGenres.first.map {
                "You are saving more series, with \($0.name) appearing most often."
            } ?? "You are saving more series for later."
        } else {
            title = "Your watchlist is balanced"
            summary = "Movies and series are both part of what you want to watch next."
        }

        return WatchlistPatternInsight(
            title: title,
            summary: summary,
            savedCount: watchlistItems.count,
            movieCount: movieCount,
            seriesCount: seriesCount,
            topGenres: topGenres,
            oldestSavedTitle: oldestSavedTitle,
            highestRatedTitle: highestRatedTitle
        )
    }

    // MARK: - Rewatch

    private func buildRewatchCandidates(
        entries: [Entry],
        now: Date
    ) -> [RewatchCandidateInsight] {
        entries
            .compactMap { entry -> RewatchCandidateInsight? in
                let daysSinceWatch = Calendar.current.dateComponents(
                    [.day],
                    from: entry.watchedAt,
                    to: now
                ).day ?? 0

                guard daysSinceWatch >= 120 else {
                    return nil
                }

                var score = 0
                var reasons: [String] = []

                if entry.quickSentiment == .loved {
                    score += 35
                    reasons.append("you loved it")
                }

                if entry.quickSentiment == .stayedWithMe {
                    score += 30
                    reasons.append("it stayed with you")
                }

                if entry.intensity >= 4 {
                    score += 20
                    reasons.append("it had a strong emotional signal")
                }

                if (entry.tmdbRating ?? 0) >= 7.5 {
                    score += 15
                    reasons.append("it has a strong TMDB rating")
                }

                if entry.tags.contains("comfort") ||
                    entry.tags.contains("favorite") ||
                    entry.tags.contains("rewatch") {
                    score += 25
                    reasons.append("your tags suggest it is worth revisiting")
                }

                guard score > 0 else {
                    return nil
                }

                let reason = reasons.first ?? "it has been a while"

                return RewatchCandidateInsight(
                    id: entry.id,
                    entryId: entry.id,
                    title: entry.displayTitle,
                    subtitle: entry.metadataText,
                    reason: "Worth revisiting because \(reason).",
                    score: score,
                    posterPath: entry.posterPath
                )
            }
            .sorted { first, second in
                first.score > second.score
            }
            .prefix(6)
            .map { $0 }
    }

    // MARK: - Genre Helpers

    private func countEntryGenres(
        _ entries: [Entry]
    ) -> [GenreCount] {
        let names = entries.flatMap { entry in
            TMDBGenreResolver.names(
                for: entry.tmdbGenreIds,
                type: entry.type
            )
        }

        return countGenreNames(names)
    }

    private func countWatchlistGenres(
        _ items: [WatchlistItem]
    ) -> [GenreCount] {
        let names = items.flatMap { item in
            TMDBGenreResolver.names(
                for: item.tmdbGenreIds,
                type: item.type
            )
        }

        return countGenreNames(names)
    }

    private func countGenres(
        fromEntries entries: [Entry],
        fromWatchlist watchlistItems: [WatchlistItem]
    ) -> [GenreCount] {
        countGenreNames(
            entries.flatMap { TMDBGenreResolver.names(for: $0.tmdbGenreIds, type: $0.type) } +
            watchlistItems.flatMap { TMDBGenreResolver.names(for: $0.tmdbGenreIds, type: $0.type) }
        )
    }

    private func countGenreNames(
        _ names: [String]
    ) -> [GenreCount] {
        let grouped = Dictionary(grouping: names, by: { $0 })

        return grouped
            .map { name, values in
                GenreCount(
                    id: abs(name.hashValue),
                    name: name,
                    count: values.count
                )
            }
            .sorted { first, second in
                if first.count != second.count {
                    return first.count > second.count
                }

                return first.name < second.name
            }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Generic Breakdown Helpers

    private func buildBreakdownItems(
        values: [String],
        total: Int,
        iconProvider: (String) -> String
    ) -> [InsightBreakdownItem] {
        let grouped = Dictionary(grouping: values, by: { $0 })

        return grouped
            .map { value, groupedValues in
                InsightBreakdownItem(
                    id: value.normalizedTitleKey,
                    title: value,
                    subtitle: nil,
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

    private func mostCommonString(
        _ values: [String]
    ) -> String? {
        Dictionary(grouping: values, by: { $0 })
            .map { value, groupedValues in
                (value: value, count: groupedValues.count)
            }
            .sorted { first, second in
                if first.count != second.count {
                    return first.count > second.count
                }

                return first.value < second.value
            }
            .first?
            .value
    }
}

private extension String {
    var capitalizedSentence: String {
        guard let first else {
            return self
        }

        return String(first).uppercased() + dropFirst()
    }

    var readableIdentifier: String {
        replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalizedSentence
    }
}
