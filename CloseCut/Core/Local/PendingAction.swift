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

    var typeRaw: String
    var entityId: String
    var userId: String

    var payloadData: Data

    var createdAt: Date
    var lastAttemptAt: Date?
    var attemptCount: Int

    var statusRaw: String
    var dedupeKey: String?

    init(
        id: String = UUID().uuidString,
        type: PendingActionType,
        entityId: String,
        userId: String,
        payloadData: Data,
        createdAt: Date = Date(),
        lastAttemptAt: Date? = nil,
        attemptCount: Int = 0,
        status: SyncStatus = .pending,
        dedupeKey: String? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.entityId = entityId
        self.userId = userId
        self.payloadData = payloadData
        self.createdAt = createdAt
        self.lastAttemptAt = lastAttemptAt
        self.attemptCount = attemptCount
        self.statusRaw = status.rawValue
        self.dedupeKey = dedupeKey
    }
}

extension PendingAction {
    var type: PendingActionType {
        PendingActionType(rawValue: typeRaw) ?? .updateEntry
    }

    var status: SyncStatus {
        SyncStatus(rawValue: statusRaw) ?? .pending
    }

    func markFailed() {
        statusRaw = SyncStatus.failed.rawValue
        lastAttemptAt = Date()
        attemptCount += 1
    }

    func markAttempted() {
        lastAttemptAt = Date()
        attemptCount += 1
    }
}
