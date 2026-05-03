//
//  CircleReaction.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import Foundation

struct CircleReaction: Identifiable, Codable, Equatable {
    let id: String
    var entryId: String
    var circleId: String
    var userId: String
    var displayName: String
    var type: CircleReactionType
    var createdAt: Date
    var updatedAt: Date

    var isActive: Bool {
        true
    }
}

enum CircleReactionType: String, Codable, CaseIterable, Identifiable {
    case loved
    case surprised
    case hitHard
    case fun
    case mustWatch
    case mixed

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .loved:
            return "❤️"
        case .surprised:
            return "😮"
        case .hitHard:
            return "😭"
        case .fun:
            return "😂"
        case .mustWatch:
            return "🔥"
        case .mixed:
            return "🤔"
        }
    }

    var title: String {
        switch self {
        case .loved:
            return "Loved"
        case .surprised:
            return "Surprised"
        case .hitHard:
            return "Hit hard"
        case .fun:
            return "Fun"
        case .mustWatch:
            return "Must watch"
        case .mixed:
            return "Mixed"
        }
    }

    var accessibilityLabel: String {
        "\(emoji) \(title)"
    }
}
