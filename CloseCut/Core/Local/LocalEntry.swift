//
//  LocalEntry.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@Model
final class LocalEntry {
    @Attribute(.unique) var id: String

    var ownerId: String

    var title: String
    var normalizedTitle: String
    var typeRaw: String
    var releaseYear: Int?

    var mood: String
    var quickSentimentRaw: String?
    var takeaway: String
    var quote: String?
    var tags: [String]
    var intensity: Int

    var watchContextRaw: String
    
    var watchedDateApproxKindRaw: String?
    var watchedDateApproxExactDate: Date?
    var watchedDateApproxMonth: Int?
    var watchedDateApproxYear: Int?
    var watchedDateApproxDisplayLabel: String?

    var cinemaAudio: Int?
    var cinemaScreen: Int?
    var cinemaComfort: Int?

    var visibilityRaw: String
    var sourceTypeRaw: String

    var watchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatusRaw: String

    init(
        id: String = UUID().uuidString,
        ownerId: String,
        title: String,
        normalizedTitle: String? = nil,
        type: EntryType,
        releaseYear: Int? = nil,
        mood: String = "",
        quickSentiment: QuickSentiment? = nil,
        takeaway: String = "",
        quote: String? = nil,
        tags: [String] = [],
        intensity: Int = 3,
        watchContext: WatchContext = .home,
        watchedDateApprox: WatchedDateApprox? = nil,
        cinemaAudio: Int? = nil,
        cinemaScreen: Int? = nil,
        cinemaComfort: Int? = nil,
        visibility: EntryVisibility = .privateOnly,
        sourceType: EntrySourceType = .fullEntry,
        watchedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.normalizedTitle = normalizedTitle ?? title.normalizedTitleKey
        self.typeRaw = type.rawValue
        self.releaseYear = releaseYear

        self.mood = mood
        self.quickSentimentRaw = quickSentiment?.rawValue
        self.takeaway = takeaway
        self.quote = quote
        self.tags = tags
        self.intensity = intensity

        self.watchContextRaw = watchContext.rawValue
        
        self.watchedDateApproxKindRaw = watchedDateApprox?.kind.rawValue
        self.watchedDateApproxExactDate = watchedDateApprox?.exactDate
        self.watchedDateApproxMonth = watchedDateApprox?.month
        self.watchedDateApproxYear = watchedDateApprox?.year
        self.watchedDateApproxDisplayLabel = watchedDateApprox?.displayLabel
        self.cinemaAudio = cinemaAudio
        self.cinemaScreen = cinemaScreen
        self.cinemaComfort = cinemaComfort

        self.visibilityRaw = visibility.rawValue
        self.sourceTypeRaw = sourceType.rawValue

        self.watchedAt = watchedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt

        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalEntry {
    var watchedDateApprox: WatchedDateApprox? {
        guard let kindRaw = watchedDateApproxKindRaw,
              let kind = ApproxDateKind(rawValue: kindRaw) else {
            return nil
        }

        return WatchedDateApprox(
            kind: kind,
            exactDate: watchedDateApproxExactDate,
            month: watchedDateApproxMonth,
            year: watchedDateApproxYear,
            displayLabel: watchedDateApproxDisplayLabel ?? "Unknown date"
        )
    }

    var domain: Entry {
        Entry(
            id: id,
            ownerId: ownerId,
            title: title,
            normalizedTitle: normalizedTitle.isEmpty ? title.normalizedTitleKey : normalizedTitle,
            type: EntryType(rawValue: typeRaw) ?? .movie,
            releaseYear: releaseYear,
            mood: mood,
            quickSentiment: quickSentimentRaw.flatMap { QuickSentiment(rawValue: $0) },
            takeaway: takeaway,
            quote: quote,
            tags: tags,
            intensity: intensity,
            watchContext: WatchContext(rawValue: watchContextRaw) ?? .home,
            watchedDateApprox: watchedDateApprox,
            cinemaAudio: cinemaAudio,
            cinemaScreen: cinemaScreen,
            cinemaComfort: cinemaComfort,
            visibility: EntryVisibility(rawValue: visibilityRaw) ?? .privateOnly,
            sourceType: EntrySourceType(rawValue: sourceTypeRaw) ?? .fullEntry,
            watchedAt: watchedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }

    func update(from entry: Entry) {
        ownerId = entry.ownerId
        title = entry.title
        normalizedTitle = entry.normalizedTitle
        typeRaw = entry.type.rawValue
        releaseYear = entry.releaseYear

        mood = entry.mood
        quickSentimentRaw = entry.quickSentiment?.rawValue
        takeaway = entry.takeaway
        quote = entry.quote
        tags = entry.tags
        intensity = entry.intensity

        watchContextRaw = entry.watchContext.rawValue
        watchedDateApproxKindRaw = entry.watchedDateApprox?.kind.rawValue
        watchedDateApproxExactDate = entry.watchedDateApprox?.exactDate
        watchedDateApproxMonth = entry.watchedDateApprox?.month
        watchedDateApproxYear = entry.watchedDateApprox?.year
        watchedDateApproxDisplayLabel = entry.watchedDateApprox?.displayLabel
        cinemaAudio = entry.cinemaAudio
        cinemaScreen = entry.cinemaScreen
        cinemaComfort = entry.cinemaComfort

        visibilityRaw = entry.visibility.rawValue
        sourceTypeRaw = entry.sourceType.rawValue

        watchedAt = entry.watchedAt
        createdAt = entry.createdAt
        updatedAt = entry.updatedAt
        deletedAt = entry.deletedAt

        syncStatusRaw = entry.syncStatus.rawValue
    }
}
