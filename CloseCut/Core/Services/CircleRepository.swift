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

    func createLocalCircle(
        ownerId: String,
        ownerDisplayName: String,
        circleName: String,
        modelContext: ModelContext
    ) throws -> CloseCircle {
        let now = Date()
        let circleId = UUID().uuidString

        let inviteCode = CircleInviteCodeGenerator.generate(
            displayName: ownerDisplayName,
            userId: ownerId
        )

        let circle = LocalCircle(
            id: circleId,
            name: circleName.trimmingCharacters(in: .whitespacesAndNewlines),
            ownerId: ownerId,
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
}

enum CircleRepositoryError: LocalizedError {
    case circleNotFound

    var errorDescription: String? {
        switch self {
        case .circleNotFound:
            return "Circle was not found."
        }
    }
}
