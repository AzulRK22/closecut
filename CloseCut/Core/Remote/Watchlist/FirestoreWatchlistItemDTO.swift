//
//  FirestoreWatchlistItemDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/05/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreWatchlistItemDTO: Codable {
    var ownerId: String
    var mediaId: String

    var title: String
    var normalizedTitle: String
    var type: String
    var releaseYear: Int?

    var status: String
    var source: String

    var externalSource: String?
    var tmdbId: Int?
    var tmdbMediaType: String?
    var posterPath: String?
    var backdropPath: String?
    var overview: String?
    var tmdbRating: Double?
    var tmdbPopularity: Double?
    var tmdbGenreIds: [Int]?

    var createdAt: Timestamp
    var updatedAt: Timestamp
    var deletedAt: Timestamp?
}

extension FirestoreWatchlistItemDTO {
    init(item: WatchlistItem) {
        self.ownerId = item.ownerId
        self.mediaId = item.mediaId

        self.title = item.title
        self.normalizedTitle = item.normalizedTitle
        self.type = item.type.rawValue
        self.releaseYear = item.releaseYear

        self.status = item.status.rawValue
        self.source = item.source.rawValue

        self.externalSource = item.externalSourceRaw
        self.tmdbId = item.tmdbId
        self.tmdbMediaType = item.tmdbMediaTypeRaw
        self.posterPath = item.posterPath
        self.backdropPath = item.backdropPath
        self.overview = item.overview
        self.tmdbRating = item.tmdbRating
        self.tmdbPopularity = item.tmdbPopularity
        self.tmdbGenreIds = item.tmdbGenreIds

        self.createdAt = Timestamp(date: item.createdAt)
        self.updatedAt = Timestamp(date: item.updatedAt)
        self.deletedAt = item.deletedAt.map {
            Timestamp(date: $0)
        }
    }

    func domain(
        id: String,
        syncStatus: SyncStatus = .synced
    ) -> WatchlistItem {
        WatchlistItem(
            id: id,
            ownerId: ownerId,
            mediaId: mediaId,
            title: title,
            normalizedTitle: normalizedTitle.isEmpty ? title.normalizedTitleKey : normalizedTitle,
            type: EntryType(rawValue: type) ?? .movie,
            releaseYear: releaseYear,
            status: WatchlistStatus(rawValue: status) ?? .saved,
            source: WatchlistSource(rawValue: source) ?? .discover,
            externalSourceRaw: externalSource,
            tmdbId: tmdbId,
            tmdbMediaTypeRaw: tmdbMediaType,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            tmdbRating: tmdbRating,
            tmdbPopularity: tmdbPopularity,
            tmdbGenreIds: tmdbGenreIds ?? [],
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue(),
            syncStatus: syncStatus
        )
    }
}
