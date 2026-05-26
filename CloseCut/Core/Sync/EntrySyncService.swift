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

    // MARK: - Push Local Pending Changes

    func syncPendingEntries(
        userId: String,
        modelContext: ModelContext
    ) async -> EntrySyncSummary {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            return EntrySyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }

        var syncedEntryIds = Set<String>()
        var syncedCount = 0
        var failedCount = 0

        do {
            let actions = try queue.fetchSyncableActions(
                userId: cleanedUserId,
                modelContext: modelContext
            )

            for action in actions where action.actionType.isEntryAction {
                do {
                    action.markSyncing()
                    try modelContext.save()

                    let syncedEntryId = try await sync(
                        action: action,
                        modelContext: modelContext
                    )

                    syncedEntryIds.insert(syncedEntryId)

                    action.markCompleted()
                    try modelContext.save()

                    syncedCount += 1
                } catch {
                    action.markFailed(error.localizedDescription)
                    try? modelContext.save()

                    failedCount += 1
                }
            }

            let orphanSummary = await syncOrphanPendingEntries(
                userId: cleanedUserId,
                excludingEntryIds: syncedEntryIds,
                modelContext: modelContext
            )

            syncedCount += orphanSummary.syncedCount
            failedCount += orphanSummary.failedCount

            do {
                _ = try queue.cleanupCompletedActions(
                    modelContext: modelContext
                )
            } catch {
                #if DEBUG
                print("⚠️ Completed action cleanup failed:", error.localizedDescription)
                #endif
            }

            return EntrySyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount,
                pulledCount: 0
            )
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch syncable actions:", error.localizedDescription)
            #endif

            return EntrySyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount + 1,
                pulledCount: 0
            )
        }
    }

    // MARK: - Pull Remote Personal Entries

    func pullRemoteEntries(
        userId: String,
        modelContext: ModelContext
    ) async -> EntrySyncSummary {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            return EntrySyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }

        do {
            let remoteEntries = try await remote.fetchEntries(
                ownerId: cleanedUserId
            )

            var pulledCount = 0

            for remoteEntry in remoteEntries {
                _ = try repository.upsertRemoteEntry(
                    remoteEntry,
                    modelContext: modelContext
                )

                pulledCount += 1
            }

            return EntrySyncSummary(
                syncedCount: 0,
                failedCount: 0,
                pulledCount: pulledCount
            )
        } catch {
            #if DEBUG
            print("⚠️ Failed to pull remote entries:", error.localizedDescription)
            #endif

            return EntrySyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }
    }

    // MARK: - Private Sync Logic

    private func sync(
        action: PendingAction,
        modelContext: ModelContext
    ) async throws -> String {
        guard action.actionType.isEntryAction else {
            throw EntrySyncError.unsupportedAction(action.actionType.rawValue)
        }

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
        case .createEntry, .updateEntry, .updateVisibility:
            try await remote.upsertEntry(entry)

            try repository.markLocalEntrySynced(
                entryId: entry.id,
                modelContext: modelContext
            )

        case .deleteEntry:
            try await remote.softDeleteEntry(entry)

            try repository.markLocalEntrySynced(
                entryId: entry.id,
                modelContext: modelContext
            )
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
                failedCount: failedCount,
                pulledCount: 0
            )
        } catch {
            #if DEBUG
            print("⚠️ Failed to sync orphan pending entries:", error.localizedDescription)
            #endif

            return EntrySyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }
    }

    private func fetchLocalPendingEntries(
        userId: String,
        excludingEntryIds: Set<String>,
        modelContext: ModelContext
    ) throws -> [Entry] {
        let pendingRaw = SyncStatus.pending.rawValue
        let cleanedUserId = userId.trimmed

        let descriptor = FetchDescriptor<LocalEntry>(
            predicate: #Predicate { entry in
                entry.ownerId == cleanedUserId &&
                entry.syncStatusRaw == pendingRaw
            },
            sortBy: [
                SortDescriptor(\LocalEntry.updatedAt, order: .forward)
            ]
        )

        return try modelContext.fetch(descriptor)
            .map { $0.domain }
            .filter { excludingEntryIds.contains($0.id) == false }
    }
}

struct EntrySyncSummary: Equatable {
    let syncedCount: Int
    let failedCount: Int
    let pulledCount: Int

    init(
        syncedCount: Int,
        failedCount: Int,
        pulledCount: Int = 0
    ) {
        self.syncedCount = syncedCount
        self.failedCount = failedCount
        self.pulledCount = pulledCount
    }

    var hasFailures: Bool {
        failedCount > 0
    }

    var didSyncAnything: Bool {
        syncedCount > 0 || pulledCount > 0
    }
}

enum EntrySyncError: LocalizedError {
    case missingPayload
    case entryNotFound
    case unsupportedAction(String)

    var errorDescription: String? {
        switch self {
        case .missingPayload:
            return "Missing sync payload."

        case .entryNotFound:
            return "Entry was not found locally."

        case .unsupportedAction(let action):
            return "Unsupported entry sync action: \(action)."
        }
    }
}
