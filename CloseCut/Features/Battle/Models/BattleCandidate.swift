//
//  BattleCandidate.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import Foundation

struct BattleCandidate: Identifiable, Equatable, Hashable {
    let id: String
    let source: BattleCandidateSource

    let title: String
    let normalizedTitle: String
    let type: EntryType
    let releaseYear: Int?

    let sourceEntryId: String?
    let tmdbId: Int?
    let tmdbMediaTypeRaw: String?

    let posterPath: String?
    let backdropPath: String?
    let overview: String?
    let tmdbRating: Double?
    let tmdbPopularity: Double?
    let tmdbGenreIds: [Int]

    let moodText: String?
    let quickSentiment: QuickSentiment?
    let takeaway: String?
    let watchedAt: Date?
    let isShared: Bool
    let isQuickAdd: Bool

    init(
        id: String,
        source: BattleCandidateSource,
        title: String,
        normalizedTitle: String? = nil,
        type: EntryType,
        releaseYear: Int? = nil,
        sourceEntryId: String? = nil,
        tmdbId: Int? = nil,
        tmdbMediaTypeRaw: String? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        overview: String? = nil,
        tmdbRating: Double? = nil,
        tmdbPopularity: Double? = nil,
        tmdbGenreIds: [Int] = [],
        moodText: String? = nil,
        quickSentiment: QuickSentiment? = nil,
        takeaway: String? = nil,
        watchedAt: Date? = nil,
        isShared: Bool = false,
        isQuickAdd: Bool = false
    ) {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        self.id = id
        self.source = source
        self.title = cleanedTitle.isEmpty ? "Untitled" : cleanedTitle
        self.normalizedTitle = normalizedTitle ?? cleanedTitle.normalizedTitleKey
        self.type = type
        self.releaseYear = releaseYear
        self.sourceEntryId = sourceEntryId
        self.tmdbId = tmdbId
        self.tmdbMediaTypeRaw = tmdbMediaTypeRaw
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.overview = overview
        self.tmdbRating = tmdbRating
        self.tmdbPopularity = tmdbPopularity
        self.tmdbGenreIds = tmdbGenreIds
        self.moodText = moodText
        self.quickSentiment = quickSentiment
        self.takeaway = takeaway
        self.watchedAt = watchedAt
        self.isShared = isShared
        self.isQuickAdd = isQuickAdd
    }

    var displayTitle: String {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Untitled" : cleaned
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

        if isQuickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    var sourceLabelText: String {
        source.displayName
    }

    var primarySignalText: String {
        if let moodText = cleanOptional(moodText) {
            return moodText
        }

        if let quickSentiment {
            return quickSentiment.displayName
        }

        if source == .tmdb {
            return "Discovery option"
        }

        if source == .manual {
            return "Added for this Battle"
        }

        return "Archive option"
    }

    var descriptionText: String {
        if let takeaway = cleanOptional(takeaway) {
            return takeaway
        }

        if let overview = cleanOptional(overview) {
            return overview
        }

        switch source {
        case .archive:
            return "From your Personal Timeline."
        case .watchlist:
            return "Saved in Want to Watch and ready for the right moment."
        case .tmdb:
            return "Added from TMDB for this decision."
        case .manual:
            return "Manual option for this Battle."
        }
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

    var normalizedIdentityKey: String {
        if let tmdbId, let tmdbMediaTypeRaw {
            return "tmdb-\(tmdbMediaTypeRaw)-\(tmdbId)"
        }

        return "\(displayTitle.normalizedTitleKey)|\(type.rawValue)"
    }

    var isExternal: Bool {
        source == .watchlist || source == .tmdb || source == .manual
    }

    var canPersistAsBattleResult: Bool {
        source == .archive && sourceEntryId != nil
    }

    var canBeSavedToTimeline: Bool {
        source == .watchlist || source == .tmdb || source == .manual
    }

    var hasUsefulMetadata: Bool {
        posterPath != nil ||
        cleanOptional(overview) != nil ||
        tmdbRating != nil ||
        tmdbGenreIds.isEmpty == false
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
