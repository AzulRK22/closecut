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
}
