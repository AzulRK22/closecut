//
//  InsightsSummary.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

struct InsightsSummary: Equatable {
    let totalWatchedCount: Int
    let savedWatchlistCount: Int

    let tasteProfile: TasteProfileInsight
    let moodPattern: MoodPatternInsight
    let genrePattern: GenrePatternInsight
    let watchlistPattern: WatchlistPatternInsight
    let rewatchCandidates: [RewatchCandidateInsight]

    var hasEnoughData: Bool {
        totalWatchedCount >= 3 || savedWatchlistCount >= 3
    }
}

struct TasteProfileInsight: Equatable {
    let title: String
    let summary: String
    let traits: [TasteTrait]
}

struct TasteTrait: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String

    init(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

struct MoodPatternInsight: Equatable {
    let title: String
    let summary: String
    let dominantMood: String?
    let dominantSentiment: String?
    let emotionalSignalCount: Int
}

struct GenrePatternInsight: Equatable {
    let title: String
    let summary: String
    let watchedGenres: [GenreCount]
    let watchlistGenres: [GenreCount]
    let overlapGenres: [String]
}

struct WatchlistPatternInsight: Equatable {
    let title: String
    let summary: String
    let savedCount: Int
    let movieCount: Int
    let seriesCount: Int
    let topGenres: [GenreCount]
    let oldestSavedTitle: String?
    let highestRatedTitle: String?
}

struct RewatchCandidateInsight: Identifiable, Equatable {
    let id: String
    let entryId: String
    let title: String
    let subtitle: String
    let reason: String
    let score: Int
    let posterPath: String?
}

struct GenreCount: Identifiable, Equatable {
    let id: Int
    let name: String
    let count: Int
}
