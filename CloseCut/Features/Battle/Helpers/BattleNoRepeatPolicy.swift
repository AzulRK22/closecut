//
//  BattleNoRepeatPolicy.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import Foundation

struct BattleNoRepeatPolicy {
    private let maxRecentlyPickedCount: Int
    private(set) var recentlyPickedCandidateIds: [String] = []

    init(maxRecentlyPickedCount: Int = 8) {
        self.maxRecentlyPickedCount = maxRecentlyPickedCount
    }

    mutating func markPicked(
        _ candidateId: String
    ) {
        let cleanedId = candidateId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedId.isEmpty == false else {
            return
        }

        recentlyPickedCandidateIds.removeAll { $0 == cleanedId }
        recentlyPickedCandidateIds.insert(cleanedId, at: 0)

        if recentlyPickedCandidateIds.count > maxRecentlyPickedCount {
            recentlyPickedCandidateIds = Array(
                recentlyPickedCandidateIds.prefix(maxRecentlyPickedCount)
            )
        }
    }

    func filter(
        _ candidates: [BattleCandidate]
    ) -> [BattleCandidate] {
        let recentlyPickedSet = Set(recentlyPickedCandidateIds)

        let filtered = candidates.filter {
            recentlyPickedSet.contains($0.id) == false
        }

        return filtered.isEmpty ? candidates : filtered
    }

    mutating func pickRandom(
        from candidates: [BattleCandidate],
        avoiding currentCandidateId: String? = nil
    ) -> BattleCandidate? {
        let validCandidates = candidates.filter {
            $0.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }

        guard validCandidates.isEmpty == false else {
            return nil
        }

        var available = filter(validCandidates)

        if let currentCandidateId,
           available.count > 1 {
            let alternatives = available.filter { $0.id != currentCandidateId }
            available = alternatives.isEmpty ? available : alternatives
        }

        guard let picked = available.randomElement() else {
            return nil
        }

        markPicked(picked.id)
        return picked
    }

    mutating func reset() {
        recentlyPickedCandidateIds.removeAll()
    }
}
