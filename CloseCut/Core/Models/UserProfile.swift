//
//  UserProfile.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String

    var displayName: String
    var email: String?
    var photoURL: String?

    var circleId: String?
    var defaultVisibility: EntryVisibility

    var createdAt: Date
    var updatedAt: Date

    var syncStatus: SyncStatus
}
