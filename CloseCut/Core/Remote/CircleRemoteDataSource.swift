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
    private let db = Firestore.firestore()

    // MARK: - Create

    func createCircle(
        closeCircle: CloseCircle,
        ownerMember: CircleMember
    ) async throws {
        let circleRef = db
            .collection("circles")
            .document(closeCircle.id)

        let memberRef = circleRef
            .collection("members")
            .document(ownerMember.userId)

        let batch = db.batch()

        var circleData: [String: Any] = [
            "name": closeCircle.name,
            "ownerId": closeCircle.ownerId,
            "ownerDisplayName": closeCircle.ownerDisplayName,
            "inviteCode": closeCircle.inviteCode,
            "inviteCodeNormalized": closeCircle.inviteCodeNormalized,
            "memberIds": closeCircle.memberIds,
            "createdAt": Timestamp(date: closeCircle.createdAt),
            "updatedAt": Timestamp(date: closeCircle.updatedAt)
        ]

        circleData["description"] = closeCircle.description ?? ""

        if let deletedAt = closeCircle.deletedAt {
            circleData["deletedAt"] = Timestamp(date: deletedAt)
        }

        let memberData = memberPayload(ownerMember)

        batch.setData(circleData, forDocument: circleRef, merge: true)
        batch.setData(memberData, forDocument: memberRef, merge: true)

        try await batch.commit()
    }

    // MARK: - Read

    func fetchCircle(
        circleId: String
    ) async throws -> CloseCircle {
        let document = try await db
            .collection("circles")
            .document(circleId)
            .getDocument()

        guard document.exists else {
            throw CircleRemoteDataSourceError.circleDocumentMissing
        }

        guard let data = document.data(),
              data["name"] != nil,
              data["ownerId"] != nil,
              data["inviteCode"] != nil,
              data["inviteCodeNormalized"] != nil,
              data["memberIds"] != nil else {
            throw CircleRemoteDataSourceError.circleDocumentIncomplete
        }

        let dto = try document.data(as: FirestoreCircleDTO.self)
        return dto.domain(id: document.documentID)
    }

    func fetchCircleByInviteCode(
        inviteCode: String
    ) async throws -> CloseCircle? {
        let normalizedCode = inviteCode.normalizedInviteCode

        let snapshot = try await db
            .collection("circles")
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
                  data["inviteCodeNormalized"] != nil,
                  data["memberIds"] != nil else {
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
        let document = try await db
            .collection("circles")
            .document(circleId)
            .collection("members")
            .document(userId)
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
        let snapshot = try await db
            .collection("circles")
            .document(circleId)
            .collection("members")
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
        let snapshot = try await db
            .collection("circles")
            .document(circleId)
            .collection("activity")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.map { document in
            let dto = try document.data(as: FirestoreCircleActivityDTO.self)
            return dto.domain(id: document.documentID)
        }
    }

    // MARK: - Invite Code

    func isInviteCodeAvailable(
        inviteCode: String
    ) async throws -> Bool {
        let normalizedCode = inviteCode.normalizedInviteCode

        let snapshot = try await db
            .collection("circles")
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
        let circleRef = db
            .collection("circles")
            .document(circle.id)

        let memberRef = circleRef
            .collection("members")
            .document(member.userId)

        let batch = db.batch()

        batch.setData(
            memberPayload(member),
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
        let circleRef = db
            .collection("circles")
            .document(circleId)

        let memberRef = circleRef
            .collection("members")
            .document(userId)

        try await memberRef.updateData([
            "status": CircleMemberStatus.removed.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])

        do {
            let circleSnapshot = try await circleRef.getDocument()

            guard circleSnapshot.exists else {
                throw CircleRemoteDataSourceError.circleDocumentMissing
            }

            guard let memberIds = circleSnapshot.data()?["memberIds"] as? [String],
                  memberIds.contains(userId) else {
                #if DEBUG
                print("ℹ️ User was not listed in circle.memberIds. Skipping arrayRemove.")
                #endif
                return
            }

            try await circleRef.updateData([
                "memberIds": FieldValue.arrayRemove([userId]),
                "updatedAt": Timestamp(date: Date())
            ])
        } catch CircleRemoteDataSourceError.circleDocumentMissing {
            throw CircleRemoteDataSourceError.circleDocumentMissing
        } catch {
            #if DEBUG
            print("⚠️ Failed to remove user from circle.memberIds:", error.localizedDescription)
            #endif
        }
    }

    // MARK: - Update / Delete

    func updateCircleDetails(
        circleId: String,
        name: String,
        description: String?
    ) async throws {
        var payload: [String: Any] = [
            "name": name,
            "updatedAt": Timestamp(date: Date())
        ]

        if let description,
           description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            payload["description"] = description
        } else {
            payload["description"] = FieldValue.delete()
        }

        try await db
            .collection("circles")
            .document(circleId)
            .updateData(payload)
    }

    func deleteCircle(
        circleId: String
    ) async throws {
        try await db
            .collection("circles")
            .document(circleId)
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
        let circleDocument = try await db
            .collection("circles")
            .document(circleId)
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

        try db
            .collection("circles")
            .document(circleId)
            .collection("activity")
            .document(activity.id)
            .setData(from: dto, merge: true)
    }
    func fetchMembershipsForUser(
        userId: String
    ) async throws -> [(circle: CloseCircle, member: CircleMember)] {
        let snapshot = try await db
            .collectionGroup("members")
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
                let circle = try await fetchCircle(circleId: circleId)

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

    // MARK: - Helpers

    private func memberPayload(_ member: CircleMember) -> [String: Any] {
        [
            "userId": member.userId,
            "displayName": member.displayName,
            "email": member.email ?? "",
            "role": member.role.rawValue,
            "status": member.status.rawValue,
            "joinedAt": Timestamp(date: member.joinedAt),
            "updatedAt": Timestamp(date: member.updatedAt)
        ]
    }
}
