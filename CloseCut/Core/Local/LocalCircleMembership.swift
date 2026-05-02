//
//  LocalCircleMembership.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation
import SwiftData

@Model
final class LocalCircleMembership {
    @Attribute(.unique) var id: String

    var circleId: String
    var userId: String

    var circleName: String
    var circleDescription: String?
    var ownerId: String
    var ownerDisplayName: String

    var roleRaw: String
    var statusRaw: String

    var joinedAt: Date
    var updatedAt: Date

    var syncStatusRaw: String

    init(
        id: String? = nil,
        circleId: String,
        userId: String,
        circleName: String,
        circleDescription: String? = nil,
        ownerId: String,
        ownerDisplayName: String,
        role: CircleMemberRole,
        status: CircleMemberStatus = .active,
        joinedAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .synced
    ) {
        self.id = id ?? "\(circleId)_\(userId)"
        self.circleId = circleId
        self.userId = userId
        self.circleName = circleName
        self.circleDescription = circleDescription
        self.ownerId = ownerId
        self.ownerDisplayName = ownerDisplayName
        self.roleRaw = role.rawValue
        self.statusRaw = status.rawValue
        self.joinedAt = joinedAt
        self.updatedAt = updatedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalCircleMembership {
    var domain: CircleMembership {
        CircleMembership(
            circleId: circleId,
            userId: userId,
            circleName: circleName,
            circleDescription: circleDescription,
            ownerId: ownerId,
            ownerDisplayName: ownerDisplayName,
            role: CircleMemberRole(rawValue: roleRaw) ?? .member,
            status: CircleMemberStatus(rawValue: statusRaw) ?? .active,
            joinedAt: joinedAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }

    func update(
        circle: CloseCircle,
        member: CircleMember,
        syncStatus: SyncStatus = .synced
    ) {
        circleId = circle.id
        userId = member.userId

        circleName = circle.name
        circleDescription = circle.description
        ownerId = circle.ownerId
        ownerDisplayName = circle.ownerDisplayName

        roleRaw = member.role.rawValue
        statusRaw = member.status.rawValue

        joinedAt = member.joinedAt
        updatedAt = Date()

        syncStatusRaw = syncStatus.rawValue
    }
}
