//
//  WatchPlanResponse.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation

struct WatchPlanResponse: Identifiable, Codable, Equatable {
    let id: String

    var planId: String
    var circleId: String

    var userId: String
    var userDisplayName: String

    var responseType: WatchPlanResponseType
    var note: String?

    var suggestedStartAt: Date?
    var suggestedDateText: String?

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatus: SyncStatus

    var isDeleted: Bool {
        deletedAt != nil
    }

    var isActive: Bool {
        isDeleted == false
    }

    var displayUserName: String {
        let cleaned = userDisplayName.trimmed
        return cleaned.isEmpty ? "Someone" : cleaned
    }

    var displayNote: String? {
        note?.trimmed.nilIfBlank
    }

    var suggestedTimeText: String? {
        if let suggestedStartAt {
            return suggestedStartAt.formatted(date: .abbreviated, time: .shortened)
        }

        return suggestedDateText?.trimmed.nilIfBlank
    }

    mutating func normalizeForLocalUse() {
        planId = planId.trimmed
        circleId = circleId.trimmed
        userId = userId.trimmed
        userDisplayName = userDisplayName.trimmed
        note = note?.trimmed.nilIfBlank
        suggestedDateText = suggestedDateText?.trimmed.nilIfBlank
        updatedAt = Date()
    }
}

enum WatchPlanResponseType: String, Codable, CaseIterable, Identifiable {
    case accepted
    case declined
    case maybe
    case suggestAnotherTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .accepted:
            return "Yes"
        case .declined:
            return "No"
        case .maybe:
            return "Maybe"
        case .suggestAnotherTime:
            return "Suggest another time"
        }
    }

    var systemImage: String {
        switch self {
        case .accepted:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        case .maybe:
            return "questionmark.circle.fill"
        case .suggestAnotherTime:
            return "calendar.badge.clock"
        }
    }

    var contributesToConfirmation: Bool {
        switch self {
        case .accepted:
            return true
        case .declined, .maybe, .suggestAnotherTime:
            return false
        }
    }
}
