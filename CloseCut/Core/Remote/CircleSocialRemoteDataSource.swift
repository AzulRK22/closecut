//
//  CircleSocialRemoteDataSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import Foundation
import FirebaseFirestore

enum CircleSocialRemoteDataSourceError: LocalizedError {
    case emptyComment
    case commentTooLong
    case invalidEntryId
    case invalidCircleId
    case invalidUserId
    case invalidCommentId

    var errorDescription: String? {
        switch self {
        case .emptyComment:
            return "Comment cannot be empty."
        case .commentTooLong:
            return "Comments must be 240 characters or less."
        case .invalidEntryId:
            return "Entry ID is invalid."
        case .invalidCircleId:
            return "Circle ID is invalid."
        case .invalidUserId:
            return "User ID is invalid."
        case .invalidCommentId:
            return "Comment ID is invalid."
        }
    }
}

@MainActor
final class CircleSocialRemoteDataSource {
    private let maxCommentLength = 240

    // MARK: - Reactions

    func fetchReactions(
        entryId: String,
        circleId: String
    ) async throws -> [CircleReaction] {
        let cleanedEntryId = clean(entryId)
        let cleanedCircleId = clean(circleId)

        guard cleanedEntryId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidEntryId
        }

        guard cleanedCircleId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidCircleId
        }

        let snapshot = try await FirestorePaths
            .entryReactions(cleanedEntryId)
            .whereField("circleId", isEqualTo: cleanedCircleId)
            .getDocuments()

        return try snapshot.documents.map { document in
            let dto = try document.data(as: FirestoreCircleReactionDTO.self)

            return dto.domain(
                id: document.documentID
            )
        }
    }

    func setReaction(
        entryId: String,
        circleId: String,
        userId: String,
        displayName: String,
        type: CircleReactionType
    ) async throws -> CircleReaction {
        let cleanedEntryId = clean(entryId)
        let cleanedCircleId = clean(circleId)
        let cleanedUserId = clean(userId)
        let cleanedDisplayName = clean(displayName)

        guard cleanedEntryId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidEntryId
        }

        guard cleanedCircleId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidCircleId
        }

        guard cleanedUserId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidUserId
        }

        let now = Date()

        let existingReaction = try? await fetchReaction(
            entryId: cleanedEntryId,
            userId: cleanedUserId
        )

        let reaction = CircleReaction(
            id: cleanedUserId,
            entryId: cleanedEntryId,
            circleId: cleanedCircleId,
            userId: cleanedUserId,
            displayName: cleanedDisplayName.isEmpty ? "Circle member" : cleanedDisplayName,
            type: type,
            createdAt: existingReaction?.createdAt ?? now,
            updatedAt: now
        )

        let dto = FirestoreCircleReactionDTO(
            reaction: reaction
        )

        try FirestorePaths
            .entryReaction(
                entryId: cleanedEntryId,
                userId: cleanedUserId
            )
            .setData(from: dto, merge: true)

        return reaction
    }

    func removeReaction(
        entryId: String,
        userId: String
    ) async throws {
        let cleanedEntryId = clean(entryId)
        let cleanedUserId = clean(userId)

        guard cleanedEntryId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidEntryId
        }

        guard cleanedUserId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidUserId
        }

        try await FirestorePaths
            .entryReaction(
                entryId: cleanedEntryId,
                userId: cleanedUserId
            )
            .delete()
    }

    private func fetchReaction(
        entryId: String,
        userId: String
    ) async throws -> CircleReaction? {
        let cleanedEntryId = clean(entryId)
        let cleanedUserId = clean(userId)

        guard cleanedEntryId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidEntryId
        }

        guard cleanedUserId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidUserId
        }

        let document = try await FirestorePaths
            .entryReaction(
                entryId: cleanedEntryId,
                userId: cleanedUserId
            )
            .getDocument()

        guard document.exists else {
            return nil
        }

        let dto = try document.data(as: FirestoreCircleReactionDTO.self)

        return dto.domain(
            id: document.documentID
        )
    }

    // MARK: - Comments

    func fetchComments(
        entryId: String,
        circleId: String,
        limit: Int = 50
    ) async throws -> [CircleComment] {
        let cleanedEntryId = clean(entryId)
        let cleanedCircleId = clean(circleId)

        guard cleanedEntryId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidEntryId
        }

        guard cleanedCircleId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidCircleId
        }

        let snapshot = try await FirestorePaths
            .entryComments(cleanedEntryId)
            .whereField("circleId", isEqualTo: cleanedCircleId)
            .order(by: "createdAt", descending: false)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            let dto = try document.data(as: FirestoreCircleCommentDTO.self)

            let comment = dto.domain(
                id: document.documentID
            )

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
        let cleanedEntryId = clean(entryId)
        let cleanedCircleId = clean(circleId)
        let cleanedUserId = clean(userId)
        let cleanedDisplayName = clean(displayName)
        let cleanedText = clean(text)

        guard cleanedEntryId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidEntryId
        }

        guard cleanedCircleId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidCircleId
        }

        guard cleanedUserId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidUserId
        }

        guard cleanedText.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.emptyComment
        }

        guard cleanedText.count <= maxCommentLength else {
            throw CircleSocialRemoteDataSourceError.commentTooLong
        }

        let now = Date()
        let commentId = UUID().uuidString

        let comment = CircleComment(
            id: commentId,
            entryId: cleanedEntryId,
            circleId: cleanedCircleId,
            userId: cleanedUserId,
            displayName: cleanedDisplayName.isEmpty ? "Circle member" : cleanedDisplayName,
            text: cleanedText,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil
        )

        let dto = FirestoreCircleCommentDTO(
            comment: comment
        )

        try FirestorePaths
            .entryComment(
                entryId: cleanedEntryId,
                commentId: commentId
            )
            .setData(from: dto, merge: true)

        return comment
    }

    func softDeleteComment(
        entryId: String,
        commentId: String,
        userId: String
    ) async throws {
        let cleanedEntryId = clean(entryId)
        let cleanedCommentId = clean(commentId)
        let cleanedUserId = clean(userId)

        guard cleanedEntryId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidEntryId
        }

        guard cleanedCommentId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidCommentId
        }

        guard cleanedUserId.isEmpty == false else {
            throw CircleSocialRemoteDataSourceError.invalidUserId
        }

        try await FirestorePaths
            .entryComment(
                entryId: cleanedEntryId,
                commentId: cleanedCommentId
            )
            .updateData([
                "deletedAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ])
    }

    // MARK: - Helpers

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
