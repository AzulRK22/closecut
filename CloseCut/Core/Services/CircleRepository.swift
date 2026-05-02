//
//  CircleRepository.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation
import SwiftData

@MainActor
final class CircleRepository {

    // MARK: - Circle Create

    func createLocalCircle(
        ownerId: String,
        ownerDisplayName: String,
        circleName: String,
        circleDescription: String? = nil,
        inviteCode: String,
        modelContext: ModelContext
    ) throws -> CloseCircle {
        let now = Date()
        let circleId = UUID().uuidString

        let cleanedName = circleName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = cleanedName.isEmpty ? "\(ownerDisplayName)'s Circle" : cleanedName

        let circle = LocalCircle(
            id: circleId,
            name: resolvedName,
            ownerId: ownerId,
            circleDescription: cleanOptionalText(circleDescription),
            ownerDisplayName: ownerDisplayName,
            inviteCode: inviteCode,
            inviteCodeNormalized: inviteCode.normalizedInviteCode,
            memberIds: [ownerId],
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .pending
        )

        modelContext.insert(circle)
        try modelContext.save()

        return circle.domain
    }

    // MARK: - Circle Read

    func fetchLocalCircle(
        id: String,
        modelContext: ModelContext
    ) throws -> CloseCircle? {
        let descriptor = FetchDescriptor<LocalCircle>(
            predicate: #Predicate { circle in
                circle.id == id
            }
        )

