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

    // MARK: - Create

    func createLocalEntry(
        ownerId: String,
        title: String,
        type: EntryType,
        mood: String,
        takeaway: String,
        quote: String?,
        tags: [String],
        intensity: Int,
        watchContext: WatchContext,
        cinemaAudio: Int?,
        cinemaScreen: Int?,
        cinemaComfort: Int?,
        visibility: EntryVisibility,
        watchedAt: Date,
        modelContext: ModelContext
    ) throws -> Entry {
        let now = Date()

        let localEntry = LocalEntry(
            id: UUID().uuidString,
            ownerId: ownerId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            mood: mood.trimmingCharacters(in: .whitespacesAndNewlines),
            takeaway: takeaway.trimmingCharacters(in: .whitespacesAndNewlines),
            quote: cleanOptionalText(quote),
            tags: cleanTags(tags),
            intensity: intensity,
            watchContext: watchContext,
            cinemaAudio: watchContext == .cinema ? cinemaAudio : nil,
            cinemaScreen: watchContext == .cinema ? cinemaScreen : nil,
            cinemaComfort: watchContext == .cinema ? cinemaComfort : nil,
            visibility: visibility,
            watchedAt: watchedAt,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .pending
        )

        modelContext.insert(localEntry)
        try modelContext.save()

        return localEntry.domain
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

    // MARK: - Update

    func updateLocalEntry(
        entryId: String,
        title: String,
        type: EntryType,
        mood: String,
        takeaway: String,
        quote: String?,
        tags: [String],
        intensity: Int,
        watchContext: WatchContext,
        cinemaAudio: Int?,
        cinemaScreen: Int?,
        cinemaComfort: Int?,
        visibility: EntryVisibility,
        watchedAt: Date,
        modelContext: ModelContext
    ) throws -> Entry {
        guard let localEntry = try fetchLocalEntryModel(
            id: entryId,
            modelContext: modelContext
        ) else {
            throw EntryRepositoryError.entryNotFound
        }

        localEntry.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        localEntry.typeRaw = type.rawValue
        localEntry.mood = mood.trimmingCharacters(in: .whitespacesAndNewlines)
        localEntry.takeaway = takeaway.trimmingCharacters(in: .whitespacesAndNewlines)
        localEntry.quote = cleanOptionalText(quote)
        localEntry.tags = cleanTags(tags)
        localEntry.intensity = intensity
        localEntry.watchContextRaw = watchContext.rawValue
        localEntry.cinemaAudio = watchContext == .cinema ? cinemaAudio : nil
        localEntry.cinemaScreen = watchContext == .cinema ? cinemaScreen : nil
        localEntry.cinemaComfort = watchContext == .cinema ? cinemaComfort : nil
        localEntry.visibilityRaw = visibility.rawValue
        localEntry.watchedAt = watchedAt
        localEntry.updatedAt = Date()
        localEntry.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        return localEntry.domain
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

        return localEntry.domain
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

        return localEntry.domain
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
