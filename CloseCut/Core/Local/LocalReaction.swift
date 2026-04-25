//
//  LocalReaction.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@Model
final class LocalReaction {
    @Attribute(.unique) var id: String

    var entryId: String
    var userId: String
    var typeRaw: String

    var createdAt: Date
    var updatedAt: Date

    var syncStatusRaw: String

    init(
        entryId: String,
        userId: String,
        type: ReactionType,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = "\(entryId)_\(userId)"
        self.entryId = entryId
        self.userId = userId
        self.typeRaw = type.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalReaction {
    var domain: Reaction {
        Reaction(
            entryId: entryId,
            userId: userId,
            type: ReactionType(rawValue: typeRaw) ?? .loved,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }

    func update(type: ReactionType, syncStatus: SyncStatus = .pending) {
        self.typeRaw = type.rawValue
        self.updatedAt = Date()
        self.syncStatusRaw = syncStatus.rawValue
    }
}
