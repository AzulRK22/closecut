//
//  EntryConflictPolicyTests.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//


import XCTest
@testable import CloseCut

@MainActor
final class EntryConflictPolicyTests: XCTestCase {

    func testInsertRemoteWhenLocalDoesNotExist() {
        let remote = makeEntry(
            title: "Past Lives",
            updatedAt: Date(),
            syncStatus: .synced
        )

        let decision = EntryConflictPolicy.decide(
            localEntry: nil,
            remoteEntry: remote
        )

        XCTAssertEqual(decision, .insertRemote)
    }

    func testKeepLocalPendingWhenLocalHasPendingChanges() {
        let now = Date()

        let local = makeEntry(
            title: "Local edit",
            updatedAt: now,
            syncStatus: .pending
        )

        let remote = makeEntry(
            title: "Remote edit",
            updatedAt: now.addingTimeInterval(60),
            syncStatus: .synced
        )

        let decision = EntryConflictPolicy.decide(
            localEntry: local,
            remoteEntry: remote
        )

        XCTAssertEqual(decision, .keepLocalPending)
    }

    func testKeepLocalPendingWhenLocalHasFailedChanges() {
        let now = Date()

        let local = makeEntry(
            title: "Local failed edit",
            updatedAt: now,
            syncStatus: .failed
        )

        let remote = makeEntry(
            title: "Remote edit",
            updatedAt: now.addingTimeInterval(60),
            syncStatus: .synced
        )

        let decision = EntryConflictPolicy.decide(
            localEntry: local,
            remoteEntry: remote
        )

        XCTAssertEqual(decision, .keepLocalPending)
    }

    func testApplyRemoteWhenRemoteIsNewerAndLocalIsSynced() {
        let now = Date()

        let local = makeEntry(
            title: "Old local",
            updatedAt: now,
            syncStatus: .synced
        )

        let remote = makeEntry(
            title: "New remote",
            updatedAt: now.addingTimeInterval(60),
            syncStatus: .synced
        )

        let decision = EntryConflictPolicy.decide(
            localEntry: local,
            remoteEntry: remote
        )

        XCTAssertEqual(decision, .applyRemote)
    }

    func testKeepLocalWhenLocalIsNewerOrEqual() {
        let now = Date()

        let local = makeEntry(
            title: "Newer local",
            updatedAt: now.addingTimeInterval(60),
            syncStatus: .synced
        )

        let remote = makeEntry(
            title: "Older remote",
            updatedAt: now,
            syncStatus: .synced
        )

        let decision = EntryConflictPolicy.decide(
            localEntry: local,
            remoteEntry: remote
        )

        XCTAssertEqual(decision, .keepLocal)
    }

    func testApplyRemoteDeletedWhenLocalIsSynced() {
        let now = Date()

        let local = makeEntry(
            title: "Local",
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )

        let remote = makeEntry(
            title: "Remote deleted",
            updatedAt: now.addingTimeInterval(60),
            deletedAt: now.addingTimeInterval(30),
            syncStatus: .synced
        )

        let decision = EntryConflictPolicy.decide(
            localEntry: local,
            remoteEntry: remote
        )

        XCTAssertEqual(decision, .applyRemote)
    }

    private func makeEntry(
        title: String,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatus: SyncStatus
    ) -> Entry {
        Entry(
            id: "entry-1",
            ownerId: "user-1",
            title: title,
            normalizedTitle: title.normalizedTitleKey,
            type: .movie,
            releaseYear: nil,
            mood: "Moved",
            quickSentiment: nil,
            takeaway: "",
            quote: nil,
            tags: [],
            intensity: 3,
            watchContext: .home,
            watchedDateApprox: .recently,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil,
            visibility: .privateOnly,
            sourceType: .fullEntry,
            watchedAt: updatedAt,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: syncStatus
        )
    }
}
