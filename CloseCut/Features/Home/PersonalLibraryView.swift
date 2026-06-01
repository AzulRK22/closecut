//
//  PersonalLibraryView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct PersonalLibraryView: View {
    let entries: [Entry]
    let watchlistItems: [WatchlistItem]
    let user: AuthUser
    let profile: UserProfile

    var externalQuickPickState: QuickPickState? = nil

    let onQuickAdd: () -> Void
    let onCreateEntry: () -> Void
    let onOpenQuickPick: (QuickPickState) -> Void
    let onQuickPickStateChange: (QuickPickState) -> Void
    let onRefreshMetadata: () async -> Void
    let onMarkWatchlistItemWatched: (WatchlistItem) async -> Void
    let onDismissWatchlistItem: (WatchlistItem) async -> Void

    @StateObject private var quickPickViewModel = HomeQuickPickViewModel()

    private let quickPickTargetCount = 3

    private var activeEntries: [Entry] {
        entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmed.isEmpty == false }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var recentlyWatched: [Entry] {
        Array(activeEntries.prefix(12))
    }

    private var savedWatchlistItems: [WatchlistItem] {
        watchlistItems
            .filter { $0.status == .saved && $0.deletedAt == nil }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var quickAddsToComplete: [Entry] {
        activeEntries
            .filter { entry in
                entry.sourceType == .quickAdd &&
                (
                    entry.mood.trimmed.isEmpty ||
                    entry.takeaway.trimmed.isEmpty ||
                    entry.tags.isEmpty
                )
            }
            .prefix(12)
            .map { $0 }
    }

    private var stayedWithYou: [Entry] {
        activeEntries
            .filter { entry in
                entry.quickSentiment == .loved ||
                entry.quickSentiment == .stayedWithMe ||
                entry.intensity >= 4
            }
            .prefix(12)
            .map { $0 }
    }

    private var rewatchCandidates: [Entry] {
        activeEntries
            .filter { entry in
                let daysSinceWatch = Calendar.current.dateComponents(
                    [.day],
                    from: entry.watchedAt,
                    to: Date()
                ).day ?? 0

                let isOldEnough = daysSinceWatch >= 120
                let hasStrongSentiment = entry.quickSentiment == .loved || entry.quickSentiment == .stayedWithMe
                let hasHighIntensity = entry.intensity >= 4
                let hasHighRating = (entry.tmdbRating ?? 0) >= 7.5

                return isOldEnough && (hasStrongSentiment || hasHighIntensity || hasHighRating)
            }
            .prefix(12)
            .map { $0 }
    }

    private var sharedMemories: [Entry] {
        activeEntries
            .filter {
                $0.visibility == .circle && $0.sharedCircleIds.isEmpty == false
            }
            .prefix(12)
            .map { $0 }
    }

    private var shouldShowHistoryProgress: Bool {
        activeEntries.count > 0 && activeEntries.count < quickPickTargetCount
    }

    private var homeRefreshKey: String {
        let entryKey = activeEntries
            .map { "\($0.id)-\($0.updatedAt.timeIntervalSince1970)-\($0.posterPath ?? "")-\($0.backdropPath ?? "")" }
            .joined(separator: "|")

        let watchlistKey = savedWatchlistItems
            .map { "\($0.id)-\($0.updatedAt.timeIntervalSince1970)-\($0.posterPath ?? "")-\($0.status.rawValue)" }
            .joined(separator: "|")

        return "\(entryKey)::\(watchlistKey)"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if activeEntries.isEmpty && savedWatchlistItems.isEmpty {
                    emptyLibraryState
                } else {
                    libraryContent
                }

                Spacer(minLength: 24)
            }
            .padding(.vertical, 16)
        }
        .background(CloseCutColors.backgroundPrimary)
        .refreshable {
            await onRefreshMetadata()
        }
        .task(id: homeRefreshKey) {
            if let externalQuickPickState {
                quickPickViewModel.adoptState(
                    externalQuickPickState
                )
            } else {
                quickPickViewModel.generateStablePick(
                    userId: user.id,
                    history: activeEntries
                )
            }
        }
        .onAppear {
            if let externalQuickPickState {
                quickPickViewModel.adoptState(
                    externalQuickPickState
                )
            }
        }
        .onChange(of: externalQuickPickState) { _, newValue in
            if let newValue {
                quickPickViewModel.adoptState(
                    newValue
                )
            }
        }
    }

    private var libraryContent: some View {
        Group {
            if activeEntries.isEmpty == false {
                VStack(spacing: 16) {
                    HomeHeroQuickPickCard(
                        state: quickPickViewModel.state,
                        onQuickAdd: onQuickAdd,
                        onOpenQuickPick: {
                            onOpenQuickPick(
                                quickPickViewModel.state
                            )
                        },
                        onRefresh: {
                            Task {
                                let newState = await quickPickViewModel.showAnotherAndReturnState(
                                    history: activeEntries
                                )

                                onQuickPickStateChange(
                                    newState
                                )
                            }
                        }
                    )

                    if shouldShowHistoryProgress {
                        HistoryProgressModule(
                            currentCount: activeEntries.count,
                            targetCount: quickPickTargetCount,
                            onQuickAdd: onQuickAdd,
                            onOpenQuickPick: {
                                onOpenQuickPick(
                                    quickPickViewModel.state
                                )
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }

            if recentlyWatched.isEmpty == false {
                PosterRailView(
                    title: "Recently watched",
                    subtitle: "Your latest memories and logged watches.",
                    entries: recentlyWatched,
                    user: user,
                    profile: profile
                )
            }

            if savedWatchlistItems.isEmpty == false {
                WatchlistRailView(
                    title: "Saved for Later",
                    subtitle: "Titles waiting for the right moment.",
                    items: Array(savedWatchlistItems.prefix(12)),
                    user: user,
                    profile: profile,
                    onMarkWatched: { item in
                        await onMarkWatchlistItemWatched(item)
                    },
                    onDismiss: { item in
                        await onDismissWatchlistItem(item)
                    }
                )
            }

            if quickAddsToComplete.isEmpty == false {
                PosterRailView(
                    title: "Continue building",
                    subtitle: "Quick Adds ready to become richer memories.",
                    entries: quickAddsToComplete,
                    user: user,
                    profile: profile
                )
            }

            if stayedWithYou.isEmpty == false {
                PosterRailView(
                    title: "Because it stayed with you",
                    subtitle: "The strongest emotional signals in your library.",
                    entries: stayedWithYou,
                    user: user,
                    profile: profile
                )
            }

            if rewatchCandidates.isEmpty == false {
                PosterRailView(
                    title: "Worth rewatching",
                    subtitle: "Older meaningful watches that may deserve another look.",
                    entries: rewatchCandidates,
                    user: user,
                    profile: profile
                )
            }

            if sharedMemories.isEmpty == false {
                PosterRailView(
                    title: "Shared with Circles",
                    subtitle: "Memories you intentionally shared with trusted people.",
                    entries: sharedMemories,
                    user: user,
                    profile: profile
                )
            }

            librarySearchHint
                .padding(.horizontal, 20)
        }
    }

    private var emptyLibraryState: some View {
        VStack(spacing: 18) {
            EmptyStateView(
                title: "Start your private taste library",
                message: "Quick Add a few movies or series you already watched. CloseCut will turn them into a visual archive, better picks, and memories you can share selectively.",
                systemImage: "film.stack",
                actionTitle: "Add past watches",
                action: onQuickAdd
            )

            Button {
                onCreateEntry()
            } label: {
                Text("Log a new watch instead")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var librarySearchHint: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Looking for something specific?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Use the search icon above to browse your full Personal library by title, year, mood, tags, shared entries, or Quick Adds.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
