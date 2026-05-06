//
//  QuickAddDraft+TMDB.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
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
            watchedDateApprox: watchedDateApprox
        )
    }
}
