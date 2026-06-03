//
//  WatchPlanRepository.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation
import SwiftData

@MainActor
final class WatchPlanRepository {

    // MARK: - Create

    func createLocalPlan(
        ownerId: String,
        ownerDisplayName: String,
        circleId: String,
        circleName: String,
        title: String? = nil,
        note: String? = nil,
        media: WatchPlanMediaSnapshot,
        proposedStartAt: Date? = nil,
        proposedEndAt: Date? = nil,
        proposedDateText: String? = nil,
        locationType: WatchPlanLocationType = .notDecided,
        locationName: String? = nil,
        locationAddress: String? = nil,
        streamingService: String? = nil,
        invitedMemberIds: [String],
        source: WatchPlanSource = .circle,
        modelContext: ModelContext
    ) throws -> WatchPlan {
        let cleanedOwnerId = ownerId.trimmed
        let cleanedCircleId = circleId.trimmed
        let cleanedMediaTitle = media.displayTitle.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            throw WatchPlanRepositoryError.missingOwnerId
        }

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRepositoryError.missingCircleId
        }

        guard cleanedMediaTitle.isEmpty == false else {
            throw WatchPlanRepositoryError.emptyMediaTitle
        }

        let cleanedInvitedIds = WatchPlan.cleanIds(
            invitedMemberIds + [cleanedOwnerId]
        )

        guard cleanedInvitedIds.contains(where: { $0 != cleanedOwnerId }) else {
            throw WatchPlanRepositoryError.noInvitees
        }

        let resolvedTitle = title?.trimmed.nilIfBlank
            ?? "Watch \(media.displayTitle)"

        let localPlan = LocalWatchPlan(
            ownerId: cleanedOwnerId,
            ownerDisplayName: ownerDisplayName.trimmed,
            circleId: cleanedCircleId,
            circleName: circleName.trimmed,
            title: resolvedTitle,
            note: note?.trimmed.nilIfBlank,
            media: media,
            proposedStartAt: proposedStartAt,
            proposedEndAt: proposedEndAt,
            proposedDateText: proposedDateText?.trimmed.nilIfBlank,
            locationType: locationType,
            locationName: locationName?.trimmed.nilIfBlank,
            locationAddress: locationAddress?.trimmed.nilIfBlank,
            streamingService: streamingService?.trimmed.nilIfBlank,
            status: .proposed,
            source: source,
            invitedMemberIds: cleanedInvitedIds,
            acceptedMemberIds: WatchPlan.cleanIds([cleanedOwnerId]),
            declinedMemberIds: [],
            maybeMemberIds: [],
            confirmedStartAt: nil,
            confirmedEndAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncStatus: .pending
        )

        modelContext.insert(localPlan)
        try modelContext.save()

        return localPlan.domain
    }

    // MARK: - Read

    func fetchLocalPlans(
        includeDeleted: Bool = false,
        modelContext: ModelContext
    ) throws -> [WatchPlan] {
        let descriptor = FetchDescriptor<LocalWatchPlan>(
            sortBy: [
                SortDescriptor(\LocalWatchPlan.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter { includeDeleted || $0.deletedAt == nil }
            .map { $0.domain }
    }

    func fetchLocalPlan(
        id: String,
        modelContext: ModelContext
    ) throws -> WatchPlan? {
        try fetchLocalPlanModel(
            id: id,
            modelContext: modelContext
        )?.domain
    }

    func fetchLocalPlanModel(
        id: String,
        modelContext: ModelContext
    ) throws -> LocalWatchPlan? {
        let cleanedId = id.trimmed

        guard cleanedId.isEmpty == false else {
            return nil
        }

        let descriptor = FetchDescriptor<LocalWatchPlan>(
            predicate: #Predicate { plan in
                plan.id == cleanedId
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    func fetchPlansForCircle(
        circleId: String,
        includeDeleted: Bool = false,
        modelContext: ModelContext
    ) throws -> [WatchPlan] {
        let cleanedCircleId = circleId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            return []
        }

        let descriptor = FetchDescriptor<LocalWatchPlan>(
            predicate: #Predicate { plan in
                plan.circleId == cleanedCircleId
            },
            sortBy: [
                SortDescriptor(\LocalWatchPlan.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter { includeDeleted || $0.deletedAt == nil }
            .map { $0.domain }
    }

    func fetchPlansForUserCircles(
        circleIds: [String],
        includeDeleted: Bool = false,
        modelContext: ModelContext
    ) throws -> [WatchPlan] {
        let cleanedCircleIds = WatchPlan.cleanIds(circleIds)

        guard cleanedCircleIds.isEmpty == false else {
            return []
        }

        let descriptor = FetchDescriptor<LocalWatchPlan>(
            sortBy: [
                SortDescriptor(\LocalWatchPlan.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter { cleanedCircleIds.contains($0.circleId) }
            .filter { includeDeleted || $0.deletedAt == nil }
            .map { $0.domain }
    }

    func fetchUpcomingConfirmedPlans(
        circleIds: [String],
        modelContext: ModelContext
    ) throws -> [WatchPlan] {
        let plans = try fetchPlansForUserCircles(
            circleIds: circleIds,
            includeDeleted: false,
            modelContext: modelContext
        )

        return plans
            .filter { $0.status == .confirmed }
            .sorted { first, second in
                let firstDate = first.confirmedStartAt ?? first.proposedStartAt ?? first.updatedAt
                let secondDate = second.confirmedStartAt ?? second.proposedStartAt ?? second.updatedAt

                return firstDate < secondDate
            }
    }

    // MARK: - Response Read

    func fetchResponses(
        planId: String,
        includeDeleted: Bool = false,
        modelContext: ModelContext
    ) throws -> [WatchPlanResponse] {
        let cleanedPlanId = planId.trimmed

        guard cleanedPlanId.isEmpty == false else {
            return []
        }

        let descriptor = FetchDescriptor<LocalWatchPlanResponse>(
            predicate: #Predicate { response in
                response.planId == cleanedPlanId
            },
            sortBy: [
                SortDescriptor(\LocalWatchPlanResponse.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter { includeDeleted || $0.deletedAt == nil }
            .map { $0.domain }
    }

    func fetchResponse(
        planId: String,
        userId: String,
        modelContext: ModelContext
    ) throws -> WatchPlanResponse? {
        try fetchResponseModel(
            planId: planId,
            userId: userId,
            modelContext: modelContext
        )?.domain
    }

    func fetchResponseModel(
        planId: String,
        userId: String,
        modelContext: ModelContext
    ) throws -> LocalWatchPlanResponse? {
        let cleanedPlanId = planId.trimmed
        let cleanedUserId = userId.trimmed

        guard cleanedPlanId.isEmpty == false,
              cleanedUserId.isEmpty == false else {
            return nil
        }

        let descriptor = FetchDescriptor<LocalWatchPlanResponse>(
            predicate: #Predicate { response in
                response.planId == cleanedPlanId &&
                response.userId == cleanedUserId
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Update Plan

    func updateLocalPlan(
        planId: String,
        title: String? = nil,
        note: String? = nil,
        proposedStartAt: Date? = nil,
        proposedEndAt: Date? = nil,
        proposedDateText: String? = nil,
        locationType: WatchPlanLocationType? = nil,
        locationName: String? = nil,
        locationAddress: String? = nil,
        streamingService: String? = nil,
        invitedMemberIds: [String]? = nil,
        modelContext: ModelContext
    ) throws -> WatchPlan {
        guard let localPlan = try fetchLocalPlanModel(
            id: planId,
            modelContext: modelContext
        ) else {
            throw WatchPlanRepositoryError.planNotFound
        }

        if let title {
            localPlan.title = title.trimmed
        }

        if let note {
            localPlan.note = note.trimmed.nilIfBlank
        }

        if let proposedStartAt {
            localPlan.proposedStartAt = proposedStartAt
        }

        if let proposedEndAt {
            localPlan.proposedEndAt = proposedEndAt
        }

        if let proposedDateText {
            localPlan.proposedDateText = proposedDateText.trimmed.nilIfBlank
        }

        if let locationType {
            localPlan.locationTypeRaw = locationType.rawValue
        }

        if let locationName {
            localPlan.locationName = locationName.trimmed.nilIfBlank
        }

        if let locationAddress {
            localPlan.locationAddress = locationAddress.trimmed.nilIfBlank
        }

        if let streamingService {
            localPlan.streamingService = streamingService.trimmed.nilIfBlank
        }

        if let invitedMemberIds {
            localPlan.invitedMemberIds = WatchPlan.cleanIds(
                invitedMemberIds + [localPlan.ownerId]
            )
        }

        localPlan.updatedAt = Date()
        localPlan.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        return localPlan.domain
    }

    // MARK: - Respond

    func respondToPlan(
        planId: String,
        circleId: String,
        userId: String,
        userDisplayName: String,
        responseType: WatchPlanResponseType,
        note: String? = nil,
        suggestedStartAt: Date? = nil,
        suggestedDateText: String? = nil,
        modelContext: ModelContext
    ) throws -> WatchPlanResponse {
        let cleanedPlanId = planId.trimmed
        let cleanedCircleId = circleId.trimmed
        let cleanedUserId = userId.trimmed

        guard cleanedPlanId.isEmpty == false else {
            throw WatchPlanRepositoryError.missingPlanId
        }

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRepositoryError.missingCircleId
        }

        guard cleanedUserId.isEmpty == false else {
            throw WatchPlanRepositoryError.missingUserId
        }

        guard let localPlan = try fetchLocalPlanModel(
            id: cleanedPlanId,
            modelContext: modelContext
        ) else {
            throw WatchPlanRepositoryError.planNotFound
        }

        guard localPlan.deletedAt == nil else {
            throw WatchPlanRepositoryError.planInactive
        }

        guard localPlan.statusRaw != WatchPlanStatus.canceled.rawValue,
              localPlan.statusRaw != WatchPlanStatus.watched.rawValue else {
            throw WatchPlanRepositoryError.planInactive
        }

        let response: LocalWatchPlanResponse

        if let existingResponse = try fetchResponseModel(
            planId: cleanedPlanId,
            userId: cleanedUserId,
            modelContext: modelContext
        ) {
            existingResponse.responseTypeRaw = responseType.rawValue
            existingResponse.note = note?.trimmed.nilIfBlank
            existingResponse.suggestedStartAt = suggestedStartAt
            existingResponse.suggestedDateText = suggestedDateText?.trimmed.nilIfBlank
            existingResponse.deletedAt = nil
            existingResponse.updatedAt = Date()
            existingResponse.syncStatusRaw = SyncStatus.pending.rawValue

            response = existingResponse
        } else {
            let newResponse = LocalWatchPlanResponse(
                planId: cleanedPlanId,
                circleId: cleanedCircleId,
                userId: cleanedUserId,
                userDisplayName: userDisplayName.trimmed,
                responseType: responseType,
                note: note?.trimmed.nilIfBlank,
                suggestedStartAt: suggestedStartAt,
                suggestedDateText: suggestedDateText?.trimmed.nilIfBlank,
                syncStatus: .pending
            )

            modelContext.insert(newResponse)
            response = newResponse
        }

        applyResponseSummary(
            to: localPlan,
            userId: cleanedUserId,
            responseType: responseType
        )

        try modelContext.save()

        return response.domain
    }

    // MARK: - Confirm / Cancel / Watched

    func confirmPlan(
        planId: String,
        confirmedStartAt: Date? = nil,
        confirmedEndAt: Date? = nil,
        modelContext: ModelContext
    ) throws -> WatchPlan {
        guard let localPlan = try fetchLocalPlanModel(
            id: planId,
            modelContext: modelContext
        ) else {
            throw WatchPlanRepositoryError.planNotFound
        }

        guard localPlan.deletedAt == nil else {
            throw WatchPlanRepositoryError.planInactive
        }

        guard localPlan.statusRaw == WatchPlanStatus.proposed.rawValue else {
            throw WatchPlanRepositoryError.planMustBeProposed
        }

        let acceptedInviteeIds = localPlan.acceptedMemberIds.filter {
            $0.trimmed != localPlan.ownerId.trimmed
        }

        guard acceptedInviteeIds.isEmpty == false else {
            throw WatchPlanRepositoryError.noAcceptedParticipants
        }

        localPlan.statusRaw = WatchPlanStatus.confirmed.rawValue
        localPlan.confirmedStartAt = confirmedStartAt ?? localPlan.proposedStartAt
        localPlan.confirmedEndAt = confirmedEndAt ?? localPlan.proposedEndAt
        localPlan.updatedAt = Date()
        localPlan.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        return localPlan.domain
    }

    func cancelPlan(
        planId: String,
        modelContext: ModelContext
    ) throws -> WatchPlan {
        guard let localPlan = try fetchLocalPlanModel(
            id: planId,
            modelContext: modelContext
        ) else {
            throw WatchPlanRepositoryError.planNotFound
        }

        guard localPlan.deletedAt == nil else {
            throw WatchPlanRepositoryError.planInactive
        }

        localPlan.statusRaw = WatchPlanStatus.canceled.rawValue
        localPlan.updatedAt = Date()
        localPlan.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        return localPlan.domain
    }

    func markPlanWatched(
        planId: String,
        modelContext: ModelContext
    ) throws -> WatchPlan {
        guard let localPlan = try fetchLocalPlanModel(
            id: planId,
            modelContext: modelContext
        ) else {
            throw WatchPlanRepositoryError.planNotFound
        }

        guard localPlan.deletedAt == nil else {
            throw WatchPlanRepositoryError.planInactive
        }

        guard localPlan.statusRaw == WatchPlanStatus.confirmed.rawValue else {
            throw WatchPlanRepositoryError.planMustBeConfirmed
        }

        localPlan.statusRaw = WatchPlanStatus.watched.rawValue
        localPlan.updatedAt = Date()
        localPlan.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        return localPlan.domain
    }

    // MARK: - Delete

    func softDeletePlan(
        planId: String,
        modelContext: ModelContext
    ) throws -> WatchPlan {
        guard let localPlan = try fetchLocalPlanModel(
            id: planId,
            modelContext: modelContext
        ) else {
            throw WatchPlanRepositoryError.planNotFound
        }

        localPlan.deletedAt = Date()
        localPlan.updatedAt = Date()
        localPlan.syncStatusRaw = SyncStatus.pending.rawValue

        try modelContext.save()

        return localPlan.domain
    }

    func deleteLocalPlanCompletely(
        planId: String,
        modelContext: ModelContext
    ) throws {
        guard let localPlan = try fetchLocalPlanModel(
            id: planId,
            modelContext: modelContext
        ) else {
            return
        }

        let responses = try fetchResponseModels(
            planId: planId,
            modelContext: modelContext
        )

        for response in responses {
            modelContext.delete(response)
        }

        modelContext.delete(localPlan)

        try modelContext.save()
    }

    // MARK: - Response Cleanup

    private func fetchResponseModels(
        planId: String,
        modelContext: ModelContext
    ) throws -> [LocalWatchPlanResponse] {
        let cleanedPlanId = planId.trimmed

        guard cleanedPlanId.isEmpty == false else {
            return []
        }

        let descriptor = FetchDescriptor<LocalWatchPlanResponse>(
            predicate: #Predicate { response in
                response.planId == cleanedPlanId
            }
        )

        return try modelContext.fetch(descriptor)
    }

    // MARK: - Helpers

    private func applyResponseSummary(
        to plan: LocalWatchPlan,
        userId: String,
        responseType: WatchPlanResponseType
    ) {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            return
        }

        plan.acceptedMemberIds.removeAll { $0 == cleanedUserId }
        plan.declinedMemberIds.removeAll { $0 == cleanedUserId }
        plan.maybeMemberIds.removeAll { $0 == cleanedUserId }

        switch responseType {
        case .accepted:
            plan.acceptedMemberIds.append(cleanedUserId)

        case .declined:
            plan.declinedMemberIds.append(cleanedUserId)

        case .maybe, .suggestAnotherTime:
            plan.maybeMemberIds.append(cleanedUserId)
        }

        plan.acceptedMemberIds = WatchPlan.cleanIds(plan.acceptedMemberIds)
        plan.declinedMemberIds = WatchPlan.cleanIds(plan.declinedMemberIds)
        plan.maybeMemberIds = WatchPlan.cleanIds(plan.maybeMemberIds)

        if plan.invitedMemberIds.contains(cleanedUserId) == false {
            plan.invitedMemberIds.append(cleanedUserId)
        }

        if plan.invitedMemberIds.contains(plan.ownerId) == false {
            plan.invitedMemberIds.append(plan.ownerId)
        }

        plan.invitedMemberIds = WatchPlan.cleanIds(plan.invitedMemberIds)

        plan.updatedAt = Date()
        plan.syncStatusRaw = SyncStatus.pending.rawValue
    }
}

enum WatchPlanRepositoryError: LocalizedError {
    case missingOwnerId
    case missingUserId
    case missingCircleId
    case missingPlanId
    case emptyMediaTitle
    case noInvitees
    case planNotFound
    case planInactive
    case noAcceptedParticipants
    case planMustBeProposed
    case planMustBeConfirmed

    var errorDescription: String? {
        switch self {
        case .missingOwnerId:
            return "A valid owner is required to create this Watch Together plan."

        case .missingUserId:
            return "A valid user is required to respond to this plan."

        case .missingCircleId:
            return "A valid Circle is required for this Watch Together plan."

        case .missingPlanId:
            return "A valid Watch Together plan is required."

        case .emptyMediaTitle:
            return "Choose a movie or series before creating the plan."

        case .noInvitees:
            return "Invite at least one Circle member to create a Watch Together plan."

        case .planNotFound:
            return "This Watch Together plan was not found."

        case .planInactive:
            return "This Watch Together plan is no longer active."

        case .noAcceptedParticipants:
            return "At least one invited member must say yes before confirming the plan."

        case .planMustBeProposed:
            return "Only proposed Watch Together plans can be confirmed."

        case .planMustBeConfirmed:
            return "Only confirmed Watch Together plans can be marked as watched."
        }
    }
}
