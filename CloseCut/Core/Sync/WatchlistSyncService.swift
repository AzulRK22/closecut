//
//  WatchlistSyncService.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/05/26.
//

import Foundation
import SwiftData

@MainActor
final class WatchlistSyncService {
    private let queue = PendingActionQueue()
    private let repository = WatchlistRepository()
    private let remote = WatchlistRemoteDataSource()

    // MARK: - Push Local Pending Changes

    func syncPendingWatchlistItems(
        userId: String,
        modelContext: ModelContext
    ) async -> WatchlistSyncSummary {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            return WatchlistSyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }

        var syncedItemIds = Set<String>()
        var syncedCount = 0
        var failedCount = 0

        do {
            let actions = try queue.fetchSyncableActions(
                userId: cleanedUserId,
                modelContext: modelContext
            )

            for action in actions where action.actionType.isWatchlistAction {
                do {
                    action.markSyncing()
                    try modelContext.save()

                    let syncedItemId = try await sync(
                        action: action,
                        modelContext: modelContext
                    )

                    syncedItemIds.insert(syncedItemId)

                    action.markCompleted()
                    try modelContext.save()

                    syncedCount += 1
                } catch {
                    action.markFailed(error.localizedDescription)
                    try? modelContext.save()

                    failedCount += 1

                    #if DEBUG
                    print("⚠️ Failed to sync watchlist action:", error.localizedDescription)
                    #endif
                }
            }

            let orphanSummary = await syncOrphanPendingWatchlistItems(
                userId: cleanedUserId,
                excludingItemIds: syncedItemIds,
                modelContext: modelContext
            )

            syncedCount += orphanSummary.syncedCount
            failedCount += orphanSummary.failedCount

            return WatchlistSyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount,
                pulledCount: 0
            )
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch watchlist sync actions:", error.localizedDescription)
            #endif

            return WatchlistSyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount + 1,
                pulledCount: 0
            )
        }
    }

    // MARK: - Pull Remote Watchlist

    func pullRemoteWatchlistItems(
        userId: String,
        modelContext: ModelContext
    ) async -> WatchlistSyncSummary {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            return WatchlistSyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }

        do {
            let remoteItems = try await remote.fetchWatchlistItems(
                ownerId: cleanedUserId
            )

            var pulledCount = 0

            for remoteItem in remoteItems {
                _ = try repository.upsertRemoteWatchlistItem(
                    remoteItem,
                    modelContext: modelContext
                )

                pulledCount += 1
            }

            return WatchlistSyncSummary(
                syncedCount: 0,
                failedCount: 0,
                pulledCount: pulledCount
            )
        } catch {
            #if DEBUG
            print("⚠️ Failed to pull remote watchlist:", error.localizedDescription)
            #endif

            return WatchlistSyncSummary(
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
        guard action.actionType.isWatchlistAction else {
            throw WatchlistSyncError.unsupportedAction(action.actionType.rawValue)
        }

        guard let payloadData = action.payloadData else {
            throw WatchlistSyncError.missingPayload
        }

        let payload = try CodableHelpers.decode(
            PendingWatchlistItemPayload.self,
            from: payloadData
        )

        guard let item = try repository.fetchLocalWatchlistItem(
            id: payload.itemId,
            modelContext: modelContext
        ) else {
            throw WatchlistSyncError.itemNotFound
        }

        switch action.actionType {
        case .createWatchlistItem, .updateWatchlistItem:
            try await remote.upsertWatchlistItem(item)

            try repository.markLocalWatchlistItemSynced(
                itemId: item.id,
                modelContext: modelContext
            )

        case .deleteWatchlistItem:
            try await remote.softDeleteWatchlistItem(item)

            try repository.markLocalWatchlistItemSynced(
                itemId: item.id,
                modelContext: modelContext
            )

        default:
            throw WatchlistSyncError.unsupportedAction(action.actionType.rawValue)
        }

        return item.id
    }

    private func syncOrphanPendingWatchlistItems(
        userId: String,
        excludingItemIds: Set<String>,
        modelContext: ModelContext
    ) async -> WatchlistSyncSummary {
        do {
            let pendingItems = try fetchLocalPendingWatchlistItems(
                userId: userId,
                excludingItemIds: excludingItemIds,
                modelContext: modelContext
            )

            var syncedCount = 0
            var failedCount = 0

            for item in pendingItems {
                do {
                    if item.deletedAt != nil {
                        try await remote.softDeleteWatchlistItem(item)
                    } else {
                        try await remote.upsertWatchlistItem(item)
                    }

                    try repository.markLocalWatchlistItemSynced(
                        itemId: item.id,
                        modelContext: modelContext
                    )

                    syncedCount += 1
                } catch {
                    try? repository.markLocalWatchlistItemFailed(
                        itemId: item.id,
                        modelContext: modelContext
                    )

                    failedCount += 1

                    #if DEBUG
                    print("⚠️ Failed to sync orphan watchlist item:", error.localizedDescription)
                    #endif
                }
            }

            return WatchlistSyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount,
                pulledCount: 0
            )
        } catch {
            #if DEBUG
            print("⚠️ Failed to sync orphan watchlist items:", error.localizedDescription)
            #endif

            return WatchlistSyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }
    }

    private func fetchLocalPendingWatchlistItems(
        userId: String,
        excludingItemIds: Set<String>,
        modelContext: ModelContext
    ) throws -> [WatchlistItem] {
        let pendingRaw = SyncStatus.pending.rawValue
        let cleanedUserId = userId.trimmed

        let descriptor = FetchDescriptor<LocalWatchlistItem>(
            predicate: #Predicate { item in
                item.ownerId == cleanedUserId &&
                item.syncStatusRaw == pendingRaw
            },
            sortBy: [
                SortDescriptor(\LocalWatchlistItem.updatedAt, order: .forward)
            ]
        )

        return try modelContext.fetch(descriptor)
            .map { $0.domain }
            .filter { excludingItemIds.contains($0.id) == false }
    }
}

struct WatchlistSyncSummary: Equatable {
    let syncedCount: Int
    let failedCount: Int
    let pulledCount: Int

    var hasFailures: Bool {
        failedCount > 0
    }

    var didSyncAnything: Bool {
        syncedCount > 0 || pulledCount > 0
    }
}

enum WatchlistSyncError: LocalizedError {
    case missingPayload
    case itemNotFound
    case unsupportedAction(String)

    var errorDescription: String? {
        switch self {
        case .missingPayload:
            return "Missing Watchlist sync payload."

        case .itemNotFound:
            return "Watchlist item was not found locally."

        case .unsupportedAction(let action):
            return "Unsupported Watchlist sync action: \(action)."
        }
    }
}
