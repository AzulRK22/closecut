//
//  EntrySyncService.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation
import SwiftData

@MainActor
final class EntrySyncService {
    private let queue = PendingActionQueue()
    private let repository = EntryRepository()
    private let remote = EntryRemoteDataSource()

    func syncPendingEntries(
        userId: String,
        modelContext: ModelContext
    ) async -> EntrySyncSummary {
        var syncedEntryIds = Set<String>()
        var syncedCount = 0
        var failedCount = 0

        do {
            let actions = try queue.fetchPendingActions(
                userId: userId,
                modelContext: modelContext
            )

            for action in actions where isEntryAction(action) {
                do {
                    let syncedEntryId = try await sync(action: action, modelContext: modelContext)
                    syncedEntryIds.insert(syncedEntryId)
                    action.markCompleted()
                    syncedCount += 1
                } catch {
                    action.markFailed(error.localizedDescription)
                    failedCount += 1
                }

                try? modelContext.save()
            }

            let orphanSummary = await syncOrphanPendingEntries(
                userId: userId,
                excludingEntryIds: syncedEntryIds,
                modelContext: modelContext
            )

            syncedCount += orphanSummary.syncedCount
            failedCount += orphanSummary.failedCount

            return EntrySyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount
            )
        } catch {
            return EntrySyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount + 1
            )
        }
    }

    private func sync(
        action: PendingAction,
        modelContext: ModelContext
    ) async throws -> String {
        guard let payloadData = action.payloadData else {
            throw EntrySyncError.missingPayload
        }

        let payload = try CodableHelpers.decode(
            PendingEntryPayload.self,
            from: payloadData
        )

        guard let entry = try repository.fetchLocalEntry(
            id: payload.entryId,
            modelContext: modelContext
        ) else {
            throw EntrySyncError.entryNotFound
        }

        switch action.actionType {
        case PendingActionType.createEntry,
             PendingActionType.updateEntry,
             PendingActionType.updateVisibility:
            try await remote.upsertEntry(entry)
            try repository.markLocalEntrySynced(
                entryId: entry.id,
                modelContext: modelContext
            )

        case PendingActionType.deleteEntry:
            try await remote.softDeleteEntry(entry)
            try repository.markLocalEntrySynced(
                entryId: entry.id,
                modelContext: modelContext
            )

        default:
            break
        }

        return entry.id
    }

    private func syncOrphanPendingEntries(
        userId: String,
        excludingEntryIds: Set<String>,
        modelContext: ModelContext
    ) async -> EntrySyncSummary {
        do {
            let pendingEntries = try fetchLocalPendingEntries(
                userId: userId,
                excludingEntryIds: excludingEntryIds,
                modelContext: modelContext
            )

            var syncedCount = 0
            var failedCount = 0

            for entry in pendingEntries {
                do {
                    if entry.deletedAt != nil {
                        try await remote.softDeleteEntry(entry)
                    } else {
                        try await remote.upsertEntry(entry)
                    }

                    try repository.markLocalEntrySynced(
                        entryId: entry.id,
                        modelContext: modelContext
                    )

                    syncedCount += 1
                } catch {
                    try? repository.markLocalEntryFailed(
                        entryId: entry.id,
                        modelContext: modelContext
                    )

                    failedCount += 1
                }
            }

            return EntrySyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount
            )
        } catch {
            return EntrySyncSummary(
                syncedCount: 0,
                failedCount: 1
            )
        }
    }

    private func fetchLocalPendingEntries(
        userId: String,
        excludingEntryIds: Set<String>,
        modelContext: ModelContext
    ) throws -> [Entry] {
        let descriptor = FetchDescriptor<LocalEntry>(
            predicate: #Predicate { entry in
                entry.ownerId == userId &&
                entry.syncStatusRaw == "pending"
            },
            sortBy: [
                SortDescriptor(\LocalEntry.updatedAt, order: .forward)
            ]
        )

        return try modelContext.fetch(descriptor)
            .map { $0.domain }
            .filter { excludingEntryIds.contains($0.id) == false }
    }

    private func isEntryAction(_ action: PendingAction) -> Bool {
        switch action.actionType {
        case PendingActionType.createEntry,
             PendingActionType.updateEntry,
             PendingActionType.deleteEntry,
             PendingActionType.updateVisibility:
            return true
        default:
            return false
        }
    }
}

struct EntrySyncSummary: Equatable {
    let syncedCount: Int
    let failedCount: Int
}

enum EntrySyncError: LocalizedError {
    case missingPayload
    case entryNotFound

    var errorDescription: String? {
        switch self {
        case .missingPayload:
            return "Missing sync payload."
        case .entryNotFound:
            return "Entry was not found locally."
        }
    }
}
