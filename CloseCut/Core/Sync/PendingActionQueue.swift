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

    // MARK: - Entry Enqueue

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

        default:
            throw PendingActionQueueError.invalidActionFamily
        }
    }

    // MARK: - Watchlist Enqueue

    func enqueueWatchlistItemAction(
        userId: String,
        itemId: String,
        actionType: PendingActionType,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        let cleanedItemId = itemId.trimmed

        guard cleanedItemId.isEmpty == false else {
            throw PendingActionQueueError.missingWatchlistItemId
        }

        switch actionType {
        case .createWatchlistItem:
            try enqueueCreateWatchlistItemAction(
                userId: userId,
                itemId: cleanedItemId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case .updateWatchlistItem:
            try enqueueUpdateWatchlistItemAction(
                userId: userId,
                itemId: cleanedItemId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case .deleteWatchlistItem:
            try enqueueDeleteWatchlistItemAction(
                userId: userId,
                itemId: cleanedItemId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        default:
            throw PendingActionQueueError.invalidActionFamily
        }
    }

    // MARK: - Watch Together Enqueue

    func enqueueWatchPlanAction(
        userId: String,
        planId: String,
        actionType: PendingActionType,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        let cleanedPlanId = planId.trimmed

        guard cleanedPlanId.isEmpty == false else {
            throw PendingActionQueueError.missingWatchPlanId
        }

        switch actionType {
        case .createWatchPlan:
            try enqueueCreateWatchPlanAction(
                userId: userId,
                planId: cleanedPlanId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case .updateWatchPlan:
            try enqueueUpdateWatchPlanAction(
                userId: userId,
                planId: cleanedPlanId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case .deleteWatchPlan:
            try enqueueDeleteWatchPlanAction(
                userId: userId,
                planId: cleanedPlanId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        default:
            throw PendingActionQueueError.invalidActionFamily
        }
    }

    func enqueueWatchPlanResponseAction(
        userId: String,
        responseId: String,
        actionType: PendingActionType,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        let cleanedResponseId = responseId.trimmed

        guard cleanedResponseId.isEmpty == false else {
            throw PendingActionQueueError.missingWatchPlanResponseId
        }

        switch actionType {
        case .createWatchPlanResponse:
            try enqueueCreateWatchPlanResponseAction(
                userId: userId,
                responseId: cleanedResponseId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case .updateWatchPlanResponse:
            try enqueueUpdateWatchPlanResponseAction(
                userId: userId,
                responseId: cleanedResponseId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        case .deleteWatchPlanResponse:
            try enqueueDeleteWatchPlanResponseAction(
                userId: userId,
                responseId: cleanedResponseId,
                payloadData: payloadData,
                modelContext: modelContext
            )

        default:
            throw PendingActionQueueError.invalidActionFamily
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

    // MARK: - Watchlist Action Strategy

    private func enqueueCreateWatchlistItemAction(
        userId: String,
        itemId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        try enqueue(
            userId: userId,
            actionType: .createWatchlistItem,
            payloadData: payloadData,
            dedupeKey: watchlistCreateKey(itemId),
            modelContext: modelContext
        )
    }

    private func enqueueUpdateWatchlistItemAction(
        userId: String,
        itemId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        if let createAction = try fetchActionByDedupeKey(
            userId: userId,
            dedupeKey: watchlistCreateKey(itemId),
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
            dedupeKey: watchlistDeleteKey(itemId),
            modelContext: modelContext
        ) != nil {
            return
        }

        try enqueue(
            userId: userId,
            actionType: .updateWatchlistItem,
            payloadData: payloadData,
            dedupeKey: watchlistUpdateKey(itemId),
            modelContext: modelContext
        )
    }

    private func enqueueDeleteWatchlistItemAction(
        userId: String,
        itemId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        try deleteActionIfExists(
            userId: userId,
            dedupeKey: watchlistUpdateKey(itemId),
            modelContext: modelContext
        )

        try enqueue(
            userId: userId,
            actionType: .deleteWatchlistItem,
            payloadData: payloadData,
            dedupeKey: watchlistDeleteKey(itemId),
            modelContext: modelContext
        )
    }

    // MARK: - Watch Plan Action Strategy

    private func enqueueCreateWatchPlanAction(
        userId: String,
        planId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        try enqueue(
            userId: userId,
            actionType: .createWatchPlan,
            payloadData: payloadData,
            dedupeKey: watchPlanCreateKey(planId),
            modelContext: modelContext
        )
    }

    private func enqueueUpdateWatchPlanAction(
        userId: String,
        planId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        if let createAction = try fetchActionByDedupeKey(
            userId: userId,
            dedupeKey: watchPlanCreateKey(planId),
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
            dedupeKey: watchPlanDeleteKey(planId),
            modelContext: modelContext
        ) != nil {
            return
        }

        try enqueue(
            userId: userId,
            actionType: .updateWatchPlan,
            payloadData: payloadData,
            dedupeKey: watchPlanUpdateKey(planId),
            modelContext: modelContext
        )
    }

    private func enqueueDeleteWatchPlanAction(
        userId: String,
        planId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        try deleteActionIfExists(
            userId: userId,
            dedupeKey: watchPlanUpdateKey(planId),
            modelContext: modelContext
        )

        try enqueue(
            userId: userId,
            actionType: .deleteWatchPlan,
            payloadData: payloadData,
            dedupeKey: watchPlanDeleteKey(planId),
            modelContext: modelContext
        )
    }

    // MARK: - Watch Plan Response Action Strategy

    private func enqueueCreateWatchPlanResponseAction(
        userId: String,
        responseId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        try enqueue(
            userId: userId,
            actionType: .createWatchPlanResponse,
            payloadData: payloadData,
            dedupeKey: watchPlanResponseCreateKey(responseId),
            modelContext: modelContext
        )
    }

    private func enqueueUpdateWatchPlanResponseAction(
        userId: String,
        responseId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        if let createAction = try fetchActionByDedupeKey(
            userId: userId,
            dedupeKey: watchPlanResponseCreateKey(responseId),
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
            dedupeKey: watchPlanResponseDeleteKey(responseId),
            modelContext: modelContext
        ) != nil {
            return
        }

        try enqueue(
            userId: userId,
            actionType: .updateWatchPlanResponse,
            payloadData: payloadData,
            dedupeKey: watchPlanResponseUpdateKey(responseId),
            modelContext: modelContext
        )
    }

    private func enqueueDeleteWatchPlanResponseAction(
        userId: String,
        responseId: String,
        payloadData: Data?,
        modelContext: ModelContext
    ) throws {
        try deleteActionIfExists(
            userId: userId,
            dedupeKey: watchPlanResponseUpdateKey(responseId),
            modelContext: modelContext
        )

        try enqueue(
            userId: userId,
            actionType: .deleteWatchPlanResponse,
            payloadData: payloadData,
            dedupeKey: watchPlanResponseDeleteKey(responseId),
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

    private func watchlistCreateKey(_ itemId: String) -> String {
        "watchlist:create:\(itemId)"
    }

    private func watchlistUpdateKey(_ itemId: String) -> String {
        "watchlist:update:\(itemId)"
    }

    private func watchlistDeleteKey(_ itemId: String) -> String {
        "watchlist:delete:\(itemId)"
    }

    private func watchPlanCreateKey(_ planId: String) -> String {
        "watchPlan:create:\(planId)"
    }

    private func watchPlanUpdateKey(_ planId: String) -> String {
        "watchPlan:update:\(planId)"
    }

    private func watchPlanDeleteKey(_ planId: String) -> String {
        "watchPlan:delete:\(planId)"
    }

    private func watchPlanResponseCreateKey(_ responseId: String) -> String {
        "watchPlanResponse:create:\(responseId)"
    }

    private func watchPlanResponseUpdateKey(_ responseId: String) -> String {
        "watchPlanResponse:update:\(responseId)"
    }

    private func watchPlanResponseDeleteKey(_ responseId: String) -> String {
        "watchPlanResponse:delete:\(responseId)"
    }
}

enum PendingActionQueueError: LocalizedError {
    case missingUserId
    case missingEntryId
    case missingWatchlistItemId
    case missingWatchPlanId
    case missingWatchPlanResponseId
    case invalidActionFamily

    var errorDescription: String? {
        switch self {
        case .missingUserId:
            return "A valid user is required to enqueue this sync action."
        case .missingEntryId:
            return "A valid entry is required to enqueue this sync action."
        case .missingWatchlistItemId:
            return "A valid Watchlist item is required to enqueue this sync action."
        case .missingWatchPlanId:
            return "A valid Watch Together plan is required to enqueue this sync action."
        case .missingWatchPlanResponseId:
            return "A valid Watch Together response is required to enqueue this sync action."
        case .invalidActionFamily:
            return "This sync action does not belong to the requested action family."
        }
    }
}
