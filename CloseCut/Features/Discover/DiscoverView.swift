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

    let user: AuthUser
    let profile: UserProfile

    private let entryRepository = EntryRepository()
    private let watchlistRepository = WatchlistRepository()

    private var currentUserEntries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

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
                await viewModel.refresh(entries: currentUserEntries)
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingWatchlist = true
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Open Want to Watch")
            }
        }
        .task(id: user.id) {
            await viewModel.loadIfNeeded(entries: currentUserEntries)
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
                },
                onStartBattle: {
                    showComingSoon("Battle integration is coming after Watchlist.")
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingWatchlist) {
            NavigationStack {
                WatchlistView(
                    user: user,
                    profile: profile,
                    onOpenDiscover: nil
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discover")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Find what could become part of your taste history next.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 42, height: 42)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
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

                DiscoverSignalPill(
                    icon: "bookmark.fill",
                    text: "Want to Watch"
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
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
            actionMessage = "\(entry.displayTitle) was added to your history."
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

    private func showComingSoon(_ message: String) {
        actionBannerStyle = .neutral
        actionMessage = message
        viewModel.clearSelection()
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
