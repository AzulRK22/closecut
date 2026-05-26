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

    var isEntryAction: Bool {
        switch self {
        case .createEntry, .updateEntry, .deleteEntry, .updateVisibility:
            return true
        }
    }
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
    static let maxRetryAttempts: Int = 5

    // If the app closes while an action is marked syncing,
    // this lets the queue recover it later.
    static let staleSyncingActionMinutes: Int = 5
}
