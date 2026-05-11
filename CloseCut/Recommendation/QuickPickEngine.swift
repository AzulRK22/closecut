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
    private let maxDiscoveryCandidates = 10
    private let maxHistoryBasedCandidates = 8

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
        let activeHistory = normalizedActiveHistory(from: history)

        guard activeHistory.count >= minimumHistoryCount else {
            return .insufficientHistory(
                currentCount: activeHistory.count,
                targetCount: minimumHistoryCount
            )
        }

        let localCandidates = buildLocalCandidates(from: activeHistory)
        let discoveryCandidates = await buildDiscoveryCandidates(from: activeHistory)

        let candidates = dedupeCandidates(
            localCandidates + discoveryCandidates
        )

        let availableCandidates = noRepeatPolicy.filter(candidates)

        let rankedCandidates = rankCandidates(
            availableCandidates,
            history: activeHistory
        )

        guard let selected = rankedCandidates.first else {
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

        if availableCandidates.count <= 1 {
            return .noAlternatives(suggestion)
        }

        return .suggestion(suggestion)
    }

    func resetSession() {
        noRepeatPolicy.reset()
    }

    // MARK: - Candidate Builders

    private func buildLocalCandidates(
        from history: [Entry]
    ) -> [SuggestionCandidate] {
        let rewatchCandidates = RewatchRule.candidates(from: history)
        let historyBasedCandidates = buildHistoryBasedCandidates(from: history)
        let seedCandidates = buildSeedCandidates(from: history)

        return rewatchCandidates + historyBasedCandidates + seedCandidates
    }

    private func buildSeedCandidates(
        from history: [Entry]
    ) -> [SuggestionCandidate] {
        let watchedKeys = watchedTitleKeys(from: history)

        return seedCandidates
            .filter { candidate in
                watchedKeys.contains(candidate.normalizedIdentityKey) == false
            }
            .map { candidate in
                enrich(
                    candidate: candidate,
                    with: history
                )
            }
    }

    private func buildHistoryBasedCandidates(
        from history: [Entry]
    ) -> [SuggestionCandidate] {
        history
            .filter { entry in
                entry.deletedAt == nil &&
                entry.sourceType == .quickAdd &&
                entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
                hasEnoughSignalForHistoryCandidate(entry)
            }
            .sorted { first, second in
                scoreEntryForHistoryCandidate(first) > scoreEntryForHistoryCandidate(second)
            }
            .prefix(maxHistoryBasedCandidates)
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
                .filter { result in
                    result.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                }
                .prefix(maxDiscoveryCandidates)
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
            signals: Array(signals.prefix(5))
        )
    }

    // MARK: - Ranking

    private func rankCandidates(
        _ candidates: [SuggestionCandidate],
        history: [Entry]
    ) -> [SuggestionCandidate] {
        candidates.sorted { first, second in
            let firstScore = score(first, history: history)
            let secondScore = score(second, history: history)

            if firstScore != secondScore {
                return firstScore > secondScore
            }

            return tieBreaker(first, second)
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
                score += genreScore(
                    genreId,
                    history: history
                )

            case .strongSentiment:
                score += 5

            case .highIntensity(let intensity):
                score += min(max(intensity, 1), 5)

            case .highTMDBRating(let rating):
                score += rating >= 8 ? 4 : 3

            case .recentFavorite:
                score += 2

            case .rewatchCandidate:
                score += 6

            case .fallback:
                score += 1
            }
        }

        if candidate.isTMDBDiscovery {
            score += 4
        }

        if candidate.isRewatchCandidate {
            score += 3
        }

        if candidate.posterPath != nil {
            score += 1
        }

        if candidate.backdropPath != nil {
            score += 1
        }

        if candidate.overview?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            score += 1
        }

        if candidate.tmdbGenreIds.isEmpty == false {
            score += 1
        }

        if candidate.isAlreadyWatched && candidate.isRewatchCandidate == false {
            score -= 2
        }

        if candidate.signals == [.fallback] {
            score -= 1
        }

        return score
    }

    private func tieBreaker(
        _ first: SuggestionCandidate,
        _ second: SuggestionCandidate
    ) -> Bool {
        if first.isTMDBDiscovery != second.isTMDBDiscovery {
            return first.isTMDBDiscovery
        }

        if first.isRewatchCandidate != second.isRewatchCandidate {
            return first.isRewatchCandidate
        }

        let firstRating = first.tmdbRating ?? 0
        let secondRating = second.tmdbRating ?? 0

        if firstRating != secondRating {
            return firstRating > secondRating
        }

        let firstPopularity = first.tmdbPopularity ?? 0
        let secondPopularity = second.tmdbPopularity ?? 0

        if firstPopularity != secondPopularity {
            return firstPopularity > secondPopularity
        }

        return (first.releaseYear ?? 0) > (second.releaseYear ?? 0)
    }

    // MARK: - Signals

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

        if isRecentlyUpdatedStrongEntry(entry) {
            signals.append(.recentFavorite)
        }

        if let tag = entry.tags.first {
            signals.append(.tagAffinity(tag))
        }

        return signals
    }

    private func hasEnoughSignalForHistoryCandidate(_ entry: Entry) -> Bool {
        entry.quickSentiment == .loved ||
        entry.quickSentiment == .stayedWithMe ||
        entry.intensity >= 4 ||
        (entry.tmdbRating ?? 0) >= 7.5 ||
        entry.tags.isEmpty == false ||
        entry.tmdbGenreIds.isEmpty == false
    }

    private func scoreEntryForHistoryCandidate(_ entry: Entry) -> Int {
        var score = 0

        if entry.quickSentiment == .loved || entry.quickSentiment == .stayedWithMe {
            score += 5
        }

        if entry.intensity >= 4 {
            score += entry.intensity
        }

        if let rating = entry.tmdbRating, rating >= 7.5 {
            score += Int(rating.rounded())
        }

        if entry.posterPath != nil {
            score += 1
        }

        if entry.tags.isEmpty == false {
            score += 1
        }

        return score
    }

    private func isRecentlyUpdatedStrongEntry(_ entry: Entry) -> Bool {
        let thirtyDaysAgo = Calendar.current.date(
            byAdding: .day,
            value: -30,
            to: Date()
        ) ?? Date.distantPast

        return entry.updatedAt > thirtyDaysAgo &&
            (
                entry.quickSentiment == .loved ||
                entry.quickSentiment == .stayedWithMe ||
                entry.intensity >= 4
            )
    }

    // MARK: - History Analysis

    private func normalizedActiveHistory(
        from history: [Entry]
    ) -> [Entry] {
        history
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
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
            .filter { $0.isEmpty == false }

        return mostFrequentValue(in: moods)
    }

    private func mostFrequentTag(in history: [Entry]) -> String? {
        let tags = history
            .flatMap { $0.tags }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

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
            .sorted { first, second in
                if first.value != second.value {
                    return first.value > second.value
                }

                return first.key < second.key
            }
            .first?
            .key
    }

    // MARK: - Dedupe

    private func dedupeCandidates(
        _ candidates: [SuggestionCandidate]
    ) -> [SuggestionCandidate] {
        var seenKeys = Set<String>()
        var uniqueCandidates: [SuggestionCandidate] = []

        for candidate in candidates {
            let key = candidate.normalizedIdentityKey

            guard seenKeys.contains(key) == false else {
                continue
            }

            seenKeys.insert(key)
            uniqueCandidates.append(candidate)
        }

        return uniqueCandidates
    }
}
