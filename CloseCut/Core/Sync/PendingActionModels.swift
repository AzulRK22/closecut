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

    case createWatchlistItem
    case updateWatchlistItem
    case deleteWatchlistItem

    case createWatchPlan
    case updateWatchPlan
    case deleteWatchPlan

    case createWatchPlanResponse
    case updateWatchPlanResponse
    case deleteWatchPlanResponse

    var isEntryAction: Bool {
        switch self {
        case .createEntry, .updateEntry, .deleteEntry, .updateVisibility:
            return true

        case .createWatchlistItem, .updateWatchlistItem, .deleteWatchlistItem,
             .createWatchPlan, .updateWatchPlan, .deleteWatchPlan,
             .createWatchPlanResponse, .updateWatchPlanResponse, .deleteWatchPlanResponse:
            return false
        }
    }

    var isWatchlistAction: Bool {
        switch self {
        case .createWatchlistItem, .updateWatchlistItem, .deleteWatchlistItem:
            return true

        case .createEntry, .updateEntry, .deleteEntry, .updateVisibility,
             .createWatchPlan, .updateWatchPlan, .deleteWatchPlan,
             .createWatchPlanResponse, .updateWatchPlanResponse, .deleteWatchPlanResponse:
            return false
        }
    }

    var isWatchPlanAction: Bool {
        switch self {
        case .createWatchPlan, .updateWatchPlan, .deleteWatchPlan:
            return true

        case .createEntry, .updateEntry, .deleteEntry, .updateVisibility,
             .createWatchlistItem, .updateWatchlistItem, .deleteWatchlistItem,
             .createWatchPlanResponse, .updateWatchPlanResponse, .deleteWatchPlanResponse:
            return false
        }
    }

    var isWatchPlanResponseAction: Bool {
        switch self {
        case .createWatchPlanResponse, .updateWatchPlanResponse, .deleteWatchPlanResponse:
            return true

        case .createEntry, .updateEntry, .deleteEntry, .updateVisibility,
             .createWatchlistItem, .updateWatchlistItem, .deleteWatchlistItem,
             .createWatchPlan, .updateWatchPlan, .deleteWatchPlan:
            return false
        }
    }

    var isWatchTogetherAction: Bool {
        isWatchPlanAction || isWatchPlanResponseAction
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

struct PendingWatchlistItemPayload: Codable, Equatable {
    let itemId: String
    let ownerId: String
    let title: String
    let status: String
    let updatedAt: Date
}

struct PendingWatchPlanPayload: Codable, Equatable {
    let planId: String
    let ownerId: String
    let circleId: String
    let title: String
    let status: String
    let updatedAt: Date
}

struct PendingWatchPlanResponsePayload: Codable, Equatable {
    let responseId: String
    let planId: String
    let circleId: String
    let userId: String
    let responseType: String
    let updatedAt: Date
}

enum PendingActionCleanupPolicy {
    static let completedActionRetentionDays: Int = 7
    static let maxRetryAttempts: Int = 5

    // If the app closes while an action is marked syncing,
    // this lets the queue recover it later.
    static let staleSyncingActionMinutes: Int = 5
}
