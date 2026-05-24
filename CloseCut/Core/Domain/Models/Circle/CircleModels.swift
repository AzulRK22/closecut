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

    var isActive: Bool {
        isDeleted == false
    }

    var displayName: String {
        let cleaned = name.trimmed
        return cleaned.isEmpty ? "Untitled Circle" : cleaned
    }

    var displayDescription: String {
        let cleaned = description?.trimmed

        if let cleaned, cleaned.isEmpty == false {
            return cleaned
        }

        return "A private space for shared watch memories."
    }

    var displayOwnerName: String {
        let cleaned = ownerDisplayName.trimmed
        return cleaned.isEmpty ? "Circle owner" : cleaned
    }

    var cleanedInviteCode: String {
        inviteCode.trimmed
    }

    var cleanedInviteCodeNormalized: String {
        let normalized = inviteCodeNormalized.trimmed

        if normalized.isEmpty == false {
            return normalized
        }

        return inviteCode.normalizedInviteCode
    }

    var activeMemberIds: [String] {
        Self.cleanIds(memberIds)
    }

    var memberCount: Int {
        activeMemberIds.count
    }

    var memberCountText: String {
        memberCount == 1 ? "1 member" : "\(memberCount) members"
    }

    var canBeJoinedByInviteCode: Bool {
        isActive && cleanedInviteCodeNormalized.isEmpty == false
    }

    func isOwned(
        by userId: String
    ) -> Bool {
        ownerId.trimmed == userId.trimmed
    }

    func containsMember(
        userId: String
    ) -> Bool {
        activeMemberIds.contains(userId.trimmed)
    }

    private static func cleanIds(
        _ ids: [String]
    ) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmed }
                    .filter { $0.isEmpty == false }
            )
        )
        .sorted()
    }
}

struct CircleMember: Identifiable, Codable, Equatable {
    var id: String {
        userId
    }

    let userId: String

    var displayName: String
    var email: String?

    var role: CircleMemberRole
    var status: CircleMemberStatus

    var joinedAt: Date
    var updatedAt: Date

    var isOwner: Bool {
        role == .owner
    }

    var isActive: Bool {
        status == .active
    }

    var displayNameText: String {
        let cleaned = displayName.trimmed
        return cleaned.isEmpty ? "Circle member" : cleaned
    }

    var emailText: String? {
        let cleaned = email?.trimmed
        return cleaned?.isEmpty == false ? cleaned : nil
    }

    var initials: String {
        let parts = displayNameText
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }

        return String(displayNameText.prefix(2)).uppercased()
    }
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

    var priority: Int {
        switch self {
        case .owner:
            return 0
        case .member:
            return 1
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

    var isVisibleInMemberList: Bool {
        switch self {
        case .active:
            return true
        case .removed:
            return false
        }
    }
}
