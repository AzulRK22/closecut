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
    init(profile: UserProfile) {
        let resolvedCircleIds = FirestoreUserProfileDTO.cleanCircleIds(
            profile.circleIds + [profile.circleId].compactMap { $0 }
        )

        self.displayName = profile.displayName
        self.email = profile.email
        self.photoURL = profile.photoURL
        self.circleId = profile.circleId ?? resolvedCircleIds.first
        self.circleIds = resolvedCircleIds

        self.defaultVisibility = profile.defaultVisibility.rawValue
        self.createdAt = Timestamp(date: profile.createdAt)
        self.updatedAt = Timestamp(date: profile.updatedAt)
    }

    func domain(id: String, syncStatus: SyncStatus = .synced) -> UserProfile {
        let resolvedCircleIds = FirestoreUserProfileDTO.cleanCircleIds(
            (circleIds ?? []) + [circleId].compactMap { $0 }
        )

        return UserProfile(
            id: id,
            displayName: displayName,
            email: email,
            photoURL: photoURL,
            circleId: circleId ?? resolvedCircleIds.first,
            circleIds: resolvedCircleIds,
            defaultVisibility: EntryVisibility(rawValue: defaultVisibility) ?? .privateOnly,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            syncStatus: syncStatus
        )
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
