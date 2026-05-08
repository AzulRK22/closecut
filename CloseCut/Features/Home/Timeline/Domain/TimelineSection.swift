//
//  TimelineSection.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 08/05/26.
//

import Foundation

enum TimelineSectionKind: String, CaseIterable, Identifiable {
    case recentlyWatched
    case stayedWithYou
    case rewatchCandidates
    case highRatedMemories
    case allHistory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recentlyWatched:
            return "Recently watched"
        case .stayedWithYou:
            return "Stayed with you"
        case .rewatchCandidates:
            return "Rewatch candidates"
        case .highRatedMemories:
            return "High-rated memories"
        case .allHistory:
            return "All history"
        }
    }

    var emptySubtitle: String? {
        switch self {
        case .recentlyWatched:
            return "Your latest memories will appear here."
        case .stayedWithYou:
            return "Memories marked as loved or stayed with you will appear here."
        case .rewatchCandidates:
            return "Older meaningful watches will appear here when they may be worth revisiting."
        case .highRatedMemories:
            return "TMDB-rated memories will appear here once metadata is available."
        case .allHistory:
            return "Your complete private archive."
        }
    }
}

struct TimelineSection: Identifiable, Equatable {
    let id: String
    let kind: TimelineSectionKind
    let title: String
    let subtitle: String?
    let entries: [Entry]

    init(
        kind: TimelineSectionKind,
        subtitle: String? = nil,
        entries: [Entry]
    ) {
        self.id = kind.rawValue
        self.kind = kind
        self.title = kind.title
        self.subtitle = subtitle
        self.entries = entries
    }
}
