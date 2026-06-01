//
//  WatchlistRepository.swift
//  CloseCut
//

import Foundation
import SwiftData

@MainActor
final class WatchlistRepository {
    private let pendingActionQueue = PendingActionQueue()

    // MARK: - Create

    func createLocalWatchlistItem(
        ownerId: String,
        media: TMDBMediaSearchResult,
        source: WatchlistSource = .discover,
        modelContext: ModelContext
    ) throws -> WatchlistItem {
        let cleanedOwnerId = ownerId.trimmed
        let cleanedTitle = media.title.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            throw WatchlistRepositoryError.missingOwnerId
        }

        guard cleanedTitle.isEmpty == false else {
            throw WatchlistRepositoryError.emptyTitle
        }

        if let duplicate = try findDuplicateLocalWatchlistItem(
            ownerId: cleanedOwnerId,
            media: media,
            modelContext: modelContext
        ) {
            if duplicate.status == .dismissed || duplicate.deletedAt != nil {
                let item = try reactivateLocalWatchlistItem(
                    itemId: duplicate.id,
                    modelContext: modelContext
                )

                try enqueueWatchlistAction(
                    userId: cleanedOwnerId,
                    actionType: .updateWatchlistItem,
                    item: item,
                    modelContext: modelContext
                )

                return item
            }

            return duplicate
        }

        let externalMetadata = EntryExternalMetadata(tmdbResult: media)

        let localItem = LocalWatchlistItem(
            ownerId: cleanedOwnerId,
            mediaId: media.watchlistMediaId,
            title: cleanedTitle,
            normalizedTitle: cleanedTitle.normalizedTitleKey,
            type: media.entryType,
            releaseYear: media.releaseYear,
            status: .saved,
            source: source,
            externalMetadata: externalMetadata,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncStatus: .pending
        )

        modelContext.insert(localItem)
        try modelContext.save()

        let item = localItem.domain

        try enqueueWatchlistAction(
            userId: cleanedOwnerId,
            actionType: .createWatchlistItem,
            item: item,
            modelContext: modelContext
        )

