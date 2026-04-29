//
//  RewatchRule.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

enum RewatchRule {
    static func candidates(
        from history: [Entry],
        now: Date = Date()
    ) -> [SuggestionCandidate] {
        history.compactMap { entry in
            guard qualifies(entry, now: now) else {
                return nil
            }

            return SuggestionCandidate(
                id: "rewatch-\(entry.id)",
                title: entry.title,
                type: entry.type,
                releaseYear: entry.releaseYear,
                sourceEntryId: entry.id,
                isAlreadyWatched: true,
                isRewatchCandidate: true,
                signals: [.rewatchCandidate]
            )
        }
    }

    private static func qualifies(
        _ entry: Entry,
        now: Date
    ) -> Bool {
        guard entry.deletedAt == nil else {
            return false
        }

        let daysSinceWatch = Calendar.current.dateComponents(
            [.day],
            from: entry.watchedAt,
            to: now
        ).day ?? 0

        let isOldEnough = daysSinceWatch >= 180
        let hasStrongSentiment = entry.quickSentiment == .loved || entry.quickSentiment == .stayedWithMe
        let hasHighIntensity = entry.intensity >= 4

        return isOldEnough && (hasStrongSentiment || hasHighIntensity)
    }
}
