//
//  WatchlistStatusFilter.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 31/05/26.
//

import SwiftUI

enum WatchlistStatusFilter: String, CaseIterable, Identifiable {
    case saved
    case watched
    case dismissed
    case all

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .saved:
            return "Want"
        case .watched:
            return "Watched"
        case .dismissed:
            return "Dismissed"
        case .all:
            return "All"
        }
    }

    var status: WatchlistStatus? {
        switch self {
        case .saved:
            return .saved
        case .watched:
            return .watched
        case .dismissed:
            return .dismissed
        case .all:
            return nil
        }
    }
}
