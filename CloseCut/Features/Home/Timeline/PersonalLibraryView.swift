//
//  PersonalLibraryView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct PersonalLibraryView: View {
    let entries: [Entry]
    let user: AuthUser
    let profile: UserProfile
    let onQuickAdd: () -> Void
    let onCreateEntry: () -> Void
    let onOpenQuickPick: () -> Void

    @State private var searchQuery = ""

    private let quickPickTargetCount = 3

    private var activeEntries: [Entry] {
        entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .sorted { $0.watchedAt > $1.watchedAt }
    }

    private var isSearching: Bool {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private var searchResults: [Entry] {
        EntrySearchFilter.filter(
            entries: activeEntries,
            query: searchQuery
        )
    }

    private var recentlyWatched: [Entry] {
        Array(activeEntries.prefix(12))
    }

    private var stayedWithYou: [Entry] {
        activeEntries.filter { entry in
            entry.quickSentiment == .loved ||
            entry.quickSentiment == .stayedWithMe ||
            entry.intensity >= 4
        }
    }

    private var rewatchCandidates: [Entry] {
        activeEntries.filter { entry in
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
    }

    private var sharedMemories: [Entry] {
        activeEntries.filter {
            $0.visibility == .circle && $0.sharedCircleIds.isEmpty == false
        }
    }

    private var enrichedMemories: [Entry] {
        activeEntries.filter {
            $0.posterPath != nil ||
            $0.overview?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
            $0.tmdbRating != nil
        }
    }

    private var shouldShowHistoryProgress: Bool {
        activeEntries.count > 0 && activeEntries.count < quickPickTargetCount
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                PersonalSearchBar(query: $searchQuery)
                    .padding(.horizontal, 20)

                if isSearching {
                    searchResultsSection
                } else if activeEntries.isEmpty {
                    emptyLibraryState
                } else {
                    libraryContent
                }

                Spacer(minLength: 24)
            }
            .padding(.vertical, 16)
        }
        .background(CloseCutColors.backgroundPrimary)
    }

    private var libraryContent: some View {
        Group {
            VStack(spacing: 16) {
                HomeHeroQuickPickCard(
                    entries: activeEntries,
                    onQuickAdd: onQuickAdd,
                    onOpenQuickPick: onOpenQuickPick
                )

                PersonalTimelineSummaryCard(
                    entries: activeEntries,
                    onQuickAdd: onQuickAdd,
                    onCreateEntry: onCreateEntry
                )

                if shouldShowHistoryProgress {
                    HistoryProgressModule(
                        currentCount: activeEntries.count,
                        targetCount: quickPickTargetCount,
                        onQuickAdd: onQuickAdd,
                        onOpenQuickPick: onOpenQuickPick
                    )
                }
            }
            .padding(.horizontal, 20)

            PosterRailView(
                title: "Recently watched",
                subtitle: "Your latest memories, quick adds, and logged watches.",
                entries: recentlyWatched,
                user: user,
                profile: profile
            )

            if stayedWithYou.isEmpty == false {
                PosterRailView(
                    title: "Stayed with you",
                    subtitle: "The titles with the strongest emotional signal.",
                    entries: stayedWithYou,
                    user: user,
                    profile: profile
                )
            }

            if rewatchCandidates.isEmpty == false {
                PosterRailView(
                    title: "Worth revisiting",
                    subtitle: "Older meaningful watches that may deserve another look.",
                    entries: rewatchCandidates,
                    user: user,
                    profile: profile
                )
            }

            if enrichedMemories.isEmpty == false {
                PosterRailView(
                    title: "With rich metadata",
                    subtitle: "Entries connected to posters, ratings, or overview data.",
                    entries: enrichedMemories,
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

            allHistorySection
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            TimelineSectionHeader(
                title: searchResults.isEmpty ? "No matches" : "Search results",
                subtitle: searchResults.isEmpty
                    ? "Try a title, mood, tag, year, or Circle status."
                    : "\(searchResults.count) \(searchResults.count == 1 ? "memory" : "memories") found."
            )
            .padding(.horizontal, 20)

            if searchResults.isEmpty {
                EmptyStateView(
                    title: "Nothing found",
                    message: "Try searching by title, mood, tag, year, movie, series, shared, private, or quick add.",
                    systemImage: "magnifyingglass",
                    actionTitle: nil,
                    action: nil
                )
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(searchResults) { entry in
                        NavigationLink {
                            EntryDetailView(
                                entry: entry,
                                user: user,
                                profile: profile
                            )
                        } label: {
                            EntryCardView(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var emptyLibraryState: some View {
        VStack(spacing: 18) {
            PersonalTimelineSummaryCard(
                entries: activeEntries,
                onQuickAdd: onQuickAdd,
                onCreateEntry: onCreateEntry
            )

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

    private var allHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimelineSectionHeader(
                title: "All history",
                subtitle: "\(activeEntries.count) private \(activeEntries.count == 1 ? "memory" : "memories") in your archive."
            )

            LazyVStack(spacing: 14) {
                ForEach(activeEntries) { entry in
                    NavigationLink {
                        EntryDetailView(
                            entry: entry,
                            user: user,
                            profile: profile
                        )
                    } label: {
                        EntryCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    PersonalLibraryView(
        entries: [],
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
        ),
        onQuickAdd: {},
        onCreateEntry: {},
        onOpenQuickPick: {}
    )
}
