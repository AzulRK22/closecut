//
//  SuggestionCandidate.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

struct SuggestionCandidate: Identifiable, Equatable {
    let id: String
    let title: String
    let type: EntryType
    let releaseYear: Int?
    let sourceEntryId: String?
    let isAlreadyWatched: Bool
    let isRewatchCandidate: Bool
    let signals: [QuickPickSignal]

    init(
        id: String = UUID().uuidString,
        title: String,
        type: EntryType,
        releaseYear: Int? = nil,
        sourceEntryId: String? = nil,
        isAlreadyWatched: Bool = false,
        isRewatchCandidate: Bool = false,
        signals: [QuickPickSignal] = []
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.releaseYear = releaseYear
        self.sourceEntryId = sourceEntryId
        self.isAlreadyWatched = isAlreadyWatched
        self.isRewatchCandidate = isRewatchCandidate
        self.signals = signals
    }

    var metadata: String {
        if let releaseYear {
            return "\(releaseYear) • \(type.displayName)"
        }

        return type.displayName
    }
}

enum QuickPickSignal: Equatable {
    case moodContinuity(String)
    case moodContrast(String)
    case tagAffinity(String)
    case strongSentiment(QuickSentiment)
    case highIntensity(Int)
    case rewatchCandidate
    case fallback
}
