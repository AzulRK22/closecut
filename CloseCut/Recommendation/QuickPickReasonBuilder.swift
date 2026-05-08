//
//  QuickPickReasonBuilder.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

enum QuickPickReasonBuilder {
    static func buildReason(
        for candidate: SuggestionCandidate,
        history: [Entry]
    ) -> (String, QuickPickReasonCode) {
        if candidate.isRewatchCandidate {
            if let sentimentSignal = candidate.signals.first(where: {
                if case .strongSentiment = $0 { return true }
                return false
            }) {
                if case .strongSentiment(let sentiment) = sentimentSignal {
                    return (
                        "You marked this as \(sentiment.displayName.lowercased()). It may be worth revisiting now.",
                        .rewatchCandidate
                    )
                }
            }

            if let rating = candidate.tmdbRating, rating >= 7.5 {
                return (
                    "This was a strong watch in your archive and it also has a solid TMDB rating. It may be a good rewatch.",
                    .rewatchCandidate
                )
            }

            return (
                "You added this before — it may be time to revisit it.",
                .rewatchCandidate
            )
        }

        if candidate.sourceEntryId == nil && candidate.isAlreadyWatched == false {
            if candidate.signals.contains(where: {
                if case .genreAffinity = $0 { return true }
                return false
            }) {
                return (
                    "Your archive leans toward similar genres, so this TMDB discovery fits the pattern of what tends to stay with you.",
                    .genreAffinity
                )
            }

            return (
                "This is a new TMDB discovery selected from patterns in your local watch history.",
                .fallback
            )
        }

        if let signal = candidate.signals.first {
            switch signal {
            case .genreAffinity:
                return (
                    "Your recent history leans toward similar genres, so this fits the pattern of what you’ve been saving.",
                    .genreAffinity
                )

            case .moodContinuity(let mood):
                return (
                    "You have been logging \(mood.lowercased()) picks lately, and this keeps that mood going.",
                    .moodContinuity
                )

            case .moodContrast(let mood):
                return (
                    "After a few \(mood.lowercased()) watches, this could work as a different reset.",
                    .moodContrast
                )

            case .tagAffinity(let tag):
                return (
                    "You keep coming back to stories tagged #\(tag), so this is a good match for your archive.",
                    .tagAffinity
                )

            case .strongSentiment(let sentiment):
                return (
                    "This matches the kind of watches you marked as \(sentiment.displayName.lowercased()).",
                    .strongSentiment
                )

            case .highIntensity:
                return (
                    "You tend to remember high-intensity watches, and this fits that stronger emotional lane.",
                    .highIntensity
                )

            case .highTMDBRating(let rating):
                return (
                    "This has a strong TMDB rating of \(String(format: "%.1f", rating)), but the pick is still based on your local history.",
                    .highTMDBRating
                )

            case .recentFavorite:
                return (
                    "Your recent favorites point in this direction.",
                    .recentFavorite
                )

            case .rewatchCandidate:
                return (
                    "You added this before — it may be time to revisit it.",
                    .rewatchCandidate
                )

            case .fallback:
                return (
                    "This matches the kind of stories that stayed with you.",
                    .fallback
                )
            }
        }

        return (
            "This matches the kind of stories that stayed with you.",
            .fallback
        )
    }

    static func confidenceLabel(
        for candidate: SuggestionCandidate
    ) -> String {
        if candidate.sourceEntryId == nil && candidate.isAlreadyWatched == false {
            return "TMDB discovery"
        }

        if candidate.isRewatchCandidate {
            return "Rewatch signal"
        }

        if candidate.signals.contains(where: {
            if case .genreAffinity = $0 { return true }
            return false
        }) {
            return "Genre match"
        }

        if candidate.signals.contains(where: {
            if case .strongSentiment = $0 { return true }
            return false
        }) {
            return "Taste signal"
        }

        if candidate.signals.contains(where: {
            if case .highTMDBRating = $0 { return true }
            return false
        }) {
            return "Metadata boost"
        }

        return "Local match"
    }
}
