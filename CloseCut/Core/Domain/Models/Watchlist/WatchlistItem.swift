//
//  WatchlistItem.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/05/26.
//

import Foundation

enum WatchlistStatus: String, Codable, CaseIterable, Identifiable {
    case saved
    case watched
    case dismissed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .saved:
            return "Want to Watch"
        case .watched:
            return "Watched"
        case .dismissed:
            return "Dismissed"
        }
    }
}

enum WatchlistSource: String, Codable, CaseIterable, Identifiable {
    case discover
    case search
    case manual
    case circle
    case battle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .discover:
            return "Discover"
        case .search:
            return "Search"
        case .manual:
            return "Manual"
        case .circle:
            return "Circle"
        case .battle:
            return "Battle"
        }
    }
}

struct WatchlistItem: Identifiable, Codable, Equatable {
    let id: String
    var ownerId: String

    var mediaId: String

    var title: String
    var normalizedTitle: String
    var type: EntryType
    var releaseYear: Int?

    var status: WatchlistStatus
    var source: WatchlistSource

    var externalSourceRaw: String?
    var tmdbId: Int?
    var tmdbMediaTypeRaw: String?
    var posterPath: String?
    var backdropPath: String?
    var overview: String?
    var tmdbRating: Double?
    var tmdbPopularity: Double?
    var tmdbGenreIds: [Int]

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatus: SyncStatus

    var isDeleted: Bool {
        deletedAt != nil
    }

    var isSaved: Bool {
        status == .saved && isDeleted == false
    }

    var displayTitle: String {
        let cleanedTitle = title.trimmed
        return cleanedTitle.isEmpty ? "Untitled" : cleanedTitle
    }

    var metadataText: String {
        var parts: [String] = []

        if let releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(type.displayName)

        if let tmdbRating, tmdbRating > 0 {
            parts.append(String(format: "%.1f TMDB", tmdbRating))
        }

        return parts.joined(separator: " • ")
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

    func matchesTMDBMedia(_ media: TMDBMediaSearchResult) -> Bool {
        mediaId == media.watchlistMediaId ||
        (
            tmdbId == media.tmdbId &&
            tmdbMediaTypeRaw == media.mediaType.rawValue
        )
    }
}

extension WatchlistItem {
    init(
        ownerId: String,
        media: TMDBMediaSearchResult,
        source: WatchlistSource = .discover,
        status: WatchlistStatus = .saved,
        syncStatus: SyncStatus = .pending
    ) {
        let now = Date()
        let cleanedTitle = media.title.trimmed

        self.id = UUID().uuidString
        self.ownerId = ownerId.trimmed

        self.mediaId = media.watchlistMediaId

        self.title = cleanedTitle
        self.normalizedTitle = cleanedTitle.normalizedTitleKey
        self.type = media.entryType
        self.releaseYear = media.releaseYear

        self.status = status
        self.source = source

        self.externalSourceRaw = ExternalMediaSource.tmdb.rawValue
        self.tmdbId = media.tmdbId
        self.tmdbMediaTypeRaw = media.mediaType.rawValue
        self.posterPath = media.posterPath
        self.backdropPath = media.backdropPath
        self.overview = media.overview
        self.tmdbRating = media.voteAverage
        self.tmdbPopularity = media.popularity
        self.tmdbGenreIds = media.genreIds

        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil

        self.syncStatus = syncStatus
    }
}

extension TMDBMediaSearchResult {
    var watchlistMediaId: String {
        "\(mediaType.rawValue)-\(tmdbId)"
    }
}