        return item
    }

    // MARK: - Read

    func fetchLocalWatchlistItems(
        ownerId: String,
        includeDeleted: Bool = false,
        modelContext: ModelContext
    ) throws -> [WatchlistItem] {
        let cleanedOwnerId = ownerId.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            return []
        }

        let descriptor = FetchDescriptor<LocalWatchlistItem>(
            predicate: #Predicate { item in
                item.ownerId == cleanedOwnerId
            },
            sortBy: [
                SortDescriptor(\LocalWatchlistItem.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter { includeDeleted || $0.deletedAt == nil }
            .map { $0.domain }
    }

    func fetchLocalWatchlistItem(
        id: String,
        modelContext: ModelContext
    ) throws -> WatchlistItem? {
        try fetchLocalWatchlistItemModel(
            id: id,
            modelContext: modelContext
        )?.domain
    }

    func fetchLocalWatchlistItemModel(
        id: String,
        modelContext: ModelContext
    ) throws -> LocalWatchlistItem? {
        let cleanedId = id.trimmed

        guard cleanedId.isEmpty == false else {
            return nil
        }

        let descriptor = FetchDescriptor<LocalWatchlistItem>(
            predicate: #Predicate { item in
                item.id == cleanedId
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    func findDuplicateLocalWatchlistItem(
        ownerId: String,
        media: TMDBMediaSearchResult,
        modelContext: ModelContext
    ) throws -> WatchlistItem? {
        let items = try fetchLocalWatchlistItems(
            ownerId: ownerId,
            includeDeleted: true,
            modelContext: modelContext
        )

        if let tmdbMatch = items.first(where: { item in
            item.matchesTMDBMedia(media)
        }) {
            return tmdbMatch
        }

        let normalizedTitle = media.title.normalizedTitleKey

        return items.first { item in
            item.normalizedTitle == normalizedTitle &&
            item.type == media.entryType &&
            yearsAreCompatible(item.releaseYear, media.releaseYear)
        }
    }

    // MARK: - Remote Merge

    func upsertRemoteWatchlistItem(
        _ remoteItem: WatchlistItem,
        modelContext: ModelContext
    ) throws -> WatchlistItem {
        let existingLocalModel = try fetchLocalWatchlistItemModel(
            id: remoteItem.id,
            modelContext: modelContext
        )

        if let existingLocalModel {
            let localItem = existingLocalModel.domain

            if localItem.syncStatus == .pending || localItem.syncStatus == .failed {
                return localItem
            }

            if remoteItem.updatedAt >= localItem.updatedAt {
                var syncedRemoteItem = remoteItem
                syncedRemoteItem.syncStatus = .synced

                existingLocalModel.update(from: syncedRemoteItem)
                existingLocalModel.syncStatusRaw = SyncStatus.synced.rawValue

                try modelContext.save()
            }

            return existingLocalModel.domain
        }

        let localItem = LocalWatchlistItem(
            id: remoteItem.id,
            ownerId: remoteItem.ownerId,
            mediaId: remoteItem.mediaId,
            title: remoteItem.title,
            normalizedTitle: remoteItem.normalizedTitle,
            type: remoteItem.type,
            releaseYear: remoteItem.releaseYear,
            status: remoteItem.status,
            source: remoteItem.source,
            externalMetadata: remoteItem.externalMetadata,
            createdAt: remoteItem.createdAt,
            updatedAt: remoteItem.updatedAt,
            deletedAt: remoteItem.deletedAt,
            syncStatus: .synced
        )

        modelContext.insert(localItem)
        try modelContext.save()

        return localItem.domain
    }

    // MARK: - Update

    func markLocalWatchlistItemWatched(
        itemId: String,
        modelContext: ModelContext
    ) throws -> WatchlistItem {
        guard let localItem = try fetchLocalWatchlistItemModel(
            id: itemId,
            modelContext: modelContext
        ) else {
            throw WatchlistRepositoryError.itemNotFound
        }

        localItem.statusRaw = WatchlistStatus.watched.rawValue
        localItem.updatedAt = Date()
        localItem.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        let item = localItem.domain

        try enqueueWatchlistAction(
            userId: item.ownerId,
            actionType: .updateWatchlistItem,
            item: item,
            modelContext: modelContext
        )

        return item
    }

    func reactivateLocalWatchlistItem(
        itemId: String,
        modelContext: ModelContext
    ) throws -> WatchlistItem {
        guard let localItem = try fetchLocalWatchlistItemModel(
            id: itemId,
            modelContext: modelContext
        ) else {
            throw WatchlistRepositoryError.itemNotFound
        }

        localItem.statusRaw = WatchlistStatus.saved.rawValue
        localItem.deletedAt = nil
        localItem.updatedAt = Date()
        localItem.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        return localItem.domain
    }

    func markLocalWatchlistItemSynced(
        itemId: String,
        modelContext: ModelContext
    ) throws {
        guard let localItem = try fetchLocalWatchlistItemModel(
            id: itemId,
            modelContext: modelContext
        ) else {
            throw WatchlistRepositoryError.itemNotFound
        }

        localItem.syncStatusRaw = SyncStatus.synced.rawValue
        try modelContext.save()
    }

    func markLocalWatchlistItemFailed(
        itemId: String,
        modelContext: ModelContext
    ) throws {
        guard let localItem = try fetchLocalWatchlistItemModel(
            id: itemId,
            modelContext: modelContext
        ) else {
            throw WatchlistRepositoryError.itemNotFound
        }

        localItem.syncStatusRaw = SyncStatus.failed.rawValue
        try modelContext.save()
    }

    // MARK: - Delete

    func softDeleteLocalWatchlistItem(
        itemId: String,
        modelContext: ModelContext
    ) throws -> WatchlistItem {
        guard let localItem = try fetchLocalWatchlistItemModel(
            id: itemId,
            modelContext: modelContext
        ) else {
            throw WatchlistRepositoryError.itemNotFound
        }

        localItem.statusRaw = WatchlistStatus.dismissed.rawValue
        localItem.deletedAt = Date()
        localItem.updatedAt = Date()
        localItem.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        let item = localItem.domain

        try enqueueWatchlistAction(
            userId: item.ownerId,
            actionType: .deleteWatchlistItem,
            item: item,
            modelContext: modelContext
        )

        return item
    }

    // MARK: - Pending Actions

    private func enqueueWatchlistAction(
        userId: String,
        actionType: PendingActionType,
        item: WatchlistItem,
        modelContext: ModelContext
    ) throws {
        let payload = PendingWatchlistItemPayload(
            itemId: item.id,
            ownerId: item.ownerId,
            title: item.title,
            status: item.status.rawValue,
            updatedAt: item.updatedAt
        )

        let payloadData = try CodableHelpers.encode(payload)

        try pendingActionQueue.enqueueWatchlistItemAction(
            userId: userId,
            itemId: item.id,
            actionType: actionType,
            payloadData: payloadData,
            modelContext: modelContext
        )
    }

    // MARK: - Helpers

    private func yearsAreCompatible(
        _ first: Int?,
        _ second: Int?
    ) -> Bool {
        if let first, let second {
            return first == second
        }

        return first == nil || second == nil
    }
}

enum WatchlistRepositoryError: LocalizedError {
    case missingOwnerId
    case emptyTitle
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .missingOwnerId:
            return "A valid user is required to save this title."
        case .emptyTitle:
            return "Title is required."
        case .itemNotFound:
            return "Watchlist item was not found."
        }
    }
}
