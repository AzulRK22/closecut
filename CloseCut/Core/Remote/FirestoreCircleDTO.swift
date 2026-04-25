//
//  FirestoreCircleDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//


import Foundation
import FirebaseFirestore

struct FirestoreCircleDTO: Codable {
    var ownerId: String
    var memberIds: [String]
    var inviteCodeHash: String?
    var createdAt: Timestamp
    var updatedAt: Timestamp
}

extension FirestoreCircleDTO {
    init(circle: Circle, inviteCodeHash: String? = nil) {
        self.ownerId = circle.ownerId
        self.memberIds = circle.memberIds
        self.inviteCodeHash = inviteCodeHash
        self.createdAt = Timestamp(date: circle.createdAt)
        self.updatedAt = Timestamp(date: circle.updatedAt)
    }

    func domain(id: String, inviteCode: String? = nil) -> Circle {
        Circle(
            id: id,
            ownerId: ownerId,
            memberIds: memberIds,
            inviteCode: inviteCode,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}
