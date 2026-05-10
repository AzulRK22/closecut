//
//  LocalUserProfile.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@Model
final class LocalUserProfile {
    @Attribute(.unique) var id: String

    var displayName: String
    var email: String?
    var photoURL: String?

    // Legacy single-circle field kept for migration/backward compatibility.
    var circleId: String?

    // Multi-circle field.
    // Important: optional for SwiftData lightweight migration.
    var circleIds: [String]?

    var defaultVisibilityRaw: String

    var createdAt: Date
    var updatedAt: Date

    var syncStatusRaw: String

    init(
        id: String,
        displayName: String,
        email: String? = nil,
        photoURL: String? = nil,
        circleId: String? = nil,
        circleIds: [String] = [],
        defaultVisibility: EntryVisibility = .privateOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .synced
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.circleId = circleId
        self.circleIds = Self.cleanCircleIds(
            circleIds + [circleId].compactMap { $0 }
        )
        self.defaultVisibilityRaw = defaultVisibility.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalUserProfile {
    private var resolvedCircleIds: [String] {
        Self.cleanCircleIds(
            (circleIds ?? []) + [circleId].compactMap { $0 }
        )
    }

    var domain: UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            email: email,
            photoURL: photoURL,
            circleId: circleId ?? resolvedCircleIds.first,
            circleIds: resolvedCircleIds,
            defaultVisibility: EntryVisibility(rawValue: defaultVisibilityRaw) ?? .privateOnly,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }

    func update(from profile: UserProfile) {
        let cleanedCircleIds = Self.cleanCircleIds(
            profile.circleIds + [profile.circleId].compactMap { $0 }
        )

        displayName = profile.displayName
        email = profile.email
        photoURL = profile.photoURL
        circleId = profile.circleId ?? cleanedCircleIds.first
        circleIds = cleanedCircleIds
        defaultVisibilityRaw = profile.defaultVisibility.rawValue
        createdAt = profile.createdAt
        updatedAt = profile.updatedAt
        syncStatusRaw = profile.syncStatus.rawValue
    }

    func addCircleId(_ circleId: String) {
        let cleanedCircleIds = Self.cleanCircleIds(
            resolvedCircleIds + [circleId]
        )

        circleIds = cleanedCircleIds
        self.circleId = self.circleId ?? cleanedCircleIds.first
        updatedAt = Date()
        syncStatusRaw = SyncStatus.pending.rawValue
    }

    func removeCircleId(_ circleId: String) {
        let cleanedCircleIds = Self.cleanCircleIds(
            resolvedCircleIds.filter { $0 != circleId }
        )

        circleIds = cleanedCircleIds

        if self.circleId == circleId {
            self.circleId = cleanedCircleIds.first
        }

        updatedAt = Date()
        syncStatusRaw = SyncStatus.pending.rawValue
    }

    private static func cleanCircleIds(_ ids: [String]) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }
}
