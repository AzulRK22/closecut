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

            var signals: [QuickPickSignal] = [.rewatchCandidate]

            if entry.intensity >= 4 {
                signals.append(.highIntensity(entry.intensity))
            }

            if let sentiment = entry.quickSentiment,
               sentiment == .loved || sentiment == .stayedWithMe {
                signals.append(.strongSentiment(sentiment))
            }

            if let rating = entry.tmdbRating, rating >= 7.5 {
                signals.append(.highTMDBRating(rating))
            }

            return SuggestionCandidate(
                rewatchEntry: entry,
                signals: signals
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

        let isOldEnough = daysSinceWatch >= 120
        let hasStrongSentiment = entry.quickSentiment == .loved || entry.quickSentiment == .stayedWithMe
        let hasHighIntensity = entry.intensity >= 4
        let hasStrongRating = (entry.tmdbRating ?? 0) >= 7.5

        return isOldEnough && (hasStrongSentiment || hasHighIntensity || hasStrongRating)
    }
}
