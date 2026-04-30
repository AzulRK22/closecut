//
//  PendingActionModels.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

enum PendingActionType: String, Codable, CaseIterable {
    case createEntry
    case updateEntry
    case deleteEntry
    case updateVisibility
    case updateProfile
    case joinCircle
    case setReaction
    case removeReaction
    case createComment
}

enum PendingActionStatus: String, Codable, CaseIterable {
    case pending
    case syncing
    case failed
    case completed
}

struct PendingEntryPayload: Codable, Equatable {
    let entryId: String
    let ownerId: String
    let title: String
    let sourceType: String
    let updatedAt: Date
}
enum PendingActionCleanupPolicy {
    static let completedActionRetentionDays: Int = 7
}
