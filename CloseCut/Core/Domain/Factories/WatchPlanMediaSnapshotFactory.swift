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
}
