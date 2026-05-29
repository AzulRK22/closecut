//
//  SessionSyncViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class SessionSyncViewModel: ObservableObject {
    @Published private(set) var isInitialCloudRefreshRunning = false
    @Published private(set) var lastInitialCloudRefreshError: String?

    private let entrySyncService = EntrySyncService()
    private let watchlistSyncService = WatchlistSyncService()

    private var refreshedUserIds: Set<String> = []

    // MARK: - Initial Session Refresh

    func runInitialCloudRefreshIfNeeded(
        userId: String,
        modelContext: ModelContext
    ) async {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            lastInitialCloudRefreshError = "Missing user."
            return
        }

        guard refreshedUserIds.contains(cleanedUserId) == false else {
            return
        }

        guard isInitialCloudRefreshRunning == false else {
            return
        }

        isInitialCloudRefreshRunning = true
        lastInitialCloudRefreshError = nil

        defer {
            isInitialCloudRefreshRunning = false
        }

        let summary = await refreshCloudSession(
            userId: cleanedUserId,
            modelContext: modelContext
        )

        if summary.hasFailures {
            lastInitialCloudRefreshError = "Cloud refresh partially failed."
        } else {
            refreshedUserIds.insert(cleanedUserId)
        }
    }

    func forceRefreshCloudSession(
        userId: String,
        modelContext: ModelContext
    ) async -> CloudRefreshSummary {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            lastInitialCloudRefreshError = "Missing user."

            return CloudRefreshSummary(
                syncedCount: 0,
                failedCount: 1,
                pulledCount: 0
            )
        }

        guard isInitialCloudRefreshRunning == false else {
            return CloudRefreshSummary(
                syncedCount: 0,
                failedCount: 0,
                pulledCount: 0
            )
        }

        isInitialCloudRefreshRunning = true
        lastInitialCloudRefreshError = nil

        defer {
            isInitialCloudRefreshRunning = false
        }

        let summary = await refreshCloudSession(
            userId: cleanedUserId,
            modelContext: modelContext
        )

        if summary.hasFailures {
            lastInitialCloudRefreshError = "Cloud refresh partially failed."
        } else {
            refreshedUserIds.insert(cleanedUserId)
        }

        return summary
    }

    func reset() {
        refreshedUserIds.removeAll()
        isInitialCloudRefreshRunning = false
        lastInitialCloudRefreshError = nil
    }

    // MARK: - Private

    private func refreshCloudSession(
        userId: String,
        modelContext: ModelContext
    ) async -> CloudRefreshSummary {
        let entryPushSummary = await entrySyncService.syncPendingEntries(
            userId: userId,
            modelContext: modelContext
        )

        let watchlistPushSummary = await watchlistSyncService.syncPendingWatchlistItems(
            userId: userId,
            modelContext: modelContext
        )

        let entryPullSummary = await entrySyncService.pullRemoteEntries(
            userId: userId,
            modelContext: modelContext
        )

        let watchlistPullSummary = await watchlistSyncService.pullRemoteWatchlistItems(
            userId: userId,
            modelContext: modelContext
        )

        return CloudRefreshSummary(
            syncedCount: entryPushSummary.syncedCount + watchlistPushSummary.syncedCount,
            failedCount: entryPushSummary.failedCount +
                watchlistPushSummary.failedCount +
                entryPullSummary.failedCount +
                watchlistPullSummary.failedCount,
            pulledCount: entryPullSummary.pulledCount + watchlistPullSummary.pulledCount
        )
    }
}

// MARK: - Cloud Refresh Summary

struct CloudRefreshSummary: Equatable {
    let syncedCount: Int
    let failedCount: Int
    let pulledCount: Int

    var hasFailures: Bool {
        failedCount > 0
    }

    var didSyncAnything: Bool {
        syncedCount > 0 || pulledCount > 0
    }
}
