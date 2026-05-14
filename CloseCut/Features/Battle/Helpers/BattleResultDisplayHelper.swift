//
//  BattleResultDisplayHelper.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import Foundation

enum BattleResultDisplayHelper {
    static func subtitle(
        for result: BattleResult
    ) -> String {
        switch result.mode {
        case .randomPick:
            return "Picked from \(result.optionTitles.count) options"

        case .headToHead:
            let opponents = result.optionTitles.filter {
                $0 != result.winnerTitle
            }

            if let opponent = opponents.first {
                return "Won against \(opponent)"
            }

            return "Won a head-to-head Battle"

        case .friend:
            return "Won a Friend Battle"

        case .circle:
            return "Won a Circle Battle"
        }
    }

    static func subtitle(
        for candidate: BattleCandidate
    ) -> String {
        candidate.metadataText
    }

    static func primaryDescription(
        for candidate: BattleCandidate
    ) -> String {
        candidate.descriptionText
    }

    static func resultLabel(
        optionCount: Int
    ) -> String {
        optionCount == 2
            ? "Head-to-head energy"
            : "Picked from \(optionCount) options"
    }
}
