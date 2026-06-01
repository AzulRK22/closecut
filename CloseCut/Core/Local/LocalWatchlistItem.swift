//
//  LocalWatchlistItem.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/05/26.
//

import Foundation
import SwiftData

@Model
final class LocalWatchlistItem {
    @Attribute(.unique) var id: String

    var ownerId: String
    var mediaId: String

    var title: String
    var normalizedTitle: String
    var typeRaw: String
    var releaseYear: Int?

    var statusRaw: String
    var sourceRaw: String

    var externalSourceRaw: String?
    var tmdbId: Int?
    var tmdbMediaTypeRaw: String?
    var posterPath: String?
    var backdropPath: String?
    var overview: String?
    var tmdbRating: Double?
    var tmdbPopularity: Double?
    var tmdbGenreIds: [Int]?

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatusRaw: String

    init(
        id: String = UUID().uuidString,
        ownerId: String,
        mediaId: String? = nil,
        title: String,
        normalizedTitle: String? = nil,
        type: EntryType,
        releaseYear: Int? = nil,
        status: WatchlistStatus = .saved,
        source: WatchlistSource = .discover,
        externalMetadata: EntryExternalMetadata? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.ownerId = ownerId.trimmed

        let resolvedMediaId: String

        if let mediaId = mediaId?.trimmed.nilIfBlank {
            resolvedMediaId = mediaId
        } else if let tmdbId = externalMetadata?.tmdbId {
            resolvedMediaId = "\(externalMetadata?.tmdbMediaTypeRaw ?? type.rawValue)-\(tmdbId)"
        } else {
            resolvedMediaId = "\(type.rawValue)-\(title.normalizedTitleKey)"
        }

        self.mediaId = resolvedMediaId

        self.title = title.trimmed
        self.normalizedTitle = normalizedTitle ?? title.normalizedTitleKey
        self.typeRaw = type.rawValue
        self.releaseYear = releaseYear

        self.statusRaw = status.rawValue
        self.sourceRaw = source.rawValue

        self.externalSourceRaw = externalMetadata?.source.rawValue
        self.tmdbId = externalMetadata?.tmdbId
        self.tmdbMediaTypeRaw = externalMetadata?.tmdbMediaTypeRaw
        self.posterPath = externalMetadata?.posterPath
        self.backdropPath = externalMetadata?.backdropPath
        self.overview = externalMetadata?.overview
        self.tmdbRating = externalMetadata?.tmdbRating
        self.tmdbPopularity = externalMetadata?.tmdbPopularity
        self.tmdbGenreIds = externalMetadata?.tmdbGenreIds ?? []

        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt

        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalWatchlistItem {
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
            tmdbGenreIds: tmdbGenreIds ?? []
        )
    }

    var domain: WatchlistItem {
        WatchlistItem(
            id: id,
            ownerId: ownerId,
            mediaId: mediaId,
            title: title,
            normalizedTitle: normalizedTitle.isEmpty ? title.normalizedTitleKey : normalizedTitle,
            type: EntryType(rawValue: typeRaw) ?? .movie,
            releaseYear: releaseYear,
            status: WatchlistStatus(rawValue: statusRaw) ?? .saved,
            source: WatchlistSource(rawValue: sourceRaw) ?? .discover,
            externalSourceRaw: externalSourceRaw,
            tmdbId: tmdbId,
            tmdbMediaTypeRaw: tmdbMediaTypeRaw,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            tmdbRating: tmdbRating,
            tmdbPopularity: tmdbPopularity,
            tmdbGenreIds: tmdbGenreIds ?? [],
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }

    func update(from item: WatchlistItem) {
        ownerId = item.ownerId
        mediaId = item.mediaId

        title = item.title
        normalizedTitle = item.normalizedTitle
        typeRaw = item.type.rawValue
        releaseYear = item.releaseYear

        statusRaw = item.status.rawValue
        sourceRaw = item.source.rawValue

        externalSourceRaw = item.externalSourceRaw
        tmdbId = item.tmdbId
        tmdbMediaTypeRaw = item.tmdbMediaTypeRaw
        posterPath = item.posterPath
        backdropPath = item.backdropPath
        overview = item.overview
        tmdbRating = item.tmdbRating
        tmdbPopularity = item.tmdbPopularity
        tmdbGenreIds = item.tmdbGenreIds

        createdAt = item.createdAt
        updatedAt = item.updatedAt
        deletedAt = item.deletedAt

        syncStatusRaw = item.syncStatus.rawValue
    }
}
