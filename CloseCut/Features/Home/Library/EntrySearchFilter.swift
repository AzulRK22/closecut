//
//  EntrySearchFilter.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import Foundation

enum EntrySearchFilter {
    static func filter(
        entries: [Entry],
        query: String
    ) -> [Entry] {
        let cleanedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard cleanedQuery.isEmpty == false else {
            return entries
        }

        return entries.filter { entry in
            searchableText(for: entry)
                .lowercased()
                .contains(cleanedQuery)
        }
    }

    private static func searchableText(for entry: Entry) -> String {
        var parts: [String] = [
            entry.title,
            entry.normalizedTitle,
            entry.type.displayName,
            entry.mood,
            entry.takeaway,
            entry.quote ?? "",
            entry.watchContext.displayName,
            entry.visibility.displayName,
            entry.sourceType.displayName
        ]

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        if let quickSentiment = entry.quickSentiment {
            parts.append(quickSentiment.displayName)
            parts.append(quickSentiment.rawValue)
        }

        if let rating = entry.tmdbRating {
            parts.append(String(format: "%.1f", rating))
        }

        parts.append(contentsOf: entry.tags)
        parts.append(contentsOf: entry.tmdbGenreIds.map { "\($0)" })

        if entry.visibility == .circle,
           entry.sharedCircleIds.isEmpty == false {
            parts.append("shared")
            parts.append("circle")
        } else {
            parts.append("private")
        }

        if entry.sourceType == .quickAdd {
            parts.append("quick add")
        }

        return parts.joined(separator: " ")
    }
}
