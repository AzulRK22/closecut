//
//  BattleGameMode.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import Foundation

enum BattleGameMode: String, CaseIterable, Identifiable {
    case pickTonight
    case headToHead
    case friend
    case circle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pickTonight:
            return "Pick for Tonight"
        case .headToHead:
            return "Movie vs Movie"
        case .friend:
            return "Friend Battle"
        case .circle:
            return "Circle Battle"
        }
    }

    var subtitle: String {
        switch self {
        case .pickTonight:
            return "Build a shortlist from your archive, TMDB, or manual ideas."
        case .headToHead:
            return "A fast mini-quiz to decide which title wins."
        case .friend:
            return "Pass-and-play voting for two people."
        case .circle:
            return "A local group picker for shared watch decisions."
        }
    }

    var systemImage: String {
        switch self {
        case .pickTonight:
            return "shuffle"
        case .headToHead:
            return "bolt.fill"
        case .friend:
            return "person.2.fill"
        case .circle:
            return "person.3.fill"
        }
    }

    var badgeText: String {
        switch self {
        case .pickTonight, .headToHead:
            return "Available now"
        case .friend:
            return "Local mode"
        case .circle:
            return "Local mode"
        }
    }

    var isAvailableNow: Bool {
        true
    }
}
