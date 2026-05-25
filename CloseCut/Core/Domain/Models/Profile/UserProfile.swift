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

    // Lightweight profile customization.
    // This keeps Settings useful before adding real photo upload/storage.
    var avatarSymbol: String?
    var avatarColorRaw: String?

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
        avatarSymbol: String? = nil,
        avatarColorRaw: String? = nil,
        circleId: String? = nil,
        circleIds: [String] = [],
        defaultVisibility: EntryVisibility = .privateOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .synced
    ) {
        self.id = id
        self.displayName = displayName.trimmed
        self.email = email.trimmedOrNil
        self.photoURL = photoURL.trimmedOrNil
        self.avatarSymbol = avatarSymbol.trimmedOrNil
        self.avatarColorRaw = avatarColorRaw.trimmedOrNil

        let resolvedCircleIds = Self.cleanCircleIds(
            circleIds + [circleId].compactMap { $0 }
        )

        self.circleId = circleId.trimmedOrNil ?? resolvedCircleIds.first
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
        circleId.trimmedOrNil ?? activeCircleIds.first
    }

    var hasCircles: Bool {
        activeCircleIds.isEmpty == false
    }

    var circleCount: Int {
        activeCircleIds.count
    }

    func belongsToCircle(_ circleId: String) -> Bool {
        activeCircleIds.contains(circleId.trimmed)
    }

    mutating func addCircleId(_ circleId: String) {
        let cleanedCircleId = circleId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            return
        }

        circleIds = Self.cleanCircleIds(circleIds + [cleanedCircleId])

        if self.circleId.trimmedOrNil == nil {
            self.circleId = cleanedCircleId
        }

        markPendingUpdate()
    }

    mutating func removeCircleId(_ circleId: String) {
        let cleanedCircleId = circleId.trimmed

        guard cleanedCircleId.isEmpty == false else {
            return
        }

        circleIds = Self.cleanCircleIds(
            circleIds.filter { $0.trimmed != cleanedCircleId }
        )

        if self.circleId?.trimmed == cleanedCircleId {
            self.circleId = circleIds.first
        }

        markPendingUpdate()
    }

    // MARK: - Profile Editing

    mutating func updateDisplayName(_ newDisplayName: String) {
        let cleanedDisplayName = newDisplayName.trimmed

        guard cleanedDisplayName.isEmpty == false else {
            return
        }

        guard cleanedDisplayName != displayName else {
            return
        }

        displayName = cleanedDisplayName
        markPendingUpdate()
    }

    mutating func updateAvatar(
        symbol: String?,
        colorRaw: String?
    ) {
        let cleanedSymbol = symbol.trimmedOrNil
        let cleanedColorRaw = colorRaw.trimmedOrNil

        guard cleanedSymbol != avatarSymbol || cleanedColorRaw != avatarColorRaw else {
            return
        }

        avatarSymbol = cleanedSymbol
        avatarColorRaw = cleanedColorRaw
        markPendingUpdate()
    }

    mutating func updatePhotoURL(_ newPhotoURL: String?) {
        let cleanedPhotoURL = newPhotoURL.trimmedOrNil

        guard cleanedPhotoURL != photoURL else {
            return
        }

        photoURL = cleanedPhotoURL
        markPendingUpdate()
    }

    mutating func updateDefaultVisibility(_ visibility: EntryVisibility) {
        guard visibility != defaultVisibility else {
            return
        }

        defaultVisibility = visibility
        markPendingUpdate()
    }

    mutating func markSynced() {
        syncStatus = .synced
        updatedAt = Date()
    }

    mutating func markFailed() {
        syncStatus = .failed
        updatedAt = Date()
    }

    private mutating func markPendingUpdate() {
        updatedAt = Date()
        syncStatus = .pending
    }

    // MARK: - Display Helpers

    var displayNameText: String {
        let cleanedDisplayName = displayName.trimmed

        if cleanedDisplayName.isEmpty == false {
            return cleanedDisplayName
        }

        if let emailPrefix = email?.split(separator: "@").first {
            let cleanedPrefix = String(emailPrefix).trimmed

            if cleanedPrefix.isEmpty == false {
                return cleanedPrefix
            }
        }

        return "CloseCut User"
    }

    var emailText: String {
        if let cleanedEmail = email.trimmedOrNil {
            return cleanedEmail
        }

        return "No email available"
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

    var avatarSymbolText: String {
        avatarSymbol.trimmedOrNil ?? "film.fill"
    }

    var avatarColorKey: String {
        avatarColorRaw.trimmedOrNil ?? "accent"
    }

    var hasCustomAvatar: Bool {
        avatarSymbol.trimmedOrNil != nil || avatarColorRaw.trimmedOrNil != nil
    }

    var profileSummaryText: String {
        if hasCircles {
            return circleCount == 1
                ? "1 private Circle"
                : "\(circleCount) private Circles"
        }

        return "Private taste journal"
    }

    // MARK: - Helpers

    private static func cleanCircleIds(_ ids: [String]) -> [String] {
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
