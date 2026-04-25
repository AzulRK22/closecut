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

    var circleId: String?
    var defaultVisibility: String

    var createdAt: Timestamp
    var updatedAt: Timestamp
}

extension FirestoreUserProfileDTO {
    init(profile: UserProfile) {
        self.displayName = profile.displayName
        self.email = profile.email
        self.photoURL = profile.photoURL
        self.circleId = profile.circleId
        self.defaultVisibility = profile.defaultVisibility.rawValue
        self.createdAt = Timestamp(date: profile.createdAt)
        self.updatedAt = Timestamp(date: profile.updatedAt)
    }

    func domain(id: String, syncStatus: SyncStatus = .synced) -> UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            email: email,
            photoURL: photoURL,
            circleId: circleId,
            defaultVisibility: EntryVisibility(rawValue: defaultVisibility) ?? .privateOnly,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            syncStatus: syncStatus
        )
    }
}
