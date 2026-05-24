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

    var displayNameText: String {
        let cleaned = displayName.trimmed
        return cleaned.isEmpty ? "Circle member" : cleaned
    }

    var accessibilityLabel: String {
        "\(displayNameText) reacted with \(type.accessibilityLabel)"
    }

    func isOwned(
        by userId: String
    ) -> Bool {
        self.userId.trimmed == userId.trimmed
    }
}

enum CircleReactionType: String, Codable, CaseIterable, Identifiable {
    case loved
    case surprised
    case hitHard
    case fun
    case mustWatch
    case mixed

    var id: String {
        rawValue
    }

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

    var shortReasonText: String {
        switch self {
        case .loved:
            return "Loved this"
        case .surprised:
            return "Surprising"
        case .hitHard:
            return "Hit hard"
        case .fun:
            return "Fun watch"
        case .mustWatch:
            return "Must watch"
        case .mixed:
            return "Mixed feelings"
        }
    }

    var sortPriority: Int {
        switch self {
        case .loved:
            return 0
        case .mustWatch:
            return 1
        case .hitHard:
            return 2
        case .surprised:
            return 3
        case .fun:
            return 4
        case .mixed:
            return 5
        }
    }
}
