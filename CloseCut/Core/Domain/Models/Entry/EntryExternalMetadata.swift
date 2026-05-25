//
//  EntryExternalMetadata.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 07/05/26.
//

import Foundation

enum ExternalMediaSource: String, Codable, CaseIterable, Identifiable {
    case tmdb

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .tmdb:
            return "TMDB"
        }
    }

    var systemImage: String {
        switch self {
        case .tmdb:
            return "sparkles.tv"
        }
    }
}

struct EntryExternalMetadata: Codable, Equatable {
    var source: ExternalMediaSource

    var tmdbId: Int
    var tmdbMediaTypeRaw: String

    var posterPath: String?
    var backdropPath: String?
    var overview: String?

    var tmdbRating: Double?
    var tmdbPopularity: Double?
    var tmdbGenreIds: [Int]

    init(
        source: ExternalMediaSource = .tmdb,
        tmdbId: Int,
        tmdbMediaTypeRaw: String,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        overview: String? = nil,
        tmdbRating: Double? = nil,
        tmdbPopularity: Double? = nil,
        tmdbGenreIds: [Int] = []
    ) {
        self.source = source
        self.tmdbId = tmdbId
        self.tmdbMediaTypeRaw = tmdbMediaTypeRaw
        self.posterPath = posterPath?.trimmed.nilIfEmpty
        self.backdropPath = backdropPath?.trimmed.nilIfEmpty
        self.overview = overview?.trimmed.nilIfEmpty
        self.tmdbRating = tmdbRating
        self.tmdbPopularity = tmdbPopularity
        self.tmdbGenreIds = tmdbGenreIds
    }

    var hasPoster: Bool {
        posterPath?.trimmed.isEmpty == false
    }

    var hasBackdrop: Bool {
        backdropPath?.trimmed.isEmpty == false
    }

    var hasOverview: Bool {
        overview?.trimmed.isEmpty == false
    }

    var hasRating: Bool {
        guard let tmdbRating else {
            return false
        }

        return tmdbRating > 0
    }

    var hasUsefulMetadata: Bool {
        hasPoster ||
        hasBackdrop ||
        hasOverview ||
        hasRating ||
        tmdbGenreIds.isEmpty == false
    }

    var identityKey: String {
        "\(source.rawValue)-\(tmdbMediaTypeRaw)-\(tmdbId)"
    }

    var posterURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: posterPath,
            size: .posterMedium
        )
    }

    var backdropURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: backdropPath,
            size: .backdropMedium
        )
    }
}

extension EntryExternalMetadata {
    init(tmdbResult: TMDBMediaSearchResult) {
        self.init(
            source: .tmdb,
            tmdbId: tmdbResult.tmdbId,
            tmdbMediaTypeRaw: tmdbResult.mediaType.rawValue,
            posterPath: tmdbResult.posterPath,
            backdropPath: tmdbResult.backdropPath,
            overview: tmdbResult.overview,
            tmdbRating: tmdbResult.voteAverage,
            tmdbPopularity: tmdbResult.popularity,
            tmdbGenreIds: tmdbResult.genreIds
        )
    }
}
