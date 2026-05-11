//
//  HomeView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    let user: AuthUser
    let profile: UserProfile

    @State private var isShowingEntryEditor = false
    @State private var isShowingQuickAdd = false
    @State private var isShowingQuickPick = false
    @State private var isShowingLibrarySearch = false
    @State private var initialQuickPickState: QuickPickState?

    private var entries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var hasActiveCircleMemberships: Bool {
        localMemberships
            .filter { $0.userId == user.id }
            .map { $0.domain }
            .contains { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    homeHeader

                    PersonalLibraryView(
                        entries: entries,
                        user: user,
                        profile: profile,
                        onQuickAdd: {
                            isShowingQuickAdd = true
                        },
                        onCreateEntry: {
                            isShowingEntryEditor = true
                        },
                        onOpenQuickPick: { state in
                            initialQuickPickState = state
                            isShowingQuickPick = true
                        }
                    )
                }
            }
            .navigationTitle("CloseCut")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingLibrarySearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Search library")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingQuickAdd = true
                    } label: {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Add past watches")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEntryEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("New entry")
                }
            }
            .sheet(isPresented: $isShowingLibrarySearch) {
                LibrarySearchView(
                    entries: entries,
                    user: user,
                    profile: profile
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingEntryEditor) {
                EntryEditorView(
                    user: user,
                    profile: profile,
                    hasCircleMembers: hasActiveCircleMemberships
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $isShowingQuickAdd) {
                QuickAddPastWatchesView(user: user)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingQuickPick) {
                QuickPickView(
                    entries: entries,
                    initialState: initialQuickPickState,
                    onQuickAdd: {
                        isShowingQuickPick = false
                        isShowingQuickAdd = true
                    },
                    onCreateEntry: {
                        isShowingQuickPick = false
                        isShowingEntryEditor = true
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var homeHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Personal")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Your private taste library, picks, and memories.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "rectangle.stack.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 36, height: 36)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
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
            circleIds: [],
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
    .modelContainer(for: [
        LocalEntry.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self,
        LocalBattleResult.self
    ], inMemory: true)
}
