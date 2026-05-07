//
//  QuickAddDraft+TMDB.swift
//  CloseCut
//

import Foundation

extension QuickAddDraft {
    init(
        tmdbResult: TMDBMediaSearchResult,
        quickSentiment: QuickSentiment?,
        watchedDateApprox: WatchedDateApprox?
    ) {
        self.init(
            title: tmdbResult.title,
            type: tmdbResult.entryType,
            releaseYear: tmdbResult.releaseYear,
            quickSentiment: quickSentiment,
            watchedDateApprox: watchedDateApprox,
            externalMetadata: EntryExternalMetadata(tmdbResult: tmdbResult)
        )
    }
}
