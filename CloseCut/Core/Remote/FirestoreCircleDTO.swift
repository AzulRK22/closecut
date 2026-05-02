//
//  FirestoreCircleDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreCircleDTO: Codable {
    var name: String
    var ownerId: String
    var inviteCode: String
    var inviteCodeNormalized: String
    var memberIds: [String]
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var deletedAt: Timestamp?
}

extension FirestoreCircleDTO {
    init(closeCircle: CloseCircle) {
        self.name = closeCircle.name
        self.ownerId = closeCircle.ownerId
        self.inviteCode = closeCircle.inviteCode
        self.inviteCodeNormalized = closeCircle.inviteCodeNormalized
        self.memberIds = closeCircle.memberIds
        self.createdAt = Timestamp(date: closeCircle.createdAt)
        self.updatedAt = Timestamp(date: closeCircle.updatedAt)
        self.deletedAt = closeCircle.deletedAt.map { Timestamp(date: $0) }
    }

    func domain(id: String) -> CloseCircle {
        CloseCircle(
            id: id,
            name: name,
            ownerId: ownerId,
            inviteCode: inviteCode,
            inviteCodeNormalized: inviteCodeNormalized,
            memberIds: memberIds,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue()
        )
    }
}
