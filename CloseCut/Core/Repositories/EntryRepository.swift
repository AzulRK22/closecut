//
//  EntryRepository.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@MainActor
final class EntryRepository {
    private let pendingActionQueue = PendingActionQueue()

    // MARK: - Create

    func createLocalEntry(
        ownerId: String,
        title: String,
        type: EntryType,
        releaseYear: Int? = nil,
        mood: String,
        quickSentiment: QuickSentiment? = nil,
        takeaway: String,
        quote: String?,
        tags: [String],
        intensity: Int,
        watchContext: WatchContext,
        watchedDateApprox: WatchedDateApprox? = nil,
        cinemaAudio: Int?,
        cinemaScreen: Int?,
        cinemaComfort: Int?,
        visibility: EntryVisibility,
        sharedCircleIds: [String] = [],
        sourceType: EntrySourceType = .fullEntry,
        externalMetadata: EntryExternalMetadata? = nil,
        watchedAt: Date,
        modelContext: ModelContext
    ) throws -> Entry {
        let cleanedOwnerId = ownerId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedTitle = title.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            throw EntryRepositoryError.missingOwnerId
        }

        guard cleanedTitle.isEmpty == false else {
            throw EntryRepositoryError.emptyTitle
        }

        if let duplicate = try findDuplicateLocalEntry(
            ownerId: cleanedOwnerId,
            title: cleanedTitle,
            type: type,
            releaseYear: releaseYear,
            externalMetadata: externalMetadata,
            modelContext: modelContext
        ) {
            return duplicate
        }

        let now = Date()
        let cleanedSharedCircleIds = cleanCircleIds(sharedCircleIds)
        let resolvedVisibility = resolveVisibility(
            requestedVisibility: visibility,
            sharedCircleIds: cleanedSharedCircleIds
        )

        let localEntry = LocalEntry(
            id: UUID().uuidString,
            ownerId: cleanedOwnerId,
            title: cleanedTitle,
            normalizedTitle: cleanedTitle.normalizedTitleKey,
            type: type,
            releaseYear: releaseYear,
            mood: mood.trimmingCharacters(in: .whitespacesAndNewlines),
            quickSentiment: quickSentiment,
            takeaway: takeaway.trimmingCharacters(in: .whitespacesAndNewlines),
            quote: cleanOptionalText(quote),
            tags: cleanTags(tags),
            intensity: intensity,
            watchContext: watchContext,
            watchedDateApprox: watchedDateApprox,
            cinemaAudio: watchContext == .cinema ? cinemaAudio : nil,
            cinemaScreen: watchContext == .cinema ? cinemaScreen : nil,
            cinemaComfort: watchContext == .cinema ? cinemaComfort : nil,
            visibility: resolvedVisibility,
            sharedCircleIds: resolvedVisibility == .circle ? cleanedSharedCircleIds : [],
            sourceType: sourceType,
            externalMetadata: externalMetadata,
            watchedAt: watchedAt,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .pending
        )

        modelContext.insert(localEntry)
        try modelContext.save()

        let entry = localEntry.domain

        try enqueueEntryAction(
            userId: cleanedOwnerId,
            actionType: .createEntry,
            entry: entry,
            modelContext: modelContext
        )

