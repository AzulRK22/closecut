//
//  UserProfile.swift
//  CloseCut
//

import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String

    var displayName: String
    var email: String?
    var photoURL: String?

    // Legacy single-circle field.
    var circleId: String?

    // Multi-circle field.
    var circleIds: [String]

    var defaultVisibility: EntryVisibility

    var createdAt: Date
    var updatedAt: Date

    var syncStatus: SyncStatus

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

        let resolvedCircleIds = Self.cleanCircleIds(
            circleIds + [circleId].compactMap { $0 }
        )

        self.circleIds = resolvedCircleIds
        self.defaultVisibility = defaultVisibility
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }

    var activeCircleIds: [String] {
        Self.cleanCircleIds(circleIds + [circleId].compactMap { $0 })
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
