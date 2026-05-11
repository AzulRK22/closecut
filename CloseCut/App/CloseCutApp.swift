//
//  CloseCutApp.swift
//  CloseCut
//

import SwiftUI
import SwiftData

@main
struct CloseCutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var authService = AuthService()
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var sessionSyncViewModel = SessionSyncViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(sessionViewModel)
                .environmentObject(sessionSyncViewModel)
        }
        .modelContainer(for: appModels)
    }

    private var appModels: [any PersistentModel.Type] {
        [
            LocalEntry.self,
            LocalCircle.self,
            LocalCircleMembership.self,
            LocalUserProfile.self,
            LocalUserState.self,
            PendingAction.self,
            LocalBattleResult.self
        ]
    }
}
