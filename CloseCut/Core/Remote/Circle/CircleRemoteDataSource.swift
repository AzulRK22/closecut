//
//  CircleRemoteDataSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation
import FirebaseFirestore

enum CircleRemoteDataSourceError: LocalizedError {
    case circleDocumentMissing
    case circleDocumentIncomplete

    var errorDescription: String? {
        switch self {
        case .circleDocumentMissing:
            return "Circle document is missing."
        case .circleDocumentIncomplete:
            return "Circle document is incomplete."
        }
    }
}

@MainActor
final class CircleRemoteDataSource {

    // MARK: - Create

    func createCircle(
        closeCircle: CloseCircle,
        ownerMember: CircleMember
    ) async throws {
        let circleRef = FirestorePaths.circle(closeCircle.id)
        let memberRef = FirestorePaths.circleMember(
            circleId: closeCircle.id,
            userId: ownerMember.userId
        )

        let batch = Firestore.firestore().batch()

        let circleDTO = FirestoreCircleDTO(closeCircle: closeCircle)
        let circleData = try Firestore.Encoder().encode(circleDTO)

        let memberDTO = FirestoreCircleMemberDTO(member: ownerMember)
        let memberData = try Firestore.Encoder().encode(memberDTO)

        batch.setData(circleData, forDocument: circleRef, merge: true)
        batch.setData(memberData, forDocument: memberRef, merge: true)

        try await batch.commit()
    }

    // MARK: - Read

    func fetchCircle(
        circleId: String
    ) async throws -> CloseCircle {
        let document = try await FirestorePaths
            .circle(circleId)
            .getDocument()

        guard document.exists else {
            throw CircleRemoteDataSourceError.circleDocumentMissing
        }

        guard let data = document.data(),
              data["name"] != nil,
              data["ownerId"] != nil,
              data["inviteCode"] != nil,
              data["inviteCodeNormalized"] != nil else {
            throw CircleRemoteDataSourceError.circleDocumentIncomplete
        }

        let dto = try document.data(as: FirestoreCircleDTO.self)
        return dto.domain(id: document.documentID)
    }

    func fetchCircleByInviteCode(
        inviteCode: String
    ) async throws -> CloseCircle? {
        let normalizedCode = inviteCode.normalizedInviteCode

        let snapshot = try await FirestorePaths
            .circlesCollection()
            .whereField("inviteCodeNormalized", isEqualTo: normalizedCode)
            .limit(to: 5)
            .getDocuments()

        for document in snapshot.documents {
            guard document.exists else {
                continue
            }

            guard let data = document.data() as [String: Any]?,
                  data["name"] != nil,
                  data["ownerId"] != nil,
                  data["inviteCode"] != nil,
                  data["inviteCodeNormalized"] != nil else {
                continue
            }

            let dto = try document.data(as: FirestoreCircleDTO.self)
            let circle = dto.domain(id: document.documentID)

            if circle.deletedAt == nil {
                return circle
            }
        }

        return nil
    }

    func fetchMember(
        circleId: String,
        userId: String
    ) async throws -> CircleMember? {
        let document = try await FirestorePaths
            .circleMember(
                circleId: circleId,
                userId: userId
            )
            .getDocument()

        guard document.exists else {
            return nil
        }

        let dto = try document.data(as: FirestoreCircleMemberDTO.self)
        return dto.domain()
    }

    func fetchMembers(
        circleId: String
    ) async throws -> [CircleMember] {
        let snapshot = try await FirestorePaths
            .circleMembers(circleId)
            .whereField("status", isEqualTo: CircleMemberStatus.active.rawValue)
            .getDocuments()

        return try snapshot.documents.map { document in
            let dto = try document.data(as: FirestoreCircleMemberDTO.self)
            return dto.domain()
        }
    }

