//
//  FirestoreReactionDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreReactionDTO: Codable {
    var userId: String
    var entryId: String
    var type: String
    var createdAt: Timestamp
    var updatedAt: Timestamp
}

extension FirestoreReactionDTO {
    init(reaction: Reaction) {
        self.userId = reaction.userId
        self.entryId = reaction.entryId
        self.type = reaction.type.rawValue
        self.createdAt = Timestamp(date: reaction.createdAt)
        self.updatedAt = Timestamp(date: reaction.updatedAt)
    }

    func domain(syncStatus: SyncStatus = .synced) -> Reaction {
        Reaction(
            entryId: entryId,
            userId: userId,
            type: ReactionType(rawValue: type) ?? .loved,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            syncStatus: syncStatus
        )
    }
}
