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
        sourceType: EntrySourceType = .fullEntry,
        watchedAt: Date,
        modelContext: ModelContext
    ) throws -> Entry {
        let now = Date()
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        let localEntry = LocalEntry(
            id: UUID().uuidString,
            ownerId: ownerId,
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
            visibility: visibility,
            sourceType: sourceType,
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
            userId: ownerId,
            actionType: PendingActionType.createEntry,
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
        if let duplicate = try findDuplicateLocalEntry(
            ownerId: ownerId,
            draft: draft,
            modelContext: modelContext
        ) {
            return duplicate
        }

        let approxDate = draft.watchedDateApprox ?? .unknown
        let watchedAt = approxDate.exactDate ?? Date()

        return try createLocalEntry(
            ownerId: ownerId,
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
            sourceType: .quickAdd,
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
        let descriptor = FetchDescriptor<LocalEntry>(
            predicate: #Predicate { entry in
                entry.ownerId == ownerId
            },
            sortBy: [
                SortDescriptor(\LocalEntry.watchedAt, order: .reverse)
            ]
        )

        let localEntries = try modelContext.fetch(descriptor)

        return localEntries
            .filter { includeDeleted || $0.deletedAt == nil }
            .map { $0.domain }
    }

    func fetchLocalEntry(
        id: String,
        modelContext: ModelContext
    ) throws -> Entry? {
        let descriptor = FetchDescriptor<LocalEntry>(
            predicate: #Predicate { entry in
                entry.id == id
            }
        )

        return try modelContext.fetch(descriptor).first?.domain
    }

    func fetchLocalEntryModel(
        id: String,
        modelContext: ModelContext
    ) throws -> LocalEntry? {
        let descriptor = FetchDescriptor<LocalEntry>(
            predicate: #Predicate { entry in
                entry.id == id
            }
        )

        return try modelContext.fetch(descriptor).first
    }
    // MARK: - Remote Merge

    func upsertRemoteEntry(
        _ remoteEntry: Entry,
        modelContext: ModelContext
    ) throws -> Entry {
        if let existingLocalEntry = try fetchLocalEntryModel(
            id: remoteEntry.id,
            modelContext: modelContext
        ) {
            let localSyncStatus = SyncStatus(rawValue: existingLocalEntry.syncStatusRaw) ?? .synced

            // Do not overwrite local changes waiting to sync.
            if localSyncStatus == .pending || localSyncStatus == .failed {
                return existingLocalEntry.domain
            }

            existingLocalEntry.update(from: remoteEntry)
            existingLocalEntry.syncStatusRaw = SyncStatus.synced.rawValue

            try modelContext.save()
            return existingLocalEntry.domain
        }

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
            sourceType: remoteEntry.sourceType,
            watchedAt: remoteEntry.watchedAt,
            createdAt: remoteEntry.createdAt,
            updatedAt: remoteEntry.updatedAt,
            deletedAt: remoteEntry.deletedAt,
            syncStatus: .synced
        )

        modelContext.insert(localEntry)
        try modelContext.save()

        return localEntry.domain
    }

    // MARK: - Duplicate Detection

    func findDuplicateLocalEntry(
        ownerId: String,
        title: String,
        type: EntryType,
        releaseYear: Int?,
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
        sourceType: EntrySourceType = .fullEntry,
        watchedAt: Date,
        modelContext: ModelContext
    ) throws -> Entry {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

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

        localEntry.visibilityRaw = visibility.rawValue
        localEntry.sourceTypeRaw = sourceType.rawValue

        localEntry.watchedAt = watchedAt
        localEntry.updatedAt = Date()
        localEntry.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        let entry = localEntry.domain

        try enqueueEntryAction(
            userId: entry.ownerId,
            actionType: PendingActionType.updateEntry,
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

        localEntry.visibilityRaw = visibility.rawValue
        localEntry.updatedAt = Date()
        localEntry.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        let entry = localEntry.domain

        try enqueueEntryAction(
            userId: entry.ownerId,
            actionType: PendingActionType.updateVisibility,
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
            actionType: PendingActionType.deleteEntry,
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

        let dedupeKey: String

        switch actionType {
        case PendingActionType.createEntry:
            dedupeKey = "entry:create:\(entry.id)"
        case PendingActionType.updateEntry:
            dedupeKey = "entry:update:\(entry.id)"
        case PendingActionType.deleteEntry:
            dedupeKey = "entry:delete:\(entry.id)"
        case PendingActionType.updateVisibility:
            dedupeKey = "entry:visibility:\(entry.id)"
        default:
            dedupeKey = "entry:\(actionType.rawValue):\(entry.id)"
        }

        try pendingActionQueue.enqueue(
            userId: userId,
            actionType: actionType,
            payloadData: payloadData,
            dedupeKey: dedupeKey,
            modelContext: modelContext
        )
    }

    // MARK: - Helpers

    private func cleanOptionalText(_ value: String?) -> String? {
        guard let value else { return nil }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }

    private func cleanTags(_ tags: [String]) -> [String] {
        tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .uniqued()
    }
}

enum EntryRepositoryError: LocalizedError {
    case entryNotFound

    var errorDescription: String? {
        switch self {
        case .entryNotFound:
            return "Entry was not found."
        }
    }
}
