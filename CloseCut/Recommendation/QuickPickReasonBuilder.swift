//
//  QuickPickReasonBuilder.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

enum QuickPickReasonBuilder {

    // MARK: - Public API

    static func buildReason(
        for candidate: SuggestionCandidate,
        history: [Entry]
    ) -> (String, QuickPickReasonCode) {
        if candidate.isRewatchCandidate {
            return buildRewatchReason(for: candidate)
        }

        if candidate.isTMDBDiscovery {
            return buildDiscoveryReason(for: candidate)
        }

        guard let primarySignal = candidate.signals.first else {
            return (
                "This matches the kind of stories that stayed with you.",
                .fallback
            )
        }

        switch primarySignal {
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
                "This has a strong TMDB rating of \(String(format: "%.1f", rating)), but the pick is still shaped by your own history.",
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

    static func confidenceLabel(
        for candidate: SuggestionCandidate
    ) -> String {
        if candidate.isTMDBDiscovery {
            return "TMDB discovery"
        }

        if candidate.isRewatchCandidate {
            return "Rewatch signal"
        }

        if containsGenreAffinity(candidate.signals) {
            return "Genre match"
        }

        if containsStrongSentiment(candidate.signals) {
            return "Taste signal"
        }

        if containsHighTMDBRating(candidate.signals) {
            return "Metadata boost"
        }

        if containsTagAffinity(candidate.signals) {
            return "Tag match"
        }

        if containsHighIntensity(candidate.signals) {
            return "Strong signal"
        }

        return "Local match"
    }

    // MARK: - Reason Builders

    private static func buildRewatchReason(
        for candidate: SuggestionCandidate
    ) -> (String, QuickPickReasonCode) {
        if let sentiment = firstStrongSentiment(in: candidate.signals) {
            return (
                "You marked this as \(sentiment.displayName.lowercased()). It may be worth revisiting now.",
                .rewatchCandidate
            )
        }

        if let rating = firstHighTMDBRating(in: candidate.signals) {
            return (
                "This was a strong watch in your archive and has a TMDB rating of \(String(format: "%.1f", rating)). It may be a good rewatch.",
                .rewatchCandidate
            )
        }

        if containsHighIntensity(candidate.signals) {
            return (
                "This was one of your higher-intensity memories. It may be worth revisiting now.",
                .rewatchCandidate
            )
        }

        return (
            "You added this before — it may be time to revisit it.",
            .rewatchCandidate
        )
    }

    private static func buildDiscoveryReason(
        for candidate: SuggestionCandidate
    ) -> (String, QuickPickReasonCode) {
        if containsGenreAffinity(candidate.signals) {
            return (
                "Your archive leans toward similar genres, so this TMDB discovery fits the pattern of what tends to stay with you.",
                .genreAffinity
            )
        }

        if let sentiment = firstStrongSentiment(in: candidate.signals) {
            return (
                "This new discovery matches the kind of watches you marked as \(sentiment.displayName.lowercased()).",
                .strongSentiment
            )
        }

        if let rating = firstHighTMDBRating(in: candidate.signals) {
            return (
                "This is a new TMDB discovery with a strong \(String(format: "%.1f", rating)) rating, filtered through your local taste history.",
                .highTMDBRating
            )
        }

        return (
            "This is a new TMDB discovery selected from patterns in your local watch history.",
            .fallback
        )
    }

    // MARK: - Signal Helpers

    private static func containsGenreAffinity(
        _ signals: [QuickPickSignal]
    ) -> Bool {
        signals.contains { signal in
            if case .genreAffinity = signal {
                return true
            }

            return false
        }
    }

    private static func containsStrongSentiment(
        _ signals: [QuickPickSignal]
    ) -> Bool {
        signals.contains { signal in
            if case .strongSentiment = signal {
                return true
            }

            return false
        }
    }

    private static func containsHighTMDBRating(
        _ signals: [QuickPickSignal]
    ) -> Bool {
        signals.contains { signal in
            if case .highTMDBRating = signal {
                return true
            }

            return false
        }
    }

    private static func containsTagAffinity(
        _ signals: [QuickPickSignal]
    ) -> Bool {
        signals.contains { signal in
            if case .tagAffinity = signal {
                return true
            }

            return false
        }
    }

    private static func containsHighIntensity(
        _ signals: [QuickPickSignal]
    ) -> Bool {
        signals.contains { signal in
            if case .highIntensity = signal {
                return true
            }

            return false
        }
    }

    private static func firstStrongSentiment(
        in signals: [QuickPickSignal]
    ) -> QuickSentiment? {
        for signal in signals {
            if case .strongSentiment(let sentiment) = signal {
                return sentiment
            }
        }

        return nil
    }

    private static func firstHighTMDBRating(
        in signals: [QuickPickSignal]
    ) -> Double? {
        for signal in signals {
            if case .highTMDBRating(let rating) = signal {
                return rating
            }
        }

        return nil
    }
}
