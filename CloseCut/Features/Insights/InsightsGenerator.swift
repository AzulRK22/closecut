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

        return InsightsSummary(
            totalWatchedCount: activeEntries.count,
            savedWatchlistCount: savedItems.count,
            tasteProfile: tasteProfile,
            moodPattern: moodPattern,
            genrePattern: genrePattern,
            watchlistPattern: watchlistPattern,
            rewatchCandidates: rewatchCandidates
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
        } else if let firstTrait = finalTraits.first {
            title = "Your taste leans \(firstTrait.title.lowercased())"
            summary = finalTraits
                .map { $0.title.lowercased() }
                .prefix(3)
                .joined(separator: ", ")
                .capitalizedSentence + " are shaping your CloseCut identity."
        } else {
            title = "Your taste is taking shape"
            summary = "Your watched history and saved picks are starting to reveal patterns."
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

    // MARK: - Helpers

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
}
