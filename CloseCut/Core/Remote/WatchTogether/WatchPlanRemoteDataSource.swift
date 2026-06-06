//
//  WatchPlanRemoteDataSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation
import FirebaseFirestore

final class WatchPlanRemoteDataSource {

    // MARK: - Paths

    private func plansCollection(
        circleId: String
    ) -> CollectionReference {
        FirestorePaths.circleWatchPlans(circleId)
    }

    private func planDocument(
        circleId: String,
        planId: String
    ) -> DocumentReference {
        FirestorePaths.circleWatchPlan(
            circleId: circleId,
            planId: planId
        )
    }

    private func responsesCollection(
        circleId: String,
        planId: String
    ) -> CollectionReference {
        FirestorePaths.watchPlanResponses(
            circleId: circleId,
            planId: planId
        )
    }

    private func responseDocument(
        circleId: String,
        planId: String,
        responseId: String
    ) -> DocumentReference {
        FirestorePaths.watchPlanResponse(
            circleId: circleId,
            planId: planId,
            responseId: responseId
        )
    }

    // MARK: - Plan Writes

    func upsertPlan(
        _ plan: WatchPlan
    ) async throws {
        let cleanedCircleId = plan.circleId.trimmed
        let cleanedPlanId = plan.id.trimmed

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingCircleId
        }

