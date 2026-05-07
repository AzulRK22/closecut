//
//  Entry.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

struct Entry: Identifiable, Codable, Equatable {
    let id: String
    var ownerId: String

    var title: String
    var normalizedTitle: String
    var type: EntryType
    var releaseYear: Int?

    var mood: String
    var quickSentiment: QuickSentiment?
    var takeaway: String
    var quote: String?
    var tags: [String]
    var intensity: Int

    var watchContext: WatchContext
    var watchedDateApprox: WatchedDateApprox?

    var cinemaAudio: Int?
    var cinemaScreen: Int?
    var cinemaComfort: Int?

    var visibility: EntryVisibility
    var sharedCircleIds: [String]

    var sourceType: EntrySourceType

    var externalSourceRaw: String?
    var tmdbId: Int?
    var tmdbMediaTypeRaw: String?
    var posterPath: String?
    var backdropPath: String?
    var overview: String?
    var tmdbRating: Double?
    var tmdbPopularity: Double?
    var tmdbGenreIds: [Int]

    var watchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatus: SyncStatus

    var isSharedWithCircle: Bool {
        visibility == .circle || sharedCircleIds.isEmpty == false
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    var isQuickAdd: Bool {
        sourceType == .quickAdd
    }

    var hasFullEmotionalDetails: Bool {
        sourceType == .fullEntry &&
        mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var hasTMDBMetadata: Bool {
        externalSourceRaw == ExternalMediaSource.tmdb.rawValue && tmdbId != nil
    }

    var externalMetadata: EntryExternalMetadata? {
        guard let tmdbId,
              let tmdbMediaTypeRaw else {
            return nil
        }

        return EntryExternalMetadata(
            source: ExternalMediaSource(rawValue: externalSourceRaw ?? "") ?? .tmdb,
            tmdbId: tmdbId,
            tmdbMediaTypeRaw: tmdbMediaTypeRaw,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            tmdbRating: tmdbRating,
            tmdbPopularity: tmdbPopularity,
            tmdbGenreIds: tmdbGenreIds
        )
    }

    var posterURL: URL? {
        TMDBImageURLBuilder.imageURL(path: posterPath)
    }

    var backdropURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: backdropPath,
            size: .backdropMedium
        )
    }
}
