//
//  CircleMembership.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

struct CircleMembership: Identifiable, Codable, Equatable {
    var id: String {
        "\(circleId)_\(userId)"
    }

    let circleId: String
    let userId: String

    var circleName: String
    var circleDescription: String?
    var ownerId: String
    var ownerDisplayName: String

    var role: CircleMemberRole
    var status: CircleMemberStatus

    var joinedAt: Date
    var updatedAt: Date

    var syncStatus: SyncStatus

    var isOwner: Bool {
        role == .owner
    }

    var isMember: Bool {
        role == .member
    }

    var isActive: Bool {
        status == .active
    }

    var isRemoved: Bool {
        status == .removed
    }

    var canManageCircle: Bool {
        isOwner && isActive
    }

    var canLeaveCircle: Bool {
        isMember && isActive
    }

    var canViewCircleContent: Bool {
        isActive
    }

    var displayCircleName: String {
        let cleaned = circleName.trimmed
        return cleaned.isEmpty ? "Untitled Circle" : cleaned
    }

    var displayCircleDescription: String {
        let cleaned = circleDescription?.trimmed

        if let cleaned, cleaned.isEmpty == false {
            return cleaned
        }

        return "A private space for shared watch memories."
    }

    var displayOwnerName: String {
        let cleaned = ownerDisplayName.trimmed
        return cleaned.isEmpty ? "Circle owner" : cleaned
    }
}
