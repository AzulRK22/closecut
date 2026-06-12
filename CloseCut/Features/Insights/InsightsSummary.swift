//
//  InsightsSummary.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

struct InsightsSummary: Equatable {
    let overviewStats: InsightOverviewStats

    let totalWatchedCount: Int
    let savedWatchlistCount: Int

    let tasteProfile: TasteProfileInsight
    let moodPattern: MoodPatternInsight
    let genrePattern: GenrePatternInsight
    let watchlistPattern: WatchlistPatternInsight
    let rewatchCandidates: [RewatchCandidateInsight]

    let mediaTypeBreakdown: MediaTypeBreakdownInsight
    let moodBreakdown: MoodBreakdownInsight
    let watchContextBreakdown: WatchContextBreakdownInsight
    let intensityInsight: IntensityInsight

    var hasEnoughData: Bool {
        totalWatchedCount >= 3 || savedWatchlistCount >= 3
    }
}

// MARK: - Premium Overview

struct InsightOverviewStats: Equatable {
    let watchedCount: Int
    let movieCount: Int
    let seriesCount: Int
    let savedCount: Int
    let quickAddCount: Int
    let fullEntryCount: Int
    let sharedMemoryCount: Int
    let cinemaWatchCount: Int
    let averageIntensity: Double
    let highIntensityCount: Int

    var watchedLabel: String {
        watchedCount == 1 ? "story watched" : "stories watched"
    }

    var movieSeriesText: String {
        "\(movieCount) movies · \(seriesCount) series"
    }

    var averageIntensityText: String {
        guard averageIntensity > 0 else {
            return "No signal yet"
        }

        return String(format: "%.1f/5", averageIntensity)
    }
}

struct InsightBreakdownItem: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let count: Int
    let percentage: Double
    let systemImage: String

    var percentageText: String {
        "\(Int(percentage.rounded()))%"
    }
}

struct MediaTypeBreakdownInsight: Equatable {
    let title: String
    let summary: String
    let items: [InsightBreakdownItem]
}

struct MoodBreakdownInsight: Equatable {
    let title: String
    let summary: String
    let items: [InsightBreakdownItem]
}

struct WatchContextBreakdownInsight: Equatable {
    let title: String
    let summary: String
    let items: [InsightBreakdownItem]
}

struct IntensityInsight: Equatable {
    let title: String
    let summary: String
    let averageIntensity: Double
    let highIntensityCount: Int
    let totalSignalCount: Int
}

// MARK: - Existing Insight Models

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
