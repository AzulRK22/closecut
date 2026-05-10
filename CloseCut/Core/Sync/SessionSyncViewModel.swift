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

    func runInitialCloudRefreshIfNeeded(
        userId: String,
        modelContext: ModelContext
    ) async {
        let cleanedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)

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

        let pushSummary = await entrySyncService.syncPendingEntries(
            userId: cleanedUserId,
            modelContext: modelContext
        )

        let pullSummary = await entrySyncService.pullRemoteEntries(
            userId: cleanedUserId,
            modelContext: modelContext
        )

        if pushSummary.hasFailures || pullSummary.hasFailures {
            lastInitialCloudRefreshError = "Cloud refresh partially failed."
        } else {
            refreshedUserIds.insert(cleanedUserId)
        }
    }

    func reset() {
        refreshedUserIds.removeAll()
        isInitialCloudRefreshRunning = false
        lastInitialCloudRefreshError = nil
    }
}
