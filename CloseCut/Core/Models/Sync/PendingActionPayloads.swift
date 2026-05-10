//
//  PendingActionPayloads.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

// MARK: - Entry

struct EntryPayload: Codable {
    let entry: Entry
    let sharedCircleIds: [String]

    init(
        entry: Entry,
        sharedCircleIds: [String]? = nil
    ) {
        self.entry = entry
        self.sharedCircleIds = Self.cleanCircleIds(
            sharedCircleIds ?? entry.sharedCircleIds
        )
    }

    private static func cleanCircleIds(_ ids: [String]) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }
}

// MARK: - Visibility

struct VisibilityPayload: Codable {
    let entryId: String
    let ownerId: String
    let visibility: EntryVisibility
    let sharedCircleIds: [String]
    let updatedAt: Date

    init(
        entryId: String,
        ownerId: String,
        visibility: EntryVisibility,
        sharedCircleIds: [String] = [],
        updatedAt: Date
    ) {
        self.entryId = entryId
        self.ownerId = ownerId

        let cleanedSharedCircleIds = Self.cleanCircleIds(sharedCircleIds)

        self.sharedCircleIds = cleanedSharedCircleIds
        self.visibility = cleanedSharedCircleIds.isEmpty ? .privateOnly : visibility
        self.updatedAt = updatedAt
    }

    private static func cleanCircleIds(_ ids: [String]) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }
}

// MARK: - Social

struct ReactionIntentPayload: Codable {
    let entryId: String
    let userId: String
    let reactionType: ReactionType?
    let updatedAt: Date
}

struct CommentPayload: Codable {
    let comment: CircleComment
}

// MARK: - Profile

struct ProfilePayload: Codable {
    let profile: UserProfile
}

// MARK: - Circle

struct JoinCirclePayload: Codable {
    let userId: String
    let inviteCode: String
}
