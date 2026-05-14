//
//  CircleQuickPickEngine.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import Foundation

@MainActor
final class CircleQuickPickEngine {
    private let minimumSharedHistoryCount = 3
    private let maxDiscoveryCandidates = 12
    private let maxSharedMemoryCandidates = 8

    private var noRepeatPolicy = NoRepeatPolicy()
    private let tmdbRepository = TMDBSearchRepository()

    private let seedCandidates: [SuggestionCandidate] = [
        SuggestionCandidate(
            id: "circle-seed-parasite",
            title: "Parasite",
            type: .movie,
            releaseYear: 2019,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "circle-seed-arrival",
            title: "Arrival",
            type: .movie,
            releaseYear: 2016,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "circle-seed-past-lives",
            title: "Past Lives",
            type: .movie,
            releaseYear: 2023,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "circle-seed-everything-everywhere",
            title: "Everything Everywhere All at Once",
            type: .movie,
            releaseYear: 2022,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "circle-seed-the-social-network",
            title: "The Social Network",
            type: .movie,
            releaseYear: 2010,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "circle-seed-dune",
            title: "Dune",
            type: .movie,
            releaseYear: 2021,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "circle-seed-severance",
            title: "Severance",
            type: .series,
            releaseYear: 2022,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "circle-seed-the-bear",
            title: "The Bear",
            type: .series,
            releaseYear: 2022,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "circle-seed-succession",
            title: "Succession",
            type: .series,
            releaseYear: 2018,
            signals: [.fallback]
        )
    ]

