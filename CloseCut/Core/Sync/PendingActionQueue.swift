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
    func enqueue(
        userId: String,
        actionType: PendingActionType,
        payloadData: Data?,
        dedupeKey: String? = nil,
        modelContext: ModelContext
    ) throws {
        let normalizedDedupeKey = dedupeKey

        if let normalizedDedupeKey,
           let existing = try fetchActionByDedupeKey(
                userId: userId,
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
            userId: userId,
            actionType: actionType,
            status: PendingActionStatus.pending,
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
        switch actionType {
        case PendingActionType.createEntry:
            try enqueueCreateEntryAction(
                userId: userId,
                entryId: entryId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case PendingActionType.updateEntry,
             PendingActionType.updateVisibility:
            try enqueueUpdateLikeEntryAction(
                userId: userId,
                entryId: entryId,
                actionType: actionType,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case PendingActionType.deleteEntry:
            try enqueueDeleteEntryAction(
                userId: userId,
                entryId: entryId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        default:
            try enqueue(
                userId: userId,
                actionType: actionType,
                payloadData: payloadData,
                dedupeKey: "entry:\(actionType.rawValue):\(entryId)",
                modelContext: modelContext
            )
        }
    }

    func fetchPendingActions(
        userId: String,
        modelContext: ModelContext
    ) throws -> [PendingAction] {
        let pendingRaw = PendingActionStatus.pending.rawValue

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == userId &&
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

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == userId &&
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
        let pendingRaw = PendingActionStatus.pending.rawValue
        let failedRaw = PendingActionStatus.failed.rawValue

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == userId &&
                (action.statusRaw == pendingRaw || action.statusRaw == failedRaw)
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

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == userId &&
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

    private func enqueueCreateEntryAction(
        userId: String,
        entryId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        // If create already exists, just update its payload.
        try enqueue(
            userId: userId,
            actionType: PendingActionType.createEntry,
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
        // If create is still pending/failed, update the create payload instead.
        // Firestore setData(merge:) with the latest full payload is enough.
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

        // If delete is already pending, do not add updates after delete.
        if try fetchActionByDedupeKey(
            userId: userId,
            dedupeKey: entryDeleteKey(entryId),
            modelContext: modelContext
        ) != nil {
            return
        }

        let key = actionType == PendingActionType.updateVisibility
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
        // Delete should dominate pending updates/visibility changes.
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

        // If create exists and the entry has never reached remote, we still keep delete
        // for now because sync can upsert deletedAt safely. This is simpler for MVP.
        try enqueue(
            userId: userId,
            actionType: PendingActionType.deleteEntry,
            payloadData: payloadData,
            dedupeKey: entryDeleteKey(entryId),
            modelContext: modelContext
        )
    }

    private func fetchActionByDedupeKey(
        userId: String,
        dedupeKey: String,
        modelContext: ModelContext
    ) throws -> PendingAction? {
        let completedRaw = PendingActionStatus.completed.rawValue

        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { action in
                action.userId == userId &&
                action.dedupeKey == dedupeKey &&
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
