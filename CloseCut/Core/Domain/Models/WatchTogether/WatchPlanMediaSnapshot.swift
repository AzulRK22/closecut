//
//  WatchPlanMediaSnapshot.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation

struct WatchPlanMediaSnapshot: Identifiable, Codable, Equatable {
    let id: String

    var title: String
    var normalizedTitle: String
    var type: EntryType
    var releaseYear: Int?

    var sourceRaw: String
    var sourceId: String?

    var externalSourceRaw: String?
    var tmdbId: Int?
    var tmdbMediaTypeRaw: String?
    var posterPath: String?
    var backdropPath: String?
    var overview: String?
    var tmdbRating: Double?
    var tmdbPopularity: Double?
    var tmdbGenreIds: [Int]

    init(
        id: String = UUID().uuidString,
        title: String,
        normalizedTitle: String? = nil,
        type: EntryType,
        releaseYear: Int? = nil,
        source: WatchPlanMediaSource,
        sourceId: String? = nil,
        externalMetadata: EntryExternalMetadata? = nil,
        overview: String? = nil,
        tmdbRating: Double? = nil,
        tmdbPopularity: Double? = nil,
        tmdbGenreIds: [Int] = []
    ) {
        let cleanedTitle = title.trimmed

        self.id = id
        self.title = cleanedTitle
        self.normalizedTitle = normalizedTitle ?? cleanedTitle.normalizedTitleKey
        self.type = type
        self.releaseYear = releaseYear

        self.sourceRaw = source.rawValue
        self.sourceId = sourceId?.trimmed.nilIfBlank

        self.externalSourceRaw = externalMetadata?.source.rawValue
        self.tmdbId = externalMetadata?.tmdbId
        self.tmdbMediaTypeRaw = externalMetadata?.tmdbMediaTypeRaw
        self.posterPath = externalMetadata?.posterPath
        self.backdropPath = externalMetadata?.backdropPath
        self.overview = externalMetadata?.overview ?? overview
        self.tmdbRating = externalMetadata?.tmdbRating ?? tmdbRating
        self.tmdbPopularity = externalMetadata?.tmdbPopularity ?? tmdbPopularity
        self.tmdbGenreIds = externalMetadata?.tmdbGenreIds ?? tmdbGenreIds
    }

    var source: WatchPlanMediaSource {
        WatchPlanMediaSource(rawValue: sourceRaw) ?? .manual
    }

    var displayTitle: String {
        title.trimmed.isEmpty ? "Untitled" : title.trimmed
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

    var posterURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: posterPath,
            size: .posterMedium
        )
    }
}

enum WatchPlanMediaSource: String, Codable, CaseIterable, Identifiable {
    case entry
    case watchlist
    case discover
    case battle
    case manual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .entry:
            return "Personal"
        case .watchlist:
            return "Want to Watch"
        case .discover:
            return "Discover"
        case .battle:
            return "Battle"
        case .manual:
            return "Manual"
        }
    }

    var systemImage: String {
        switch self {
        case .entry:
            return "film.stack"
        case .watchlist:
            return "bookmark.fill"
        case .discover:
            return "sparkles"
        case .battle:
            return "bolt.fill"
        case .manual:
            return "pencil"
        }
    }
}
