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

    var isActive: Bool {
        isDeleted == false
    }

    var isQuickAdd: Bool {
        sourceType == .quickAdd
    }

    var isFullEntry: Bool {
        sourceType == .fullEntry
    }

    var isImported: Bool {
        sourceType == .imported
    }

    var hasTitle: Bool {
        displayTitle.trimmed.isEmpty == false
    }

    var hasFullEmotionalDetails: Bool {
        sourceType == .fullEntry &&
        mood.trimmed.isEmpty == false
    }

    var hasAnyPersonalSignal: Bool {
        mood.trimmed.isEmpty == false ||
        quickSentiment != nil ||
        takeaway.trimmed.isEmpty == false ||
        quote?.trimmed.isEmpty == false ||
        tags.isEmpty == false ||
        intensity > 0
    }

    var hasUsefulContentForDetail: Bool {
        primaryBodyText.trimmed.isEmpty == false ||
        quote?.trimmed.isEmpty == false ||
        tags.isEmpty == false ||
        hasCinemaExperience
    }

    var hasTMDBMetadata: Bool {
        externalSourceRaw == ExternalMediaSource.tmdb.rawValue && tmdbId != nil
    }

    var hasPoster: Bool {
        posterPath?.trimmed.isEmpty == false
    }

    var hasBackdrop: Bool {
        backdropPath?.trimmed.isEmpty == false
    }

    var hasCinemaExperience: Bool {
        cinemaAudio != nil ||
        cinemaScreen != nil ||
        cinemaComfort != nil ||
        watchContext == .cinema
    }

    var isRecommendationPositiveSignal: Bool {
        if let quickSentiment {
            return quickSentiment.isPositiveSignal
        }

        return intensity >= 4
    }

    var isRecommendationNegativeSignal: Bool {
        quickSentiment?.isNegativeSignal == true
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

    var isPrivateOnly: Bool {
        visibility == .privateOnly || isSharedWithCircle == false
    }

    func isOwned(
        by userId: String
    ) -> Bool {
        ownerId.trimmed == userId.trimmed
    }

    func isShared(
        with circleId: String
    ) -> Bool {
        activeSharedCircleIds.contains(circleId.trimmed)
    }

    // MARK: - Display Helpers

    var displayTitle: String {
        let cleanedTitle = title.trimmed
        return cleanedTitle.isEmpty ? "Untitled" : cleanedTitle
    }

    var displayMoodText: String {
        let cleanedMood = mood.trimmed

        if cleanedMood.isEmpty == false {
            return cleanedMood
        }

        return quickSentiment?.displayName ?? "No mood yet"
    }

    var displayMoodWithEmoji: String {
        if let quickSentiment, mood.trimmed.isEmpty {
            return "\(quickSentiment.emoji) \(quickSentiment.displayName)"
        }

        let parsedMood = Mood.from(mood)

        if parsedMood != .empty {
            return "\(parsedMood.emoji) \(parsedMood.label)"
        }

        return displayMoodText
    }

    var displayDateText: String {
        watchedDateApprox?.resolvedDisplayLabel
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

    var compactMetadataText: String {
        var parts: [String] = []

        if let releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(type.displayName)

        if sourceType == .quickAdd {
            parts.append("Quick Add")
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

    var sourceDisplayText: String {
        sourceType.displayName
    }

    var primaryBodyText: String {
        let cleanedTakeaway = takeaway.trimmed

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

    var quoteText: String? {
        cleanOptional(quote)
    }

    var cleanTags: [String] {
        Self.cleanTags(tags)
    }

    var topTags: [String] {
        Array(cleanTags.prefix(4))
    }

    var intensityText: String {
        guard intensity > 0 else {
            return "No intensity"
        }

        return "\(intensity)/5"
    }

    var cinemaExperienceSummary: String? {
        guard hasCinemaExperience else {
            return nil
        }

        var parts: [String] = []

        if let cinemaAudio {
            parts.append("Audio \(cinemaAudio)/5")
        }

        if let cinemaScreen {
            parts.append("Screen \(cinemaScreen)/5")
        }

        if let cinemaComfort {
            parts.append("Comfort \(cinemaComfort)/5")
        }

        if parts.isEmpty {
            return "Watched in cinema"
        }

        return parts.joined(separator: " • ")
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

    var externalIdentityKey: String? {
        guard let tmdbId,
              let tmdbMediaTypeRaw else {
            return nil
        }

        return "\(ExternalMediaSource.tmdb.rawValue)-\(tmdbMediaTypeRaw)-\(tmdbId)"
    }

    var normalizedIdentityKey: String {
        if let externalIdentityKey {
            return externalIdentityKey
        }

        return "\(displayTitle.normalizedTitleKey)|\(type.rawValue)"
    }

    // MARK: - Mutation Helpers

    mutating func normalizeForLocalUse() {
        title = displayTitle
        normalizedTitle = displayTitle.normalizedTitleKey
        tags = cleanTags
        sharedCircleIds = activeSharedCircleIds
        mood = mood.trimmed
        takeaway = takeaway.trimmed
        quote = cleanOptional(quote)
        posterPath = cleanOptional(posterPath)
        backdropPath = cleanOptional(backdropPath)
        overview = cleanOptional(overview)
        updatedAt = Date()
    }

    func withUpdatedSharing(
        visibility: EntryVisibility,
        sharedCircleIds: [String]
    ) -> Entry {
        var copy = self
        copy.visibility = visibility
        copy.sharedCircleIds = Self.cleanIds(sharedCircleIds)
        copy.updatedAt = Date()
        return copy
    }

    func enriched(
        with metadata: EntryExternalMetadata
    ) -> Entry {
        var copy = self

        copy.externalSourceRaw = metadata.source.rawValue
        copy.tmdbId = metadata.tmdbId
        copy.tmdbMediaTypeRaw = metadata.tmdbMediaTypeRaw
        copy.posterPath = metadata.posterPath
        copy.backdropPath = metadata.backdropPath
        copy.overview = metadata.overview
        copy.tmdbRating = metadata.tmdbRating
        copy.tmdbPopularity = metadata.tmdbPopularity
        copy.tmdbGenreIds = metadata.tmdbGenreIds
        copy.updatedAt = Date()

        return copy
    }

    // MARK: - Helpers

    private static func cleanIds(
        _ ids: [String]
    ) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmed }
                    .filter { $0.isEmpty == false }
            )
        )
        .sorted()
    }

    private static func cleanTags(
        _ tags: [String]
    ) -> [String] {
        Array(
            Set(
                tags
                    .map { $0.trimmed }
                    .filter { $0.isEmpty == false }
                    .map { $0.lowercased() }
            )
        )
        .sorted()
    }

    private func cleanOptional(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmed
        return cleaned.isEmpty ? nil : cleaned
    }
}