        return try modelContext.fetch(descriptor).first?.domain
    }

    func fetchLocalCircleModel(
        id: String,
        modelContext: ModelContext
    ) throws -> LocalCircle? {
        let descriptor = FetchDescriptor<LocalCircle>(
            predicate: #Predicate { circle in
                circle.id == id
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    func fetchLocalCirclesForUser(
        userId: String,
        modelContext: ModelContext
    ) throws -> [CloseCircle] {
        let memberships = try fetchLocalMemberships(
            userId: userId,
            includeRemoved: false,
            modelContext: modelContext
        )

        let circleIds = Set(memberships.map { $0.circleId })

        let descriptor = FetchDescriptor<LocalCircle>(
            sortBy: [
                SortDescriptor(\LocalCircle.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter { circleIds.contains($0.id) }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    // MARK: - Circle Upsert / Update

    func upsertRemoteCircle(
        _ remoteCircle: CloseCircle,
        modelContext: ModelContext
    ) throws -> CloseCircle {
        if let existing = try fetchLocalCircleModel(
            id: remoteCircle.id,
            modelContext: modelContext
        ) {
            existing.update(from: remoteCircle, syncStatus: .synced)
            try modelContext.save()
            return existing.domain
        }

        let localCircle = LocalCircle(
            id: remoteCircle.id,
            name: remoteCircle.name,
            ownerId: remoteCircle.ownerId,
            circleDescription: remoteCircle.description,
            ownerDisplayName: remoteCircle.ownerDisplayName,
            inviteCode: remoteCircle.inviteCode,
            inviteCodeNormalized: remoteCircle.inviteCodeNormalized,
            memberIds: remoteCircle.memberIds,
            createdAt: remoteCircle.createdAt,
            updatedAt: remoteCircle.updatedAt,
            deletedAt: remoteCircle.deletedAt,
            syncStatus: .synced
        )

        modelContext.insert(localCircle)
        try modelContext.save()

        return localCircle.domain
    }

    func updateLocalCircleMembership(
        circleId: String,
        userId: String,
        modelContext: ModelContext
    ) throws -> CloseCircle {
        guard let circle = try fetchLocalCircleModel(
            id: circleId,
            modelContext: modelContext
        ) else {
            throw CircleRepositoryError.circleNotFound
        }

        if circle.memberIds.contains(userId) == false {
            circle.memberIds.append(userId)
        }

        circle.updatedAt = Date()
        circle.syncStatusRaw = SyncStatus.synced.rawValue

        try modelContext.save()

        return circle.domain
    }

    func markCircleSynced(
        circleId: String,
        modelContext: ModelContext
    ) throws {
        guard let circle = try fetchLocalCircleModel(
            id: circleId,
            modelContext: modelContext
        ) else {
            throw CircleRepositoryError.circleNotFound
        }

        circle.syncStatusRaw = SyncStatus.synced.rawValue
        circle.updatedAt = Date()
        try modelContext.save()
    }
    func updateLocalCircleDetails(
        circleId: String,
        name: String,
        description: String?,
        modelContext: ModelContext
    ) throws -> CloseCircle {
        guard let circle = try fetchLocalCircleModel(
            id: circleId,
            modelContext: modelContext
        ) else {
            throw CircleRepositoryError.circleNotFound
        }

        circle.name = name
        circle.circleDescription = cleanOptionalText(description)
        circle.updatedAt = Date()
        circle.syncStatusRaw = SyncStatus.synced.rawValue

        try modelContext.save()

        return circle.domain
    }

    func markLocalCircleDeleted(
        circleId: String,
        modelContext: ModelContext
    ) throws {
        guard let circle = try fetchLocalCircleModel(
            id: circleId,
            modelContext: modelContext
        ) else {
            throw CircleRepositoryError.circleNotFound
        }

        let now = Date()

        circle.deletedAt = now
        circle.updatedAt = now
        circle.syncStatusRaw = SyncStatus.synced.rawValue

        try modelContext.save()
    }

    func markLocalMembershipsRemovedForCircle(
        circleId: String,
        modelContext: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<LocalCircleMembership>(
            predicate: #Predicate { membership in
                membership.circleId == circleId
            }
        )

        let memberships = try modelContext.fetch(descriptor)

        for membership in memberships {
            membership.statusRaw = CircleMemberStatus.removed.rawValue
            membership.updatedAt = Date()
            membership.syncStatusRaw = SyncStatus.synced.rawValue
        }

        if memberships.isEmpty == false {
            try modelContext.save()
        }
    }

    // MARK: - Memberships

    func fetchLocalMemberships(
        userId: String,
        includeRemoved: Bool = false,
        modelContext: ModelContext
    ) throws -> [CircleMembership] {
        let descriptor = FetchDescriptor<LocalCircleMembership>(
            predicate: #Predicate { membership in
                membership.userId == userId
            },
            sortBy: [
                SortDescriptor(\LocalCircleMembership.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter {
                includeRemoved ||
                $0.statusRaw == CircleMemberStatus.active.rawValue
            }
            .map { $0.domain }
    }

    func fetchLocalMembershipModel(
        circleId: String,
        userId: String,
        modelContext: ModelContext
    ) throws -> LocalCircleMembership? {
        let membershipId = "\(circleId)_\(userId)"

        let descriptor = FetchDescriptor<LocalCircleMembership>(
            predicate: #Predicate { membership in
                membership.id == membershipId
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    func upsertLocalMembership(
        circle: CloseCircle,
        member: CircleMember,
        modelContext: ModelContext
    ) throws -> CircleMembership {
        if let existing = try fetchLocalMembershipModel(
            circleId: circle.id,
            userId: member.userId,
            modelContext: modelContext
        ) {
            existing.update(
                circle: circle,
                member: member,
                syncStatus: .synced
            )

            try modelContext.save()
            return existing.domain
        }

        let membership = LocalCircleMembership(
            circleId: circle.id,
            userId: member.userId,
            circleName: circle.name,
            circleDescription: circle.description,
            ownerId: circle.ownerId,
            ownerDisplayName: circle.ownerDisplayName,
            role: member.role,
            status: member.status,
            joinedAt: member.joinedAt,
            updatedAt: member.updatedAt,
            syncStatus: .synced
        )

        modelContext.insert(membership)
        try modelContext.save()

        return membership.domain
    }
    func markLocalMembershipRemoved(
        circleId: String,
        userId: String,
        modelContext: ModelContext
    ) throws {
        guard let membership = try fetchLocalMembershipModel(
            circleId: circleId,
            userId: userId,
            modelContext: modelContext
        ) else {
            throw CircleRepositoryError.membershipNotFound
        }

        membership.statusRaw = CircleMemberStatus.removed.rawValue
        membership.updatedAt = Date()
        membership.syncStatusRaw = SyncStatus.synced.rawValue

        try modelContext.save()
    }
    func removeLocalCircleCompletely(
        circleId: String,
        userId: String,
        modelContext: ModelContext
    ) throws {
        if let membership = try fetchLocalMembershipModel(
            circleId: circleId,
            userId: userId,
            modelContext: modelContext
        ) {
            modelContext.delete(membership)
        }

        if let circle = try fetchLocalCircleModel(
            id: circleId,
            modelContext: modelContext
        ) {
            modelContext.delete(circle)
        }

        try modelContext.save()
    }

    // MARK: - Helpers

    private func cleanOptionalText(_ value: String?) -> String? {
        guard let value else { return nil }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }
}

enum CircleRepositoryError: LocalizedError {
    case circleNotFound
    case membershipNotFound

    var errorDescription: String? {
        switch self {
        case .circleNotFound:
            return "Circle was not found."
        case .membershipNotFound:
            return "Circle membership was not found."
        }
    }
}
