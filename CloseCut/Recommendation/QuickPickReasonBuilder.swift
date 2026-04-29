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
            return (
                "You added this before — it may be time to revisit it.",
                .rewatchCandidate
            )
        }

        if let signal = candidate.signals.first {
            switch signal {
            case .moodContinuity(let mood):
                return (
                    "You have been logging \(mood.lowercased()) picks lately.",
                    .moodContinuity
                )

            case .moodContrast(let mood):
                return (
                    "After a few \(mood.lowercased()) watches, this could be a different reset.",
                    .moodContrast
                )

            case .tagAffinity(let tag):
                return (
                    "You keep coming back to stories tagged #\(tag).",
                    .tagAffinity
                )

            case .strongSentiment(let sentiment):
                return (
                    "This matches the kind of watches you marked as \(sentiment.displayName.lowercased()).",
                    .strongSentiment
                )

            case .highIntensity:
                return (
                    "You tend to remember high-intensity watches like this one.",
                    .highIntensity
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
}
