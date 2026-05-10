//
//  UserProfileRepository.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseFirestore
import SwiftData

@MainActor
final class UserProfileRepository {
    private let db = Firestore.firestore()

    func ensureUserProfile(
        for authUser: AuthUser,
        modelContext: ModelContext
    ) async throws -> UserProfile {
        if let remoteProfile = try await fetchRemoteProfile(userId: authUser.id) {
            let profile = remoteProfile
            try upsertLocalProfile(profile, modelContext: modelContext)
            return profile
        } else {
            let newProfile = UserProfile(
                id: authUser.id,
                displayName: defaultDisplayName(from: authUser),
                email: authUser.email,
                photoURL: authUser.photoURL?.absoluteString,
                circleId: nil,
                circleIds: [],
                defaultVisibility: .privateOnly,
                createdAt: Date(),
                updatedAt: Date(),
                syncStatus: .synced
            )

            try await createRemoteProfile(newProfile)
            try upsertLocalProfile(newProfile, modelContext: modelContext)

            return newProfile
        }
    }

    func fetchRemoteProfile(userId: String) async throws -> UserProfile? {
        let snapshot = try await FirestorePaths
            .user(userId)
            .getDocument()

        guard snapshot.exists else {
            return nil
        }

        let dto = try snapshot.data(as: FirestoreUserProfileDTO.self)
        return dto.domain(id: userId, syncStatus: .synced)
    }

    func createRemoteProfile(_ profile: UserProfile) async throws {
        let dto = FirestoreUserProfileDTO(profile: profile)

        try FirestorePaths
            .user(profile.id)
            .setData(from: dto, merge: true)
    }

    func updateRemoteProfile(_ profile: UserProfile) async throws {
        let dto = FirestoreUserProfileDTO(profile: profile)

        try FirestorePaths
            .user(profile.id)
            .setData(from: dto, merge: true)
    }

