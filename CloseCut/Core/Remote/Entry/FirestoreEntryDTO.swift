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

    // Legacy field. Keep for backward compatibility while sharedCircleIds becomes the source of truth.
    var circleId: String?

    // Multi-circle field.
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

    var externalSource: String?
    var tmdbId: Int?
    var tmdbMediaType: String?
    var posterPath: String?
    var backdropPath: String?
    var overview: String?
    var tmdbRating: Double?
    var tmdbPopularity: Double?
    var tmdbGenreIds: [Int]?

    var watchedAt: Timestamp
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var deletedAt: Timestamp?
}

extension FirestoreEntryDTO {
    init(
        entry: Entry,
        circleId: String? = nil
    ) {
        let cleanedSharedCircleIds = entry.sharedCircleIds.cleanedUniqueIds
        let cleanedLegacyCircleId = circleId.trimmedOrNil

        self.ownerId = entry.ownerId

        // Legacy compatibility:
        // New code should rely on sharedCircleIds.
        // circleId remains populated only to support old data / old queries.
        self.circleId = cleanedLegacyCircleId ?? cleanedSharedCircleIds.first
        self.sharedCircleIds = cleanedSharedCircleIds

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
        self.watchedDateApproxExactDate = entry.watchedDateApprox?.exactDate.map {
            Timestamp(date: $0)
        }
        self.watchedDateApproxMonth = entry.watchedDateApprox?.month
        self.watchedDateApproxYear = entry.watchedDateApprox?.year
        self.watchedDateApproxDisplayLabel = entry.watchedDateApprox?.displayLabel

        self.cinemaAudio = entry.cinemaAudio
        self.cinemaScreen = entry.cinemaScreen
        self.cinemaComfort = entry.cinemaComfort

        self.visibility = entry.visibility.rawValue
        self.sourceType = entry.sourceType.rawValue

        self.externalSource = entry.externalSourceRaw
        self.tmdbId = entry.tmdbId
        self.tmdbMediaType = entry.tmdbMediaTypeRaw
        self.posterPath = entry.posterPath
        self.backdropPath = entry.backdropPath
        self.overview = entry.overview
        self.tmdbRating = entry.tmdbRating
        self.tmdbPopularity = entry.tmdbPopularity
        self.tmdbGenreIds = entry.tmdbGenreIds

        self.watchedAt = Timestamp(date: entry.watchedAt)
        self.createdAt = Timestamp(date: entry.createdAt)
        self.updatedAt = Timestamp(date: entry.updatedAt)
        self.deletedAt = entry.deletedAt.map {
            Timestamp(date: $0)
        }
    }

    func domain(
        id: String,
        syncStatus: SyncStatus = .synced
    ) -> Entry {
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
            resolvedSharedCircleIds = sharedCircleIds.cleanedUniqueIds
        } else if let circleId {
            resolvedSharedCircleIds = [circleId].cleanedUniqueIds
        } else {
            resolvedSharedCircleIds = []
        }

        let resolvedVisibility: EntryVisibility

        if resolvedSharedCircleIds.isEmpty {
            resolvedVisibility = .privateOnly
        } else {
            resolvedVisibility = EntryVisibility(rawValue: visibility) ?? .circle
        }

        return Entry(
            id: id,
            ownerId: ownerId,
            title: title,
            normalizedTitle: normalizedTitle.isEmpty ? title.normalizedTitleKey : normalizedTitle,
            type: EntryType(rawValue: type) ?? .movie,
            releaseYear: releaseYear,
            mood: mood,
            quickSentiment: quickSentiment.flatMap {
                QuickSentiment(rawValue: $0)
            },
            takeaway: takeaway,
            quote: quote,
            tags: tags,
            intensity: intensity,
            watchContext: WatchContext(rawValue: watchContext) ?? .home,
            watchedDateApprox: approxDate,
            cinemaAudio: cinemaAudio,
            cinemaScreen: cinemaScreen,
            cinemaComfort: cinemaComfort,
            visibility: resolvedVisibility,
            sharedCircleIds: resolvedSharedCircleIds,
            sourceType: EntrySourceType(rawValue: sourceType) ?? .fullEntry,
            externalSourceRaw: externalSource,
            tmdbId: tmdbId,
            tmdbMediaTypeRaw: tmdbMediaType,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            tmdbRating: tmdbRating,
            tmdbPopularity: tmdbPopularity,
            tmdbGenreIds: tmdbGenreIds ?? [],
            watchedAt: watchedAt.dateValue(),
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue(),
            syncStatus: syncStatus
        )
    }
}
