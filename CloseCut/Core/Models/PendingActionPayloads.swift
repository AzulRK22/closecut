//
//  PendingActionPayloads.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

struct EntryPayload: Codable {
    let entry: Entry
    let circleId: String?
}

struct VisibilityPayload: Codable {
    let entryId: String
    let ownerId: String
    let visibility: EntryVisibility
    let circleId: String?
    let updatedAt: Date
}

struct ReactionIntentPayload: Codable {
    let entryId: String
    let userId: String
    let reactionType: ReactionType?
    let updatedAt: Date
}

struct CommentPayload: Codable {
    let comment: Comment
}

struct ProfilePayload: Codable {
    let profile: UserProfile
}

struct JoinCirclePayload: Codable {
    let userId: String
    let inviteCode: String
}
