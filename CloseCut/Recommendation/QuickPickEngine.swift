//
//  QuickPickEngine.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

@MainActor
final class QuickPickEngine {
    private let minimumHistoryCount = 3
    private var noRepeatPolicy = NoRepeatPolicy()

    private let seedCandidates: [SuggestionCandidate] = [
        SuggestionCandidate(
            id: "seed-before-sunrise",
            title: "Before Sunrise",
            type: .movie,
            releaseYear: 1995,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-columbus",
            title: "Columbus",
            type: .movie,
            releaseYear: 2017,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-minari",
            title: "Minari",
            type: .movie,
            releaseYear: 2020,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-frances-ha",
            title: "Frances Ha",
            type: .movie,
            releaseYear: 2012,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-about-time",
            title: "About Time",
            type: .movie,
            releaseYear: 2013,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-station-eleven",
            title: "Station Eleven",
            type: .series,
            releaseYear: 2021,
            signals: [.fallback]
        ),
        SuggestionCandidate(
            id: "seed-severance",
            title: "Severance",
            type: .series,
            releaseYear: 2022,
            signals: [.fallback]
        )
    ]

    func generateSuggestion(
        history: [Entry]
    ) -> QuickPickState {
        let activeHistory = history.filter { $0.deletedAt == nil }

        guard activeHistory.count >= minimumHistoryCount else {
            return .insufficientHistory(
                currentCount: activeHistory.count,
                targetCount: minimumHistoryCount
            )
        }

        let candidates = buildCandidates(from: activeHistory)
        let availableCandidates = noRepeatPolicy.filter(candidates)

        guard let selected = rankCandidates(
            availableCandidates,
            history: activeHistory
        ).first else {
            return .error("Couldn’t make a pick right now.")
        }

        noRepeatPolicy.markShown(selected.id)

        let reason = QuickPickReasonBuilder.buildReason(
            for: selected,
            history: activeHistory
        )

        let suggestion = QuickPickSuggestion(
            candidate: selected,
            reason: reason.0,
            reasonCode: reason.1
        )

        if availableCandidates.count == 1 {
            return .noAlternatives(suggestion)
        }

        return .suggestion(suggestion)
    }

    func resetSession() {
        noRepeatPolicy.reset()
    }

    private func buildCandidates(
        from history: [Entry]
    ) -> [SuggestionCandidate] {
        let rewatchCandidates = RewatchRule.candidates(from: history)

        let watchedKeys = Set(
            history.map {
                "\($0.normalizedTitle)|\($0.type.rawValue)"
            }
        )

        let unwatchedSeeds = seedCandidates
            .filter { candidate in
                let key = "\(candidate.title.normalizedTitleKey)|\(candidate.type.rawValue)"
                return watchedKeys.contains(key) == false
            }
            .map { enrich(candidate: $0, with: history) }

        return rewatchCandidates + unwatchedSeeds
    }

    private func enrich(
        candidate: SuggestionCandidate,
        with history: [Entry]
    ) -> SuggestionCandidate {
        var signals = candidate.signals

        if let frequentMood = mostFrequentMood(in: history) {
            signals.insert(.moodContinuity(frequentMood), at: 0)
        }

        if let frequentTag = mostFrequentTag(in: history) {
            signals.append(.tagAffinity(frequentTag))
        }

        if let strongSentiment = mostRecentStrongSentiment(in: history) {
            signals.append(.strongSentiment(strongSentiment))
        }

        return SuggestionCandidate(
            id: candidate.id,
            title: candidate.title,
            type: candidate.type,
            releaseYear: candidate.releaseYear,
            sourceEntryId: candidate.sourceEntryId,
            isAlreadyWatched: candidate.isAlreadyWatched,
            isRewatchCandidate: candidate.isRewatchCandidate,
            signals: signals
        )
    }

    private func rankCandidates(
        _ candidates: [SuggestionCandidate],
        history: [Entry]
    ) -> [SuggestionCandidate] {
        candidates.sorted { first, second in
            score(first, history: history) > score(second, history: history)
        }
    }

    private func score(
        _ candidate: SuggestionCandidate,
        history: [Entry]
    ) -> Int {
        var score = 0

        for signal in candidate.signals {
            switch signal {
            case .moodContinuity:
                score += 3
            case .tagAffinity:
                score += 3
            case .strongSentiment:
                score += 2
            case .highIntensity:
                score += 2
            case .rewatchCandidate:
                score += 4
            case .moodContrast:
                score += 2
            case .fallback:
                score += 1
            }
        }

        return score
    }

    private func mostFrequentMood(in history: [Entry]) -> String? {
        let moods = history
            .map { $0.mood.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return mostFrequentValue(in: moods)
    }

    private func mostFrequentTag(in history: [Entry]) -> String? {
        let tags = history.flatMap { $0.tags }
        return mostFrequentValue(in: tags)
    }

    private func mostRecentStrongSentiment(in history: [Entry]) -> QuickSentiment? {
        history
            .sorted { $0.updatedAt > $1.updatedAt }
            .compactMap { $0.quickSentiment }
            .first { $0 == .loved || $0 == .stayedWithMe }
    }

    private func mostFrequentValue(in values: [String]) -> String? {
        let counts = Dictionary(grouping: values, by: { $0 })
            .mapValues { $0.count }

        return counts
            .sorted { $0.value > $1.value }
            .first?
            .key
    }
}