        return entry
    }

    func createQuickAddEntry(
        ownerId: String,
        draft: QuickAddDraft,
        visibility: EntryVisibility = .privateOnly,
        modelContext: ModelContext
    ) throws -> Entry {
        let cleanedOwnerId = ownerId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedOwnerId.isEmpty == false else {
            throw EntryRepositoryError.missingOwnerId
        }

        if let duplicate = try findDuplicateLocalEntry(
            ownerId: cleanedOwnerId,
            draft: draft,
            modelContext: modelContext
        ) {
            return duplicate
        }

        let approxDate = draft.watchedDateApprox ?? .unknown
        let watchedAt = approxDate.exactDate ?? Date()

        return try createLocalEntry(
            ownerId: cleanedOwnerId,
            title: draft.title,
            type: draft.type,
            releaseYear: draft.releaseYear,
            mood: "",
            quickSentiment: draft.quickSentiment,
            takeaway: "",
            quote: nil,
            tags: [],
            intensity: 3,
            watchContext: .home,
            watchedDateApprox: approxDate,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil,
            visibility: visibility,
            sharedCircleIds: [],
            sourceType: .quickAdd,
            externalMetadata: draft.externalMetadata,
            watchedAt: watchedAt,
            modelContext: modelContext
        )
    }

    // MARK: - Read

    func fetchLocalEntries(
        ownerId: String,
        includeDeleted: Bool = false,
        modelContext: ModelContext
    ) throws -> [Entry] {
        let cleanedOwnerId = ownerId.trimmingCharacters(in: .whitespacesAndNewlines)

        let descriptor = FetchDescriptor<LocalEntry>(
            predicate: #Predicate { entry in
                entry.ownerId == cleanedOwnerId
            },
            sortBy: [
                SortDescriptor(\LocalEntry.watchedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter { includeDeleted || $0.deletedAt == nil }
            .map { $0.domain }
    }

    func fetchLocalEntry(
        id: String,
        modelContext: ModelContext
    ) throws -> Entry? {
        let cleanedId = id.trimmingCharacters(in: .whitespacesAndNewlines)

        let descriptor = FetchDescriptor<LocalEntry>(
            predicate: #Predicate { entry in
                entry.id == cleanedId
            }
        )

        return try modelContext.fetch(descriptor).first?.domain
    }

    func fetchLocalEntryModel(
        id: String,
        modelContext: ModelContext
    ) throws -> LocalEntry? {
        let cleanedId = id.trimmingCharacters(in: .whitespacesAndNewlines)

        let descriptor = FetchDescriptor<LocalEntry>(
            predicate: #Predicate { entry in
                entry.id == cleanedId
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Remote Merge

    func upsertRemoteEntry(
        _ remoteEntry: Entry,
        modelContext: ModelContext
    ) throws -> Entry {
        let existingLocalModel = try fetchLocalEntryModel(
            id: remoteEntry.id,
            modelContext: modelContext
        )

        let existingLocalEntry = existingLocalModel?.domain

        let decision = EntryConflictPolicy.decide(
            localEntry: existingLocalEntry,
            remoteEntry: remoteEntry
        )

        switch decision {
        case .insertRemote:
            let localEntry = LocalEntry(
                id: remoteEntry.id,
                ownerId: remoteEntry.ownerId,
                title: remoteEntry.title,
                normalizedTitle: remoteEntry.normalizedTitle,
                type: remoteEntry.type,
                releaseYear: remoteEntry.releaseYear,
                mood: remoteEntry.mood,
                quickSentiment: remoteEntry.quickSentiment,
                takeaway: remoteEntry.takeaway,
                quote: remoteEntry.quote,
                tags: remoteEntry.tags,
                intensity: remoteEntry.intensity,
                watchContext: remoteEntry.watchContext,
                watchedDateApprox: remoteEntry.watchedDateApprox,
                cinemaAudio: remoteEntry.cinemaAudio,
                cinemaScreen: remoteEntry.cinemaScreen,
                cinemaComfort: remoteEntry.cinemaComfort,
                visibility: remoteEntry.visibility,
                sharedCircleIds: remoteEntry.sharedCircleIds,
                sourceType: remoteEntry.sourceType,
                externalMetadata: remoteEntry.externalMetadata,
                watchedAt: remoteEntry.watchedAt,
                createdAt: remoteEntry.createdAt,
                updatedAt: remoteEntry.updatedAt,
                deletedAt: remoteEntry.deletedAt,
                syncStatus: .synced
            )

            modelContext.insert(localEntry)
            try modelContext.save()

            return localEntry.domain

        case .applyRemote:
            guard let existingLocalModel else {
                throw EntryRepositoryError.entryNotFound
            }

            var syncedRemoteEntry = remoteEntry
            syncedRemoteEntry.syncStatus = .synced

            existingLocalModel.update(from: syncedRemoteEntry)
            existingLocalModel.syncStatusRaw = SyncStatus.synced.rawValue

            try modelContext.save()

            return existingLocalModel.domain

        case .keepLocal, .keepLocalPending:
            guard let existingLocalEntry else {
                throw EntryRepositoryError.entryNotFound
            }

            return existingLocalEntry
        }
    }

    // MARK: - Duplicate Detection

    func findDuplicateLocalEntry(
        ownerId: String,
        title: String,
        type: EntryType,
        releaseYear: Int?,
        externalMetadata: EntryExternalMetadata? = nil,
        modelContext: ModelContext
    ) throws -> Entry? {
        let entries = try fetchLocalEntries(
            ownerId: ownerId,
            includeDeleted: false,
            modelContext: modelContext
        )

        return DuplicateDetector.findDuplicate(
            title: title,
            type: type,
            releaseYear: releaseYear,
            externalMetadata: externalMetadata,
            in: entries
        )
    }

    func findDuplicateLocalEntry(
        ownerId: String,
        draft: QuickAddDraft,
        modelContext: ModelContext
    ) throws -> Entry? {
        let entries = try fetchLocalEntries(
            ownerId: ownerId,
            includeDeleted: false,
            modelContext: modelContext
        )

        return DuplicateDetector.findDuplicate(
            draft: draft,
            in: entries
        )
    }

    // MARK: - Update

    func updateLocalEntry(
        entryId: String,
        title: String,
        type: EntryType,
        releaseYear: Int? = nil,
        mood: String,
        quickSentiment: QuickSentiment? = nil,
        takeaway: String,
        quote: String?,
        tags: [String],
        intensity: Int,
        watchContext: WatchContext,
        watchedDateApprox: WatchedDateApprox? = nil,
        cinemaAudio: Int?,
        cinemaScreen: Int?,
        cinemaComfort: Int?,
        visibility: EntryVisibility,
        sharedCircleIds: [String] = [],
        sourceType: EntrySourceType = .fullEntry,
        externalMetadata: EntryExternalMetadata? = nil,
        watchedAt: Date,
        modelContext: ModelContext
    ) throws -> Entry {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        let cleanedTitle = title.trimmed

        guard cleanedTitle.isEmpty == false else {
            throw EntryRepositoryError.emptyTitle
        }

        let cleanedSharedCircleIds = cleanCircleIds(sharedCircleIds)
        let resolvedVisibility = resolveVisibility(
            requestedVisibility: visibility,
            sharedCircleIds: cleanedSharedCircleIds
        )

        localEntry.title = cleanedTitle
        localEntry.normalizedTitle = cleanedTitle.normalizedTitleKey
        localEntry.typeRaw = type.rawValue
        localEntry.releaseYear = releaseYear

        localEntry.mood = mood.trimmingCharacters(in: .whitespacesAndNewlines)
        localEntry.quickSentimentRaw = quickSentiment?.rawValue
        localEntry.takeaway = takeaway.trimmingCharacters(in: .whitespacesAndNewlines)
        localEntry.quote = cleanOptionalText(quote)
        localEntry.tags = cleanTags(tags)
        localEntry.intensity = intensity

        localEntry.watchContextRaw = watchContext.rawValue
        localEntry.watchedDateApproxKindRaw = watchedDateApprox?.kind.rawValue
        localEntry.watchedDateApproxExactDate = watchedDateApprox?.exactDate
        localEntry.watchedDateApproxMonth = watchedDateApprox?.month
        localEntry.watchedDateApproxYear = watchedDateApprox?.year
        localEntry.watchedDateApproxDisplayLabel = watchedDateApprox?.displayLabel

        localEntry.cinemaAudio = watchContext == .cinema ? cinemaAudio : nil
        localEntry.cinemaScreen = watchContext == .cinema ? cinemaScreen : nil
        localEntry.cinemaComfort = watchContext == .cinema ? cinemaComfort : nil

        localEntry.visibilityRaw = resolvedVisibility.rawValue
        localEntry.sharedCircleIds = resolvedVisibility == .circle ? cleanedSharedCircleIds : []
        localEntry.sourceTypeRaw = sourceType.rawValue

        applyExternalMetadata(
            externalMetadata,
            to: localEntry
        )

        localEntry.watchedAt = watchedAt
        localEntry.updatedAt = Date()
        localEntry.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        let entry = localEntry.domain

        try enqueueEntryAction(
            userId: entry.ownerId,
            actionType: .updateEntry,
            entry: entry,
            modelContext: modelContext
        )

        return entry
    }

    func updateLocalVisibility(
        entryId: String,
        visibility: EntryVisibility,
        modelContext: ModelContext
    ) throws -> Entry {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        if visibility == .privateOnly {
            localEntry.sharedCircleIds = []
            localEntry.visibilityRaw = EntryVisibility.privateOnly.rawValue
        } else {
            let cleanedSharedCircleIds = cleanCircleIds(localEntry.sharedCircleIds)

            localEntry.sharedCircleIds = cleanedSharedCircleIds
            localEntry.visibilityRaw = cleanedSharedCircleIds.isEmpty
                ? EntryVisibility.privateOnly.rawValue
                : EntryVisibility.circle.rawValue
        }

        localEntry.updatedAt = Date()
        localEntry.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        let entry = localEntry.domain

        try enqueueEntryAction(
            userId: entry.ownerId,
            actionType: .updateVisibility,
            entry: entry,
            modelContext: modelContext
        )

        return entry
    }

    func updateLocalSharedCircles(
        entryId: String,
        sharedCircleIds: [String],
        modelContext: ModelContext
    ) throws -> Entry {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        let cleanedSharedCircleIds = cleanCircleIds(sharedCircleIds)

        localEntry.sharedCircleIds = cleanedSharedCircleIds
        localEntry.visibilityRaw = cleanedSharedCircleIds.isEmpty
            ? EntryVisibility.privateOnly.rawValue
            : EntryVisibility.circle.rawValue

        localEntry.updatedAt = Date()
        localEntry.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        let entry = localEntry.domain

        try enqueueEntryAction(
            userId: entry.ownerId,
            actionType: .updateVisibility,
            entry: entry,
            modelContext: modelContext
        )

        return entry
    }

    func markLocalEntrySynced(
        entryId: String,
        modelContext: ModelContext
    ) throws {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        localEntry.syncStatusRaw = SyncStatus.synced.rawValue
        try modelContext.save()
    }

    func markLocalEntryFailed(
        entryId: String,
        modelContext: ModelContext
    ) throws {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        localEntry.syncStatusRaw = SyncStatus.failed.rawValue
        try modelContext.save()
    }

    // MARK: - Delete

    func softDeleteLocalEntry(
        entryId: String,
        modelContext: ModelContext
    ) throws -> Entry {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        let now = Date()

        localEntry.deletedAt = now
        localEntry.updatedAt = now
        localEntry.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        let entry = localEntry.domain

        try enqueueEntryAction(
            userId: entry.ownerId,
            actionType: .deleteEntry,
            entry: entry,
            modelContext: modelContext
        )

        return entry
    }

    func hardDeleteLocalEntry(
        entryId: String,
        modelContext: ModelContext
    ) throws {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        modelContext.delete(localEntry)
        try modelContext.save()
    }

    // MARK: - Pending Actions

    private func enqueueEntryAction(
        userId: String,
        actionType: PendingActionType,
        entry: Entry,
        modelContext: ModelContext
    ) throws {
        let payload = PendingEntryPayload(
            entryId: entry.id,
            ownerId: entry.ownerId,
            title: entry.title,
            sourceType: entry.sourceType.rawValue,
            updatedAt: entry.updatedAt
        )

        let payloadData = try CodableHelpers.encode(payload)

        try pendingActionQueue.enqueueEntryAction(
            userId: userId,
            entryId: entry.id,
            actionType: actionType,
            payloadData: payloadData,
            modelContext: modelContext
        )
    }

    // MARK: - Metadata Helpers

    private func applyExternalMetadata(
        _ externalMetadata: EntryExternalMetadata?,
        to localEntry: LocalEntry
    ) {
        guard let externalMetadata else {
            localEntry.externalSourceRaw = nil
            localEntry.tmdbId = nil
            localEntry.tmdbMediaTypeRaw = nil
            localEntry.posterPath = nil
            localEntry.backdropPath = nil
            localEntry.overview = nil
            localEntry.tmdbRating = nil
            localEntry.tmdbPopularity = nil
            localEntry.tmdbGenreIds = []
            return
        }

        localEntry.externalSourceRaw = externalMetadata.source.rawValue
        localEntry.tmdbId = externalMetadata.tmdbId
        localEntry.tmdbMediaTypeRaw = externalMetadata.tmdbMediaTypeRaw
        localEntry.posterPath = externalMetadata.posterPath
        localEntry.backdropPath = externalMetadata.backdropPath
        localEntry.overview = externalMetadata.overview
        localEntry.tmdbRating = externalMetadata.tmdbRating
        localEntry.tmdbPopularity = externalMetadata.tmdbPopularity
        localEntry.tmdbGenreIds = externalMetadata.tmdbGenreIds
    }

    // MARK: - Cleaning Helpers

    private func resolveVisibility(
        requestedVisibility: EntryVisibility,
        sharedCircleIds: [String]
    ) -> EntryVisibility {
        guard requestedVisibility == .circle else {
            return .privateOnly
        }

        return sharedCircleIds.isEmpty ? .privateOnly : .circle
    }

    private func cleanOptionalText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }

    private func cleanTags(_ tags: [String]) -> [String] {
        Array(
            Set(
                tags
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }

    private func cleanCircleIds(_ ids: [String]) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }
}

enum EntryRepositoryError: LocalizedError {
    case entryNotFound
    case missingOwnerId
    case emptyTitle

    var errorDescription: String? {
        switch self {
        case .entryNotFound:
            return "Entry was not found."
        case .missingOwnerId:
            return "A valid owner is required."
        case .emptyTitle:
            return "Title is required."
        }
    }
}
