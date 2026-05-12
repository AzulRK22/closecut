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
            .filter {
                LibrarySearchPipeline.needsDetails($0)
            }
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

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    searchField

                    if activeEntries.isEmpty == false {
                        filterControls
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
        .onAppear {
            isSearchFocused = true
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Find anything in your taste history.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Search by title, year, mood, tag, or browse your saved memories by type.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                summaryPill(
                    icon: "rectangle.stack.fill",
                    text: "\(activeEntries.count) total"
                )

                summaryPill(
                    icon: "bolt.fill",
                    text: "\(quickAddCount) quick"
                )

                summaryPill(
                    icon: "wand.and.stars",
                    text: "\(needsDetailsCount) to complete"
                )

                if sharedCount > 0 {
                    summaryPill(
                        icon: "person.2.fill",
                        text: "\(sharedCount) shared"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            TextField("Search title, year, mood, tag…", text: $searchQuery)
                .focused($isSearchFocused)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                Button {
                    searchQuery = ""
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var filterControls: some View {
        VStack(spacing: 10) {
            LibraryFilterChipsView(
                title: "Browse",
                options: LibraryBrowseFilter.allCases,
                selectedFilter: $selectedFilter
            )

            HStack {
                Text(isSearchOrFilterActive ? resultCountText : "Browse your library")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                Spacer()

                Menu {
                    ForEach(LibrarySortOption.allCases) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            Label(
                                option.title,
                                systemImage: selectedSort == option ? "checkmark" : option.systemImage
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedSort.systemImage)
                            .font(.caption2.weight(.semibold))

                        Text(selectedSort.title)
                            .font(.caption.weight(.semibold))

                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(CloseCutColors.input)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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
                LibrarySectionPreviewView(
                    title: "Recently watched",
                    subtitle: "Your latest memories and logged watches.",
                    entries: recentlyWatched,
                    user: user,
                    profile: profile,
                    actionTitle: nil,
                    action: nil
                )

                if needsDetailsEntries.isEmpty == false {
                    LibrarySectionPreviewView(
                        title: "Ready to complete",
                        subtitle: "Quick Adds that can become richer memories.",
                        entries: needsDetailsEntries,
                        user: user,
                        profile: profile,
                        actionTitle: "View all",
                        action: {
                            selectedFilter = .needsDetails
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
                            selectedFilter = .quickAdd
                        }
                    )
                }

                if sharedEntries.isEmpty == false {
                    LibrarySectionPreviewView(
                        title: "Shared with Circles",
                        subtitle: "Memories you intentionally shared with trusted people.",
                        entries: sharedEntries,
                        user: user,
                        profile: profile,
                        actionTitle: "View all",
                        action: {
                            selectedFilter = .shared
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
            VStack(alignment: .leading, spacing: 3) {
                Text(resultCountText)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(resultsSubtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isSearchOrFilterActive {
                Button {
                    clearSearchAndFilters()
                } label: {
                    Text("Reset")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(CloseCutColors.input)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 2)
    }

    private var emptyLibraryState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.largeTitle)
                .foregroundStyle(CloseCutColors.accentLight)

            VStack(spacing: 6) {
                Text("No memories yet")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Add a few past watches first, then your library will become searchable and organized.")
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
            Image(systemName: "magnifyingglass")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            VStack(spacing: 5) {
                Text("No matching memories")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Try another title, year, mood, tag, or reset your filters.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                clearSearchAndFilters()
            } label: {
                Text("Reset search")
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var libraryTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Your library gets smarter as you add context.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Completing Quick Adds with mood, takeaway, tags, and metadata improves your archive and future picks.")
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

    private var resultsSubtitle: String {
        let cleanedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

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
        searchQuery = ""
        selectedFilter = .all
        selectedSort = .recent
    }

    private func summaryPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
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
