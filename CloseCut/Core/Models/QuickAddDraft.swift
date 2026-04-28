//
//  QuickAddDraft.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 27/04/26.
//

import Foundation

struct QuickAddDraft: Equatable, Identifiable {
    let id: String

    var title: String
    var normalizedTitle: String
    var type: EntryType
    var releaseYear: Int?
    var quickSentiment: QuickSentiment?
    var watchedDateApprox: WatchedDateApprox?

    init(
        id: String = UUID().uuidString,
        title: String,
        type: EntryType = .movie,
        releaseYear: Int? = nil,
        quickSentiment: QuickSentiment? = nil,
        watchedDateApprox: WatchedDateApprox? = nil
    ) {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        self.id = id
        self.title = cleanedTitle
        self.normalizedTitle = cleanedTitle.normalizedTitleKey
        self.type = type
        self.releaseYear = releaseYear
        self.quickSentiment = quickSentiment
        self.watchedDateApprox = watchedDateApprox
    }

    var isValid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
