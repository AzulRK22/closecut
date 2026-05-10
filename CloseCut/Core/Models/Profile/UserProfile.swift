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
    // Keep this for backward compatibility while the app fully moves to multi-circle.
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

        let resolvedCircleIds = Self.cleanCircleIds(
            circleIds + [circleId].compactMap { $0 }
        )

        self.circleId = circleId ?? resolvedCircleIds.first
        self.circleIds = resolvedCircleIds
        self.defaultVisibility = defaultVisibility
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }

    // MARK: - Circle Helpers

    var activeCircleIds: [String] {
        Self.cleanCircleIds(circleIds + [circleId].compactMap { $0 })
    }

    var primaryCircleId: String? {
        circleId ?? activeCircleIds.first
    }

    var hasCircles: Bool {
        activeCircleIds.isEmpty == false
    }

    func belongsToCircle(_ circleId: String) -> Bool {
        activeCircleIds.contains(
            circleId.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    mutating func addCircleId(_ circleId: String) {
        let cleanedCircleId = circleId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedCircleId.isEmpty == false else {
            return
        }

        circleIds = Self.cleanCircleIds(circleIds + [cleanedCircleId])

        if self.circleId == nil {
            self.circleId = cleanedCircleId
        }

        updatedAt = Date()
        syncStatus = .pending
    }

    mutating func removeCircleId(_ circleId: String) {
        let cleanedCircleId = circleId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedCircleId.isEmpty == false else {
            return
        }

        circleIds = Self.cleanCircleIds(
            circleIds.filter { $0 != cleanedCircleId }
        )

        if self.circleId == cleanedCircleId {
            self.circleId = circleIds.first
        }

        updatedAt = Date()
        syncStatus = .pending
    }

    // MARK: - Display Helpers

    var displayNameText: String {
        let cleanedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedDisplayName.isEmpty == false {
            return cleanedDisplayName
        }

        if let emailPrefix = email?.split(separator: "@").first {
            return String(emailPrefix)
        }

        return "CloseCut User"
    }

    // MARK: - Helpers

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
