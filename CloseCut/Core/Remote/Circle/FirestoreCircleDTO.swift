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
    var description: String?
    var ownerId: String
    var ownerDisplayName: String?
    var inviteCode: String
    var inviteCodeNormalized: String
    var memberIds: [String]?
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var deletedAt: Timestamp?
}

extension FirestoreCircleDTO {
    init(
        closeCircle: CloseCircle
    ) {
        self.name = closeCircle.name.trimmed
        self.description = closeCircle.description.trimmedOrNil
        self.ownerId = closeCircle.ownerId.trimmed
        self.ownerDisplayName = closeCircle.ownerDisplayName.trimmed
        self.inviteCode = closeCircle.inviteCode.trimmed
        self.inviteCodeNormalized = closeCircle.inviteCodeNormalized.normalizedInviteCode
        self.memberIds = closeCircle.memberIds.cleanedUniqueIds
        self.createdAt = Timestamp(date: closeCircle.createdAt)
        self.updatedAt = Timestamp(date: closeCircle.updatedAt)
        self.deletedAt = closeCircle.deletedAt.map {
            Timestamp(date: $0)
        }
    }

    func domain(
        id: String
    ) -> CloseCircle {
        let cleanedOwnerId = ownerId.trimmed
        let resolvedMemberIds = ((memberIds ?? []) + [cleanedOwnerId]).cleanedUniqueIds

        return CloseCircle(
            id: id,
            name: name.trimmed.isEmpty ? "Untitled Circle" : name.trimmed,
            description: description.trimmedOrNil,
            ownerId: cleanedOwnerId,
            ownerDisplayName: ownerDisplayName.trimmedOrNil ?? "Circle Owner",
            inviteCode: inviteCode.trimmed,
            inviteCodeNormalized: inviteCodeNormalized.normalizedInviteCode,
            memberIds: resolvedMemberIds,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue()
        )
    }
}
