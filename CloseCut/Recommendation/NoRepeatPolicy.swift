//
//  NoRepeatPolicy.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

struct NoRepeatPolicy {
    private(set) var recentlyShownCandidateIds: Set<String> = []

    mutating func markShown(_ candidateId: String) {
        recentlyShownCandidateIds.insert(candidateId)
    }

    func filter(_ candidates: [SuggestionCandidate]) -> [SuggestionCandidate] {
        let filtered = candidates.filter {
            recentlyShownCandidateIds.contains($0.id) == false
        }

        return filtered.isEmpty ? candidates : filtered
    }

    mutating func reset() {
        recentlyShownCandidateIds.removeAll()
    }
}
