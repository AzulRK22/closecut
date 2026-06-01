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

    @StateObject private var viewModel = DiscoverViewModel()

    @State private var actionMessage: String?
    @State private var actionBannerStyle: SyncResultBannerStyle = .neutral
    @State private var isSavingWatched = false
    @State private var isSavingWatchlist = false
    @State private var isShowingWatchlist = false

    @State private var searchText = ""
    @State private var searchResults: [TMDBMediaSearchResult] = []
    @State private var isSearching = false
    @State private var searchErrorMessage: String?

    let user: AuthUser
    let profile: UserProfile

    private let entryRepository = EntryRepository()
    private let watchlistRepository = WatchlistRepository()
    private let tmdbRepository = TMDBMediaRepository()

    private var currentUserEntries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
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
                .padding(.horizontal, 20)
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
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
                        text: "Want to Watch"
                    )
                }
                .buttonStyle(.plain)
            }
        }
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
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isSearchMode {
            searchContent
        } else if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
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
                message: "Look up a movie or series, then add it to Personal or save it to Want to Watch.",
                systemImage: "magnifyingglass",
                actionTitle: nil,
                action: nil
            )
        } else {
            DiscoverMediaRail(
                title: "Search results",
                subtitle: "Choose a title to preview before saving.",
                emptyMessage: "No matching titles found.",
                items: searchResults
            ) { media in
                viewModel.select(media)
            }
        }
    }

    private var sectionsView: some View {
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

    // MARK: - Actions

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

    private func addWatched(_ media: TMDBMediaSearchResult) async {
        guard isSavingWatched == false else {
            return
        }

        isSavingWatched = true
        defer { isSavingWatched = false }

        let draft = QuickAddDraft(
            title: media.title,
            type: media.entryType,
            releaseYear: media.releaseYear,
            quickSentiment: nil,
            watchedDateApprox: .unknown,
            externalMetadata: EntryExternalMetadata(tmdbResult: media)
        )

        do {
            let entry = try entryRepository.createQuickAddEntry(
                ownerId: user.id,
                draft: draft,
                visibility: .privateOnly,
                modelContext: modelContext
            )

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
