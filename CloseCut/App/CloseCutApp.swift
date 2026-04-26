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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
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
