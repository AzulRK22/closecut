//
//  LibrarySortOption.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import Foundation

enum LibrarySortOption: String, CaseIterable, Identifiable {
    case recent
    case alphabetical
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent:
            return "Recent"
        case .alphabetical:
            return "A–Z"
        case .year:
            return "Year"
        }
    }

    var systemImage: String {
        switch self {
        case .recent:
            return "clock.fill"
        case .alphabetical:
            return "textformat.abc"
        case .year:
            return "calendar"
        }
    }
}
