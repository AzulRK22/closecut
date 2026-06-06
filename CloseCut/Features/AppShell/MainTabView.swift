//
//  MainTabView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

private enum MainTab: String {
    case personal
    case discover
    case circle
    case battle
    case settings

    var title: String {
        switch self {
        case .personal:
            return "Personal"
        case .discover:
            return "Discover"
        case .circle:
            return "Social"
        case .battle:
            return "Battle"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .personal:
            return "film.stack"
        case .discover:
            return "sparkles"
        case .circle:
            return "person.2.fill"
        case .battle:
            return "bolt.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var sessionSyncViewModel: SessionSyncViewModel
    @Environment(\.modelContext) private var modelContext

    let user: AuthUser
    let profile: UserProfile

    @SceneStorage("MainTabView.selectedTab")
    private var selectedTabRawValue: String = MainTab.personal.rawValue

    private var selectedTab: Binding<MainTab> {
        Binding(
            get: {
                MainTab(rawValue: selectedTabRawValue) ?? .personal
            },
            set: { newValue in
                selectedTabRawValue = newValue.rawValue
            }
        )
    }

    var body: some View {
        TabView(selection: selectedTab) {
            NavigationStack {
                HomeView(
                    user: user,
                    profile: profile
                )
            }
            .tabItem {
                Label(
                    MainTab.personal.title,
                    systemImage: MainTab.personal.systemImage
                )
            }
            .tag(MainTab.personal)

            NavigationStack {
                DiscoverView(
                    user: user,
                    profile: profile
                )
            }
            .tabItem {
                Label(
                    MainTab.discover.title,
                    systemImage: MainTab.discover.systemImage
                )
            }
            .tag(MainTab.discover)

            NavigationStack {
                CircleView(
                    user: user,
                    profile: profile
                )
            }
            .tabItem {
                Label(
                    MainTab.circle.title,
                    systemImage: MainTab.circle.systemImage
                )
            }
            .tag(MainTab.circle)

            NavigationStack {
                BattleView(
                    user: user,
                    profile: profile
                )
            }
            .tabItem {
                Label(
                    MainTab.battle.title,
                    systemImage: MainTab.battle.systemImage
                )
            }
            .tag(MainTab.battle)

            NavigationStack {
                SettingsView(
                    user: user,
                    profile: profile
                )
            }
            .tabItem {
                Label(
                    MainTab.settings.title,
                    systemImage: MainTab.settings.systemImage
                )
            }
            .tag(MainTab.settings)
        }
        .tint(CloseCutColors.accent)
        .preferredColorScheme(.dark)
        .task(id: user.id) {
            await sessionSyncViewModel.runInitialCloudRefreshIfNeeded(
                userId: user.id,
                modelContext: modelContext
            )
        }
    }
}
