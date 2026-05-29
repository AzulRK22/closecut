//
//  EntryMetadataEnrichmentService.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/05/26.
//

import Foundation
import SwiftData

@MainActor
final class EntryMetadataEnrichmentService {
    private let entryRepository: EntryRepository
    private let tmdbRepository: TMDBMediaRepository

    init(
        entryRepository: EntryRepository? = nil,
        tmdbRepository: TMDBMediaRepository? = nil
    ) {
        self.entryRepository = entryRepository ?? EntryRepository()
        self.tmdbRepository = tmdbRepository ?? TMDBMediaRepository()
    }

    func enrichMissingMetadataIfNeeded(
        ownerId: String,
        entries: [Entry],
        maxEntries: Int = 8,
        modelContext: ModelContext
    ) async -> EntryMetadataEnrichmentSummary {
        let cleanedOwnerId = ownerId.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            return EntryMetadataEnrichmentSummary(
                attemptedCount: 0,
                enrichedCount: 0,
                skippedCount: 0,
                failedCount: 1
            )
        }

        guard TMDBConfiguration.hasValidReadAccessToken else {
            #if DEBUG
            print("⚠️ Metadata enrichment skipped: missing TMDB token.")
            #endif

            return EntryMetadataEnrichmentSummary(
                attemptedCount: 0,
                enrichedCount: 0,
                skippedCount: entries.count,
                failedCount: 0
            )
        }

        let candidates = entries
            .filter { $0.ownerId == cleanedOwnerId }
            .filter { $0.deletedAt == nil }
            .filter { shouldAttemptEnrichment($0) }
            .prefix(maxEntries)

        var attemptedCount = 0
        var enrichedCount = 0
        var skippedCount = 0
        var failedCount = 0

        for entry in candidates {
            attemptedCount += 1

            do {
                guard let metadata = try await findMetadata(for: entry) else {
                    skippedCount += 1

                    #if DEBUG
                    print("⚠️ No TMDB metadata match for:", entry.displayTitle)
                    #endif

                    continue
                }

                let before = entry

                let after = try entryRepository.enrichLocalEntryMetadata(
                    entryId: entry.id,
                    metadata: metadata,
                    modelContext: modelContext,
                    shouldEnqueueSync: true
                )

                if didActuallyEnrich(before: before, after: after) {
                    enrichedCount += 1

                    #if DEBUG
                    print("✅ Enriched metadata for:", after.displayTitle)
                    print("   posterPath:", after.posterPath ?? "nil")
                    print("   backdropPath:", after.backdropPath ?? "nil")
                    #endif
                } else {
                    skippedCount += 1
                }
            } catch {
                failedCount += 1

                #if DEBUG
                print("⚠️ Metadata enrichment failed for \(entry.displayTitle):", error.localizedDescription)
                #endif
            }
        }

        return EntryMetadataEnrichmentSummary(
            attemptedCount: attemptedCount,
            enrichedCount: enrichedCount,
            skippedCount: skippedCount,
            failedCount: failedCount
        )
    }

    func forceRefreshMetadata(
        ownerId: String,
        entries: [Entry],
        maxEntries: Int = 20,
        modelContext: ModelContext
    ) async -> EntryMetadataEnrichmentSummary {
        await enrichMissingMetadataIfNeeded(
            ownerId: ownerId,
            entries: entries,
            maxEntries: maxEntries,
            modelContext: modelContext
        )
    }

    // MARK: - Matching

    private func findMetadata(
        for entry: Entry
    ) async throws -> EntryExternalMetadata? {
        let query = entry.displayTitle.trimmed

        guard query.count >= TMDBConfiguration.minimumSearchQueryLength else {
            return nil
        }

        let results = try await tmdbRepository.searchMedia(
            query: query
        )

        #if DEBUG
        print("🔎 TMDB search for:", query)
        print("   Results:", results.map { "\($0.title) (\($0.releaseYear.map(String.init) ?? "n/a")) [\($0.mediaType.rawValue)]" })
        #endif

        guard let bestMatch = bestMatch(
            for: entry,
            in: results
        ) else {
            return nil
        }

        let metadata = EntryExternalMetadata(
            tmdbResult: bestMatch
        )

        return metadata.hasUsefulMetadata ? metadata : nil
    }

    private func bestMatch(
        for entry: Entry,
        in results: [TMDBMediaSearchResult]
    ) -> TMDBMediaSearchResult? {
        let compatibleResults = results.filter { result in
            result.entryType == entry.type
        }

        let exactTitleMatches = compatibleResults.filter { result in
            result.title.normalizedTitleKey == entry.displayTitle.normalizedTitleKey
        }

        if let releaseYear = entry.releaseYear {
            if let exactYearMatch = exactTitleMatches.first(where: { result in
                result.releaseYear == releaseYear
            }) {
                return exactYearMatch
            }

            if let compatibleYearMatch = exactTitleMatches.first(where: { result in
                guard let resultYear = result.releaseYear else {
                    return false
                }

                return abs(resultYear - releaseYear) <= 1
            }) {
                return compatibleYearMatch
            }
        }

        if let exactTitleMatch = exactTitleMatches.first {
            return exactTitleMatch
        }

        return compatibleResults.first
    }

    private func shouldAttemptEnrichment(
        _ entry: Entry
    ) -> Bool {
        guard entry.deletedAt == nil else {
            return false
        }

        if entry.posterPath?.trimmed.isEmpty != false {
            return true
        }

        if entry.backdropPath?.trimmed.isEmpty != false {
            return true
        }

        if entry.overview?.trimmed.isEmpty != false {
            return true
        }

        if entry.tmdbGenreIds.isEmpty {
            return true
        }

        if entry.tmdbRating == nil {
            return true
        }

        return false
    }

    private func didActuallyEnrich(
        before: Entry,
        after: Entry
    ) -> Bool {
        before.posterPath != after.posterPath ||
        before.backdropPath != after.backdropPath ||
        before.overview != after.overview ||
        before.tmdbRating != after.tmdbRating ||
        before.tmdbPopularity != after.tmdbPopularity ||
        before.tmdbGenreIds != after.tmdbGenreIds ||
        before.tmdbId != after.tmdbId ||
        before.tmdbMediaTypeRaw != after.tmdbMediaTypeRaw
    }
}

struct EntryMetadataEnrichmentSummary: Equatable {
    let attemptedCount: Int
    let enrichedCount: Int
    let skippedCount: Int
    let failedCount: Int

    var didEnrichAnything: Bool {
        enrichedCount > 0
    }

    var hasFailures: Bool {
        failedCount > 0
    }

    var userMessage: String {
        if enrichedCount > 0 {
            return "Updated posters and metadata for \(enrichedCount) memories."
        }

        if failedCount > 0 {
            return "Some metadata could not be refreshed."
        }

        return "Your visual metadata is already up to date."
    }
}
