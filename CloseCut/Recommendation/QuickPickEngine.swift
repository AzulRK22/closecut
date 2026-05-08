//
//  QuickPickEngine.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

@MainActor
final class QuickPickEngine {
    private let minimumHistoryCount = 3
    private var noRepeatPolicy = NoRepeatPolicy()
    private let tmdbRepository = TMDBSearchRepository()

    private let seedCandidates: [SuggestionCandidate] = [
        SuggestionCandidate(
            id: "seed-before-sunrise",
            title: "Before Sunrise",
            type: .movie,
            releaseYear: 1995,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-columbus",
            title: "Columbus",
            type: .movie,
            releaseYear: 2017,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-minari",
            title: "Minari",
            type: .movie,
            releaseYear: 2020,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-frances-ha",
            title: "Frances Ha",
            type: .movie,
            releaseYear: 2012,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-about-time",
            title: "About Time",
            type: .movie,
            releaseYear: 2013,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-station-eleven",
            title: "Station Eleven",
            type: .series,
            releaseYear: 2021,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-severance",
            title: "Severance",
            type: .series,
            releaseYear: 2022,
            signals: [.fallback]
        )
    ]

    func generateSuggestion(
        history: [Entry]
    ) async -> QuickPickState {
        let activeHistory = history
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }

        guard activeHistory.count >= minimumHistoryCount else {
            return .insufficientHistory(
                currentCount: activeHistory.count,
                targetCount: minimumHistoryCount
            )
        }

        let localCandidates = buildLocalCandidates(from: activeHistory)
        let discoveryCandidates = await buildDiscoveryCandidates(from: activeHistory)
        let candidates = localCandidates + discoveryCandidates

        let availableCandidates = noRepeatPolicy.filter(candidates)

        guard let selected = rankCandidates(
            availableCandidates,
            history: activeHistory
        ).first else {
            return .error("Couldn’t make a pick right now.")
        }

        noRepeatPolicy.markShown(selected.id)

        let reason = QuickPickReasonBuilder.buildReason(
            for: selected,
            history: activeHistory
        )

        let suggestion = QuickPickSuggestion(
            candidate: selected,
            reason: reason.0,
            reasonCode: reason.1,
            confidenceLabel: QuickPickReasonBuilder.confidenceLabel(for: selected),
            signals: Array(selected.signals.prefix(3))
        )

        if availableCandidates.count == 1 {
            return .noAlternatives(suggestion)
        }

