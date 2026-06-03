//
//  LocalWatchPlanResponse.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation
import SwiftData

@Model
final class LocalWatchPlanResponse {
    @Attribute(.unique) var id: String

    var planId: String
    var circleId: String

    var userId: String
    var userDisplayName: String

    var responseTypeRaw: String
    var note: String?

    var suggestedStartAt: Date?
    var suggestedDateText: String?

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatusRaw: String

    init(
        id: String = UUID().uuidString,
        planId: String,
        circleId: String,
        userId: String,
        userDisplayName: String,
        responseType: WatchPlanResponseType,
        note: String? = nil,
        suggestedStartAt: Date? = nil,
        suggestedDateText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id

        self.planId = planId.trimmed
        self.circleId = circleId.trimmed

        self.userId = userId.trimmed
        self.userDisplayName = userDisplayName.trimmed

        self.responseTypeRaw = responseType.rawValue
        self.note = note?.trimmed.nilIfBlank

        self.suggestedStartAt = suggestedStartAt
        self.suggestedDateText = suggestedDateText?.trimmed.nilIfBlank

        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt

        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalWatchPlanResponse {
    var domain: WatchPlanResponse {
        WatchPlanResponse(
            id: id,
            planId: planId,
            circleId: circleId,
            userId: userId,
            userDisplayName: userDisplayName,
            responseType: WatchPlanResponseType(rawValue: responseTypeRaw) ?? .maybe,
            note: note,
            suggestedStartAt: suggestedStartAt,
            suggestedDateText: suggestedDateText,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }

    func update(from response: WatchPlanResponse) {
        planId = response.planId
        circleId = response.circleId

        userId = response.userId
        userDisplayName = response.userDisplayName

        responseTypeRaw = response.responseType.rawValue
        note = response.note

        suggestedStartAt = response.suggestedStartAt
        suggestedDateText = response.suggestedDateText

        createdAt = response.createdAt
        updatedAt = response.updatedAt
        deletedAt = response.deletedAt

        syncStatusRaw = response.syncStatus.rawValue
    }
}
