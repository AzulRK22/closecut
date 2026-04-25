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

    var circleId: String?
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
        self.defaultVisibilityRaw = defaultVisibility.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalUserProfile {
    var domain: UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            email: email,
            photoURL: photoURL,
            circleId: circleId,
            defaultVisibility: EntryVisibility(rawValue: defaultVisibilityRaw) ?? .privateOnly,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }
}
