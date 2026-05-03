//
//  EntryRemoteDataSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation
import FirebaseFirestore

@MainActor
final class EntryRemoteDataSource {
    private let db = Firestore.firestore()

    func upsertEntry(
        _ entry: Entry,
        circleId: String? = nil
    ) async throws {
        let dto = FirestoreEntryDTO(
            entry: entry,
            circleId: circleId
        )

        try db
            .collection("entries")
            .document(entry.id)
            .setData(from: dto, merge: true)
    }

    func softDeleteEntry(
        _ entry: Entry,
        circleId: String? = nil
    ) async throws {
        var deletedEntry = entry
        deletedEntry.deletedAt = entry.deletedAt ?? Date()
        deletedEntry.updatedAt = Date()

        let dto = FirestoreEntryDTO(
            entry: deletedEntry,
            circleId: circleId
        )

        try db
            .collection("entries")
            .document(entry.id)
            .setData(from: dto, merge: true)
    }

    func fetchEntries(
        ownerId: String
    ) async throws -> [Entry] {
        let snapshot = try await db
            .collection("entries")
            .whereField("ownerId", isEqualTo: ownerId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return try snapshot.documents.map { document in
            let dto = try document.data(as: FirestoreEntryDTO.self)
            return dto.domain(
                id: document.documentID,
                syncStatus: .synced
            )
        }
    }
    func fetchSharedEntries(
        circleId: String
    ) async throws -> [Entry] {
        let snapshot = try await db
            .collection("entries")
            .whereField("visibility", isEqualTo: EntryVisibility.circle.rawValue)
            .whereField("circleId", isEqualTo: circleId)
            .getDocuments()

        let entries = try snapshot.documents.map { document in
            let dto = try document.data(as: FirestoreEntryDTO.self)

            return dto.domain(
                id: document.documentID,
                syncStatus: .synced
            )
        }

        return entries
            .filter { $0.deletedAt == nil }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }
}
