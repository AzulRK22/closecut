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
        self.sharedCircleIds = Self.cleanIds(
            sharedCircleIds ?? entry.sharedCircleIds
        )
    }

    private static func cleanIds(_ ids: [String]) -> [String] {
        ids.cleanedUniqueIds
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
        self.entryId = entryId.trimmed
        self.ownerId = ownerId.trimmed

        let cleanedSharedCircleIds = sharedCircleIds.cleanedUniqueIds

        self.sharedCircleIds = cleanedSharedCircleIds
        self.visibility = cleanedSharedCircleIds.isEmpty ? .privateOnly : visibility
        self.updatedAt = updatedAt
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

struct ProfileIdentityPayload: Codable {
    let userId: String
    let displayName: String
    let avatarSymbol: String?
    let avatarColorRaw: String?
    let photoURL: String?
    let updatedAt: Date

    init(
        userId: String,
        displayName: String,
        avatarSymbol: String?,
        avatarColorRaw: String?,
        photoURL: String?,
        updatedAt: Date = Date()
    ) {
        self.userId = userId.trimmed
        self.displayName = displayName.trimmed
        self.avatarSymbol = avatarSymbol.trimmedOrNil
        self.avatarColorRaw = avatarColorRaw.trimmedOrNil
        self.photoURL = photoURL.trimmedOrNil
        self.updatedAt = updatedAt
    }
}

struct DefaultVisibilityPayload: Codable {
    let userId: String
    let defaultVisibility: EntryVisibility
    let updatedAt: Date

    init(
        userId: String,
        defaultVisibility: EntryVisibility,
        updatedAt: Date = Date()
    ) {
        self.userId = userId.trimmed
        self.defaultVisibility = defaultVisibility
        self.updatedAt = updatedAt
    }
}

// MARK: - Circle

struct JoinCirclePayload: Codable {
    let userId: String
    let inviteCode: String

    init(
        userId: String,
        inviteCode: String
    ) {
        self.userId = userId.trimmed
        self.inviteCode = inviteCode.normalizedInviteCode
    }
}
