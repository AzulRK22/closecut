//
//  EntryDraftFactory.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 07/06/26.
//

import Foundation

enum EntryDraftFactory {
    static func quickAddFromWatchPlan(
        _ plan: WatchPlan
    ) -> QuickAddDraft {
        QuickAddDraft(
            title: plan.media.displayTitle,
            type: plan.media.type,
            releaseYear: plan.media.releaseYear,
            quickSentiment: nil,
            watchedDateApprox: resolvedWatchedDateApprox(from: plan),
            externalMetadata: plan.media.externalMetadata
        )
    }

    static func quickAddFromTMDBResult(
        _ result: TMDBMediaSearchResult
    ) -> QuickAddDraft {
        QuickAddDraft(
            title: result.title,
            type: result.entryType,
            releaseYear: result.releaseYear,
            quickSentiment: nil,
            watchedDateApprox: .unknown,
            externalMetadata: EntryExternalMetadata(tmdbResult: result)
        )
    }

    static func quickAddFromWatchlistItem(
        _ item: WatchlistItem
    ) -> QuickAddDraft {
        QuickAddDraft(
            title: item.displayTitle,
            type: item.type,
            releaseYear: item.releaseYear,
            quickSentiment: nil,
            watchedDateApprox: .unknown,
            externalMetadata: item.externalMetadata
        )
    }

    static func quickAddFromEntry(
        _ entry: Entry
    ) -> QuickAddDraft {
        QuickAddDraft(
            title: entry.displayTitle,
            type: entry.type,
            releaseYear: entry.releaseYear,
            quickSentiment: entry.quickSentiment,
            watchedDateApprox: entry.watchedDateApprox,
            externalMetadata: entry.externalMetadata
        )
    }

    // MARK: - Private Helpers

    private static func resolvedWatchedDateApprox(
        from plan: WatchPlan
    ) -> WatchedDateApprox {
        if let confirmedStartAt = plan.confirmedStartAt {
            return .exact(confirmedStartAt)
        }

        if let proposedStartAt = plan.proposedStartAt {
            return .exact(proposedStartAt)
        }

        if plan.status == .watched {
            return .recently
        }

        return .unknown
    }
}
