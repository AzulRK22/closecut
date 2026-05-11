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
    }

    private var searchedEntries: [Entry] {
        EntrySearchFilter.filter(
            entries: activeEntries,
            query: searchQuery
        )
    }

    private var filteredEntries: [Entry] {
        searchedEntries.filter { entry in
            switch selectedFilter {
            case .all:
                return true

            case .movies:
                return entry.type == .movie

            case .series:
                return entry.type == .series

            case .shared:
                return entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false

            case .quickAdd:
                return entry.sourceType == .quickAdd

            case .needsDetails:
                return needsDetails(entry)
            }
        }
    }

    private var sortedEntries: [Entry] {
        switch selectedSort {
        case .recent:
            return filteredEntries.sorted { first, second in
                first.watchedAt > second.watchedAt
            }

        case .alphabetical:
            return filteredEntries.sorted { first, second in
                first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }

        case .year:
            return filteredEntries.sorted { first, second in
                let firstYear = first.releaseYear ?? Int.min
                let secondYear = second.releaseYear ?? Int.min

                if firstYear != secondYear {
                    return firstYear > secondYear
                }

                return first.watchedAt > second.watchedAt
            }
        }
    }

    private var resultCountText: String {
        if sortedEntries.count == 1 {
            return "1 memory"
        }

        return "\(sortedEntries.count) memories"
    }

    private var hasAnyEntries: Bool {
        activeEntries.isEmpty == false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    searchField

                    if hasAnyEntries {
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
        .onAppear {
            isSearchFocused = true
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find and organize your private watch history.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                summaryPill(
                    icon: "rectangle.stack.fill",
                    text: "\(activeEntries.count) total"
                )

                summaryPill(
                    icon: "person.2.fill",
                    text: "\(sharedCount) shared"
                )

                summaryPill(
                    icon: "bolt.fill",
                    text: "\(quickAddCount) quick adds"
                )
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

    private var controls: some View {
        VStack(spacing: 14) {
            LibraryFilterChipsView(
                title: "Filter",
                options: LibraryBrowseFilter.allCases,
                selectedFilter: $selectedFilter
            )

            LibrarySortChipsView(
                title: "Sort",
                options: LibrarySortOption.allCases,
                selectedSort: $selectedSort
            )
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        if activeEntries.isEmpty {
            emptyLibraryState
        } else if sortedEntries.isEmpty {
            emptyResultsState
        } else {
            resultsList
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(resultCountText)
                            .font(.headline)
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text(resultsSubtitle)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 2)

                ForEach(sortedEntries) { entry in
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
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
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

                Text("Add a few past watches first, then your library will become searchable.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(CloseCutColors.textTertiary)

            VStack(spacing: 6) {
                Text("No matching memories")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Try another title, year, mood, tag, or filter.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                clearFilters()
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
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sharedCount: Int {
        activeEntries.filter {
            $0.visibility == .circle && $0.sharedCircleIds.isEmpty == false
        }.count
    }

    private var quickAddCount: Int {
        activeEntries.filter {
            $0.sourceType == .quickAdd
        }.count
    }

    private var resultsSubtitle: String {
        let filterText = selectedFilter.title
        let sortText = selectedSort.title

        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(filterText) • Sorted by \(sortText)"
        }

        return "\(filterText) • “\(searchQuery)” • Sorted by \(sortText)"
    }

    private func needsDetails(_ entry: Entry) -> Bool {
        guard entry.sourceType == .quickAdd else {
            return false
        }

        return entry.mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            entry.tags.isEmpty
    }

    private func clearFilters() {
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
