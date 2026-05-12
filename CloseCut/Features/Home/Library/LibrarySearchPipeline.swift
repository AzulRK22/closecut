//
//  LibrarySearchPipeline.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import Foundation

enum LibrarySearchPipeline {

    static func process(
        entries: [Entry],
        query: String,
        filter: LibraryBrowseFilter,
        sort: LibrarySortOption
    ) -> [Entry] {
        let activeEntries = entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }

        let searchedEntries = EntrySearchFilter.filter(
            entries: activeEntries,
            query: query
        )

        let filteredEntries = searchedEntries.filter { entry in
            matches(
                entry: entry,
                filter: filter
            )
        }

        return sortEntries(
            filteredEntries,
            sort: sort
        )
    }

    static func matches(
        entry: Entry,
        filter: LibraryBrowseFilter
    ) -> Bool {
        switch filter {
        case .all:
            return true

        case .movies:
            return entry.type == .movie

        case .series:
            return entry.type == .series

        case .shared:
            return entry.visibility == .circle &&
                entry.sharedCircleIds.isEmpty == false

        case .quickAdd:
            return entry.sourceType == .quickAdd

        case .needsDetails:
            return needsDetails(entry)
        }
    }

    static func needsDetails(
        _ entry: Entry
    ) -> Bool {
        guard entry.sourceType == .quickAdd else {
            return false
        }

        return entry.mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            entry.tags.isEmpty
    }

    static func sortEntries(
        _ entries: [Entry],
        sort: LibrarySortOption
    ) -> [Entry] {
        switch sort {
        case .recent:
            return entries.sorted { first, second in
                first.watchedAt > second.watchedAt
            }

        case .alphabetical:
            return entries.sorted { first, second in
                first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }

        case .year:
            return entries.sorted { first, second in
                let firstYear = first.releaseYear ?? Int.min
                let secondYear = second.releaseYear ?? Int.min

                if firstYear != secondYear {
                    return firstYear > secondYear
                }

                return first.watchedAt > second.watchedAt
            }
        }
    }

    static func isSearchOrFilterActive(
        query: String,
        filter: LibraryBrowseFilter
    ) -> Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
            filter != .all
    }
}
