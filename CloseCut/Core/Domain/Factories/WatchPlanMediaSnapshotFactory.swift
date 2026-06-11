//
//  WatchPlanMediaSnapshotFactory.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 08/06/26.
//

import Foundation

enum WatchPlanMediaSnapshotFactory {
    static func fromTMDBResult(
        _ result: TMDBMediaSearchResult,
        source: WatchPlanMediaSource = .discover
    ) -> WatchPlanMediaSnapshot {
        WatchPlanMediaSnapshot(
            title: result.title,
            type: result.entryType,
            releaseYear: result.releaseYear,
            source: source,
            sourceId: result.id,
            externalMetadata: EntryExternalMetadata(tmdbResult: result)
        )
    }

    static func fromWatchlistItem(
        _ item: WatchlistItem
    ) -> WatchPlanMediaSnapshot {
        WatchPlanMediaSnapshot(
            title: item.displayTitle,
            type: item.type,
            releaseYear: item.releaseYear,
            source: .watchlist,
            sourceId: item.id,
            externalMetadata: item.externalMetadata
        )
    }

    static func fromEntry(
        _ entry: Entry
    ) -> WatchPlanMediaSnapshot {
        WatchPlanMediaSnapshot(
            title: entry.displayTitle,
            type: entry.type,
            releaseYear: entry.releaseYear,
            source: .entry,
            sourceId: entry.id,
            externalMetadata: entry.externalMetadata,
            overview: entry.overview,
            tmdbRating: entry.tmdbRating,
            tmdbPopularity: entry.tmdbPopularity,
            tmdbGenreIds: entry.tmdbGenreIds
        )
    }

    static func fromBattleCandidate(
        _ candidate: BattleCandidate
    ) -> WatchPlanMediaSnapshot {
        WatchPlanMediaSnapshot(
            title: candidate.displayTitle,
            type: candidate.type,
            releaseYear: candidate.releaseYear,
            source: .battle,
            sourceId: candidate.id,
            externalMetadata: externalMetadata(from: candidate),
            overview: candidate.overview,
            tmdbRating: candidate.tmdbRating,
            tmdbPopularity: candidate.tmdbPopularity,
            tmdbGenreIds: candidate.tmdbGenreIds
        )
    }

    static func manual(
        title: String,
        type: EntryType
    ) -> WatchPlanMediaSnapshot {
        WatchPlanMediaSnapshot(
            title: title,
            type: type,
            source: .manual
        )
    }

    private static func externalMetadata(
        from candidate: BattleCandidate
    ) -> EntryExternalMetadata? {
        guard candidate.tmdbId != nil,
              candidate.tmdbMediaTypeRaw != nil else {
            return nil
        }

        return EntryExternalMetadata(
            tmdbResult: tmdbLikeResult(from: candidate)
        )
    }

    private static func tmdbLikeResult(
        from candidate: BattleCandidate
    ) -> TMDBMediaSearchResult {
        let resolvedTMDBId = candidate.tmdbId ?? abs(candidate.id.hashValue)
        let resolvedMediaType = resolvedMediaType(from: candidate)

        return TMDBMediaSearchResult(
            id: "battle-\(resolvedMediaType.rawValue)-\(resolvedTMDBId)",
            tmdbId: resolvedTMDBId,
            mediaType: resolvedMediaType,
            title: candidate.displayTitle,
            releaseYear: candidate.releaseYear,
            overview: candidate.overview,
            posterPath: candidate.posterPath,
            backdropPath: candidate.backdropPath,
            voteAverage: candidate.tmdbRating,
            popularity: candidate.tmdbPopularity,
            genreIds: candidate.tmdbGenreIds
        )
    }

    private static func resolvedMediaType(
        from candidate: BattleCandidate
    ) -> TMDBMediaType {
        if let raw = candidate.tmdbMediaTypeRaw,
           let mediaType = TMDBMediaType(rawValue: raw) {
            return mediaType
        }

        return candidate.type == .series ? .tv : .movie
    }
}
