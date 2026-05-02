//
//  LocalCircle.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@Model
final class LocalCircle {
    @Attribute(.unique) var id: String

    var name: String
    var ownerId: String
    var inviteCode: String
    var inviteCodeNormalized: String
    var memberIds: [String]

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatusRaw: String

    init(
        id: String = UUID().uuidString,
        name: String,
        ownerId: String,
        inviteCode: String,
        inviteCodeNormalized: String? = nil,
        memberIds: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.name = name
        self.ownerId = ownerId
        self.inviteCode = inviteCode
        self.inviteCodeNormalized = inviteCodeNormalized ?? inviteCode.normalizedInviteCode
        self.memberIds = memberIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalCircle {
    var domain: CloseCircle {
        CloseCircle(
            id: id,
            name: name,
            ownerId: ownerId,
            inviteCode: inviteCode,
            inviteCodeNormalized: inviteCodeNormalized,
            memberIds: memberIds,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    func update(from circle: CloseCircle, syncStatus: SyncStatus = .synced) {
        name = circle.name
        ownerId = circle.ownerId
        inviteCode = circle.inviteCode
        inviteCodeNormalized = circle.inviteCodeNormalized
        memberIds = circle.memberIds
        createdAt = circle.createdAt
        updatedAt = circle.updatedAt
        deletedAt = circle.deletedAt
        syncStatusRaw = syncStatus.rawValue
    }
}
