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
    var externalMetadata: EntryExternalMetadata?

    init(
        id: String = UUID().uuidString,
        title: String,
        type: EntryType = .movie,
        releaseYear: Int? = nil,
        quickSentiment: QuickSentiment? = nil,
        watchedDateApprox: WatchedDateApprox? = nil,
        externalMetadata: EntryExternalMetadata? = nil
    ) {
        let cleanedTitle = title.trimmed

        self.id = id
        self.title = cleanedTitle
        self.normalizedTitle = cleanedTitle.normalizedTitleKey
        self.type = type
        self.releaseYear = releaseYear
        self.quickSentiment = quickSentiment
        self.watchedDateApprox = watchedDateApprox
        self.externalMetadata = externalMetadata
    }

    var isValid: Bool {
        title.trimmed.isEmpty == false
    }

    var displayTitle: String {
        let cleaned = title.trimmed
        return cleaned.isEmpty ? "Untitled" : cleaned
    }

    var metadataText: String {
        var parts: [String] = []

        if let releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(type.displayName)

        if externalMetadata != nil {
            parts.append("TMDB")
        }

        return parts.joined(separator: " • ")
    }

    var sentimentText: String {
        quickSentiment?.displayName ?? "No reaction yet"
    }

    var sentimentEmojiText: String {
        guard let quickSentiment else {
            return "No reaction yet"
        }

        return "\(quickSentiment.emoji) \(quickSentiment.displayName)"
    }

    var dateText: String {
        watchedDateApprox?.resolvedDisplayLabel ?? "Unknown date"
    }

    var hasExternalMetadata: Bool {
        externalMetadata != nil
    }

    var posterURL: URL? {
        externalMetadata?.posterURL
    }

    func withTitle(
        _ newTitle: String
    ) -> QuickAddDraft {
        QuickAddDraft(
            id: id,
            title: newTitle,
            type: type,
            releaseYear: releaseYear,
            quickSentiment: quickSentiment,
            watchedDateApprox: watchedDateApprox,
            externalMetadata: externalMetadata
        )
    }

    func enriched(
        with metadata: EntryExternalMetadata,
        title: String? = nil,
        releaseYear: Int? = nil,
        type: EntryType? = nil
    ) -> QuickAddDraft {
        QuickAddDraft(
            id: id,
            title: title ?? self.title,
            type: type ?? self.type,
            releaseYear: releaseYear ?? self.releaseYear,
            quickSentiment: quickSentiment,
            watchedDateApprox: watchedDateApprox,
            externalMetadata: metadata
        )
    }
}
