//
//  CloseCutApp.swift
//  CloseCut
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct CloseCutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authService: AuthService
    @StateObject private var sessionViewModel: SessionViewModel
    @StateObject private var sessionSyncViewModel: SessionSyncViewModel

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        _authService = StateObject(
            wrappedValue: AuthService()
        )

        _sessionViewModel = StateObject(
            wrappedValue: SessionViewModel()
        )

        _sessionSyncViewModel = StateObject(
            wrappedValue: SessionSyncViewModel()
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(sessionViewModel)
                .environmentObject(sessionSyncViewModel)
        }
        .modelContainer(for: [
            LocalEntry.self,
            LocalCircle.self,
            LocalCircleMembership.self,
            LocalUserProfile.self,
            LocalUserState.self,
            PendingAction.self,
            LocalBattleResult.self
        ])
    }
}
