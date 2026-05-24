//
//  CircleModels.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

struct CloseCircle: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var description: String?
    var ownerId: String
    var ownerDisplayName: String
    var inviteCode: String
    var inviteCodeNormalized: String
    var memberIds: [String]
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var isDeleted: Bool {
        deletedAt != nil
    }
}

struct CircleMember: Identifiable, Codable, Equatable {
    var id: String { userId }

    let userId: String
    var displayName: String
    var email: String?
    var role: CircleMemberRole
    var status: CircleMemberStatus
    var joinedAt: Date
    var updatedAt: Date
}

enum CircleMemberRole: String, Codable, CaseIterable {
    case owner
    case member

    var displayName: String {
        switch self {
        case .owner:
            return "Owner"
        case .member:
            return "Member"
        }
    }
}

enum CircleMemberStatus: String, Codable, CaseIterable {
    case active
    case removed

    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .removed:
            return "Removed"
        }
    }
}
