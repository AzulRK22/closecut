//
//  CircleService.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation
import SwiftData

@MainActor
final class CircleService {
    private let circleRepository = CircleRepository()
    private let circleRemoteDataSource = CircleRemoteDataSource()
    private let userProfileRepository = UserProfileRepository()

    // MARK: - Create Circle

    func createCircle(
        user: AuthUser,
        profile: UserProfile,
        circleName: String,
        circleDescription: String? = nil,
        modelContext: ModelContext
    ) async throws -> CloseCircle {
        let cleanedName = circleName.trimmingCharacters(in: .whitespacesAndNewlines)

        let resolvedName = cleanedName.isEmpty
            ? "\(profile.displayName)'s Circle"
            : cleanedName

        let inviteCode = try await generateUniqueInviteCode(
            circleName: resolvedName,
            ownerDisplayName: profile.displayName
        )

        let circle = try circleRepository.createLocalCircle(
            ownerId: user.id,
            ownerDisplayName: profile.displayName,
            circleName: resolvedName,
            circleDescription: circleDescription,
            inviteCode: inviteCode,
            modelContext: modelContext
        )

        let ownerMember = CircleMember(
            userId: user.id,
            displayName: profile.displayName,
            email: profile.email ?? user.email,
            role: .owner,
            status: .active,
            joinedAt: Date(),
            updatedAt: Date()
        )

        try await circleRemoteDataSource.createCircle(
            closeCircle: circle,
            ownerMember: ownerMember
        )

        try? await circleRemoteDataSource.createActivity(
            circleId: circle.id,
            type: .circleCreated,
            actorId: user.id,
            actorDisplayName: profile.displayName,
            message: "\(profile.displayName) created this Circle."
        )

        _ = try circleRepository.upsertLocalMembership(
            circle: circle,
            member: ownerMember,
            modelContext: modelContext
        )

        try await userProfileRepository.addRemoteCircleId(
            userId: user.id,
            circleId: circle.id
        )

        _ = try userProfileRepository.addLocalCircleId(
            userId: user.id,
            circleId: circle.id,
            fallbackProfile: profile,
            modelContext: modelContext
        )

        try circleRepository.markCircleSynced(
            circleId: circle.id,
            modelContext: modelContext
        )

        return circle
    }

    // MARK: - Preview Circle

    func previewCircle(
        inviteCode: String,
        currentUserId: String
    ) async throws -> CirclePreview {
        let normalizedCode = inviteCode.normalizedInviteCode

        guard normalizedCode.isEmpty == false else {
            throw CircleServiceError.invalidInviteCode
        }

        guard let circle = try await circleRemoteDataSource.fetchCircleByInviteCode(
            inviteCode: normalizedCode
        ) else {
            throw CircleServiceError.circleNotFound
        }

        if circle.deletedAt != nil {
            throw CircleServiceError.circleNotFound
        }

        let existingMembership = try await circleRemoteDataSource.fetchMember(
            circleId: circle.id,
            userId: currentUserId
        )

        return CirclePreview(
            circle: circle,
            currentUserMembership: existingMembership
        )
    }

    // MARK: - Join Circle

    func joinCircle(
        user: AuthUser,
        profile: UserProfile,
        inviteCode: String,
        modelContext: ModelContext
    ) async throws -> CloseCircle {
        let normalizedCode = inviteCode.normalizedInviteCode

        guard normalizedCode.isEmpty == false else {
            throw CircleServiceError.invalidInviteCode
        }

        guard let remoteCircle = try await circleRemoteDataSource.fetchCircleByInviteCode(
            inviteCode: normalizedCode
        ) else {
            throw CircleServiceError.circleNotFound
        }

        if remoteCircle.deletedAt != nil {
            throw CircleServiceError.circleNotFound
        }

        let member = CircleMember(
            userId: user.id,
            displayName: profile.displayName,
            email: profile.email ?? user.email,
            role: remoteCircle.ownerId == user.id ? .owner : .member,
            status: .active,
            joinedAt: Date(),
            updatedAt: Date()
        )

        try await circleRemoteDataSource.joinCircle(
            circle: remoteCircle,
            member: member
        )

        try? await circleRemoteDataSource.createActivity(
            circleId: remoteCircle.id,
            type: .memberJoined,
            actorId: user.id,
            actorDisplayName: profile.displayName,
            message: "\(profile.displayName) joined the Circle."
        )

        try await userProfileRepository.addRemoteCircleId(
            userId: user.id,
            circleId: remoteCircle.id
        )

        var updatedCircle = remoteCircle

        if updatedCircle.memberIds.contains(user.id) == false {
            updatedCircle.memberIds.append(user.id)
        }

        updatedCircle.updatedAt = Date()

        let localCircle = try circleRepository.upsertRemoteCircle(
            updatedCircle,
            modelContext: modelContext
        )

        _ = try circleRepository.upsertLocalMembership(
            circle: updatedCircle,
            member: member,
            modelContext: modelContext
        )

        _ = try userProfileRepository.addLocalCircleId(
            userId: user.id,
            circleId: remoteCircle.id,
            fallbackProfile: profile,
            modelContext: modelContext
        )

        return localCircle
    }

