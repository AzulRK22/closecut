//
//  LibrarySearchView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct LibrarySearchView: View {
    @Environment(\.dismiss) private var dismiss

    let entries: [Entry]
    let user: AuthUser
    let profile: UserProfile

    @State private var searchQuery = ""
    @State private var selectedFilter: LibraryBrowseFilter = .all
    @State private var selectedSort: LibrarySortOption = .recent

    @FocusState private var isSearchFocused: Bool

    private var activeEntries: [Entry] {
        entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var processedEntries: [Entry] {
        LibrarySearchPipeline.process(
            entries: activeEntries,
            query: searchQuery,
            filter: selectedFilter,
            sort: selectedSort
        )
    }

    private var isSearchOrFilterActive: Bool {
        LibrarySearchPipeline.isSearchOrFilterActive(
            query: searchQuery,
            filter: selectedFilter
        )
    }

    private var recentlyWatched: [Entry] {
        Array(activeEntries.prefix(6))
    }

    private var needsDetailsEntries: [Entry] {
        activeEntries
            .filter { LibrarySearchPipeline.needsDetails($0) }
            .prefix(6)
            .map { $0 }
    }

    private var quickAddEntries: [Entry] {
        activeEntries
            .filter { $0.sourceType == .quickAdd }
            .prefix(6)
            .map { $0 }
    }

    private var sharedEntries: [Entry] {
        activeEntries
            .filter {
                $0.visibility == .circle &&
                $0.sharedCircleIds.isEmpty == false
            }
            .prefix(6)
            .map { $0 }
    }

    private var strongMemories: [Entry] {
        activeEntries
            .filter {
                $0.quickSentiment == .loved ||
                $0.quickSentiment == .stayedWithMe ||
                $0.intensity >= 4
            }
            .prefix(6)
            .map { $0 }
    }

    private var sharedCount: Int {
        activeEntries.filter {
            $0.visibility == .circle &&
            $0.sharedCircleIds.isEmpty == false
        }.count
    }

    private var quickAddCount: Int {
        activeEntries.filter {
            $0.sourceType == .quickAdd
        }.count
    }

    private var needsDetailsCount: Int {
        activeEntries.filter {
            LibrarySearchPipeline.needsDetails($0)
        }.count
    }

    private var resultCountText: String {
        processedEntries.count == 1 ? "1 memory" : "\(processedEntries.count) memories"
    }

    private var cleanedQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    searchField

                    if activeEntries.isEmpty == false {
                        controls
                    }

                    content
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Library")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Every movie, series, mood, and memory you’ve saved.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "books.vertical.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 38, height: 38)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
            }

            if activeEntries.isEmpty == false {
                libraryStats
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var libraryStats: some View {
        HStack(spacing: 10) {
            statCard(
                value: "\(activeEntries.count)",
                label: activeEntries.count == 1 ? "Memory" : "Memories",
                icon: "rectangle.stack.fill"
            )

            statCard(
                value: "\(needsDetailsCount)",
                label: "To complete",
                icon: "wand.and.stars"
            )

            statCard(
                value: "\(sharedCount)",
                label: "Shared",
                icon: "person.2.fill"
            )
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSearchFocused ? CloseCutColors.accentLight : CloseCutColors.textTertiary)

            TextField("Search your memories", text: $searchQuery)
                .focused($isSearchFocused)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if cleanedQuery.isEmpty == false {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        searchQuery = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(14)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(isSearchFocused ? CloseCutColors.accent.opacity(0.7) : CloseCutColors.separator, lineWidth: isSearchFocused ? 1 : 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            LibraryFilterChipsView(
                options: LibraryBrowseFilter.allCases,
                selectedFilter: $selectedFilter
            )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isSearchOrFilterActive ? resultCountText : "Curated shelves")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)

                    Text(isSearchOrFilterActive ? activeContextText : "Browse your archive by memory type.")
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if isSearchOrFilterActive {
                    Button {
                        clearSearchAndFilters()
                    } label: {
                        Text("Clear")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.horizontal, 10)
                            .frame(height: 32)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                LibrarySortMenuButton(
                    selectedSort: $selectedSort
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        if activeEntries.isEmpty {
            emptyLibraryState
        } else if isSearchOrFilterActive {
            resultsContent
        } else {
            browseContent
        }
    }

    private var browseContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if recentlyWatched.isEmpty == false {
                    LibrarySectionPreviewView(
                        title: "Recently saved",
                        subtitle: "The latest memories added to your private archive.",
                        entries: recentlyWatched,
                        user: user,
                        profile: profile
                    )
                }

                if needsDetailsEntries.isEmpty == false {
                    LibrarySectionPreviewView(
                        title: "Finish these memories",
                        subtitle: "Quick Adds that are ready for mood, tags, and a better takeaway.",
                        entries: needsDetailsEntries,
                        user: user,
                        profile: profile,
                        actionTitle: "View all",
                        action: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedFilter = .needsDetails
                            }
                        }
                    )
                }

                if strongMemories.isEmpty == false {
                    LibrarySectionPreviewView(
                        title: "Strongest signals",
                        subtitle: "The watches that stayed with you the most.",
                        entries: strongMemories,
                        user: user,
                        profile: profile
                    )
                }

                if sharedEntries.isEmpty == false {
                    LibrarySectionPreviewView(
                        title: "Shared with Circles",
                        subtitle: "The memories you chose to share with trusted people.",
                        entries: sharedEntries,
                        user: user,
                        profile: profile,
                        actionTitle: "View all",
                        action: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedFilter = .shared
                            }
                        }
                    )
                }

                if quickAddEntries.isEmpty == false {
                    LibrarySectionPreviewView(
                        title: "Quick Adds",
                        subtitle: "Fast-added titles from your past watch history.",
                        entries: quickAddEntries,
                        user: user,
                        profile: profile,
                        actionTitle: "View all",
                        action: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedFilter = .quickAdd
                            }
                        }
                    )
                }

                libraryTip
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var resultsContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                resultsHeader

                if processedEntries.isEmpty {
                    emptyResultsCard
                } else {
                    ForEach(processedEntries) { entry in
                        NavigationLink {
                            EntryDetailView(
                                entry: entry,
                                user: user,
                                profile: profile
                            )
                        } label: {
                            CompactEntryRowView(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var resultsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(resultsTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(activeContextText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private var emptyLibraryState: some View {
        VStack(spacing: 18) {
            Image(systemName: "film.stack")
                .font(.largeTitle)
                .foregroundStyle(CloseCutColors.accentLight)

            VStack(spacing: 6) {
                Text("Your library is waiting")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Add a few past watches first, then this becomes your searchable private archive.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyResultsCard: some View {
        VStack(spacing: 14) {
            Image(systemName: selectedFilter.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            VStack(spacing: 5) {
                Text(selectedFilter.emptyTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(cleanedQuery.isEmpty ? selectedFilter.emptyMessage : "Try a different title, mood, year, tag, or clear your filters.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                clearSearchAndFilters()
            } label: {
                Text("Back to library")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(CloseCutColors.input)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var libraryTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Your archive gets better with context.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Completing Quick Adds with mood, tags, and a takeaway makes your library feel more personal — and improves future picks.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(15)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var resultsTitle: String {
        if cleanedQuery.isEmpty == false {
            return resultCountText
        }

        return selectedFilter.title
    }

    private var activeContextText: String {
        var parts: [String] = []

        if selectedFilter != .all {
            parts.append(selectedFilter.title)
        }

        if cleanedQuery.isEmpty == false {
            parts.append("“\(cleanedQuery)”")
        }

        parts.append("Sorted by \(selectedSort.title)")

        return parts.joined(separator: " • ")
    }

    private func clearSearchAndFilters() {
        withAnimation(.easeInOut(duration: 0.18)) {
            searchQuery = ""
            selectedFilter = .all
            selectedSort = .recent
        }
    }

    private func statCard(
        value: String,
        label: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(CloseCutColors.input.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}

#Preview {
    LibrarySearchView(
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
        )
    )
}
