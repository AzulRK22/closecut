//
//  MediaSearchView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct MediaSearchView: View {
    let title: String
    let subtitle: String
    let placeholder: String
    let onCancel: () -> Void
    let onSelect: (TMDBMediaSearchResult) -> Void

    @State private var query = ""
    @State private var results: [TMDBMediaSearchResult] = []
    @State private var selectedResultId: String?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    @FocusState private var isSearchFocused: Bool

    private let repository = TMDBMediaRepository()
    private let debounceNanoseconds: UInt64 = 450_000_000
    private let maxDisplayedResults = 20

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSearch: Bool {
        trimmedQuery.count >= 2
    }

    private var displayedResults: [TMDBMediaSearchResult] {
        Array(results.prefix(maxDisplayedResults))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    searchField

                    content
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelSearch()
                        onCancel()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
        .onDisappear {
            cancelSearch()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Powered by TMDB metadata. Your CloseCut memory stays personal.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                TextField(placeholder, text: $query)
                    .focused($isSearchFocused)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        runSearchImmediately()
                    }
                    .onChange(of: query) { _, newValue in
                        scheduleSearch(for: newValue)
                    }

                if query.isEmpty == false {
                    Button {
                        clearSearch()
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

            if trimmedQuery.isEmpty == false && canSearch == false {
                Text("Type at least 2 characters.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        if isSearching {
            loadingState
        } else if let errorMessage {
            errorState(errorMessage)
        } else if trimmedQuery.isEmpty {
            emptyStartState
        } else if results.isEmpty && canSearch {
            emptyResultsState
        } else {
            resultsList
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text("Searching TMDB…")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var emptyStartState: some View {
        VStack(spacing: 14) {
            Image(systemName: "film.stack")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)

            VStack(spacing: 5) {
                Text("Search movies and series")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Find a title from TMDB and use it to enrich your CloseCut entry.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var emptyResultsState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            VStack(spacing: 5) {
                Text("No results found")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Try a different title, spelling, or year.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.failed)

            VStack(spacing: 5) {
                Text("Search failed")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                runSearchImmediately()
            } label: {
                Text("Try again")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(CloseCutColors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(canSearch == false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(displayedResults) { result in
                    Button {
                        select(result)
                    } label: {
                        MediaSearchResultRow(
                            result: result,
                            isSelected: selectedResultId == result.id
                        )
                    }
                    .buttonStyle(.plain)
                }

                if results.count > displayedResults.count {
                    Text("Showing top \(displayedResults.count) results. Refine your search for better matches.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func scheduleSearch(for value: String) {
        searchTask?.cancel()

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.count >= 2 else {
            results = []
            errorMessage = nil
            isSearching = false
            selectedResultId = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: debounceNanoseconds)

            guard Task.isCancelled == false else {
                return
            }

            await performSearch(query: cleaned)
        }
    }

    private func runSearchImmediately() {
        searchTask?.cancel()

        guard canSearch else {
            return
        }

        let searchQuery = trimmedQuery

        searchTask = Task {
            await performSearch(query: searchQuery)
        }
    }

    @MainActor
    private func performSearch(query searchQuery: String) async {
        let normalizedSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedSearchQuery.count >= 2 else {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            let fetchedResults = try await repository.searchMedia(
                query: normalizedSearchQuery
            )

            guard Task.isCancelled == false else {
                return
            }

            guard trimmedQuery == normalizedSearchQuery else {
                return
            }

            results = fetchedResults
            selectedResultId = nil
            isSearching = false
        } catch {
            guard Task.isCancelled == false else {
                return
            }

            guard trimmedQuery == normalizedSearchQuery else {
                return
            }

            results = []
            selectedResultId = nil
            errorMessage = error.localizedDescription
            isSearching = false

            #if DEBUG
            print("❌ Media search failed:", error.localizedDescription)
            #endif
        }
    }

    private func select(_ result: TMDBMediaSearchResult) {
        selectedResultId = result.id
        searchTask?.cancel()
        onSelect(result)
    }

    private func clearSearch() {
        searchTask?.cancel()
        searchTask = nil
        query = ""
        results = []
        errorMessage = nil
        isSearching = false
        selectedResultId = nil
        isSearchFocused = true
    }

    private func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }
}
