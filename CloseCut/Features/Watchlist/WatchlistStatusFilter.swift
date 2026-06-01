//
//  WatchlistStatusFilter.swift
//  CloseCut
//

import Foundation

enum WatchlistStatusFilter: String, CaseIterable, Identifiable {
    case saved
    case watched
    case dismissed

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .saved:
            return "Saved"
        case .watched:
            return "Watched"
        case .dismissed:
            return "Dismissed"
        }
    }

    var systemImage: String {
        switch self {
        case .saved:
            return "bookmark.fill"
        case .watched:
            return "checkmark.circle.fill"
        case .dismissed:
            return "xmark.circle.fill"
        }
    }
}
