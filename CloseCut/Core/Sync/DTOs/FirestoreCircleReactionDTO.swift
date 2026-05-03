//
//  FirestoreCircleReactionDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreCircleReactionDTO: Codable {
    var entryId: String
    var circleId: String
    var userId: String
    var displayName: String
    var type: String
    var createdAt: Timestamp
    var updatedAt: Timestamp
}

extension FirestoreCircleReactionDTO {
    init(reaction: CircleReaction) {
        self.entryId = reaction.entryId
        self.circleId = reaction.circleId
        self.userId = reaction.userId
        self.displayName = reaction.displayName
        self.type = reaction.type.rawValue
        self.createdAt = Timestamp(date: reaction.createdAt)
        self.updatedAt = Timestamp(date: reaction.updatedAt)
    }

    func domain(id: String) -> CircleReaction {
        CircleReaction(
            id: id,
            entryId: entryId,
            circleId: circleId,
            userId: userId,
            displayName: displayName,
            type: CircleReactionType(rawValue: type) ?? .loved,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}
