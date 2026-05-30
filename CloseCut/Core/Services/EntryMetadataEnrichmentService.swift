//
//  EntryMetadataEnrichmentService.swift
//  CloseCut
//

import Foundation
import SwiftData

struct EntryMetadataEnrichmentSummary: Equatable {
    let scannedCount: Int
    let enrichedCount: Int
    let skippedCount: Int
    let failedCount: Int

    var didEnrichAnything: Bool {
        enrichedCount > 0
    }

    var hasFailures: Bool {
        failedCount > 0
    }
}

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

    func enrichMissingMetadata(
        entries: [Entry],
        modelContext: ModelContext
    ) async -> EntryMetadataEnrichmentSummary {
        guard TMDBConfiguration.hasValidReadAccessToken else {
            return EntryMetadataEnrichmentSummary(
                scannedCount: entries.count,
                enrichedCount: 0,
                skippedCount: entries.count,
                failedCount: 0
            )
        }

        let candidates = entries
            .filter { $0.deletedAt == nil }
            .filter { shouldAttemptEnrichment($0) }

        var enrichedCount = 0
        var skippedCount = entries.count - candidates.count
        var failedCount = 0

        for entry in candidates {
            do {
                guard let metadata = try await fetchBestMetadata(for: entry) else {
                    skippedCount += 1
                    continue
                }

                let enrichedEntry = try entryRepository.enrichLocalEntryMetadata(
                    entryId: entry.id,
                    metadata: metadata,
                    modelContext: modelContext,
                    shouldEnqueueSync: true
                )

                if enrichedEntry.updatedAt != entry.updatedAt {
                    enrichedCount += 1
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
            scannedCount: entries.count,
            enrichedCount: enrichedCount,
            skippedCount: skippedCount,
            failedCount: failedCount
        )
    }

    private func shouldAttemptEnrichment(_ entry: Entry) -> Bool {
        if entry.hasPoster == false {
            return true
        }

        if entry.hasBackdrop == false {
            return true
        }

        if entry.overview?.trimmed.isEmpty != false {
            return true
        }

        if entry.tmdbRating == nil {
            return true
        }

        if entry.tmdbGenreIds.isEmpty {
            return true
        }

        return false
    }

    private func fetchBestMetadata(
        for entry: Entry
    ) async throws -> EntryExternalMetadata? {
        let query = entry.displayTitle.trimmed

        guard query.isEmpty == false else {
            return nil
        }

        let results = try await tmdbRepository.searchMedia(
            query: query
        )

        guard results.isEmpty == false else {
            return nil
        }

        let bestResult = bestMatch(
            for: entry,
            from: results
        )

        guard let bestResult else {
            return nil
        }

        return EntryExternalMetadata(
            tmdbResult: bestResult
        )
    }

    private func bestMatch(
        for entry: Entry,
        from results: [TMDBMediaSearchResult]
    ) -> TMDBMediaSearchResult? {
        if let tmdbId = entry.tmdbId,
           let tmdbMediaTypeRaw = entry.tmdbMediaTypeRaw,
           let exactExternalMatch = results.first(where: {
               $0.tmdbId == tmdbId &&
               $0.mediaType.rawValue == tmdbMediaTypeRaw
           }) {
            return exactExternalMatch
        }

        let normalizedEntryTitle = entry.displayTitle.normalizedTitleKey

        let sameTitleAndType = results.filter { result in
            result.title.normalizedTitleKey == normalizedEntryTitle &&
            result.entryType == entry.type
        }

        if let releaseYear = entry.releaseYear,
           let sameYearMatch = sameTitleAndType.first(where: {
               $0.releaseYear == releaseYear
           }) {
            return sameYearMatch
        }

        if let sameTitleMatch = sameTitleAndType.first {
            return sameTitleMatch
        }

        let sameTypeResults = results.filter {
            $0.entryType == entry.type
        }

        return sameTypeResults.first ?? results.first
    }
}
