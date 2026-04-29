//
//  PendingAction.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@Model
final class PendingAction {
    @Attribute(.unique) var id: String

    var userId: String
    var actionTypeRaw: String
    var statusRaw: String
    var payloadData: Data?
    var dedupeKey: String?

    var attempts: Int
    var lastErrorMessage: String?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        actionType: PendingActionType,
        status: PendingActionStatus = .pending,
        payloadData: Data? = nil,
        dedupeKey: String? = nil,
        attempts: Int = 0,
        lastErrorMessage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.actionTypeRaw = actionType.rawValue
        self.statusRaw = status.rawValue
        self.payloadData = payloadData
        self.dedupeKey = dedupeKey
        self.attempts = attempts
        self.lastErrorMessage = lastErrorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension PendingAction {
    var actionType: PendingActionType {
        PendingActionType(rawValue: actionTypeRaw) ?? PendingActionType.createEntry
    }

    var status: PendingActionStatus {
        PendingActionStatus(rawValue: statusRaw) ?? PendingActionStatus.pending
    }

    func markPending() {
        statusRaw = PendingActionStatus.pending.rawValue
        updatedAt = Date()
    }

    func markSyncing() {
        statusRaw = PendingActionStatus.syncing.rawValue
        updatedAt = Date()
    }

    func markFailed(_ message: String) {
        statusRaw = PendingActionStatus.failed.rawValue
        lastErrorMessage = message
        attempts += 1
        updatedAt = Date()
    }

    func markCompleted() {
        statusRaw = PendingActionStatus.completed.rawValue
        updatedAt = Date()
    }
}
