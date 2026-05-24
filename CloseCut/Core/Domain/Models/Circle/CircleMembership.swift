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

    var isActive: Bool {
        status == .active
    }
}
