//
//  SuggestionCandidate.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

struct SuggestionCandidate: Identifiable, Equatable {
    let id: String
    let title: String
    let type: EntryType
    let releaseYear: Int?
    let sourceEntryId: String?

    let isAlreadyWatched: Bool
    let isRewatchCandidate: Bool

    let posterPath: String?
    let backdropPath: String?
    let overview: String?
    let tmdbRating: Double?
    let tmdbPopularity: Double?
    let tmdbGenreIds: [Int]

    let signals: [QuickPickSignal]

    init(
        id: String = UUID().uuidString,
        title: String,
        type: EntryType,
        releaseYear: Int? = nil,
        sourceEntryId: String? = nil,
        isAlreadyWatched: Bool = false,
        isRewatchCandidate: Bool = false,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        overview: String? = nil,
        tmdbRating: Double? = nil,
        tmdbPopularity: Double? = nil,
        tmdbGenreIds: [Int] = [],
        signals: [QuickPickSignal] = []
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.releaseYear = releaseYear
        self.sourceEntryId = sourceEntryId
        self.isAlreadyWatched = isAlreadyWatched
        self.isRewatchCandidate = isRewatchCandidate
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.overview = overview
        self.tmdbRating = tmdbRating
        self.tmdbPopularity = tmdbPopularity
        self.tmdbGenreIds = tmdbGenreIds
        self.signals = signals
    }

    init(
        rewatchEntry entry: Entry,
        signals: [QuickPickSignal] = [.rewatchCandidate]
    ) {
        self.init(
            id: "rewatch-\(entry.id)",
            title: entry.title,
            type: entry.type,
            releaseYear: entry.releaseYear,
            sourceEntryId: entry.id,
            isAlreadyWatched: true,
            isRewatchCandidate: true,
            posterPath: entry.posterPath,
            backdropPath: entry.backdropPath,
            overview: entry.overview,
            tmdbRating: entry.tmdbRating,
            tmdbPopularity: entry.tmdbPopularity,
            tmdbGenreIds: entry.tmdbGenreIds,
            signals: signals
        )
    }

    var metadata: String {
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

enum QuickPickSignal: Equatable {
    case moodContinuity(String)
    case moodContrast(String)
    case tagAffinity(String)
    case genreAffinity(Int)
    case strongSentiment(QuickSentiment)
    case highIntensity(Int)
    case highTMDBRating(Double)
    case recentFavorite
    case rewatchCandidate
    case fallback

    var displayLabel: String {
        switch self {
        case .moodContinuity:
            return "Mood match"
        case .moodContrast:
            return "Mood reset"
        case .tagAffinity:
            return "Tag match"
        case .genreAffinity:
            return "Genre match"
        case .strongSentiment:
            return "Strong memory"
        case .highIntensity:
            return "High intensity"
        case .highTMDBRating:
            return "Well rated"
        case .recentFavorite:
            return "Recent favorite"
        case .rewatchCandidate:
            return "Rewatch"
        case .fallback:
            return "Taste match"
        }
    }
}
