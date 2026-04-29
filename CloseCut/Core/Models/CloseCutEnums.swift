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
}

enum SyncStatus: String, Codable, CaseIterable {
    case synced
    case pending
    case failed
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
}
