//
//  CircleSocialRemoteDataSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import Foundation
import FirebaseFirestore

@MainActor
final class CircleSocialRemoteDataSource {
    private let db = Firestore.firestore()

    // MARK: - Reactions

    func fetchReactions(
        entryId: String
    ) async throws -> [CircleReaction] {
        let snapshot = try await db
            .collection("entries")
            .document(entryId)
            .collection("reactions")
            .getDocuments()

        return try snapshot.documents.map { document in
            let dto = try document.data(as: FirestoreCircleReactionDTO.self)
            return dto.domain(id: document.documentID)
        }
    }

    func setReaction(
        entryId: String,
        circleId: String,
        userId: String,
        displayName: String,
        type: CircleReactionType
    ) async throws -> CircleReaction {
        let now = Date()

        let reaction = CircleReaction(
            id: userId,
            entryId: entryId,
            circleId: circleId,
            userId: userId,
            displayName: displayName,
            type: type,
            createdAt: now,
            updatedAt: now
        )

        let dto = FirestoreCircleReactionDTO(reaction: reaction)

        try db
            .collection("entries")
            .document(entryId)
            .collection("reactions")
            .document(userId)
            .setData(from: dto, merge: true)

        return reaction
    }

    func removeReaction(
        entryId: String,
        userId: String
    ) async throws {
        try await db
            .collection("entries")
            .document(entryId)
            .collection("reactions")
            .document(userId)
            .delete()
    }

    // MARK: - Comments

    func fetchComments(
        entryId: String,
        limit: Int = 50
    ) async throws -> [CircleComment] {
        let snapshot = try await db
            .collection("entries")
            .document(entryId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            let dto = try document.data(as: FirestoreCircleCommentDTO.self)
            let comment = dto.domain(id: document.documentID)

            return comment.deletedAt == nil ? comment : nil
        }
    }

    func createComment(
        entryId: String,
        circleId: String,
        userId: String,
        displayName: String,
        text: String
    ) async throws -> CircleComment {
        let now = Date()
        let commentId = UUID().uuidString

        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let comment = CircleComment(
            id: commentId,
            entryId: entryId,
            circleId: circleId,
            userId: userId,
            displayName: displayName,
            text: cleanedText,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil
        )

        let dto = FirestoreCircleCommentDTO(comment: comment)

        try db
            .collection("entries")
            .document(entryId)
            .collection("comments")
            .document(commentId)
            .setData(from: dto, merge: true)

        return comment
    }

    func softDeleteComment(
        entryId: String,
        commentId: String,
        userId: String
    ) async throws {
        try await db
            .collection("entries")
            .document(entryId)
            .collection("comments")
            .document(commentId)
            .updateData([
                "deletedAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ])
    }
}