        return .suggestion(suggestion)
    }

    func resetSession() {
        noRepeatPolicy.reset()
    }

    private func buildLocalCandidates(
        from history: [Entry]
    ) -> [SuggestionCandidate] {
        let rewatchCandidates = RewatchRule.candidates(from: history)

        let watchedKeys = Set(
            history.map {
                "\($0.normalizedTitle)|\($0.type.rawValue)"
            }
        )

        let unwatchedSeeds = seedCandidates
            .filter { candidate in
                let key = "\(candidate.title.normalizedTitleKey)|\(candidate.type.rawValue)"
                return watchedKeys.contains(key) == false
            }
            .map { enrich(candidate: $0, with: history) }

        let historyBasedCandidates = buildHistoryBasedCandidates(from: history)

        return rewatchCandidates + historyBasedCandidates + unwatchedSeeds
    }

    private func buildDiscoveryCandidates(
        from history: [Entry]
    ) async -> [SuggestionCandidate] {
        guard TMDBConfiguration.hasValidReadAccessToken else {
            return []
        }

        let genreIds = dominantGenreIds(from: history)
        let preferredType = preferredEntryType(from: history)
        let watchedKeys = watchedTitleKeys(from: history)
        let watchedTMDBIds = Set(history.compactMap { $0.tmdbId })

        guard genreIds.isEmpty == false else {
            return []
        }

        do {
            let results = try await tmdbRepository.discoverMedia(
                genreIds: genreIds,
                preferredType: preferredType
            )

            return results
                .filter { result in
                    watchedTMDBIds.contains(result.tmdbId) == false
                }
                .filter { result in
                    let key = "\(result.title.normalizedTitleKey)|\(result.entryType.rawValue)"
                    return watchedKeys.contains(key) == false
                }
                .prefix(10)
                .map { result in
                    discoveryCandidate(
                        from: result,
                        history: history,
                        dominantGenreIds: genreIds
                    )
                }
        } catch {
            #if DEBUG
            print("⚠️ QuickPick TMDB discovery failed:", error.localizedDescription)
            #endif

            return []
        }
    }

    private func discoveryCandidate(
        from result: TMDBMediaSearchResult,
        history: [Entry],
        dominantGenreIds: [Int]
    ) -> SuggestionCandidate {
        var signals: [QuickPickSignal] = []

        if let matchedGenre = result.genreIds.first(where: { dominantGenreIds.contains($0) }) {
            signals.append(.genreAffinity(matchedGenre))
        }

        if let strongSentiment = mostRecentStrongSentiment(in: history) {
            signals.append(.strongSentiment(strongSentiment))
        }

        if let rating = result.voteAverage, rating >= 7.3 {
            signals.append(.highTMDBRating(rating))
        }

        if let frequentMood = mostFrequentMood(in: history) {
            signals.append(.moodContinuity(frequentMood))
        }

        if signals.isEmpty {
            signals.append(.fallback)
        }

        return SuggestionCandidate(
            id: "tmdb-\(result.mediaType.rawValue)-\(result.tmdbId)",
            title: result.title,
            type: result.entryType,
            releaseYear: result.releaseYear,
            sourceEntryId: nil,
            isAlreadyWatched: false,
            isRewatchCandidate: false,
            posterPath: result.posterPath,
            backdropPath: result.backdropPath,
            overview: result.overview,
            tmdbRating: result.voteAverage,
            tmdbPopularity: result.popularity,
            tmdbGenreIds: result.genreIds,
            signals: signals
        )
    }

    private func buildHistoryBasedCandidates(
        from history: [Entry]
    ) -> [SuggestionCandidate] {
        history
            .filter { entry in
                entry.sourceType == .quickAdd &&
                entry.quickSentiment != nil &&
                entry.deletedAt == nil
            }
            .prefix(8)
            .map { entry in
                var signals = signalsFromEntry(entry)

                if signals.isEmpty {
                    signals = [.fallback]
                }

                return SuggestionCandidate(
                    id: "memory-\(entry.id)",
                    title: entry.title,
                    type: entry.type,
                    releaseYear: entry.releaseYear,
                    sourceEntryId: entry.id,
                    isAlreadyWatched: true,
                    isRewatchCandidate: false,
                    posterPath: entry.posterPath,
                    backdropPath: entry.backdropPath,
                    overview: entry.overview,
                    tmdbRating: entry.tmdbRating,
                    tmdbPopularity: entry.tmdbPopularity,
                    tmdbGenreIds: entry.tmdbGenreIds,
                    signals: signals
                )
            }
    }

    private func enrich(
        candidate: SuggestionCandidate,
        with history: [Entry]
    ) -> SuggestionCandidate {
        var signals = candidate.signals

        if let frequentMood = mostFrequentMood(in: history) {
            signals.insert(.moodContinuity(frequentMood), at: 0)
        }

        if let frequentTag = mostFrequentTag(in: history) {
            signals.append(.tagAffinity(frequentTag))
        }

        if let strongSentiment = mostRecentStrongSentiment(in: history) {
            signals.append(.strongSentiment(strongSentiment))
        }

        if let dominantGenre = mostFrequentGenreId(in: history) {
            signals.append(.genreAffinity(dominantGenre))
        }

        return SuggestionCandidate(
            id: candidate.id,
            title: candidate.title,
            type: candidate.type,
            releaseYear: candidate.releaseYear,
            sourceEntryId: candidate.sourceEntryId,
            isAlreadyWatched: candidate.isAlreadyWatched,
            isRewatchCandidate: candidate.isRewatchCandidate,
            posterPath: candidate.posterPath,
            backdropPath: candidate.backdropPath,
            overview: candidate.overview,
            tmdbRating: candidate.tmdbRating,
            tmdbPopularity: candidate.tmdbPopularity,
            tmdbGenreIds: candidate.tmdbGenreIds,
            signals: signals
        )
    }

    private func signalsFromEntry(_ entry: Entry) -> [QuickPickSignal] {
        var signals: [QuickPickSignal] = []

        if let sentiment = entry.quickSentiment,
           sentiment == .loved || sentiment == .stayedWithMe {
            signals.append(.strongSentiment(sentiment))
        }

        if entry.intensity >= 4 {
            signals.append(.highIntensity(entry.intensity))
        }

        if let rating = entry.tmdbRating, rating >= 7.5 {
            signals.append(.highTMDBRating(rating))
        }

        if let firstGenre = entry.tmdbGenreIds.first {
            signals.append(.genreAffinity(firstGenre))
        }

        if entry.updatedAt > Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast {
            signals.append(.recentFavorite)
        }

        if let tag = entry.tags.first {
            signals.append(.tagAffinity(tag))
        }

        return signals
    }

    private func rankCandidates(
        _ candidates: [SuggestionCandidate],
        history: [Entry]
    ) -> [SuggestionCandidate] {
        candidates.sorted { first, second in
            score(first, history: history) > score(second, history: history)
        }
    }

    private func score(
        _ candidate: SuggestionCandidate,
        history: [Entry]
    ) -> Int {
        var score = 0

        for signal in candidate.signals {
            switch signal {
            case .moodContinuity:
                score += 3
            case .moodContrast:
                score += 2
            case .tagAffinity:
                score += 3
            case .genreAffinity(let genreId):
                score += genreScore(genreId, history: history)
            case .strongSentiment:
                score += 4
            case .highIntensity:
                score += 2
            case .highTMDBRating(let rating):
                score += rating >= 8 ? 3 : 2
            case .recentFavorite:
                score += 2
            case .rewatchCandidate:
                score += 5
            case .fallback:
                score += 1
            }
        }

        if candidate.sourceEntryId == nil && candidate.isAlreadyWatched == false {
            score += 3
        }

        if candidate.posterPath != nil {
            score += 1
        }

        if candidate.overview != nil {
            score += 1
        }

        if candidate.isAlreadyWatched && candidate.isRewatchCandidate == false {
            score -= 1
        }

        return score
    }

    private func watchedTitleKeys(from history: [Entry]) -> Set<String> {
        Set(
            history.map {
                "\($0.normalizedTitle)|\($0.type.rawValue)"
            }
        )
    }

    private func dominantGenreIds(from history: [Entry]) -> [Int] {
        let genreIds = history.flatMap { $0.tmdbGenreIds }

        let counts = Dictionary(grouping: genreIds, by: { $0 })
            .mapValues { $0.count }

        return counts
            .sorted { first, second in
                if first.value != second.value {
                    return first.value > second.value
                }

                return first.key < second.key
            }
            .prefix(3)
            .map { $0.key }
    }

    private func preferredEntryType(from history: [Entry]) -> EntryType? {
        let movieCount = history.filter { $0.type == .movie }.count
        let seriesCount = history.filter { $0.type == .series }.count

        if movieCount == seriesCount {
            return nil
        }

        return movieCount > seriesCount ? .movie : .series
    }

    private func genreScore(
        _ genreId: Int,
        history: [Entry]
    ) -> Int {
        let count = history.filter { $0.tmdbGenreIds.contains(genreId) }.count

        switch count {
        case 3...:
            return 5
        case 2:
            return 4
        case 1:
            return 2
        default:
            return 1
        }
    }

    private func mostFrequentMood(in history: [Entry]) -> String? {
        let moods = history
            .map { $0.mood.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return mostFrequentValue(in: moods)
    }

    private func mostFrequentTag(in history: [Entry]) -> String? {
        let tags = history.flatMap { $0.tags }
        return mostFrequentValue(in: tags)
    }

    private func mostRecentStrongSentiment(in history: [Entry]) -> QuickSentiment? {
        history
            .sorted { $0.updatedAt > $1.updatedAt }
            .compactMap { $0.quickSentiment }
            .first { $0 == .loved || $0 == .stayedWithMe }
    }

    private func mostFrequentGenreId(in history: [Entry]) -> Int? {
        dominantGenreIds(from: history).first
    }

    private func mostFrequentValue(in values: [String]) -> String? {
        let counts = Dictionary(grouping: values, by: { $0 })
            .mapValues { $0.count }

        return counts
            .sorted { $0.value > $1.value }
            .first?
            .key
    }
}
