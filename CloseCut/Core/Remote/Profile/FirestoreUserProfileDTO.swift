//
//  FirestoreUserProfileDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreUserProfileDTO: Codable {
    var displayName: String
    var email: String?
    var photoURL: String?

    // Legacy single-circle field.
    var circleId: String?

    // Multi-circle field.
    var circleIds: [String]?

    var defaultVisibility: String

    var createdAt: Timestamp
    var updatedAt: Timestamp
}

extension FirestoreUserProfileDTO {
    init(
        profile: UserProfile
    ) {
        let resolvedCircleIds = (
            profile.circleIds + [profile.circleId].compactMap { $0 }
        ).cleanedUniqueIds

        self.displayName = profile.displayNameText
        self.email = profile.email.trimmedOrNil
        self.photoURL = profile.photoURL.trimmedOrNil

        // Legacy compatibility.
        self.circleId = profile.circleId.trimmedOrNil ?? resolvedCircleIds.first
        self.circleIds = resolvedCircleIds

        self.defaultVisibility = profile.defaultVisibility.rawValue
        self.createdAt = Timestamp(date: profile.createdAt)
        self.updatedAt = Timestamp(date: profile.updatedAt)
    }

    func domain(
        id: String,
        syncStatus: SyncStatus = .synced
    ) -> UserProfile {
        let resolvedCircleIds = (
            (circleIds ?? []) + [circleId].compactMap { $0 }
        ).cleanedUniqueIds

        return UserProfile(
            id: id,
            displayName: displayName.trimmed.isEmpty ? "CloseCut User" : displayName.trimmed,
            email: email.trimmedOrNil,
            photoURL: photoURL.trimmedOrNil,
            circleId: circleId.trimmedOrNil ?? resolvedCircleIds.first,
            circleIds: resolvedCircleIds,
            defaultVisibility: EntryVisibility(rawValue: defaultVisibility) ?? .privateOnly,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            syncStatus: syncStatus
        )
    }
}
