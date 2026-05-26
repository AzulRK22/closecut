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
    ) async -> EntrySyncSummary {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            lastInitialCloudRefreshError = "Missing user."

            return EntrySyncSummary(
                syncedCount: 0,
                failedCount: 1,
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
    ) async -> EntrySyncSummary {
        let pushSummary = await entrySyncService.syncPendingEntries(
            userId: userId,
            modelContext: modelContext
        )

        let pullSummary = await entrySyncService.pullRemoteEntries(
            userId: userId,
            modelContext: modelContext
        )

        return EntrySyncSummary(
            syncedCount: pushSummary.syncedCount,
            failedCount: pushSummary.failedCount + pullSummary.failedCount,
            pulledCount: pullSummary.pulledCount
        )
    }
}
