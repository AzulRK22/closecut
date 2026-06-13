//
//  WrapSummary.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

struct WrapSummary: Equatable {
    let period: WrapPeriod

    let watchedCount: Int
    let movieCount: Int
    let seriesCount: Int
    let savedCount: Int
    let sharedCount: Int
    let cinemaCount: Int

    let quickAddCount: Int
    let fullEntryCount: Int

    let topGenres: [WrapRankedItem]
    let savedGenres: [WrapRankedItem]
    let moodSignals: [WrapRankedItem]
    let watchContexts: [WrapRankedItem]

    let dominantMood: WrapRankedItem?
    let topGenre: WrapRankedItem?
    let topEntry: WrapEntryHighlight?
    let strongestEntry: WrapEntryHighlight?
    let posterHighlights: [WrapPosterHighlight]

    let averageIntensity: Double
    let highIntensityCount: Int

    let emotionalTitle: String
    let emotionalSummary: String
    let shareTitle: String

    var hasEnoughData: Bool {
        watchedCount > 0 || savedCount >= 3
    }

    var movieSeriesText: String {
        "\(movieCount) movies · \(seriesCount) series"
    }

    var averageIntensityText: String {
        guard averageIntensity > 0 else {
            return "No signal"
        }

        return String(format: "%.1f/5", averageIntensity)
    }

    var wrappedCountText: String {
        if watchedCount == 1 {
            return "1 story watched"
        }

        return "\(watchedCount) stories watched"
    }
}

struct WrapRankedItem: Identifiable, Equatable {
    let id: String
    let title: String
    let count: Int
    let percentage: Double
    let systemImage: String

    var percentageText: String {
        "\(Int(percentage.rounded()))%"
    }
}

struct WrapEntryHighlight: Identifiable, Equatable {
    let id: String
    let entryId: String
    let title: String
    let subtitle: String
    let reason: String
    let posterPath: String?
    let intensity: Int
}

struct WrapPosterHighlight: Identifiable, Equatable {
    let id: String
    let title: String
    let posterPath: String?
    let type: EntryType
}

struct WrapAvailability: Equatable {
    let latestMonthlyPeriod: WrapPeriod?
    let shouldPromoteMonthlyWrap: Bool
    let canShowLatestMonthlyWrap: Bool

    let allTimePeriod: WrapPeriod?
    let canShowAllTimeRecap: Bool

    var hasAnyWrap: Bool {
        canShowLatestMonthlyWrap || canShowAllTimeRecap
    }
}