    func fetchActivities(
        circleId: String,
        limit: Int = 30
    ) async throws -> [CircleActivity] {
        let snapshot = try await FirestorePaths
            .circleActivity(circleId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.map { document in
            let dto = try document.data(as: FirestoreCircleActivityDTO.self)

            return dto.domain(
                id: document.documentID
            )
        }
    }

    func fetchMembershipsForUser(
        userId: String
    ) async throws -> [(circle: CloseCircle, member: CircleMember)] {
        let snapshot = try await FirestorePaths
            .membersCollectionGroup()
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        var results: [(circle: CloseCircle, member: CircleMember)] = []

        for document in snapshot.documents {
            let dto = try document.data(as: FirestoreCircleMemberDTO.self)
            let member = dto.domain()

            guard member.status == .active else {
                continue
            }

            guard let circleId = document.reference.parent.parent?.documentID else {
                continue
            }

            do {
                let circle = try await fetchCircle(
                    circleId: circleId
                )

                if circle.deletedAt == nil {
                    results.append((circle, member))
                }
            } catch {
                #if DEBUG
                print("⚠️ Skipped remote Circle membership during pull:", error.localizedDescription)
                #endif
            }
        }

        return results
    }

    // MARK: - Invite Code

    func isInviteCodeAvailable(
        inviteCode: String
    ) async throws -> Bool {
        let normalizedCode = inviteCode.normalizedInviteCode

        let snapshot = try await FirestorePaths
            .circlesCollection()
            .whereField("inviteCodeNormalized", isEqualTo: normalizedCode)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.isEmpty
    }

    // MARK: - Join / Leave

    func joinCircle(
        circle: CloseCircle,
        member: CircleMember
    ) async throws {
        let circleRef = FirestorePaths.circle(circle.id)
        let memberRef = FirestorePaths.circleMember(
            circleId: circle.id,
            userId: member.userId
        )

        let batch = Firestore.firestore().batch()

        let memberDTO = FirestoreCircleMemberDTO(member: member)
        let memberData = try Firestore.Encoder().encode(memberDTO)

        batch.setData(
            memberData,
            forDocument: memberRef,
            merge: true
        )

        batch.updateData(
            [
                "memberIds": FieldValue.arrayUnion([member.userId]),
                "updatedAt": Timestamp(date: Date())
            ],
            forDocument: circleRef
        )

        try await batch.commit()
    }

    func leaveCircle(
        circleId: String,
        userId: String
    ) async throws {
        let circleRef = FirestorePaths.circle(circleId)
        let memberRef = FirestorePaths.circleMember(
            circleId: circleId,
            userId: userId
        )

        let batch = Firestore.firestore().batch()

        batch.updateData(
            [
                "status": CircleMemberStatus.removed.rawValue,
                "updatedAt": Timestamp(date: Date())
            ],
            forDocument: memberRef
        )

        batch.updateData(
            [
                "memberIds": FieldValue.arrayRemove([userId]),
                "updatedAt": Timestamp(date: Date())
            ],
            forDocument: circleRef
        )

        try await batch.commit()
    }

    // MARK: - Update / Delete

    func updateCircleDetails(
        circleId: String,
        name: String,
        description: String?
    ) async throws {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)

        var payload: [String: Any] = [
            "name": cleanedName,
            "updatedAt": Timestamp(date: Date())
        ]

        if let cleanedDescription,
           cleanedDescription.isEmpty == false {
            payload["description"] = cleanedDescription
        } else {
            payload["description"] = FieldValue.delete()
        }

        try await FirestorePaths
            .circle(circleId)
            .updateData(payload)
    }

    func deleteCircle(
        circleId: String
    ) async throws {
        try await FirestorePaths
            .circle(circleId)
            .updateData([
                "deletedAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ])
    }

    // MARK: - Activity

    func createActivity(
        circleId: String,
        type: CircleActivityType,
        actorId: String,
        actorDisplayName: String,
        message: String
    ) async throws {
        let circleDocument = try await FirestorePaths
            .circle(circleId)
            .getDocument()

        guard circleDocument.exists,
              let data = circleDocument.data(),
              data["name"] != nil else {
            throw CircleRemoteDataSourceError.circleDocumentMissing
        }

        let activity = CircleActivity(
            id: UUID().uuidString,
            circleId: circleId,
            type: type,
            actorId: actorId,
            actorDisplayName: actorDisplayName,
            message: message,
            createdAt: Date()
        )

        let dto = FirestoreCircleActivityDTO(activity: activity)

        try FirestorePaths
            .circleActivityDocument(
                circleId: circleId,
                activityId: activity.id
            )
            .setData(from: dto, merge: true)
    }
}
