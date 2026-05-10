//
//  EntryExternalMetadata.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 07/05/26.
//

import Foundation

enum ExternalMediaSource: String, Codable {
    case tmdb

    var displayName: String {
        switch self {
        case .tmdb:
            return "TMDB"
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
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.overview = overview
        self.tmdbRating = tmdbRating
        self.tmdbPopularity = tmdbPopularity
        self.tmdbGenreIds = tmdbGenreIds
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
