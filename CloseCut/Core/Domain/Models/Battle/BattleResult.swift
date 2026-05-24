//
//  BattleResult.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum BattleMode: String, Codable, CaseIterable {
    case randomPick
    case headToHead
    case friend
    case circle

    var displayName: String {
        switch self {
        case .randomPick:
            return "Pick for Tonight"
        case .headToHead:
            return "Movie vs Movie"
        case .friend:
            return "Friend Battle"
        case .circle:
            return "Circle Battle"
        }
    }

    var systemImage: String {
        switch self {
        case .randomPick:
            return "shuffle"
        case .headToHead:
            return "bolt.fill"
        case .friend:
            return "person.2.fill"
        case .circle:
            return "person.3.fill"
        }
    }

    var isSocialMode: Bool {
        switch self {
        case .friend, .circle:
            return true
        case .randomPick, .headToHead:
            return false
        }
    }

    var isPersonalMode: Bool {
        isSocialMode == false
    }
}

struct BattleResult: Identifiable, Codable, Equatable {
    let id: String

    var ownerId: String
    var mode: BattleMode
    var title: String

    var optionEntryIds: [String]
    var optionTitles: [String]

    var winnerEntryId: String
    var winnerTitle: String

    var createdAt: Date
}
