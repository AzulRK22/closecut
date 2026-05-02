//
//  HomeView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    let user: AuthUser
    let profile: UserProfile

    @State private var selectedSegment: HomeSegment = .timeline
    @State private var isShowingEntryEditor = false
    @State private var isShowingQuickAdd = false

    private var entries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    CloseCutHeroHeader(
                        title: "Your taste history",
                        subtitle: "Memories, moods, and picks shaped by what you watch.",
                        systemImage: "sparkles"
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    Picker("Home section", selection: $selectedSegment) {
                        ForEach(HomeSegment.allCases) { segment in
                            Text(segment.title)
                                .tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    switch selectedSegment {
                    case .timeline:
                        TimelineView(
                            entries: entries,
                            user: user,
                            profile: profile,
                            onQuickAdd: {
                                isShowingQuickAdd = true
                            },
                            onCreateEntry: {
                                isShowingEntryEditor = true
                            },
                            onOpenQuickPick: {
                                selectedSegment = .quickPick
                            }
                        )

                    case .quickPick:
                        QuickPickView(
                            entries: entries,
                            onQuickAdd: {
                                isShowingQuickAdd = true
                            },
                            onCreateEntry: {
                                isShowingEntryEditor = true
                            }
                        )
                    }
                }
            }
            .navigationTitle("CloseCut")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingQuickAdd = true
                    } label: {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("Add past watches")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEntryEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("New entry")
                }
            }
            .sheet(isPresented: $isShowingEntryEditor) {
                EntryEditorView(
                    user: user,
                    profile: profile,
                    hasCircleMembers: false
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $isShowingQuickAdd) {

                QuickAddPastWatchesView(user: user)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    HomeView(
        user: AuthUser(
            id: "preview-user",
            email: "preview@closecut.dev",
            displayName: "Preview",
            photoURL: nil
        ),
        profile: UserProfile(
            id: "preview-user",
            displayName: "Preview",
            email: "preview@closecut.dev",
            photoURL: nil,
            circleId: nil,
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
    .environmentObject(AuthService())
    .modelContainer(for: [
        LocalEntry.self,
        LocalReaction.self,
        LocalComment.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self
    ], inMemory: true)
}
