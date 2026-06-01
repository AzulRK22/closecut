//
//  HomeView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionSyncViewModel: SessionSyncViewModel

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalWatchlistItem.updatedAt, order: .reverse)
    private var localWatchlistItems: [LocalWatchlistItem]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    let user: AuthUser
    let profile: UserProfile

    @State private var isShowingEntryEditor = false
    @State private var isShowingQuickAdd = false
    @State private var isShowingQuickPick = false
    @State private var isShowingLibrarySearch = false

    @State private var initialQuickPickState: QuickPickState?
    @State private var externalQuickPickState: QuickPickState?

    @State private var refreshMessage: String?
    @State private var refreshBannerStyle: SyncResultBannerStyle = .neutral
    @State private var isRefreshingLibrary = false

    private let entryRepository = EntryRepository()
    private let watchlistRepository = WatchlistRepository()

    private var entries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var savedWatchlistItems: [WatchlistItem] {
        localWatchlistItems
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
            .filter { item in
                item.status == .saved &&
                item.deletedAt == nil
            }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
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

                    if let refreshMessage {
                        SyncResultBanner(
                            message: refreshMessage,
                            style: refreshBannerStyle
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    PersonalLibraryView(
                        entries: entries,
                        watchlistItems: savedWatchlistItems,
                        user: user,
                        profile: profile,
                        externalQuickPickState: externalQuickPickState,
                        onQuickAdd: {
                            isShowingQuickAdd = true
                        },
                        onCreateEntry: {
                            isShowingEntryEditor = true
                        },
                        onOpenQuickPick: { state in
                            initialQuickPickState = state
                            externalQuickPickState = state
                            isShowingQuickPick = true
                        },
                        onQuickPickStateChange: { newState in
                            initialQuickPickState = newState
                            externalQuickPickState = newState
                        },
                        onRefreshMetadata: {
                            await refreshPersonalLibrary()
                        },
                        onMarkWatchlistItemWatched: { item in
                            await markWatchlistItemAsWatched(item)
                        },
                        onDismissWatchlistItem: { item in
                            await dismissWatchlistItem(item)
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
                    },
                    onStateChange: { newState in
                        initialQuickPickState = newState
                        externalQuickPickState = newState
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

                Text(isRefreshingLibrary ? "Refreshing your library…" : "Your private taste library, picks, and memories.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            ZStack {
                Image(systemName: "rectangle.stack.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 36, height: 36)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                if isRefreshingLibrary {
                    ProgressView()
                        .scaleEffect(0.72)
                        .tint(CloseCutColors.accentLight)
                        .frame(width: 36, height: 36)
                        .background(CloseCutColors.input.opacity(0.96))
                        .clipShape(SwiftUI.Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func markWatchlistItemAsWatched(_ item: WatchlistItem) async {
        let draft = QuickAddDraft(
            title: item.displayTitle,
            type: item.type,
            releaseYear: item.releaseYear,
            quickSentiment: nil,
            watchedDateApprox: .unknown,
            externalMetadata: item.externalMetadata
        )

        do {
            let entry = try entryRepository.createQuickAddEntry(
                ownerId: user.id,
                draft: draft,
                visibility: .privateOnly,
                modelContext: modelContext
            )

            _ = try watchlistRepository.markLocalWatchlistItemWatched(
                itemId: item.id,
                modelContext: modelContext
            )

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    refreshBannerStyle = .success
                    refreshMessage = "\(entry.displayTitle) moved to Personal."
                }
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    refreshBannerStyle = .warning
                    refreshMessage = error.localizedDescription
                }
            }
        }
    }

    private func dismissWatchlistItem(_ item: WatchlistItem) async {
        do {
            _ = try watchlistRepository.softDeleteLocalWatchlistItem(
                itemId: item.id,
                modelContext: modelContext
            )

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    refreshBannerStyle = .success
                    refreshMessage = "\(item.displayTitle) was dismissed."
                }
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    refreshBannerStyle = .warning
                    refreshMessage = error.localizedDescription
                }
            }
        }
    }

    private func refreshPersonalLibrary() async {
        guard isRefreshingLibrary == false else {
            return
        }

        isRefreshingLibrary = true

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.18)) {
                refreshMessage = nil
            }
        }

        defer {
            isRefreshingLibrary = false
        }

        let syncSummary = await sessionSyncViewModel.forceRefreshCloudSession(
            userId: user.id,
            modelContext: modelContext
        )

        let currentEntries = localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }

        let enrichmentService = EntryMetadataEnrichmentService()

        let enrichmentSummary = await enrichmentService.enrichMissingMetadata(
            entries: currentEntries,
            modelContext: modelContext
        )

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.18)) {
                if syncSummary.hasFailures || enrichmentSummary.hasFailures {
                    refreshBannerStyle = .warning
                    refreshMessage = "Some items could not refresh, but your library is still safe."
                } else if enrichmentSummary.enrichedCount > 0 {
                    refreshBannerStyle = .success
                    refreshMessage = "Updated \(enrichmentSummary.enrichedCount) \(enrichmentSummary.enrichedCount == 1 ? "memory" : "memories") with posters and metadata."
                } else if syncSummary.didSyncAnything {
                    refreshBannerStyle = .success
                    refreshMessage = "Your library synced successfully."
                } else {
                    refreshBannerStyle = .neutral
                    refreshMessage = "Your library is up to date."
                }
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
            circleIds: [],
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
    .environmentObject(SessionSyncViewModel())
    .modelContainer(for: [
        LocalEntry.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self,
        LocalBattleResult.self,
        LocalWatchlistItem.self
    ], inMemory: true)
}
