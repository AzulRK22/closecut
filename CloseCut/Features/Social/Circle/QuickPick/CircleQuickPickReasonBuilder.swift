//
//  CircleQuickPickReasonBuilder.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import Foundation

enum CircleQuickPickReasonBuilder {

    static func buildReason(
        for candidate: SuggestionCandidate,
        sharedEntries: [Entry],
        memberCount: Int
    ) -> (String, QuickPickReasonCode) {
        if candidate.isTMDBDiscovery {
            return buildDiscoveryReason(
                for: candidate,
                sharedEntries: sharedEntries,
                memberCount: memberCount
            )
        }

        if candidate.isRewatchCandidate || candidate.isAlreadyWatched {
            return (
                "This Circle has already shared this title, and the group signals suggest it may be worth revisiting together.",
                .rewatchCandidate
            )
        }

        guard let primarySignal = candidate.signals.first else {
            return (
                "This fits the kind of titles this Circle has been sharing.",
                .fallback
            )
        }

        switch primarySignal {
        case .genreAffinity:
            return (
                "This matches the genres that appear most often in this Circle’s shared history.",
                .genreAffinity
            )

        case .moodContinuity(let mood):
            return (
                "This Circle has been sharing \(mood.lowercased()) memories, and this keeps that group mood going.",
                .moodContinuity
            )

        case .tagAffinity(let tag):
            return (
                "This connects with the #\(tag) pattern in this Circle’s shared entries.",
                .tagAffinity
            )

        case .strongSentiment(let sentiment):
            return (
                "This matches the kind of titles this Circle has marked as \(sentiment.displayName.lowercased()).",
                .strongSentiment
            )

        case .highIntensity:
            return (
                "This Circle has a strong signal for high-intensity watches, so this could work well as a group pick.",
                .highIntensity
            )

        case .highTMDBRating(let rating):
            return (
                "This has a strong TMDB rating of \(String(format: "%.1f", rating)) and matches the group’s shared taste patterns.",
                .highTMDBRating
            )

        case .recentFavorite:
            return (
                "Recent shared memories in this Circle point in this direction.",
                .recentFavorite
            )

        case .rewatchCandidate:
            return (
                "This Circle already has enough signal around this title to make it a strong rewatch option.",
                .rewatchCandidate
            )

        case .moodContrast:
            return (
                "This could work as a different reset after what this Circle has been sharing lately.",
                .moodContrast
            )

        case .fallback:
            return (
                "This fits the kind of titles this Circle has been sharing.",
                .fallback
            )
        }
    }

    static func confidenceLabel(
        for candidate: SuggestionCandidate
    ) -> String {
        if candidate.isTMDBDiscovery {
            return "Group discovery"
        }

        if candidate.isRewatchCandidate {
            return "Group rewatch"
        }

        if containsGenreAffinity(candidate.signals) {
            return "Group genre match"
        }

        if containsStrongSentiment(candidate.signals) {
            return "Shared taste signal"
        }

        if containsHighTMDBRating(candidate.signals) {
            return "Metadata boost"
        }

        if containsTagAffinity(candidate.signals) {
            return "Group tag match"
        }

        if containsHighIntensity(candidate.signals) {
            return "Strong group signal"
        }

        return "Group match"
    }

    private static func buildDiscoveryReason(
        for candidate: SuggestionCandidate,
        sharedEntries: [Entry],
        memberCount: Int
    ) -> (String, QuickPickReasonCode) {
        let groupText = memberCount <= 1 ? "this Circle" : "your group"

        if containsGenreAffinity(candidate.signals) {
            return (
                "Based on the genres \(groupText) has shared, this TMDB discovery fits the group’s current taste pattern.",
                .genreAffinity
            )
        }

        if let sentiment = firstStrongSentiment(in: candidate.signals) {
            return (
                "This discovery matches the kind of watches \(groupText) has marked as \(sentiment.displayName.lowercased()).",
                .strongSentiment
            )
        }

        if let rating = firstHighTMDBRating(in: candidate.signals) {
            return (
                "This is a strong TMDB discovery with a \(String(format: "%.1f", rating)) rating, filtered through this Circle’s shared history.",
                .highTMDBRating
            )
        }

        return (
            "This is a TMDB discovery selected from the shared taste patterns inside this Circle.",
            .fallback
        )
    }

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
