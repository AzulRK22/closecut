//
//  LocalComment.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@Model
final class LocalComment {
    @Attribute(.unique) var id: String

    var entryId: String
    var userId: String

    var text: String

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatusRaw: String

    init(
        id: String = UUID().uuidString,
        entryId: String,
        userId: String,
        text: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.entryId = entryId
        self.userId = userId
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalComment {
    var domain: Comment {
        Comment(
            id: id,
            entryId: entryId,
            userId: userId,
            text: text,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }
}
