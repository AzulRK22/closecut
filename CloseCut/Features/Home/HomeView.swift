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

    @Query(sort: \LocalCircle.updatedAt, order: .reverse)
    private var localCircles: [LocalCircle]

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

    @State private var selectedMediaForWatchPlan: WatchPlanMediaSnapshot?
    @State private var showCreateWatchPlanSheet = false
    @State private var isCreatingWatchPlan = false
    @State private var watchPlanErrorMessage: String?

    private let entryRepository = EntryRepository()
    private let watchlistRepository = WatchlistRepository()
    private let watchPlanRepository = WatchPlanRepository()
    private let watchPlanSyncService = WatchPlanSyncService()

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

    private var memberships: [CircleMembership] {
        localMemberships
            .filter { $0.userId == user.id }
            .map { $0.domain }
            .filter { $0.isActive }
            .sorted { first, second in
                if first.isOwner != second.isOwner {
                    return first.isOwner && !second.isOwner
                }

                return first.updatedAt > second.updatedAt
            }
    }

    private var circlesById: [String: CloseCircle] {
        Dictionary(
            uniqueKeysWithValues: localCircles.map { ($0.id, $0.domain) }
        )
    }

    private var circleRows: [(circle: CloseCircle, membership: CircleMembership)] {
        memberships.compactMap { membership in
            guard let circle = circlesById[membership.circleId],
                  circle.deletedAt == nil else {
                return nil
            }

            return (circle, membership)
        }
    }

    private var hasActiveCircleMemberships: Bool {
        memberships.isEmpty == false
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
                        },
                        onPlanWatchlistItemWithCircle: { item in
                            openCreateWatchPlanFromWatchlistItem(item)
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
            .sheet(isPresented: $showCreateWatchPlanSheet) {
                CreateWatchPlanSheet(
                    circleRows: circleRows,
                    selectedCircleId: circleRows.first?.circle.id,
                    initialMedia: selectedMediaForWatchPlan,
                    isCreating: isCreatingWatchPlan,
                    onCancel: {
                        showCreateWatchPlanSheet = false
                        selectedMediaForWatchPlan = nil
                    },
                    onCreate: { draft in
                        Task {
                            await createWatchPlanFromHomeWatchlist(draft)
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert("Watch Together failed", isPresented: Binding(
                get: { watchPlanErrorMessage != nil },
                set: { if !$0 { watchPlanErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(watchPlanErrorMessage ?? "Unknown error.")
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

    // MARK: - Watchlist Personal Actions

    private func markWatchlistItemAsWatched(_ item: WatchlistItem) async {
        let draft = EntryDraftFactory.quickAddFromWatchlistItem(item)

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

    // MARK: - Watch Together From Home Watchlist

    private func openCreateWatchPlanFromWatchlistItem(
        _ item: WatchlistItem
    ) {
        guard circleRows.isEmpty == false else {
            withAnimation(.easeInOut(duration: 0.18)) {
                refreshBannerStyle = .warning
                refreshMessage = "Create or join a Circle before planning this title."
            }

            return
        }

        selectedMediaForWatchPlan = WatchPlanMediaSnapshotFactory.fromWatchlistItem(item)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            showCreateWatchPlanSheet = true
        }
    }

    private func createWatchPlanFromHomeWatchlist(
        _ draft: WatchPlanCreationDraft
    ) async {
        guard isCreatingWatchPlan == false else {
            return
        }

        guard let selectedRow = circleRows.first(where: { row in
            row.circle.id == draft.circleId
        }) else {
            watchPlanErrorMessage = "Choose a valid Circle before creating this plan."
            return
        }

        let invitedMemberIds = draft.invitedMemberIds.filter { memberId in
            memberId.trimmed.isEmpty == false &&
            memberId.trimmed != user.id.trimmed
        }

        guard invitedMemberIds.isEmpty == false else {
            watchPlanErrorMessage = "Select at least one Circle member to invite."
            return
        }

        isCreatingWatchPlan = true
        watchPlanErrorMessage = nil

        defer {
            isCreatingWatchPlan = false
        }

        do {
            let createdPlan = try watchPlanRepository.createLocalPlan(
                ownerId: user.id,
                ownerDisplayName: profile.displayName,
                circleId: selectedRow.circle.id,
                circleName: selectedRow.circle.displayName,
                title: draft.planTitle,
                note: draft.note,
                media: draft.media,
                proposedStartAt: nil,
                proposedEndAt: nil,
                proposedDateText: draft.proposedDateText,
                locationType: draft.locationType,
                locationName: draft.locationName,
                locationAddress: draft.locationAddress,
                streamingService: draft.streamingService,
                invitedMemberIds: invitedMemberIds,
                source: .watchlist,
                modelContext: modelContext
            )

            let syncSummary = await watchPlanSyncService.syncPendingWatchTogetherItems(
                userId: user.id,
                modelContext: modelContext
            )

            await MainActor.run {
                showCreateWatchPlanSheet = false
                selectedMediaForWatchPlan = nil

                withAnimation(.easeInOut(duration: 0.18)) {
                    if syncSummary.hasFailures {
                        refreshBannerStyle = .warning
                        refreshMessage = "Plan created locally, but it could not sync yet. It will retry later."
                    } else {
                        refreshBannerStyle = .success
                        refreshMessage = "\(createdPlan.media.displayTitle) was planned with your Circle."
                    }
                }
            }
        } catch {
            await MainActor.run {
                watchPlanErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Refresh

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
        LocalWatchlistItem.self,
        LocalWatchPlan.self,
        LocalWatchPlanResponse.self
    ], inMemory: true)
}
