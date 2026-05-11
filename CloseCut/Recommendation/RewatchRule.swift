//
//  RewatchRule.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

enum RewatchRule {
    private static let minimumDaysSinceWatch = 120
    private static let strongRatingThreshold = 7.5

    static func candidates(
        from history: [Entry],
        now: Date = Date()
    ) -> [SuggestionCandidate] {
        history
            .filter { qualifies($0, now: now) }
            .sorted { first, second in
                score(first) > score(second)
            }
            .map { entry in
                SuggestionCandidate(
                    rewatchEntry: entry,
                    signals: signals(for: entry)
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

        guard entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return false
        }

        let daysSinceWatch = Calendar.current.dateComponents(
            [.day],
            from: entry.watchedAt,
            to: now
        ).day ?? 0

        guard daysSinceWatch >= minimumDaysSinceWatch else {
            return false
        }

        return hasStrongSentiment(entry) ||
            entry.intensity >= 4 ||
            (entry.tmdbRating ?? 0) >= strongRatingThreshold
    }

    private static func signals(for entry: Entry) -> [QuickPickSignal] {
        var signals: [QuickPickSignal] = [.rewatchCandidate]

        if entry.intensity >= 4 {
            signals.append(.highIntensity(entry.intensity))
        }

        if let sentiment = entry.quickSentiment,
           sentiment == .loved || sentiment == .stayedWithMe {
            signals.append(.strongSentiment(sentiment))
        }

        if let rating = entry.tmdbRating, rating >= strongRatingThreshold {
            signals.append(.highTMDBRating(rating))
        }

        if let genreId = entry.tmdbGenreIds.first {
            signals.append(.genreAffinity(genreId))
        }

        return signals
    }

    private static func score(_ entry: Entry) -> Int {
        var score = 0

        if hasStrongSentiment(entry) {
            score += 5
        }

        if entry.intensity >= 4 {
            score += entry.intensity
        }

        if let rating = entry.tmdbRating, rating >= strongRatingThreshold {
            score += Int(rating.rounded())
        }

        if entry.posterPath != nil {
            score += 1
        }

        if entry.overview?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            score += 1
        }

        return score
    }

    private static func hasStrongSentiment(_ entry: Entry) -> Bool {
        entry.quickSentiment == .loved || entry.quickSentiment == .stayedWithMe
    }
}
