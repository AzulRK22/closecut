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
    case metadataHighlights
    case allHistory

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .recentlyWatched:
            return "Recently watched"
        case .stayedWithYou:
            return "Stayed with you"
        case .rewatchCandidates:
            return "Rewatch candidates"
        case .metadataHighlights:
            return "Enriched memories"
        case .allHistory:
            return "All history"
        }
    }

    var emptySubtitle: String? {
        switch self {
        case .recentlyWatched:
            return "Your latest memories will appear here."
        case .stayedWithYou:
            return "Memories marked as loved or intense will appear here."
        case .rewatchCandidates:
            return "Older meaningful watches will appear here when they may be worth revisiting."
        case .metadataHighlights:
            return "Memories with useful metadata will appear here."
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
