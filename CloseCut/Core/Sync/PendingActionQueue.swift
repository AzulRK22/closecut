//
//  PendingActionQueue.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation
import SwiftData

@MainActor
final class PendingActionQueue {

    // MARK: - Enqueue

    func enqueue(
        userId: String,
        actionType: PendingActionType,
        payloadData: Data?,
        dedupeKey: String? = nil,
        modelContext: ModelContext
    ) throws {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            throw PendingActionQueueError.missingUserId
        }

        let normalizedDedupeKey = dedupeKey?.trimmed.nilIfBlank

        if let normalizedDedupeKey,
           let existing = try fetchActionByDedupeKey(
                userId: cleanedUserId,
                dedupeKey: normalizedDedupeKey,
                modelContext: modelContext
           ) {
            existing.actionTypeRaw = actionType.rawValue
            existing.statusRaw = PendingActionStatus.pending.rawValue
            existing.payloadData = payloadData
            existing.updatedAt = Date()
            existing.lastErrorMessage = nil

            try modelContext.save()
            return
        }

        let action = PendingAction(
            userId: cleanedUserId,
            actionType: actionType,
            status: .pending,
            payloadData: payloadData,
            dedupeKey: normalizedDedupeKey
        )

        modelContext.insert(action)
        try modelContext.save()
    }

    func enqueueEntryAction(
        userId: String,
        entryId: String,
        actionType: PendingActionType,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        let cleanedEntryId = entryId.trimmed

        guard cleanedEntryId.isEmpty == false else {
            throw PendingActionQueueError.missingEntryId
        }

        switch actionType {
        case .createEntry:
            try enqueueCreateEntryAction(
                userId: userId,
                entryId: cleanedEntryId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case .updateEntry, .updateVisibility:
            try enqueueUpdateLikeEntryAction(
                userId: userId,
                entryId: cleanedEntryId,
                actionType: actionType,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case .deleteEntry:
            try enqueueDeleteEntryAction(
                userId: userId,
                entryId: cleanedEntryId,
                payloadData: payloadData,
                modelContext: modelContext
            )
        }
    }

    // MARK: - Fetch

    func fetchPendingActions(
        userId: String,
        modelContext: ModelContext
    ) throws -> [PendingAction] {
        let pendingRaw = PendingActionStatus.pending.rawValue
        let cleanedUserId = userId.trimmed

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == cleanedUserId &&
                action.statusRaw == pendingRaw
            },
            sortBy: [
                SortDescriptor(\PendingAction.createdAt, order: .forward)
            ]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchFailedActions(
        userId: String,
        modelContext: ModelContext
    ) throws -> [PendingAction] {
        let failedRaw = PendingActionStatus.failed.rawValue
        let cleanedUserId = userId.trimmed

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == cleanedUserId &&
                action.statusRaw == failedRaw
            },
            sortBy: [
                SortDescriptor(\PendingAction.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchSyncableActions(
        userId: String,
        modelContext: ModelContext
    ) throws -> [PendingAction] {
        try recoverStaleSyncingActions(
            userId: userId,
            modelContext: modelContext
        )

        let pendingRaw = PendingActionStatus.pending.rawValue
        let failedRaw = PendingActionStatus.failed.rawValue
        let cleanedUserId = userId.trimmed
        let maxAttempts = PendingActionCleanupPolicy.maxRetryAttempts

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == cleanedUserId &&
                action.attempts < maxAttempts &&
                (
                    action.statusRaw == pendingRaw ||
                    action.statusRaw == failedRaw
                )
            },
            sortBy: [
                SortDescriptor(\PendingAction.createdAt, order: .forward)
            ]
        )

        return try modelContext.fetch(descriptor)
    }

    func pendingCount(
        userId: String,
        modelContext: ModelContext
    ) throws -> Int {
        try fetchPendingActions(
            userId: userId,
            modelContext: modelContext
        ).count
    }

    // MARK: - Recovery

    func recoverStaleSyncingActions(
        userId: String,
        modelContext: ModelContext
    ) throws {
        let syncingRaw = PendingActionStatus.syncing.rawValue
        let pendingRaw = PendingActionStatus.pending.rawValue
        let cleanedUserId = userId.trimmed

        let cutoffDate = Calendar.current.date(
            byAdding: .minute,
            value: -PendingActionCleanupPolicy.staleSyncingActionMinutes,
            to: Date()
        ) ?? Date()

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == cleanedUserId &&
                action.statusRaw == syncingRaw &&
                action.updatedAt < cutoffDate
            }
        )

        let staleActions = try modelContext.fetch(descriptor)

        for action in staleActions {
            action.statusRaw = pendingRaw
            action.updatedAt = Date()
        }

        if staleActions.isEmpty == false {
            try modelContext.save()
        }
    }

    // MARK: - Cleanup

    @discardableResult
    func cleanupCompletedActions(
        olderThanDays days: Int? = nil,
        modelContext: ModelContext
    ) throws -> Int {
        let retentionDays = days ?? PendingActionCleanupPolicy.completedActionRetentionDays
        let completedRaw = PendingActionStatus.completed.rawValue

        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -retentionDays,
            to: Date()
        ) ?? Date()

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.statusRaw == completedRaw &&
                action.updatedAt < cutoffDate
            }
        )

        let actionsToDelete = try modelContext.fetch(descriptor)

        for action in actionsToDelete {
            modelContext.delete(action)
        }

        if actionsToDelete.isEmpty == false {
            try modelContext.save()
        }

        return actionsToDelete.count
    }

    @discardableResult
    func cleanupAllCompletedActions(
        userId: String,
        modelContext: ModelContext
    ) throws -> Int {
        let completedRaw = PendingActionStatus.completed.rawValue
        let cleanedUserId = userId.trimmed

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == cleanedUserId &&
                action.statusRaw == completedRaw
            }
        )

        let actionsToDelete = try modelContext.fetch(descriptor)

        for action in actionsToDelete {
            modelContext.delete(action)
        }

        if actionsToDelete.isEmpty == false {
            try modelContext.save()
        }

        return actionsToDelete.count
    }

    // MARK: - Entry Action Strategy

    private func enqueueCreateEntryAction(
        userId: String,
        entryId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        try enqueue(
            userId: userId,
            actionType: .createEntry,
            payloadData: payloadData,
            dedupeKey: entryCreateKey(entryId),
            modelContext: modelContext
        )
    }

    private func enqueueUpdateLikeEntryAction(
        userId: String,
        entryId: String,
        actionType: PendingActionType,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        if let createAction = try fetchActionByDedupeKey(
            userId: userId,
            dedupeKey: entryCreateKey(entryId),
            modelContext: modelContext
        ) {
            createAction.payloadData = payloadData
            createAction.statusRaw = PendingActionStatus.pending.rawValue
            createAction.updatedAt = Date()
            createAction.lastErrorMessage = nil

            try modelContext.save()
            return
        }

        if try fetchActionByDedupeKey(
            userId: userId,
            dedupeKey: entryDeleteKey(entryId),
            modelContext: modelContext
        ) != nil {
            return
        }

        let key = actionType == .updateVisibility
            ? entryVisibilityKey(entryId)
            : entryUpdateKey(entryId)

        try enqueue(
            userId: userId,
            actionType: actionType,
            payloadData: payloadData,
            dedupeKey: key,
            modelContext: modelContext
        )
    }

    private func enqueueDeleteEntryAction(
        userId: String,
        entryId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        try deleteActionIfExists(
            userId: userId,
            dedupeKey: entryUpdateKey(entryId),
            modelContext: modelContext
        )

        try deleteActionIfExists(
            userId: userId,
            dedupeKey: entryVisibilityKey(entryId),
            modelContext: modelContext
        )

        try enqueue(
            userId: userId,
            actionType: .deleteEntry,
            payloadData: payloadData,
            dedupeKey: entryDeleteKey(entryId),
            modelContext: modelContext
        )
    }

    // MARK: - Private Fetch Helpers

    private func fetchActionByDedupeKey(
        userId: String,
        dedupeKey: String,
        modelContext: ModelContext
    ) throws -> PendingAction? {
        let completedRaw = PendingActionStatus.completed.rawValue
        let cleanedUserId = userId.trimmed
        let cleanedDedupeKey = dedupeKey.trimmed

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == cleanedUserId &&
                action.dedupeKey == cleanedDedupeKey &&
                action.statusRaw != completedRaw
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    private func deleteActionIfExists(
        userId: String,
        dedupeKey: String,
        modelContext: ModelContext
    ) throws {
        if let action = try fetchActionByDedupeKey(
            userId: userId,
            dedupeKey: dedupeKey,
            modelContext: modelContext
        ) {
            modelContext.delete(action)
            try modelContext.save()
        }
    }

    // MARK: - Dedupe Keys

    private func entryCreateKey(_ entryId: String) -> String {
        "entry:create:\(entryId)"
    }

    private func entryUpdateKey(_ entryId: String) -> String {
        "entry:update:\(entryId)"
    }

    private func entryDeleteKey(_ entryId: String) -> String {
        "entry:delete:\(entryId)"
    }

    private func entryVisibilityKey(_ entryId: String) -> String {
        "entry:visibility:\(entryId)"
    }
}

enum PendingActionQueueError: LocalizedError {
    case missingUserId
    case missingEntryId

    var errorDescription: String? {
        switch self {
        case .missingUserId:
            return "A valid user is required to enqueue this sync action."
        case .missingEntryId:
            return "A valid entry is required to enqueue this sync action."
        }
    }
}
