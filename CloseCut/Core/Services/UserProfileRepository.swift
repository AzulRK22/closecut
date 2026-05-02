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
            existing.displayName = profile.displayName
            existing.email = profile.email
            existing.photoURL = profile.photoURL
            existing.circleId = profile.circleId
            existing.defaultVisibilityRaw = profile.defaultVisibility.rawValue
            existing.createdAt = profile.createdAt
            existing.updatedAt = profile.updatedAt
            existing.syncStatusRaw = profile.syncStatus.rawValue
        } else {
            let localProfile = LocalUserProfile(
                id: profile.id,
                displayName: profile.displayName,
                email: profile.email,
                photoURL: profile.photoURL,
                circleId: profile.circleId,
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
        try await FirestorePaths
            .user(userId)
            .setData(
                [
                    "circleId": circleId as Any,
                    "updatedAt": Timestamp(date: Date())
                ],
                merge: true
            )
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
