//
//  CloseCutApp.swift
//  CloseCut
//

import SwiftUI
import SwiftData

@main
struct CloseCutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var authService: AuthService
    @StateObject private var sessionViewModel: SessionViewModel
    @StateObject private var sessionSyncViewModel: SessionSyncViewModel

    init() {
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
        .modelContainer(for: AppModelContainer.models)
    }
}
