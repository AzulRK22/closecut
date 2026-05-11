//
//  NoRepeatPolicy.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

struct NoRepeatPolicy {
    private let maxRecentlyShownCount: Int
    private(set) var recentlyShownCandidateIds: [String] = []

    init(maxRecentlyShownCount: Int = 8) {
        self.maxRecentlyShownCount = maxRecentlyShownCount
    }

    mutating func markShown(_ candidateId: String) {
        let cleanedCandidateId = candidateId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedCandidateId.isEmpty == false else {
            return
        }

        recentlyShownCandidateIds.removeAll { $0 == cleanedCandidateId }
        recentlyShownCandidateIds.insert(cleanedCandidateId, at: 0)

        if recentlyShownCandidateIds.count > maxRecentlyShownCount {
            recentlyShownCandidateIds = Array(recentlyShownCandidateIds.prefix(maxRecentlyShownCount))
        }
    }

    func filter(_ candidates: [SuggestionCandidate]) -> [SuggestionCandidate] {
        let recentlyShownSet = Set(recentlyShownCandidateIds)

        let filtered = candidates.filter { candidate in
            recentlyShownSet.contains(candidate.id) == false
        }

        return filtered.isEmpty ? candidates : filtered
    }

    mutating func reset() {
        recentlyShownCandidateIds.removeAll()
    }
}
