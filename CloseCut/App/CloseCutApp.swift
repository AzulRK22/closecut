//
//  CloseCutApp.swift
//  CloseCut
//

import SwiftUI
import SwiftData

@main
struct CloseCutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authService = AuthService()
    @StateObject private var sessionViewModel = SessionViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(sessionViewModel)
        }
        .modelContainer(for: [
            LocalEntry.self,
            LocalReaction.self,
            LocalComment.self,
            LocalCircle.self,
            LocalUserProfile.self,
            PendingAction.self
        ])
    }
}