    func fetchLocalProfile(
        userId: String,
        modelContext: ModelContext
    ) throws -> LocalUserProfile? {
        let descriptor = FetchDescriptor<LocalUserProfile>(
            predicate: #Predicate { profile in
                profile.id == userId
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    func upsertLocalProfile(
        _ profile: UserProfile,
        modelContext: ModelContext
    ) throws {
        if let existing = try fetchLocalProfile(
            userId: profile.id,
            modelContext: modelContext
        ) {
            existing.update(from: profile)
        } else {
            let localProfile = LocalUserProfile(
                id: profile.id,
                displayName: profile.displayName,
                email: profile.email,
                photoURL: profile.photoURL,
                circleId: profile.circleId,
                circleIds: profile.circleIds,
                defaultVisibility: profile.defaultVisibility,
                createdAt: profile.createdAt,
                updatedAt: profile.updatedAt,
                syncStatus: profile.syncStatus
            )

            modelContext.insert(localProfile)
        }

        try modelContext.save()
    }

    // MARK: - Circle Linking

    func updateLocalCircleId(
        userId: String,
        circleId: String?,
        fallbackProfile: UserProfile? = nil,
        modelContext: ModelContext
    ) throws -> UserProfile {
        if let localProfile = try fetchLocalProfile(
            userId: userId,
            modelContext: modelContext
        ) {
            localProfile.circleId = circleId
            localProfile.circleIds = cleanCircleIds(
                (localProfile.circleIds ?? []) + [circleId].compactMap { $0 }
            )
            localProfile.updatedAt = Date()
            localProfile.syncStatusRaw = SyncStatus.pending.rawValue

            try modelContext.save()

            return localProfile.domain
        }

        guard let fallbackProfile else {
            throw UserProfileRepositoryError.profileNotFound
        }

        var newProfile = fallbackProfile
        newProfile.circleId = circleId
        newProfile.circleIds = cleanCircleIds(
            newProfile.circleIds + [circleId].compactMap { $0 }
        )
        newProfile.updatedAt = Date()
        newProfile.syncStatus = .pending

        try upsertLocalProfile(
            newProfile,
            modelContext: modelContext
        )

        return newProfile
    }

    func addLocalCircleId(
        userId: String,
        circleId: String,
        fallbackProfile: UserProfile? = nil,
        modelContext: ModelContext
    ) throws -> UserProfile {
        if let localProfile = try fetchLocalProfile(
            userId: userId,
            modelContext: modelContext
        ) {
            localProfile.addCircleId(circleId)
            try modelContext.save()
            return localProfile.domain
        }

        guard let fallbackProfile else {
            throw UserProfileRepositoryError.profileNotFound
        }

        var newProfile = fallbackProfile
        newProfile.circleId = newProfile.circleId ?? circleId
        newProfile.circleIds = cleanCircleIds(newProfile.circleIds + [circleId])
        newProfile.updatedAt = Date()
        newProfile.syncStatus = .pending

        try upsertLocalProfile(
            newProfile,
            modelContext: modelContext
        )

        return newProfile
    }

    func removeLocalCircleId(
        userId: String,
        circleId: String,
        fallbackProfile: UserProfile? = nil,
        modelContext: ModelContext
    ) throws -> UserProfile {
        if let localProfile = try fetchLocalProfile(
            userId: userId,
            modelContext: modelContext
        ) {
            localProfile.removeCircleId(circleId)
            try modelContext.save()
            return localProfile.domain
        }

        guard let fallbackProfile else {
            throw UserProfileRepositoryError.profileNotFound
        }

        var newProfile = fallbackProfile
        newProfile.circleIds = cleanCircleIds(newProfile.circleIds.filter { $0 != circleId })

        if newProfile.circleId == circleId {
            newProfile.circleId = newProfile.circleIds.first
        }

        newProfile.updatedAt = Date()
        newProfile.syncStatus = .pending

        try upsertLocalProfile(
            newProfile,
            modelContext: modelContext
        )

        return newProfile
    }

    func updateRemoteCircleId(
        userId: String,
        circleId: String?
    ) async throws {
        var circleIds: [String] = []

        if let remoteProfile = try await fetchRemoteProfile(userId: userId) {
            circleIds = cleanCircleIds(
                remoteProfile.circleIds + [circleId].compactMap { $0 }
            )
        } else if let circleId {
            circleIds = [circleId]
        }

        try await FirestorePaths
            .user(userId)
            .setData(
                [
                    "circleId": circleId as Any,
                    "circleIds": circleIds,
                    "updatedAt": Timestamp(date: Date())
                ],
                merge: true
            )
    }

    func addRemoteCircleId(
        userId: String,
        circleId: String
    ) async throws {
        let remoteProfile = try await fetchRemoteProfile(userId: userId)

        let existingCircleIds = remoteProfile?.activeCircleIds ?? []
        let resolvedCircleId = remoteProfile?.circleId ?? circleId

        let updatedCircleIds = cleanCircleIds(existingCircleIds + [circleId])

        try await FirestorePaths
            .user(userId)
            .setData(
                [
                    "circleId": resolvedCircleId,
                    "circleIds": updatedCircleIds,
                    "updatedAt": Timestamp(date: Date())
                ],
                merge: true
            )
    }

    func removeRemoteCircleId(
        userId: String,
        circleId: String
    ) async throws {
        let remoteProfile = try await fetchRemoteProfile(userId: userId)

        let existingCircleIds = remoteProfile?.activeCircleIds ?? []
        let updatedCircleIds = cleanCircleIds(
            existingCircleIds.filter { $0 != circleId }
        )

        let resolvedCircleId = remoteProfile?.circleId == circleId
            ? updatedCircleIds.first
            : remoteProfile?.circleId

        var payload: [String: Any] = [
            "circleIds": updatedCircleIds,
            "updatedAt": Timestamp(date: Date())
        ]

        if let resolvedCircleId {
            payload["circleId"] = resolvedCircleId
        } else {
            payload["circleId"] = FieldValue.delete()
        }

        try await FirestorePaths
            .user(userId)
            .setData(payload, merge: true)
    }

    func markProfileSynced(
        userId: String,
        modelContext: ModelContext
    ) throws {
        guard let localProfile = try fetchLocalProfile(
            userId: userId,
            modelContext: modelContext
        ) else {
            throw UserProfileRepositoryError.profileNotFound
        }

        localProfile.syncStatusRaw = SyncStatus.synced.rawValue
        try modelContext.save()
    }

    private func defaultDisplayName(from authUser: AuthUser) -> String {
        if let displayName = authUser.displayName,
           !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return displayName
        }

        if let email = authUser.email,
           let firstPart = email.split(separator: "@").first {
            return String(firstPart)
        }

        return "CloseCut User"
    }

    private func cleanCircleIds(_ ids: [String]) -> [String] {
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

enum UserProfileRepositoryError: LocalizedError {
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "User profile was not found."
        }
    }
}
