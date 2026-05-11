//
//  LibraryBrowseFilter.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import Foundation

enum LibraryBrowseFilter: String, CaseIterable, Identifiable {
    case all
    case movies
    case series
    case shared
    case quickAdd
    case needsDetails

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .movies:
            return "Movies"
        case .series:
            return "Series"
        case .shared:
            return "Shared"
        case .quickAdd:
            return "Quick Add"
        case .needsDetails:
            return "Needs details"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "rectangle.stack.fill"
        case .movies:
            return "film.fill"
        case .series:
            return "tv.fill"
        case .shared:
            return "person.2.fill"
        case .quickAdd:
            return "bolt.fill"
        case .needsDetails:
            return "wand.and.stars"
        }
    }
}
