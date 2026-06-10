//
//  WatchlistView.swift
//  CloseCut
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \LocalWatchlistItem.updatedAt, order: .reverse)
    private var localWatchlistItems: [LocalWatchlistItem]

    @Query(sort: \LocalCircle.updatedAt, order: .reverse)
    private var localCircles: [LocalCircle]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    let user: AuthUser
    let profile: UserProfile

    @State private var selectedFilter: WatchlistStatusFilter = .saved
    @State private var selectedItem: WatchlistItem?
    @State private var actionMessage: String?
    @State private var actionBannerStyle: SyncResultBannerStyle = .neutral
    @State private var activeActionItemId: String?

    @State private var selectedMediaForWatchPlan: WatchPlanMediaSnapshot?
    @State private var showCreateWatchPlanSheet = false
    @State private var isCreatingWatchPlan = false
    @State private var watchPlanErrorMessage: String?

    private let entryRepository = EntryRepository()
    private let watchlistRepository = WatchlistRepository()
    private let watchPlanRepository = WatchPlanRepository()
    private let watchPlanSyncService = WatchPlanSyncService()

    private var allItems: [WatchlistItem] {
        localWatchlistItems
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var filteredItems: [WatchlistItem] {
        allItems.filter { item in
            switch selectedFilter {
            case .saved:
                return item.status == .saved && item.deletedAt == nil
            case .watched:
                return item.status == .watched && item.deletedAt == nil
            case .dismissed:
                return item.status == .dismissed || item.deletedAt != nil
            }
        }
    }

    private var savedCount: Int {
        allItems.filter { $0.status == .saved && $0.deletedAt == nil }.count
    }

    private var watchedCount: Int {
        allItems.filter { $0.status == .watched && $0.deletedAt == nil }.count
    }

    private var dismissedCount: Int {
        allItems.filter { $0.status == .dismissed || $0.deletedAt != nil }.count
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

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header

                        filterPicker

                        if let actionMessage {
                            SyncResultBanner(
                                message: actionMessage,
                                style: actionBannerStyle
                            )
                        }

                        content

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Want to Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                    .accessibilityLabel("Close Want to Watch")
                }
            }
            .sheet(item: $selectedItem) { item in
                WatchlistItemDetailSheet(
                    item: item,
                    isProcessing: activeActionItemId == item.id,
                    onMarkWatched: {
                        Task {
                            await markAsWatched(item)
                        }
                    },
                    onPlanWithCircle: {
                        openCreateWatchPlanFromWatchlist(item)
                    },
                    onDismiss: {
                        Task {
                            await dismissItem(item)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
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
                            await createWatchPlanFromWatchlist(draft)
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
            .preferredColorScheme(.dark)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Want to Watch")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Your private queue of titles waiting for the right moment.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "bookmark.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 42, height: 42)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
            }

            HStack(spacing: 10) {
                watchlistStat(
                    value: "\(savedCount)",
                    label: "saved"
                )

                watchlistStat(
                    value: "\(watchedCount)",
                    label: "watched"
                )

                watchlistStat(
                    value: "\(dismissedCount)",
                    label: "dismissed"
                )
            }
        }
    }

    private func watchlistStat(
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(WatchlistStatusFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: filter.systemImage)
                            .font(.caption2.weight(.semibold))

                        Text(filter.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedFilter == filter ? .white : CloseCutColors.textSecondary)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(selectedFilter == filter ? CloseCutColors.accent : CloseCutColors.input)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var content: some View {
        if filteredItems.isEmpty {
            WatchlistEmptyStateView(filter: selectedFilter)
        } else {
            LazyVStack(spacing: 14) {
                ForEach(filteredItems) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        WatchlistItemCardView(
                            item: item,
                            isProcessing: activeActionItemId == item.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Personal Actions

    private func markAsWatched(_ item: WatchlistItem) async {
        guard activeActionItemId == nil else {
            return
        }

        activeActionItemId = item.id
        defer { activeActionItemId = nil }

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

            actionBannerStyle = .success
            actionMessage = "\(entry.displayTitle) moved to Personal."
            selectedItem = nil

            withAnimation(.easeInOut(duration: 0.18)) {
                selectedFilter = .saved
            }
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func dismissItem(_ item: WatchlistItem) async {
        guard activeActionItemId == nil else {
            return
        }

        activeActionItemId = item.id
        defer { activeActionItemId = nil }

        do {
            _ = try watchlistRepository.softDeleteLocalWatchlistItem(
                itemId: item.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(item.displayTitle) was removed from Want to Watch."
            selectedItem = nil
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    // MARK: - Watch Together Actions

    private func openCreateWatchPlanFromWatchlist(
        _ item: WatchlistItem
    ) {
        guard circleRows.isEmpty == false else {
            actionBannerStyle = .warning
            actionMessage = "Create or join a Circle before planning this title."
            selectedItem = nil
            return
        }

        selectedMediaForWatchPlan = WatchPlanMediaSnapshotFactory.fromWatchlistItem(item)
        selectedItem = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            showCreateWatchPlanSheet = true
        }
    }

    private func createWatchPlanFromWatchlist(
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

            showCreateWatchPlanSheet = false
            selectedMediaForWatchPlan = nil

            if syncSummary.hasFailures {
                actionBannerStyle = .warning
                actionMessage = "Plan created locally, but it could not sync yet. It will retry later."
            } else {
                actionBannerStyle = .success
                actionMessage = "\(createdPlan.media.displayTitle) was planned with your Circle."
            }
        } catch {
            watchPlanErrorMessage = error.localizedDescription
        }
    }
}