    func generateSuggestion(
        sharedEntries: [Entry],
        memberCount: Int
    ) async -> QuickPickState {
        let activeSharedEntries = normalizedActiveSharedEntries(
            from: sharedEntries
        )

        guard activeSharedEntries.count >= minimumSharedHistoryCount else {
            return .insufficientHistory(
                currentCount: activeSharedEntries.count,
                targetCount: minimumSharedHistoryCount
            )
        }

        let localCandidates = buildLocalCandidates(
            from: activeSharedEntries
        )

        let discoveryCandidates = await buildDiscoveryCandidates(
            from: activeSharedEntries
        )

        let candidates = dedupeCandidates(
            localCandidates + discoveryCandidates
        )

        let availableCandidates = noRepeatPolicy.filter(candidates)

        let rankedCandidates = rankCandidates(
            availableCandidates,
            sharedEntries: activeSharedEntries
        )

        guard let selected = rankedCandidates.first else {
            return .error("Couldn’t make a group pick right now.")
        }

        noRepeatPolicy.markShown(selected.id)

        let reason = CircleQuickPickReasonBuilder.buildReason(
            for: selected,
            sharedEntries: activeSharedEntries,
            memberCount: memberCount
        )

        let suggestion = QuickPickSuggestion(
            candidate: selected,
            reason: reason.0,
            reasonCode: reason.1,
            confidenceLabel: CircleQuickPickReasonBuilder.confidenceLabel(
                for: selected
            ),
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
        from sharedEntries: [Entry]
    ) -> [SuggestionCandidate] {
        let sharedMemoryCandidates = buildSharedMemoryCandidates(
            from: sharedEntries
        )

        let seedCandidates = buildSeedCandidates(
            from: sharedEntries
        )

        return sharedMemoryCandidates + seedCandidates
    }

    private func buildSharedMemoryCandidates(
        from sharedEntries: [Entry]
    ) -> [SuggestionCandidate] {
        sharedEntries
            .filter { entry in
                entry.deletedAt == nil &&
                entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
                hasEnoughSignalForSharedCandidate(entry)
            }
            .sorted { first, second in
                scoreEntryForSharedCandidate(first) > scoreEntryForSharedCandidate(second)
            }
            .prefix(maxSharedMemoryCandidates)
            .map { entry in
                var signals = signalsFromEntry(entry)

                if signals.isEmpty {
                    signals = [.fallback]
                }

                return SuggestionCandidate(
                    id: "circle-memory-\(entry.id)",
                    title: entry.title,
                    type: entry.type,
                    releaseYear: entry.releaseYear,
                    sourceEntryId: entry.id,
                    isAlreadyWatched: true,
                    isRewatchCandidate: true,
                    posterPath: entry.posterPath,
                    backdropPath: entry.backdropPath,
                    overview: entry.overview,
                    tmdbRating: entry.tmdbRating,
                    tmdbPopularity: entry.tmdbPopularity,
                    tmdbGenreIds: entry.tmdbGenreIds,
                    signals: Array((signals + [.rewatchCandidate]).prefix(5))
                )
            }
    }

    private func buildSeedCandidates(
        from sharedEntries: [Entry]
    ) -> [SuggestionCandidate] {
        let watchedKeys = watchedTitleKeys(from: sharedEntries)

        return seedCandidates
            .filter { candidate in
                watchedKeys.contains(candidate.normalizedIdentityKey) == false
            }
            .map { candidate in
                enrich(
                    candidate: candidate,
                    with: sharedEntries
                )
            }
    }

    private func buildDiscoveryCandidates(
        from sharedEntries: [Entry]
    ) async -> [SuggestionCandidate] {
        guard TMDBConfiguration.hasValidReadAccessToken else {
            return []
        }

        let genreIds = dominantGenreIds(from: sharedEntries)
        let preferredType = preferredEntryType(from: sharedEntries)
        let watchedKeys = watchedTitleKeys(from: sharedEntries)
        let watchedTMDBIds = Set(sharedEntries.compactMap { $0.tmdbId })

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
                        sharedEntries: sharedEntries,
                        dominantGenreIds: genreIds
                    )
                }
        } catch {
            #if DEBUG
            print("⚠️ Circle QuickPick TMDB discovery failed:", error.localizedDescription)
            #endif

            return []
        }
    }

    private func discoveryCandidate(
        from result: TMDBMediaSearchResult,
        sharedEntries: [Entry],
        dominantGenreIds: [Int]
    ) -> SuggestionCandidate {
        var signals: [QuickPickSignal] = []

        if let matchedGenre = result.genreIds.first(where: { dominantGenreIds.contains($0) }) {
            signals.append(.genreAffinity(matchedGenre))
        }

        if let strongSentiment = mostRecentStrongSentiment(in: sharedEntries) {
            signals.append(.strongSentiment(strongSentiment))
        }

        if let rating = result.voteAverage, rating >= 7.3 {
            signals.append(.highTMDBRating(rating))
        }

        if let frequentMood = mostFrequentMood(in: sharedEntries) {
            signals.append(.moodContinuity(frequentMood))
        }

        if signals.isEmpty {
            signals.append(.fallback)
        }

        return SuggestionCandidate(
            id: "tmdb-circle-\(result.mediaType.rawValue)-\(result.tmdbId)",
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
        with sharedEntries: [Entry]
    ) -> SuggestionCandidate {
        var signals = candidate.signals

        if let frequentMood = mostFrequentMood(in: sharedEntries) {
            signals.insert(.moodContinuity(frequentMood), at: 0)
        }

        if let frequentTag = mostFrequentTag(in: sharedEntries) {
            signals.append(.tagAffinity(frequentTag))
        }

        if let strongSentiment = mostRecentStrongSentiment(in: sharedEntries) {
            signals.append(.strongSentiment(strongSentiment))
        }

        if let dominantGenre = dominantGenreIds(from: sharedEntries).first {
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
        sharedEntries: [Entry]
    ) -> [SuggestionCandidate] {
        candidates.sorted { first, second in
            let firstScore = score(
                first,
                sharedEntries: sharedEntries
            )

            let secondScore = score(
                second,
                sharedEntries: sharedEntries
            )

            if firstScore != secondScore {
                return firstScore > secondScore
            }

            return tieBreaker(first, second)
        }
    }

    private func score(
        _ candidate: SuggestionCandidate,
        sharedEntries: [Entry]
    ) -> Int {
        var score = 0

        for signal in candidate.signals {
            switch signal {
            case .genreAffinity(let genreId):
                score += genreScore(
                    genreId,
                    sharedEntries: sharedEntries
                )

            case .strongSentiment:
                score += 5

            case .highIntensity(let intensity):
                score += min(max(intensity, 1), 5)

            case .highTMDBRating(let rating):
                score += rating >= 8 ? 4 : 3

            case .moodContinuity:
                score += 3

            case .tagAffinity:
                score += 3

            case .recentFavorite:
                score += 2

            case .rewatchCandidate:
                score += 4

            case .moodContrast:
                score += 2

            case .fallback:
                score += 1
            }
        }

        if candidate.isTMDBDiscovery {
            score += 5
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

        if candidate.isAlreadyWatched && candidate.isRewatchCandidate {
            score += 1
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

    private func signalsFromEntry(
        _ entry: Entry
    ) -> [QuickPickSignal] {
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

    private func hasEnoughSignalForSharedCandidate(
        _ entry: Entry
    ) -> Bool {
        entry.quickSentiment == .loved ||
        entry.quickSentiment == .stayedWithMe ||
        entry.intensity >= 4 ||
        (entry.tmdbRating ?? 0) >= 7.5 ||
        entry.tags.isEmpty == false ||
        entry.tmdbGenreIds.isEmpty == false
    }

    private func scoreEntryForSharedCandidate(
        _ entry: Entry
    ) -> Int {
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

        if entry.overview?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            score += 1
        }

        if entry.tags.isEmpty == false {
            score += 1
        }

        return score
    }

    private func isRecentlyUpdatedStrongEntry(
        _ entry: Entry
    ) -> Bool {
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

    // MARK: - Shared History Analysis

    private func normalizedActiveSharedEntries(
        from entries: [Entry]
    ) -> [Entry] {
        entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private func watchedTitleKeys(
        from entries: [Entry]
    ) -> Set<String> {
        Set(
            entries.map {
                "\($0.normalizedTitle)|\($0.type.rawValue)"
            }
        )
    }

    private func dominantGenreIds(
        from entries: [Entry]
    ) -> [Int] {
        let genreIds = entries.flatMap { $0.tmdbGenreIds }

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

    private func preferredEntryType(
        from entries: [Entry]
    ) -> EntryType? {
        let movieCount = entries.filter { $0.type == .movie }.count
        let seriesCount = entries.filter { $0.type == .series }.count

        if movieCount == seriesCount {
            return nil
        }

        return movieCount > seriesCount ? .movie : .series
    }

    private func genreScore(
        _ genreId: Int,
        sharedEntries: [Entry]
    ) -> Int {
        let count = sharedEntries.filter {
            $0.tmdbGenreIds.contains(genreId)
        }.count

        switch count {
        case 3...:
            return 6
        case 2:
            return 4
        case 1:
            return 2
        default:
            return 1
        }
    }

    private func mostFrequentMood(
        in entries: [Entry]
    ) -> String? {
        let moods = entries
            .map { $0.mood.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        return mostFrequentValue(in: moods)
    }

    private func mostFrequentTag(
        in entries: [Entry]
    ) -> String? {
        let tags = entries
            .flatMap { $0.tags }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        return mostFrequentValue(in: tags)
    }

    private func mostRecentStrongSentiment(
        in entries: [Entry]
    ) -> QuickSentiment? {
        entries
            .sorted { $0.updatedAt > $1.updatedAt }
            .compactMap { $0.quickSentiment }
            .first { $0 == .loved || $0 == .stayedWithMe }
    }

    private func mostFrequentValue(
        in values: [String]
    ) -> String? {
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