    // MARK: - Leave Circle

    func leaveCircle(
        circle: CloseCircle,
        membership: CircleMembership,
        actorDisplayName: String,
        modelContext: ModelContext
    ) async throws {
        guard membership.role != .owner else {
            throw CircleServiceError.ownerCannotLeaveCircle
        }

        try await circleRemoteDataSource.leaveCircle(
            circleId: circle.id,
            userId: membership.userId
        )

        try? await circleRemoteDataSource.createActivity(
            circleId: circle.id,
            type: .memberLeft,
            actorId: membership.userId,
            actorDisplayName: actorDisplayName,
            message: "\(actorDisplayName) left the Circle."
        )

        try await userProfileRepository.removeRemoteCircleId(
            userId: membership.userId,
            circleId: circle.id
        )

        try circleRepository.markLocalMembershipRemoved(
            circleId: circle.id,
            userId: membership.userId,
            modelContext: modelContext
        )

        _ = try? userProfileRepository.removeLocalCircleId(
            userId: membership.userId,
            circleId: circle.id,
            modelContext: modelContext
        )
    }

    // MARK: - Update Circle

    func updateCircleDetails(
        circle: CloseCircle,
        membership: CircleMembership,
        name: String,
        description: String?,
        modelContext: ModelContext
    ) async throws -> CloseCircle {
        guard membership.role == .owner else {
            throw CircleServiceError.ownerOnlyAction
        }

        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedName.isEmpty == false else {
            throw CircleServiceError.invalidCircleName
        }

        let cleanedDescription = cleanOptionalText(description)

        try await circleRemoteDataSource.updateCircleDetails(
            circleId: circle.id,
            name: cleanedName,
            description: cleanedDescription
        )

        try? await circleRemoteDataSource.createActivity(
            circleId: circle.id,
            type: .circleUpdated,
            actorId: membership.userId,
            actorDisplayName: circle.ownerDisplayName,
            message: "\(circle.ownerDisplayName) updated the Circle details."
        )

        return try circleRepository.updateLocalCircleDetails(
            circleId: circle.id,
            name: cleanedName,
            description: cleanedDescription,
            modelContext: modelContext
        )
    }

    // MARK: - Delete Circle

    func deleteCircle(
        circle: CloseCircle,
        membership: CircleMembership,
        modelContext: ModelContext
    ) async throws {
        guard membership.role == .owner else {
            throw CircleServiceError.ownerOnlyAction
        }

        try? await circleRemoteDataSource.createActivity(
            circleId: circle.id,
            type: .circleDeleted,
            actorId: membership.userId,
            actorDisplayName: circle.ownerDisplayName,
            message: "\(circle.ownerDisplayName) deleted this Circle."
        )

        try await circleRemoteDataSource.deleteCircle(
            circleId: circle.id
        )

        try circleRepository.markLocalCircleDeleted(
            circleId: circle.id,
            modelContext: modelContext
        )

        try circleRepository.markLocalMembershipsRemovedForCircle(
            circleId: circle.id,
            modelContext: modelContext
        )

        try await userProfileRepository.removeRemoteCircleId(
            userId: membership.userId,
            circleId: circle.id
        )

        _ = try? userProfileRepository.removeLocalCircleId(
            userId: membership.userId,
            circleId: circle.id,
            modelContext: modelContext
        )
    }

    // MARK: - Helpers

    private func cleanOptionalText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }

    private func generateUniqueInviteCode(
        circleName: String,
        ownerDisplayName: String
    ) async throws -> String {
        for _ in 0..<8 {
            let candidate = CircleInviteCodeGenerator.generateCandidate(
                circleName: circleName,
                ownerDisplayName: ownerDisplayName
            )

            let isAvailable = try await circleRemoteDataSource.isInviteCodeAvailable(
                inviteCode: candidate
            )

            if isAvailable {
                return candidate
            }
        }

        throw CircleServiceError.inviteCodeUnavailable
    }

    // MARK: - Errors

    enum CircleServiceError: LocalizedError {
        case invalidInviteCode
        case circleNotFound
        case inviteCodeUnavailable
        case ownerCannotLeaveCircle
        case ownerOnlyAction
        case invalidCircleName

        var errorDescription: String? {
            switch self {
            case .invalidInviteCode:
                return "Enter a valid invite code."
            case .circleNotFound:
                return "No Circle was found with that invite code."
            case .inviteCodeUnavailable:
                return "Couldn’t generate a unique invite code. Please try again."
            case .ownerCannotLeaveCircle:
                return "Owners can’t leave their own Circle. You can edit or delete the Circle instead."
            case .ownerOnlyAction:
                return "Only the Circle owner can perform this action."
            case .invalidCircleName:
                return "Circle name is required."
            }
        }
    }
}
