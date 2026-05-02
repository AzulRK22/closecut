//
//  CircleRemoteDataSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation
import FirebaseFirestore

@MainActor
final class CircleRemoteDataSource {
    private let db = Firestore.firestore()

    func createCircle(
        closeCircle: CloseCircle,
        ownerMember: CircleMember
    ) async throws {
        let circleDTO = FirestoreCircleDTO(closeCircle: closeCircle)
        let memberDTO = FirestoreCircleMemberDTO(member: ownerMember)

        let circleRef = db
            .collection("circles")
            .document(closeCircle.id)

        let memberRef = circleRef
            .collection("members")
            .document(ownerMember.userId)

        let batch = db.batch()

        try batch.setData(
            from: circleDTO,
            forDocument: circleRef,
            merge: true
        )

        try batch.setData(
            from: memberDTO,
            forDocument: memberRef,
            merge: true
        )

        try await batch.commit()
    }

    func fetchCircle(
        circleId: String
    ) async throws -> CloseCircle {
        let document = try await db
            .collection("circles")
            .document(circleId)
            .getDocument()

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
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            return nil
        }

        let dto = try document.data(as: FirestoreCircleDTO.self)

        return dto.domain(id: document.documentID)
    }
    func joinCircle(
        circle: CloseCircle,
        member: CircleMember
    ) async throws {
        let memberDTO = FirestoreCircleMemberDTO(member: member)

        let circleRef = db
            .collection("circles")
            .document(circle.id)

        let memberRef = circleRef
            .collection("members")
            .document(member.userId)

        let batch = db.batch()

        try batch.setData(
            from: memberDTO,
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

        let batch = db.batch()

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
    func updateCircleDetails(
        circleId: String,
        name: String,
        description: String?
    ) async throws {
        try await db
            .collection("circles")
            .document(circleId)
            .updateData([
                "name": name,
                "description": description as Any,
                "updatedAt": Timestamp(date: Date())
            ])
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
}
