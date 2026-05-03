//
//  FirestoreCircleCommentDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreCircleCommentDTO: Codable {
    var entryId: String
    var circleId: String
    var userId: String
    var displayName: String
    var text: String
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var deletedAt: Timestamp?
}

extension FirestoreCircleCommentDTO {
    init(comment: CircleComment) {
        self.entryId = comment.entryId
        self.circleId = comment.circleId
        self.userId = comment.userId
        self.displayName = comment.displayName
        self.text = comment.text
        self.createdAt = Timestamp(date: comment.createdAt)
        self.updatedAt = Timestamp(date: comment.updatedAt)
        self.deletedAt = comment.deletedAt.map { Timestamp(date: $0) }
    }

    func domain(id: String) -> CircleComment {
        CircleComment(
            id: id,
            entryId: entryId,
            circleId: circleId,
            userId: userId,
            displayName: displayName,
            text: text,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue()
        )
    }
}
