//
//  CloseCutEnums.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

enum EntryType: String, Codable, CaseIterable, Identifiable {
    case movie
    case series

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .movie:
            return "Movie"
        case .series:
            return "Series"
        }
    }

    var pluralDisplayName: String {
        switch self {
        case .movie:
            return "Movies"
        case .series:
            return "Series"
        }
    }

    var systemImage: String {
        switch self {
        case .movie:
            return "film.fill"
        case .series:
            return "tv.fill"
        }
    }
}

enum WatchContext: String, Codable, CaseIterable, Identifiable {
    case home
    case cinema

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .home:
            return "Home"
        case .cinema:
            return "Cinema"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house.fill"
        case .cinema:
            return "popcorn.fill"
        }
    }
}

enum EntryVisibility: String, Codable, CaseIterable, Identifiable {
    case privateOnly
    case circle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .privateOnly:
            return "Private"
        case .circle:
            return "Circle"
        }
    }

    var systemImage: String {
        switch self {
        case .privateOnly:
            return "lock.fill"
        case .circle:
            return "person.2.fill"
        }
    }

    var isPrivate: Bool {
        self == .privateOnly
    }

    var requiresCircleSelection: Bool {
        self == .circle
    }
}

enum SyncStatus: String, Codable, CaseIterable {
    case synced
    case pending
    case failed

    var displayName: String {
        switch self {
        case .synced:
            return "Synced"
        case .pending:
            return "Pending"
        case .failed:
            return "Needs retry"
        }
    }

    var systemImage: String {
        switch self {
        case .synced:
            return "checkmark.circle.fill"
        case .pending:
            return "clock.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    var isFinal: Bool {
        self == .synced
    }

    var needsUserAttention: Bool {
        self == .failed
    }
}

enum ReactionType: String, Codable, CaseIterable, Identifiable {
    case loved
    case feltThat
    case surprised
    case comfort
    case heavy
    case iconic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .loved:
            return "Loved"
        case .feltThat:
            return "Felt That"
        case .surprised:
            return "Surprised"
        case .comfort:
            return "Comfort"
        case .heavy:
            return "Heavy"
        case .iconic:
            return "Iconic"
        }
    }

    var symbol: String {
        switch self {
        case .loved:
            return "heart.fill"
        case .feltThat:
            return "sparkles"
        case .surprised:
            return "exclamationmark.bubble.fill"
        case .comfort:
            return "moon.fill"
        case .heavy:
            return "cloud.rain.fill"
        case .iconic:
            return "star.fill"
        }
    }

    var emoji: String {
        switch self {
        case .loved:
            return "❤️"
        case .feltThat:
            return "✨"
        case .surprised:
            return "😮"
        case .comfort:
            return "🌙"
        case .heavy:
            return "🌧️"
        case .iconic:
            return "⭐️"
        }
    }

    var accessibilityLabel: String {
        "\(emoji) \(displayName)"
    }
}
