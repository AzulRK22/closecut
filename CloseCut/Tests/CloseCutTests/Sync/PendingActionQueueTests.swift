//
//  PendingActionQueueTests.swift
//  CloseCutTests
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import XCTest
import SwiftData
@testable import CloseCut

@MainActor
final class PendingActionQueueTests: XCTestCase {

    func testEnqueueCreatesPendingAction() throws {
        let context = try makeInMemoryContext()
        let queue = PendingActionQueue()

        try queue.enqueue(
            userId: "user-1",
            actionType: PendingActionType.createEntry,
            payloadData: nil,
            dedupeKey: "entry:create:1",
            modelContext: context
        )

        let pending = try queue.fetchPendingActions(
            userId: "user-1",
            modelContext: context
        )

        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.actionTypeRaw, PendingActionType.createEntry.rawValue)
        XCTAssertEqual(pending.first?.statusRaw, PendingActionStatus.pending.rawValue)
    }

    func testEnqueueWithSameDedupeKeyUpdatesExistingAction() throws {
        let context = try makeInMemoryContext()
        let queue = PendingActionQueue()

        try queue.enqueue(
            userId: "user-1",
            actionType: PendingActionType.updateEntry,
            payloadData: nil,
            dedupeKey: "entry:update:1",
            modelContext: context
        )

        try queue.enqueue(
            userId: "user-1",
            actionType: PendingActionType.updateEntry,
            payloadData: nil,
            dedupeKey: "entry:update:1",
            modelContext: context
        )

        let pending = try queue.fetchPendingActions(
            userId: "user-1",
            modelContext: context
        )

        XCTAssertEqual(pending.count, 1)
    }

    func testCompletedActionDoesNotAppearInPendingFetch() throws {
        let context = try makeInMemoryContext()
        let queue = PendingActionQueue()

        try queue.enqueue(
            userId: "user-1",
            actionType: PendingActionType.createEntry,
            payloadData: nil,
            dedupeKey: "entry:create:1",
            modelContext: context
        )

        let pending = try queue.fetchPendingActions(
            userId: "user-1",
            modelContext: context
        )

        pending.first?.markCompleted()
        try context.save()

        let updatedPending = try queue.fetchPendingActions(
            userId: "user-1",
            modelContext: context
        )

        XCTAssertEqual(updatedPending.count, 0)
    }
    func testUpdateAfterPendingCreateCompactsIntoCreateAction() throws {
        let context = try makeInMemoryContext()
        let queue = PendingActionQueue()

        try queue.enqueueEntryAction(
            userId: "user-1",
            entryId: "entry-1",
            actionType: PendingActionType.createEntry,
            payloadData: nil,
            modelContext: context
        )

        try queue.enqueueEntryAction(
            userId: "user-1",
            entryId: "entry-1",
            actionType: PendingActionType.updateEntry,
            payloadData: nil,
            modelContext: context
        )

        let pending = try queue.fetchPendingActions(
            userId: "user-1",
            modelContext: context
        )

        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.actionTypeRaw, PendingActionType.createEntry.rawValue)
    }

    func testDeleteRemovesPendingUpdateForSameEntry() throws {
        let context = try makeInMemoryContext()
        let queue = PendingActionQueue()

        try queue.enqueueEntryAction(
            userId: "user-1",
            entryId: "entry-1",
            actionType: PendingActionType.updateEntry,
            payloadData: nil,
            modelContext: context
        )

        try queue.enqueueEntryAction(
            userId: "user-1",
            entryId: "entry-1",
            actionType: PendingActionType.deleteEntry,
            payloadData: nil,
            modelContext: context
        )

        let pending = try queue.fetchPendingActions(
            userId: "user-1",
            modelContext: context
        )

        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.actionTypeRaw, PendingActionType.deleteEntry.rawValue)
    }

    func testCleanupAllCompletedActionsDeletesOnlyCompletedForUser() throws {
        let context = try makeInMemoryContext()
        let queue = PendingActionQueue()

        try queue.enqueue(
            userId: "user-1",
            actionType: PendingActionType.createEntry,
            payloadData: nil,
            dedupeKey: "entry:create:1",
            modelContext: context
        )

        try queue.enqueue(
            userId: "user-1",
            actionType: PendingActionType.updateEntry,
            payloadData: nil,
            dedupeKey: "entry:update:1",
            modelContext: context
        )

        let pending = try queue.fetchPendingActions(
            userId: "user-1",
            modelContext: context
        )

        pending.first?.markCompleted()
        try context.save()

        let deletedCount = try queue.cleanupAllCompletedActions(
            userId: "user-1",
            modelContext: context
        )

        let remainingPending = try queue.fetchPendingActions(
            userId: "user-1",
            modelContext: context
        )

        XCTAssertEqual(deletedCount, 1)
        XCTAssertEqual(remainingPending.count, 1)
    }
    private func makeInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: PendingAction.self,
            configurations: configuration
        )

        return ModelContext(container)
    }
}
