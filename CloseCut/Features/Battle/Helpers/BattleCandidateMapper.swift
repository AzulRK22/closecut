//
//  BattleCandidateMapper.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import Foundation

enum BattleCandidateMapper {
    static func candidate(
        from entry: Entry
    ) -> BattleCandidate {
        BattleCandidate(
            id: "entry-\(entry.id)",
            source: .archive,
            title: entry.displayTitle,
            normalizedTitle: entry.normalizedTitle,
            type: entry.type,
            releaseYear: entry.releaseYear,
            sourceEntryId: entry.id,
            tmdbId: entry.tmdbId,
            tmdbMediaTypeRaw: entry.tmdbMediaTypeRaw,
            posterPath: entry.posterPath,
            backdropPath: entry.backdropPath,
            overview: entry.overview,
            tmdbRating: entry.tmdbRating,
            tmdbPopularity: entry.tmdbPopularity,
            tmdbGenreIds: entry.tmdbGenreIds,
            moodText: entry.displayMoodText,
            quickSentiment: entry.quickSentiment,
            takeaway: entry.takeaway,
            watchedAt: entry.watchedAt,
            isShared: entry.isSharedWithCircle,
            isQuickAdd: entry.isQuickAdd
        )
    }

    static func candidates(
        from entries: [Entry]
    ) -> [BattleCandidate] {
        entries
            .filter { $0.deletedAt == nil }
            .filter { $0.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .map { candidate(from: $0) }
    }

    static func candidate(
        from item: WatchlistItem
    ) -> BattleCandidate {
        BattleCandidate(
            id: "watchlist-\(item.id)",
            source: .watchlist,
            title: item.displayTitle,
            type: item.type,
            releaseYear: item.releaseYear,
            sourceEntryId: nil,
            tmdbId: item.tmdbId,
            tmdbMediaTypeRaw: item.tmdbMediaTypeRaw,
            posterPath: item.posterPath,
            backdropPath: item.backdropPath,
            overview: item.overview,
            tmdbRating: item.tmdbRating,
            tmdbPopularity: item.tmdbPopularity,
            tmdbGenreIds: item.tmdbGenreIds,
            moodText: nil,
            quickSentiment: nil,
            takeaway: nil,
            watchedAt: nil,
            isShared: false,
            isQuickAdd: false
        )
    }

    static func candidates(
        from watchlistItems: [WatchlistItem]
    ) -> [BattleCandidate] {
        watchlistItems
            .filter { $0.status == .saved && $0.deletedAt == nil }
            .filter { $0.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .map { candidate(from: $0) }
    }

    static func candidate(
        from result: TMDBMediaSearchResult
    ) -> BattleCandidate {
        BattleCandidate(
            id: "tmdb-\(result.mediaType.rawValue)-\(result.tmdbId)",
            source: .tmdb,
            title: result.title,
            type: result.entryType,
            releaseYear: result.releaseYear,
            sourceEntryId: nil,
            tmdbId: result.tmdbId,
            tmdbMediaTypeRaw: result.mediaType.rawValue,
            posterPath: result.posterPath,
            backdropPath: result.backdropPath,
            overview: result.overview,
            tmdbRating: result.voteAverage,
            tmdbPopularity: result.popularity,
            tmdbGenreIds: result.genreIds,
            moodText: nil,
            quickSentiment: nil,
            takeaway: nil,
            watchedAt: nil,
            isShared: false,
            isQuickAdd: false
        )
    }

    static func manualCandidate(
        title: String,
        type: EntryType
    ) -> BattleCandidate {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        return BattleCandidate(
            id: "manual-\(cleanedTitle.normalizedTitleKey)-\(type.rawValue)-\(UUID().uuidString)",
            source: .manual,
            title: cleanedTitle,
            type: type,
            releaseYear: nil,
            sourceEntryId: nil,
            tmdbId: nil,
            tmdbMediaTypeRaw: nil,
            posterPath: nil,
            backdropPath: nil,
            overview: nil,
            tmdbRating: nil,
            tmdbPopularity: nil,
            tmdbGenreIds: [],
            moodText: nil,
            quickSentiment: nil,
            takeaway: nil,
            watchedAt: nil,
            isShared: false,
            isQuickAdd: false
        )
    }

    static func dedupe(
        _ candidates: [BattleCandidate]
    ) -> [BattleCandidate] {
        var seenKeys = Set<String>()
        var unique: [BattleCandidate] = []

        for candidate in candidates {
            let key = candidate.normalizedIdentityKey

            guard seenKeys.contains(key) == false else {
                continue
            }

            seenKeys.insert(key)
            unique.append(candidate)
        }

        return unique
    }

    static func entries(
        from candidates: [BattleCandidate],
        eligibleEntries: [Entry]
    ) -> [Entry] {
        candidates.compactMap { candidate in
            guard candidate.source == .archive,
                  let sourceEntryId = candidate.sourceEntryId else {
                return nil
            }

            return eligibleEntries.first { entry in
                entry.id == sourceEntryId
            }
        }
    }

    static func entry(
        from candidate: BattleCandidate,
        eligibleEntries: [Entry]
    ) -> Entry? {
        guard candidate.source == .archive,
              let sourceEntryId = candidate.sourceEntryId else {
            return nil
        }

        return eligibleEntries.first { entry in
            entry.id == sourceEntryId
        }
    }
}
