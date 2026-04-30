//
//  MainTabView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject private var sessionSyncViewModel: SessionSyncViewModel
    @Environment(\.modelContext) private var modelContext
    
    let user: AuthUser
    let profile: UserProfile

    var body: some View {
        TabView {
            HomeView(user: user, profile: profile)
                .tabItem {
                    Label("Timeline", systemImage: "film.stack")
                }

            CircleView(user: user, profile: profile)
                .tabItem {
                    Label("Circle", systemImage: "person.2.circle")
                }

            SettingsView(user: user, profile: profile)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(CloseCutColors.accent)
        .preferredColorScheme(.dark)
        .task {
            await sessionSyncViewModel.runInitialCloudRefreshIfNeeded(
                userId: user.id,
                modelContext: modelContext
            )
        }
    }
}
