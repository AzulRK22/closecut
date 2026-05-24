//
//  Entry.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

struct Entry: Identifiable, Codable, Equatable {
    let id: String
    var ownerId: String

    var title: String
    var normalizedTitle: String
    var type: EntryType
    var releaseYear: Int?

    var mood: String
    var quickSentiment: QuickSentiment?
    var takeaway: String
    var quote: String?
    var tags: [String]
    var intensity: Int

    var watchContext: WatchContext
    var watchedDateApprox: WatchedDateApprox?

    var cinemaAudio: Int?
    var cinemaScreen: Int?
    var cinemaComfort: Int?

    var visibility: EntryVisibility
    var sharedCircleIds: [String]

    var sourceType: EntrySourceType

    var externalSourceRaw: String?
    var tmdbId: Int?
    var tmdbMediaTypeRaw: String?
    var posterPath: String?
    var backdropPath: String?
    var overview: String?
    var tmdbRating: Double?
    var tmdbPopularity: Double?
    var tmdbGenreIds: [Int]

    var watchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatus: SyncStatus

    // MARK: - State

    var isDeleted: Bool {
        deletedAt != nil
    }

    var isQuickAdd: Bool {
        sourceType == .quickAdd
    }

    var hasFullEmotionalDetails: Bool {
        sourceType == .fullEntry &&
        mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var hasTMDBMetadata: Bool {
        externalSourceRaw == ExternalMediaSource.tmdb.rawValue && tmdbId != nil
    }

    // MARK: - Sharing

    var activeSharedCircleIds: [String] {
        Self.cleanIds(sharedCircleIds)
    }

    var isSharedWithCircle: Bool {
        visibility == .circle && activeSharedCircleIds.isEmpty == false
    }

    var shouldAppearInCircleTimeline: Bool {
        isDeleted == false && isSharedWithCircle
    }

    func isShared(with circleId: String) -> Bool {
        activeSharedCircleIds.contains(
            circleId.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - Display Helpers

    var displayTitle: String {
        let cleanedTitle = title.trimmed
        return cleanedTitle.isEmpty ? "Untitled" : cleanedTitle
    }

    var displayMoodText: String {
        let cleanedMood = mood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedMood.isEmpty {
            return quickSentiment?.displayName ?? "No mood yet"
        }

        return cleanedMood
    }

    var displayDateText: String {
        watchedDateApprox?.displayLabel
            ?? watchedAt.formatted(date: .abbreviated, time: .omitted)
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

    var sharingStatusText: String {
        guard isSharedWithCircle else {
            return "Private"
        }

        if activeSharedCircleIds.count == 1 {
            return "Shared with 1 Circle"
        }

        return "Shared with \(activeSharedCircleIds.count) Circles"
    }

    var quickAddStatusText: String? {
        sourceType == .quickAdd ? "Quick Add" : nil
    }

    var primaryBodyText: String {
        let cleanedTakeaway = takeaway.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedTakeaway.isEmpty == false {
            return cleanedTakeaway
        }

        if let overview = cleanOptional(overview) {
            return overview
        }

        if let quickSentiment {
            return quickSentiment.displayName
        }

        return sourceType == .quickAdd
            ? "Added to your history"
            : "No takeaway added yet."
    }

    // MARK: - External Metadata

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
        TMDBImageURLBuilder.imageURL(path: posterPath)
    }

    var backdropURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: backdropPath,
            size: .backdropMedium
        )
    }

    // MARK: - Helpers

    private static func cleanIds(_ ids: [String]) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
