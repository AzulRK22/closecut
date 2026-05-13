//
//  QuickAddSuggestion.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation

struct QuickAddSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let type: EntryType
    let releaseYear: Int?

    init(
        id: String = UUID().uuidString,
        title: String,
        type: EntryType = .movie,
        releaseYear: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.releaseYear = releaseYear
    }

    var metadata: String {
        let yearText = releaseYear.map { "\($0)" } ?? "Unknown year"
        return "\(yearText) • \(type.displayName)"
    }
}
