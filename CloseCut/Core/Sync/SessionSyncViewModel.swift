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
        guard refreshedUserIds.contains(userId) == false else {
            return
        }

        refreshedUserIds.insert(userId)
        isInitialCloudRefreshRunning = true
        lastInitialCloudRefreshError = nil

        let summary = await entrySyncService.pullRemoteEntries(
            userId: userId,
            modelContext: modelContext
        )

        if summary.failedCount > 0 {
            lastInitialCloudRefreshError = "Cloud refresh failed."
        }

        isInitialCloudRefreshRunning = false
    }

    func reset() {
        refreshedUserIds.removeAll()
        isInitialCloudRefreshRunning = false
        lastInitialCloudRefreshError = nil
    }
}
