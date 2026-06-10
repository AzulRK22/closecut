//
//  DiscoverView.swift
//  CloseCut
//

import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LocalEntry.updatedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalWatchlistItem.updatedAt, order: .reverse)
    private var localWatchlistItems: [LocalWatchlistItem]

    @Query(sort: \LocalCircle.updatedAt, order: .reverse)
    private var localCircles: [LocalCircle]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    @StateObject private var viewModel = DiscoverViewModel()

    @State private var actionMessage: String?
    @State private var actionBannerStyle: SyncResultBannerStyle = .neutral

    @State private var isSavingWatched = false
    @State private var isSavingWatchlist = false
    @State private var isShowingWatchlist = false
    @State private var activeWatchlistRailActionItemId: String?

    @State private var searchText = ""
    @State private var searchResults: [TMDBMediaSearchResult] = []
    @State private var isSearching = false
    @State private var searchErrorMessage: String?

    @State private var selectedMediaForWatchPlan: WatchPlanMediaSnapshot?
    @State private var showCreateWatchPlanSheet = false
    @State private var isCreatingWatchPlan = false
    @State private var watchPlanErrorMessage: String?

    let user: AuthUser
    let profile: UserProfile

    private let entryRepository = EntryRepository()
    private let watchlistRepository = WatchlistRepository()
    private let tmdbRepository = TMDBMediaRepository()
    private let watchPlanRepository = WatchPlanRepository()
    private let watchPlanSyncService = WatchPlanSyncService()

    private var currentUserEntries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
            .filter { $0.deletedAt == nil }
    }

    private var currentUserWatchlistItems: [WatchlistItem] {
        localWatchlistItems
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var savedWatchlistItems: [WatchlistItem] {
        currentUserWatchlistItems.filter { item in
            item.status == .saved && item.deletedAt == nil
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

    private var trimmedSearchText: String {
        searchText.trimmed
    }

    private var isSearchMode: Bool {
        trimmedSearchText.isEmpty == false
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    searchBar

                    if let actionMessage {
                        SyncResultBanner(
                            message: actionMessage,
                            style: actionBannerStyle
                        )
                    }

                    content

                    Spacer(minLength: 28)
                }
                .padding(.vertical, 16)
            }
            .refreshable {
                await refreshCurrentMode()
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task(id: user.id) {
            await viewModel.loadIfNeeded(entries: currentUserEntries)
        }
        .task(id: trimmedSearchText) {
            await runSearchIfNeeded()
        }
        .sheet(isPresented: $isShowingWatchlist) {
            WatchlistView(
                user: user,
                profile: profile
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $viewModel.selectedMedia) { media in
            DiscoverMediaDetailSheet(
                media: media,
                isAlreadyInPersonal: isMediaAlreadyInPersonal(media),
                isSavedToWatchlist: isMediaSavedToWatchlist(media),
                isSavingWatched: isSavingWatched,
                isSavingWatchlist: isSavingWatchlist,
                onAddWatched: {
                    Task {
                        await addWatched(media)
                    }
                },
                onSaveForLater: {
                    Task {
                        await saveForLater(media)
                    }
                },
                onRemoveFromWatchlist: {
                    Task {
                        await removeFromWatchlist(media)
                    }
                },
                onCreateWatchPlan: {
                    openCreateWatchPlanFromDiscover(media)
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
                        await createWatchPlanFromDiscover(draft)
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discover")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Find what could become part of your Personal library next.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    isShowingWatchlist = true
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(width: 42, height: 42)
                        .background(CloseCutColors.input)
                        .clipShape(SwiftUI.Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Want to Watch")
            }

            HStack(spacing: 8) {
                DiscoverSignalPill(
                    icon: "flame.fill",
                    text: "Trending"
                )

                DiscoverSignalPill(
                    icon: "wand.and.stars",
                    text: "Taste-based"
                )

                Button {
                    isShowingWatchlist = true
                } label: {
                    DiscoverSignalPill(
                        icon: "bookmark.fill",
                        text: "\(savedWatchlistItems.count) saved"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            TextField(
                "Search movies or series",
                text: $searchText
            )
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .font(.subheadline)
            .foregroundStyle(CloseCutColors.textPrimary)
            .submitLabel(.search)
            .onSubmit {
                Task {
                    await searchNow(query: trimmedSearchText)
                }
            }

            if trimmedSearchText.isEmpty == false {
                Button {
                    searchText = ""
                    searchResults = []
                    searchErrorMessage = nil
                    isSearching = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isSearchMode {
            searchContent
                .padding(.horizontal, 20)
        } else if viewModel.isLoading {
            loadingView
                .padding(.horizontal, 20)
        } else if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
                .padding(.horizontal, 20)
        } else if viewModel.hasContent {
            sectionsView
        } else {
            EmptyStateView(
                title: "Nothing to discover yet",
                message: "Try refreshing or check your TMDB configuration.",
                systemImage: "sparkles",
                actionTitle: "Refresh",
                action: {
                    Task {
                        await viewModel.refresh(entries: currentUserEntries)
                    }
                }
            )
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if isSearching {
            loadingSearchView
        } else if let searchErrorMessage {
            EmptyStateView(
                title: "Search couldn't load",
                message: searchErrorMessage,
                systemImage: "wifi.exclamationmark",
                actionTitle: "Try again",
                action: {
                    Task {
                        await searchNow(query: trimmedSearchText)
                    }
                }
            )
        } else if searchResults.isEmpty {
            EmptyStateView(
                title: "Search Discover",
                message: "Look up a movie or series, then add it to Personal, save it to Want to Watch, or plan it with a Circle.",
                systemImage: "magnifyingglass",
                actionTitle: nil,
                action: nil
            )
        } else {
            DiscoverMediaRail(
                title: "Search results",
                subtitle: "Choose a title to preview before saving or planning.",
                emptyMessage: "No matching titles found.",
                items: searchResults
            ) { media in
                viewModel.select(media)
            }
        }
    }

    private var sectionsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            WatchlistRailView(
                title: "Ready from Want to Watch",
                subtitle: "Saved titles waiting for the right moment.",
                items: savedWatchlistItems,
                user: user,
                profile: profile,
                onMarkWatched: { item in
                    await markWatchlistItemAsWatched(item)
                },
                onPlanWithCircle: { item in
                    openCreateWatchPlanFromWatchlistRail(item)
                },
                onDismiss: { item in
                    await dismissWatchlistItem(item)
                }
            )

            VStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.sections) { section in
                    DiscoverMediaRail(
                        title: section.id.title,
                        subtitle: section.id.subtitle,
                        emptyMessage: section.id.emptyMessage,
                        items: section.items
                    ) { media in
                        viewModel.select(media)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(CloseCutColors.input)
                        .frame(width: 180, height: 18)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(CloseCutColors.card)
                                    .frame(width: 132, height: 230)
                            }
                        }
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityLabel("Loading Discover")
    }

    private var loadingSearchView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Searching…")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(CloseCutColors.card)
                        .frame(width: 132, height: 230)
                }
            }
        }
        .redacted(reason: .placeholder)
    }

    private func errorView(_ message: String) -> some View {
        EmptyStateView(
            title: "Discover couldn't load",
            message: message,
            systemImage: "wifi.exclamationmark",
            actionTitle: "Try again",
            action: {
                Task {
                    await viewModel.refresh(entries: currentUserEntries)
                }
            }
        )
    }

    // MARK: - State Checks

    private func isMediaSavedToWatchlist(
        _ media: TMDBMediaSearchResult
    ) -> Bool {
        currentUserWatchlistItems.contains { item in
            item.status == .saved &&
            item.deletedAt == nil &&
            item.matchesTMDBMedia(media)
        }
    }

    private func matchingSavedWatchlistItem(
        for media: TMDBMediaSearchResult
    ) -> WatchlistItem? {
        currentUserWatchlistItems.first { item in
            item.status == .saved &&
            item.deletedAt == nil &&
            item.matchesTMDBMedia(media)
        }
    }

    private func isMediaAlreadyInPersonal(
        _ media: TMDBMediaSearchResult
    ) -> Bool {
        currentUserEntries.contains { entry in
            if let tmdbId = entry.tmdbId,
               let mediaTypeRaw = entry.tmdbMediaTypeRaw {
                return tmdbId == media.tmdbId &&
                    mediaTypeRaw == media.mediaType.rawValue
            }

            return entry.displayTitle.normalizedTitleKey == media.title.normalizedTitleKey &&
                entry.type == media.entryType &&
                yearsAreCompatible(entry.releaseYear, media.releaseYear)
        }
    }

    private func yearsAreCompatible(
        _ first: Int?,
        _ second: Int?
    ) -> Bool {
        if let first, let second {
            return first == second
        }

        return first == nil || second == nil
    }

    // MARK: - Refresh / Search

    private func refreshCurrentMode() async {
        if isSearchMode {
            await searchNow(query: trimmedSearchText)
        } else {
            await viewModel.refresh(entries: currentUserEntries)
        }
    }

    private func runSearchIfNeeded() async {
        let query = trimmedSearchText

        guard query.count >= TMDBConfiguration.minimumSearchQueryLength else {
            searchResults = []
            searchErrorMessage = nil
            isSearching = false
            return
        }

        try? await Task.sleep(nanoseconds: 450_000_000)

        guard query == trimmedSearchText else {
            return
        }

        await searchNow(query: query)
    }

    private func searchNow(query: String) async {
        let cleanedQuery = query.trimmed

        guard cleanedQuery.count >= TMDBConfiguration.minimumSearchQueryLength else {
            searchResults = []
            searchErrorMessage = nil
            isSearching = false
            return
        }

        isSearching = true
        searchErrorMessage = nil

        do {
            let results = try await tmdbRepository.searchMedia(
                query: cleanedQuery
            )

            guard cleanedQuery == trimmedSearchText else {
                return
            }

            searchResults = results
        } catch {
            guard cleanedQuery == trimmedSearchText else {
                return
            }

            searchResults = []
            searchErrorMessage = error.localizedDescription
        }

        guard cleanedQuery == trimmedSearchText else {
            return
        }

        isSearching = false
    }

    // MARK: - Discover Actions

    private func addWatched(_ media: TMDBMediaSearchResult) async {
        guard isSavingWatched == false else {
            return
        }

        guard isMediaAlreadyInPersonal(media) == false else {
            actionBannerStyle = .neutral
            actionMessage = "\(media.title) is already in Personal."
            viewModel.clearSelection()
            return
        }

        isSavingWatched = true
        defer { isSavingWatched = false }

        let draft = EntryDraftFactory.quickAddFromTMDBResult(media)

        do {
            let entry = try entryRepository.createQuickAddEntry(
                ownerId: user.id,
                draft: draft,
                visibility: .privateOnly,
                modelContext: modelContext
            )

            if let existingItem = matchingSavedWatchlistItem(for: media) {
                _ = try watchlistRepository.markLocalWatchlistItemWatched(
                    itemId: existingItem.id,
                    modelContext: modelContext
                )
            }

            actionBannerStyle = .success
            actionMessage = "\(entry.displayTitle) was added to Personal."
            viewModel.clearSelection()
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func saveForLater(_ media: TMDBMediaSearchResult) async {
        guard isSavingWatchlist == false else {
            return
        }

        guard isMediaAlreadyInPersonal(media) == false else {
            actionBannerStyle = .neutral
            actionMessage = "\(media.title) is already in Personal."
            viewModel.clearSelection()
            return
        }

        guard isMediaSavedToWatchlist(media) == false else {
            actionBannerStyle = .neutral
            actionMessage = "\(media.title) is already saved to Want to Watch."
            viewModel.clearSelection()
            return
        }

        isSavingWatchlist = true
        defer { isSavingWatchlist = false }

        do {
            let item = try watchlistRepository.createLocalWatchlistItem(
                ownerId: user.id,
                media: media,
                source: .discover,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(item.displayTitle) was saved to Want to Watch."
            viewModel.clearSelection()
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func removeFromWatchlist(
        _ media: TMDBMediaSearchResult
    ) async {
        guard isSavingWatchlist == false else {
            return
        }

        guard let item = matchingSavedWatchlistItem(for: media) else {
            actionBannerStyle = .neutral
            actionMessage = "\(media.title) is not currently saved."
            viewModel.clearSelection()
            return
        }

        isSavingWatchlist = true
        defer { isSavingWatchlist = false }

        do {
            _ = try watchlistRepository.softDeleteLocalWatchlistItem(
                itemId: item.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(item.displayTitle) was removed from Want to Watch."
            viewModel.clearSelection()
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    // MARK: - Watch Together from Discover

    private func openCreateWatchPlanFromDiscover(
        _ media: TMDBMediaSearchResult
    ) {
        guard circleRows.isEmpty == false else {
            actionBannerStyle = .warning
            actionMessage = "Create or join a Circle before planning this title."
            viewModel.clearSelection()
            return
        }

        selectedMediaForWatchPlan = WatchPlanMediaSnapshotFactory.fromTMDBResult(
            media,
            source: .discover
        )

        viewModel.clearSelection()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            showCreateWatchPlanSheet = true
        }
    }

    private func createWatchPlanFromDiscover(
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
                source: .discover,
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
    private func openCreateWatchPlanFromWatchlistRail(
        _ item: WatchlistItem
    ) {
        guard circleRows.isEmpty == false else {
            actionBannerStyle = .warning
            actionMessage = "Create or join a Circle before planning this title."
            return
        }

        selectedMediaForWatchPlan = WatchPlanMediaSnapshotFactory.fromWatchlistItem(item)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            showCreateWatchPlanSheet = true
        }
    }

    // MARK: - Watchlist Rail Actions

    private func markWatchlistItemAsWatched(
        _ item: WatchlistItem
    ) async {
        guard activeWatchlistRailActionItemId == nil else {
            return
        }

        activeWatchlistRailActionItemId = item.id
        defer { activeWatchlistRailActionItemId = nil }

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
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func dismissWatchlistItem(
        _ item: WatchlistItem
    ) async {
        guard activeWatchlistRailActionItemId == nil else {
            return
        }

        activeWatchlistRailActionItemId = item.id
        defer { activeWatchlistRailActionItemId = nil }

        do {
            _ = try watchlistRepository.softDeleteLocalWatchlistItem(
                itemId: item.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(item.displayTitle) was removed from Want to Watch."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }
}

private struct DiscoverSignalPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
}
