//
//  FirestoreEntryDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreEntryDTO: Codable {
    var ownerId: String

    // Legacy field. Keep for backward compatibility for now.
    var circleId: String?

    // New multi-circle field.
    var sharedCircleIds: [String]?

    var title: String
    var normalizedTitle: String
    var type: String
    var releaseYear: Int?

    var mood: String
    var quickSentiment: String?
    var takeaway: String
    var quote: String?
    var tags: [String]
    var intensity: Int

    var watchContext: String
    var watchedDateApproxKind: String?
    var watchedDateApproxExactDate: Timestamp?
    var watchedDateApproxMonth: Int?
    var watchedDateApproxYear: Int?
    var watchedDateApproxDisplayLabel: String?

    var cinemaAudio: Int?
    var cinemaScreen: Int?
    var cinemaComfort: Int?

    var visibility: String
    var sourceType: String

    var watchedAt: Timestamp
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var deletedAt: Timestamp?
}

extension FirestoreEntryDTO {
    init(entry: Entry, circleId: String? = nil) {
        self.ownerId = entry.ownerId

        // Legacy compatibility:
        // If caller passes circleId, use it. Otherwise use first shared circle if any.
        self.circleId = circleId ?? entry.sharedCircleIds.first

        self.sharedCircleIds = entry.sharedCircleIds

        self.title = entry.title
        self.normalizedTitle = entry.normalizedTitle
        self.type = entry.type.rawValue
        self.releaseYear = entry.releaseYear

        self.mood = entry.mood
        self.quickSentiment = entry.quickSentiment?.rawValue
        self.takeaway = entry.takeaway
        self.quote = entry.quote
        self.tags = entry.tags
        self.intensity = entry.intensity

        self.watchContext = entry.watchContext.rawValue
        self.watchedDateApproxKind = entry.watchedDateApprox?.kind.rawValue
        self.watchedDateApproxExactDate = entry.watchedDateApprox?.exactDate.map { Timestamp(date: $0) }
        self.watchedDateApproxMonth = entry.watchedDateApprox?.month
        self.watchedDateApproxYear = entry.watchedDateApprox?.year
        self.watchedDateApproxDisplayLabel = entry.watchedDateApprox?.displayLabel

        self.cinemaAudio = entry.cinemaAudio
        self.cinemaScreen = entry.cinemaScreen
        self.cinemaComfort = entry.cinemaComfort

        self.visibility = entry.visibility.rawValue
        self.sourceType = entry.sourceType.rawValue

        self.watchedAt = Timestamp(date: entry.watchedAt)
        self.createdAt = Timestamp(date: entry.createdAt)
        self.updatedAt = Timestamp(date: entry.updatedAt)
        self.deletedAt = entry.deletedAt.map { Timestamp(date: $0) }
    }

    func domain(id: String, syncStatus: SyncStatus = .synced) -> Entry {
        let approxDate: WatchedDateApprox?

        if let watchedDateApproxKind,
           let kind = ApproxDateKind(rawValue: watchedDateApproxKind) {
            approxDate = WatchedDateApprox(
                kind: kind,
                exactDate: watchedDateApproxExactDate?.dateValue(),
                month: watchedDateApproxMonth,
                year: watchedDateApproxYear,
                displayLabel: watchedDateApproxDisplayLabel ?? "Unknown date"
            )
        } else {
            approxDate = nil
        }

        let resolvedSharedCircleIds: [String]

        if let sharedCircleIds {
            resolvedSharedCircleIds = sharedCircleIds
        } else if let circleId {
            resolvedSharedCircleIds = [circleId]
        } else {
            resolvedSharedCircleIds = []
        }

        return Entry(
            id: id,
            ownerId: ownerId,
            title: title,
            normalizedTitle: normalizedTitle.isEmpty ? title.normalizedTitleKey : normalizedTitle,
            type: EntryType(rawValue: type) ?? .movie,
            releaseYear: releaseYear,
            mood: mood,
            quickSentiment: quickSentiment.flatMap { QuickSentiment(rawValue: $0) },
            takeaway: takeaway,
            quote: quote,
            tags: tags,
            intensity: intensity,
            watchContext: WatchContext(rawValue: watchContext) ?? .home,
            watchedDateApprox: approxDate,
            cinemaAudio: cinemaAudio,
            cinemaScreen: cinemaScreen,
            cinemaComfort: cinemaComfort,
            visibility: EntryVisibility(rawValue: visibility) ?? .privateOnly,
            sharedCircleIds: resolvedSharedCircleIds,
            sourceType: EntrySourceType(rawValue: sourceType) ?? .fullEntry,
            watchedAt: watchedAt.dateValue(),
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue(),
            syncStatus: syncStatus
        )
    }
}
