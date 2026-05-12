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
            return "To complete"
        }
    }

    var shortTitle: String {
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
            return "Quick"
        case .needsDetails:
            return "Complete"
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

    var emptyTitle: String {
        switch self {
        case .all:
            return "No memories yet"
        case .movies:
            return "No movies yet"
        case .series:
            return "No series yet"
        case .shared:
            return "No shared memories yet"
        case .quickAdd:
            return "No Quick Adds yet"
        case .needsDetails:
            return "Nothing to complete"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all:
            return "Add a few past watches first, then your library will become searchable and organized."
        case .movies:
            return "Movies you add will appear here."
        case .series:
            return "Series you add will appear here."
        case .shared:
            return "Memories shared with Circles will appear here."
        case .quickAdd:
            return "Fast-added watches will appear here."
        case .needsDetails:
            return "Quick Adds that need mood, takeaway, or tags will appear here."
        }
    }
}
