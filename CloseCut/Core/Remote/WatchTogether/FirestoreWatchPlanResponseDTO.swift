//
//  FirestoreWatchPlanResponseDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreWatchPlanResponseDTO: Codable {
    let id: String

    let planId: String
    let circleId: String

    let userId: String
    let userDisplayName: String

    let responseTypeRaw: String
    let note: String?

    let suggestedStartAt: Timestamp?
    let suggestedDateText: String?

    let createdAt: Timestamp
    let updatedAt: Timestamp
    let deletedAt: Timestamp?

    init(response: WatchPlanResponse) {
        self.id = response.id

        self.planId = response.planId
        self.circleId = response.circleId

        self.userId = response.userId
        self.userDisplayName = response.userDisplayName

        self.responseTypeRaw = response.responseType.rawValue
        self.note = response.note

        self.suggestedStartAt = response.suggestedStartAt.map(Timestamp.init(date:))
        self.suggestedDateText = response.suggestedDateText

        self.createdAt = Timestamp(date: response.createdAt)
        self.updatedAt = Timestamp(date: response.updatedAt)
        self.deletedAt = response.deletedAt.map(Timestamp.init(date:))
    }

    var domain: WatchPlanResponse {
        WatchPlanResponse(
            id: id,
            planId: planId,
            circleId: circleId,
            userId: userId,
            userDisplayName: userDisplayName,
            responseType: WatchPlanResponseType(rawValue: responseTypeRaw) ?? .maybe,
            note: note,
            suggestedStartAt: suggestedStartAt?.dateValue(),
            suggestedDateText: suggestedDateText,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue(),
            syncStatus: .synced
        )
    }
}
