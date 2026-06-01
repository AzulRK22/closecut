//
//  WatchlistRemoteDataSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/05/26.
//


import Foundation
import FirebaseFirestore

@MainActor
final class WatchlistRemoteDataSource {

    // MARK: - Write

    func upsertWatchlistItem(
        _ item: WatchlistItem
    ) async throws {
        let dto = FirestoreWatchlistItemDTO(item: item)

        try FirestorePaths
            .watchlistItem(item.id)
            .setData(from: dto, merge: true)
    }

    func softDeleteWatchlistItem(
        _ item: WatchlistItem
    ) async throws {
        var deletedItem = item
        deletedItem.status = .dismissed
        deletedItem.deletedAt = item.deletedAt ?? Date()
        deletedItem.updatedAt = Date()

        let dto = FirestoreWatchlistItemDTO(item: deletedItem)

        try FirestorePaths
            .watchlistItem(item.id)
            .setData(from: dto, merge: true)
    }

    // MARK: - Read

    func fetchWatchlistItems(
        ownerId: String
    ) async throws -> [WatchlistItem] {
        let cleanedOwnerId = ownerId.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            return []
        }

        let snapshot = try await FirestorePaths
            .watchlistItemsCollection()
            .whereField("ownerId", isEqualTo: cleanedOwnerId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return try snapshot.documents.map { document in
            let dto = try document.data(as: FirestoreWatchlistItemDTO.self)

            return dto.domain(
                id: document.documentID,
                syncStatus: .synced
            )
        }
    }
}
