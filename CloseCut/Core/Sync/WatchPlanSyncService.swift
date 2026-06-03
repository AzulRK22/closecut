//
//  WatchPlanSyncService.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation
import SwiftData

@MainActor
final class WatchPlanSyncService {
    private let remoteDataSource = WatchPlanRemoteDataSource()
    private let pendingActionQueue = PendingActionQueue()

    // MARK: - Push

    func syncPendingWatchTogetherItems(
        userId: String,
        modelContext: ModelContext
    ) async -> WatchPlanSyncSummary {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            return WatchPlanSyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }

        do {
            let actions = try pendingActionQueue.fetchSyncableActions(
                userId: cleanedUserId,
                modelContext: modelContext
            )
            .filter { $0.actionType.isWatchTogetherAction }

            var syncedCount = 0
            var failedCount = 0

            for action in actions {
                do {
                    action.statusRaw = PendingActionStatus.syncing.rawValue
                    action.updatedAt = Date()
                    try modelContext.save()

                    try await processAction(
                        action,
                        modelContext: modelContext
                    )

                    action.statusRaw = PendingActionStatus.completed.rawValue
                    action.updatedAt = Date()
                    action.lastErrorMessage = nil
                    syncedCount += 1

                    try modelContext.save()
                } catch {
                    action.statusRaw = PendingActionStatus.failed.rawValue
                    action.updatedAt = Date()
                    action.attempts += 1
                    action.lastErrorMessage = error.localizedDescription
                    failedCount += 1

                    try? modelContext.save()

                    #if DEBUG
                    print("❌ Watch Together sync action failed:", action.actionTypeRaw, error.localizedDescription)
                    #endif
                }
            }

            return WatchPlanSyncSummary(
                syncedCount: syncedCount,
                failedCount: failedCount,
                pulledCount: 0
            )
        } catch {
            #if DEBUG
            print("❌ Could not fetch Watch Together syncable actions:", error.localizedDescription)
            #endif

            return WatchPlanSyncSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }
    }

    private func processAction(
        _ action: PendingAction,
        modelContext: ModelContext
    ) async throws {
        guard let actionType = PendingActionType(rawValue: action.actionTypeRaw) else {
            throw WatchPlanSyncServiceError.invalidActionType
        }

        switch actionType {
        case .createWatchPlan, .updateWatchPlan:
            let payload = CodableHelpers.decodeIfPossible(
                PendingWatchPlanPayload.self,
                from: action.payloadData
            )

            guard let planId = payload?.planId else {
                throw WatchPlanSyncServiceError.missingPayload
            }

            guard let plan = try fetchLocalPlan(
                id: planId,
                modelContext: modelContext
            ) else {
                throw WatchPlanSyncServiceError.localPlanMissing
            }

            try await remoteDataSource.upsertPlan(plan)
            try markLocalPlanSynced(
                id: plan.id,
                modelContext: modelContext
            )

        case .deleteWatchPlan:
            let payload = CodableHelpers.decodeIfPossible(
                PendingWatchPlanPayload.self,
                from: action.payloadData
            )

            guard let planId = payload?.planId else {
                throw WatchPlanSyncServiceError.missingPayload
            }

            guard let plan = try fetchLocalPlan(
                id: planId,
                includeDeleted: true,
                modelContext: modelContext
            ) else {
                throw WatchPlanSyncServiceError.localPlanMissing
            }

            try await remoteDataSource.softDeletePlan(plan)
            try markLocalPlanSynced(
                id: plan.id,
                modelContext: modelContext
            )

        case .createWatchPlanResponse, .updateWatchPlanResponse:
            let payload = CodableHelpers.decodeIfPossible(
                PendingWatchPlanResponsePayload.self,
                from: action.payloadData
            )

            guard let responseId = payload?.responseId else {
                throw WatchPlanSyncServiceError.missingPayload
            }

            guard let response = try fetchLocalResponse(
                id: responseId,
                modelContext: modelContext
            ) else {
                throw WatchPlanSyncServiceError.localResponseMissing
            }

            try await remoteDataSource.upsertResponse(response)
            try markLocalResponseSynced(
                id: response.id,
                modelContext: modelContext
            )

        case .deleteWatchPlanResponse:
            let payload = CodableHelpers.decodeIfPossible(
                PendingWatchPlanResponsePayload.self,
                from: action.payloadData
            )

            guard let responseId = payload?.responseId else {
                throw WatchPlanSyncServiceError.missingPayload
            }

            guard let response = try fetchLocalResponse(
                id: responseId,
                includeDeleted: true,
                modelContext: modelContext
            ) else {
                throw WatchPlanSyncServiceError.localResponseMissing
            }

            try await remoteDataSource.softDeleteResponse(response)
            try markLocalResponseSynced(
                id: response.id,
                modelContext: modelContext
            )

        default:
            return
        }
    }

    // MARK: - Pull

    func pullRemoteWatchTogetherItems(
        circleIds: [String],
        modelContext: ModelContext
    ) async -> WatchPlanSyncSummary {
        let cleanedCircleIds = WatchPlan.cleanIds(circleIds)

        guard cleanedCircleIds.isEmpty == false else {
            return WatchPlanSyncSummary(
                syncedCount: 0,
                failedCount: 0,
                pulledCount: 0
            )
        }

        var pulledCount = 0
        var failedCount = 0

        for circleId in cleanedCircleIds {
            do {
                let remotePlans = try await remoteDataSource.fetchPlansForCircle(
                    circleId: circleId,
                    includeDeleted: true,
                    limit: 50
                )

                for remotePlan in remotePlans {
                    try upsertRemotePlan(
                        remotePlan,
                        modelContext: modelContext
                    )
                    pulledCount += 1

                    let remoteResponses = try await remoteDataSource.fetchResponses(
                        circleId: remotePlan.circleId,
                        planId: remotePlan.id,
                        includeDeleted: true
                    )

                    for remoteResponse in remoteResponses {
                        try upsertRemoteResponse(
                            remoteResponse,
                            modelContext: modelContext
                        )
                        pulledCount += 1
                    }
                }
            } catch {
                failedCount += 1

                #if DEBUG
                print("⚠️ Failed to pull Watch Together for Circle \(circleId):", error.localizedDescription)
                #endif
            }
        }

        return WatchPlanSyncSummary(
            syncedCount: 0,
            failedCount: failedCount,
            pulledCount: pulledCount
        )
    }

    // MARK: - Local Fetch

    private func fetchLocalPlan(
        id: String,
        includeDeleted: Bool = false,
        modelContext: ModelContext
    ) throws -> WatchPlan? {
        let cleanedId = id.trimmed

        guard cleanedId.isEmpty == false else {
            return nil
        }

        let descriptor = FetchDescriptor<LocalWatchPlan>(
            predicate: #Predicate { plan in
                plan.id == cleanedId
            }
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            return nil
        }

        guard includeDeleted || model.deletedAt == nil else {
            return nil
        }

        return model.domain
    }

    private func fetchLocalResponse(
        id: String,
        includeDeleted: Bool = false,
        modelContext: ModelContext
    ) throws -> WatchPlanResponse? {
        let cleanedId = id.trimmed

        guard cleanedId.isEmpty == false else {
            return nil
        }

        let descriptor = FetchDescriptor<LocalWatchPlanResponse>(
            predicate: #Predicate { response in
                response.id == cleanedId
            }
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            return nil
        }

        guard includeDeleted || model.deletedAt == nil else {
            return nil
        }

        return model.domain
    }

    // MARK: - Local Upsert

    private func upsertRemotePlan(
        _ remotePlan: WatchPlan,
        modelContext: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<LocalWatchPlan>(
            predicate: #Predicate { plan in
                plan.id == remotePlan.id
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            let localPlan = existing.domain

            if localPlan.syncStatus == .pending || localPlan.syncStatus == .failed {
                return
            }

            if remotePlan.updatedAt >= localPlan.updatedAt {
                var syncedRemotePlan = remotePlan
                syncedRemotePlan.syncStatus = .synced

                existing.update(from: syncedRemotePlan)
                existing.syncStatusRaw = SyncStatus.synced.rawValue

                try modelContext.save()
            }

            return
        }

        var syncedRemotePlan = remotePlan
        syncedRemotePlan.syncStatus = .synced

        let localPlan = LocalWatchPlan(
            id: syncedRemotePlan.id,
            ownerId: syncedRemotePlan.ownerId,
            ownerDisplayName: syncedRemotePlan.ownerDisplayName,
            circleId: syncedRemotePlan.circleId,
            circleName: syncedRemotePlan.circleName,
            title: syncedRemotePlan.title,
            note: syncedRemotePlan.note,
            media: syncedRemotePlan.media,
            proposedStartAt: syncedRemotePlan.proposedStartAt,
            proposedEndAt: syncedRemotePlan.proposedEndAt,
            proposedDateText: syncedRemotePlan.proposedDateText,
            locationType: syncedRemotePlan.locationType,
            locationName: syncedRemotePlan.locationName,
            locationAddress: syncedRemotePlan.locationAddress,
            streamingService: syncedRemotePlan.streamingService,
            status: syncedRemotePlan.status,
            source: syncedRemotePlan.source,
            invitedMemberIds: syncedRemotePlan.invitedMemberIds,
            acceptedMemberIds: syncedRemotePlan.acceptedMemberIds,
            declinedMemberIds: syncedRemotePlan.declinedMemberIds,
            maybeMemberIds: syncedRemotePlan.maybeMemberIds,
            confirmedStartAt: syncedRemotePlan.confirmedStartAt,
            confirmedEndAt: syncedRemotePlan.confirmedEndAt,
            createdAt: syncedRemotePlan.createdAt,
            updatedAt: syncedRemotePlan.updatedAt,
            deletedAt: syncedRemotePlan.deletedAt,
            syncStatus: .synced
        )

        modelContext.insert(localPlan)
        try modelContext.save()
    }

    private func upsertRemoteResponse(
        _ remoteResponse: WatchPlanResponse,
        modelContext: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<LocalWatchPlanResponse>(
            predicate: #Predicate { response in
                response.id == remoteResponse.id
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            let localResponse = existing.domain

            if localResponse.syncStatus == .pending || localResponse.syncStatus == .failed {
                return
            }

            if remoteResponse.updatedAt >= localResponse.updatedAt {
                var syncedRemoteResponse = remoteResponse
                syncedRemoteResponse.syncStatus = .synced

                existing.update(from: syncedRemoteResponse)
                existing.syncStatusRaw = SyncStatus.synced.rawValue

                try modelContext.save()
            }

            return
        }

        var syncedRemoteResponse = remoteResponse
        syncedRemoteResponse.syncStatus = .synced

        let localResponse = LocalWatchPlanResponse(
            id: syncedRemoteResponse.id,
            planId: syncedRemoteResponse.planId,
            circleId: syncedRemoteResponse.circleId,
            userId: syncedRemoteResponse.userId,
            userDisplayName: syncedRemoteResponse.userDisplayName,
            responseType: syncedRemoteResponse.responseType,
            note: syncedRemoteResponse.note,
            suggestedStartAt: syncedRemoteResponse.suggestedStartAt,
            suggestedDateText: syncedRemoteResponse.suggestedDateText,
            createdAt: syncedRemoteResponse.createdAt,
            updatedAt: syncedRemoteResponse.updatedAt,
            deletedAt: syncedRemoteResponse.deletedAt,
            syncStatus: .synced
        )

        modelContext.insert(localResponse)
        try modelContext.save()
    }

    // MARK: - Mark Synced

    private func markLocalPlanSynced(
        id: String,
        modelContext: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<LocalWatchPlan>(
            predicate: #Predicate { plan in
                plan.id == id
            }
        )

        guard let plan = try modelContext.fetch(descriptor).first else {
            return
        }

        plan.syncStatusRaw = SyncStatus.synced.rawValue
        try modelContext.save()
    }

    private func markLocalResponseSynced(
        id: String,
        modelContext: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<LocalWatchPlanResponse>(
            predicate: #Predicate { response in
                response.id == id
            }
        )

        guard let response = try modelContext.fetch(descriptor).first else {
            return
        }

        response.syncStatusRaw = SyncStatus.synced.rawValue
        try modelContext.save()
    }
}

struct WatchPlanSyncSummary: Equatable {
    let syncedCount: Int
    let failedCount: Int
    let pulledCount: Int

    var hasFailures: Bool {
        failedCount > 0
    }
}

enum WatchPlanSyncServiceError: LocalizedError {
    case invalidActionType
    case missingPayload
    case localPlanMissing
    case localResponseMissing

    var errorDescription: String? {
        switch self {
        case .invalidActionType:
            return "Invalid Watch Together sync action."
        case .missingPayload:
            return "Missing Watch Together sync payload."
        case .localPlanMissing:
            return "The local Watch Together plan could not be found."
        case .localResponseMissing:
            return "The local Watch Together response could not be found."
        }
    }
}