        guard cleanedPlanId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingPlanId
        }

        let dto = FirestoreWatchPlanDTO(plan: plan)

        try planDocument(
            circleId: cleanedCircleId,
            planId: cleanedPlanId
        )
        .setData(from: dto, merge: true)
    }

    func softDeletePlan(
        _ plan: WatchPlan
    ) async throws {
        var deletedPlan = plan
        deletedPlan.deletedAt = Date()
        deletedPlan.updatedAt = Date()
        deletedPlan.syncStatus = .pending

        try await upsertPlan(deletedPlan)
    }

    // MARK: - Plan Reads

    func fetchPlan(
        circleId: String,
        planId: String
    ) async throws -> WatchPlan {
        let cleanedCircleId = circleId.trimmed
        let cleanedPlanId = planId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingCircleId
        }

        guard cleanedPlanId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingPlanId
        }

        let snapshot = try await planDocument(
            circleId: cleanedCircleId,
            planId: cleanedPlanId
        )
        .getDocument()

        guard snapshot.exists else {
            throw WatchPlanRemoteDataSourceError.planDocumentMissing
        }

        let dto = try snapshot.data(as: FirestoreWatchPlanDTO.self)
        return dto.domain
    }

    func fetchPlansForCircle(
        circleId: String,
        includeDeleted: Bool = false,
        limit: Int = 50
    ) async throws -> [WatchPlan] {
        let cleanedCircleId = circleId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingCircleId
        }

        let snapshot = try await plansCollection(
            circleId: cleanedCircleId
        )
        .order(by: "updatedAt", descending: true)
        .limit(to: limit)
        .getDocuments()

        let plans = try snapshot.documents.map { document in
            try document.data(as: FirestoreWatchPlanDTO.self).domain
        }

        return plans.filter { plan in
            includeDeleted || plan.deletedAt == nil
        }
    }

    func fetchActivePlansForCircle(
        circleId: String,
        limit: Int = 50
    ) async throws -> [WatchPlan] {
        try await fetchPlansForCircle(
            circleId: circleId,
            includeDeleted: false,
            limit: limit
        )
        .filter { plan in
            plan.status != .canceled &&
            plan.status != .watched
        }
    }

    func fetchPlansForCircles(
        circleIds: [String],
        includeDeleted: Bool = false,
        limitPerCircle: Int = 50
    ) async throws -> [WatchPlan] {
        let cleanedCircleIds = WatchPlan.cleanIds(circleIds)

        guard cleanedCircleIds.isEmpty == false else {
            return []
        }

        var allPlans: [WatchPlan] = []

        for circleId in cleanedCircleIds {
            let plans = try await fetchPlansForCircle(
                circleId: circleId,
                includeDeleted: includeDeleted,
                limit: limitPerCircle
            )

            allPlans.append(contentsOf: plans)
        }

        return allPlans.sorted { first, second in
            first.updatedAt > second.updatedAt
        }
    }

    // MARK: - Response Writes

    func upsertResponse(
        _ response: WatchPlanResponse
    ) async throws {
        let cleanedCircleId = response.circleId.trimmed
        let cleanedPlanId = response.planId.trimmed
        let cleanedResponseId = response.id.trimmed
        let cleanedUserId = response.userId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingCircleId
        }

        guard cleanedPlanId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingPlanId
        }

        guard cleanedResponseId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingResponseId
        }

        guard cleanedUserId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingUserId
        }

        let planRef = planDocument(
            circleId: cleanedCircleId,
            planId: cleanedPlanId
        )

        let responseRef = responseDocument(
            circleId: cleanedCircleId,
            planId: cleanedPlanId,
            responseId: cleanedResponseId
        )

        let dto = FirestoreWatchPlanResponseDTO(response: response)
        let responseData = try Firestore.Encoder().encode(dto)

        let batch = Firestore.firestore().batch()

        batch.setData(
            responseData,
            forDocument: responseRef,
            merge: true
        )

        var planPayload: [String: Any] = [
            "acceptedMemberIds": FieldValue.arrayRemove([cleanedUserId]),
            "declinedMemberIds": FieldValue.arrayRemove([cleanedUserId]),
            "maybeMemberIds": FieldValue.arrayRemove([cleanedUserId]),
            "invitedMemberIds": FieldValue.arrayUnion([cleanedUserId]),
            "updatedAt": Timestamp(date: Date())
        ]

        if response.deletedAt == nil {
            switch response.responseType {
            case .accepted:
                planPayload["acceptedMemberIds"] = FieldValue.arrayUnion([cleanedUserId])

            case .declined:
                planPayload["declinedMemberIds"] = FieldValue.arrayUnion([cleanedUserId])

            case .maybe, .suggestAnotherTime:
                planPayload["maybeMemberIds"] = FieldValue.arrayUnion([cleanedUserId])
            }
        }

        batch.updateData(
            planPayload,
            forDocument: planRef
        )

        try await batch.commit()
    }

    func softDeleteResponse(
        _ response: WatchPlanResponse
    ) async throws {
        var deletedResponse = response
        deletedResponse.deletedAt = Date()
        deletedResponse.updatedAt = Date()
        deletedResponse.syncStatus = .pending

        let cleanedCircleId = deletedResponse.circleId.trimmed
        let cleanedPlanId = deletedResponse.planId.trimmed
        let cleanedResponseId = deletedResponse.id.trimmed
        let cleanedUserId = deletedResponse.userId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingCircleId
        }

        guard cleanedPlanId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingPlanId
        }

        guard cleanedResponseId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingResponseId
        }

        guard cleanedUserId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingUserId
        }

        let planRef = planDocument(
            circleId: cleanedCircleId,
            planId: cleanedPlanId
        )

        let responseRef = responseDocument(
            circleId: cleanedCircleId,
            planId: cleanedPlanId,
            responseId: cleanedResponseId
        )

        let dto = FirestoreWatchPlanResponseDTO(response: deletedResponse)
        let responseData = try Firestore.Encoder().encode(dto)

        let batch = Firestore.firestore().batch()

        batch.setData(
            responseData,
            forDocument: responseRef,
            merge: true
        )

        batch.updateData(
            [
                "acceptedMemberIds": FieldValue.arrayRemove([cleanedUserId]),
                "declinedMemberIds": FieldValue.arrayRemove([cleanedUserId]),
                "maybeMemberIds": FieldValue.arrayRemove([cleanedUserId]),
                "updatedAt": Timestamp(date: Date())
            ],
            forDocument: planRef
        )

        try await batch.commit()
    }

    // MARK: - Response Reads

    func fetchResponses(
        circleId: String,
        planId: String,
        includeDeleted: Bool = false
    ) async throws -> [WatchPlanResponse] {
        let cleanedCircleId = circleId.trimmed
        let cleanedPlanId = planId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingCircleId
        }

        guard cleanedPlanId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingPlanId
        }

        let snapshot = try await responsesCollection(
            circleId: cleanedCircleId,
            planId: cleanedPlanId
        )
        .order(by: "updatedAt", descending: true)
        .getDocuments()

        let responses = try snapshot.documents.map { document in
            try document.data(as: FirestoreWatchPlanResponseDTO.self).domain
        }

        return responses.filter { response in
            includeDeleted || response.deletedAt == nil
        }
    }

    func fetchResponse(
        circleId: String,
        planId: String,
        responseId: String
    ) async throws -> WatchPlanResponse {
        let cleanedCircleId = circleId.trimmed
        let cleanedPlanId = planId.trimmed
        let cleanedResponseId = responseId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingCircleId
        }

        guard cleanedPlanId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingPlanId
        }

        guard cleanedResponseId.isEmpty == false else {
            throw WatchPlanRemoteDataSourceError.missingResponseId
        }

        let snapshot = try await responseDocument(
            circleId: cleanedCircleId,
            planId: cleanedPlanId,
            responseId: cleanedResponseId
        )
        .getDocument()

        guard snapshot.exists else {
            throw WatchPlanRemoteDataSourceError.responseDocumentMissing
        }

        let dto = try snapshot.data(as: FirestoreWatchPlanResponseDTO.self)
        return dto.domain
    }
}

enum WatchPlanRemoteDataSourceError: LocalizedError {
    case missingCircleId
    case missingPlanId
    case missingResponseId
    case missingUserId
    case planDocumentMissing
    case responseDocumentMissing

    var errorDescription: String? {
        switch self {
        case .missingCircleId:
            return "A valid Circle is required to sync this Watch Together plan."

        case .missingPlanId:
            return "A valid Watch Together plan is required."

        case .missingResponseId:
            return "A valid Watch Together response is required."

        case .missingUserId:
            return "A valid user is required to sync this Watch Together response."

        case .planDocumentMissing:
            return "This Watch Together plan could not be found in the cloud."

        case .responseDocumentMissing:
            return "This Watch Together response could not be found in the cloud."
        }
    }
}
