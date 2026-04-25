//
//  FirestoreCommentDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreCommentDTO: Codable {
    var entryId: String
    var userId: String
    var text: String
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var deletedAt: Timestamp?
}

extension FirestoreCommentDTO {
    init(comment: Comment) {
        self.entryId = comment.entryId
        self.userId = comment.userId
        self.text = comment.text
        self.createdAt = Timestamp(date: comment.createdAt)
        self.updatedAt = Timestamp(date: comment.updatedAt)
        self.deletedAt = comment.deletedAt.map { Timestamp(date: $0) }
    }

    func domain(id: String, syncStatus: SyncStatus = .synced) -> Comment {
        Comment(
            id: id,
            entryId: entryId,
            userId: userId,
            text: text,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue(),
            syncStatus: syncStatus
        )
    }
}
