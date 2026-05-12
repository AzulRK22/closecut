//
//  QuickAddPastWatchesView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import SwiftUI
import SwiftData

struct QuickAddPastWatchesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = QuickAddViewModel()
    @FocusState private var isSearchFocused: Bool

    @State private var selectedPreviewResult: TMDBMediaSearchResult?

    let user: AuthUser

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            searchCard

                            statusMessages

                            tmdbResultsSection

                            if viewModel.shouldShowLocalFallback {
                                suggestionsSection
                            }

                            if viewModel.canAddManualTitle {
                                manualAddButton
                            }

                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.accent)
                }
            }
            .sheet(item: $selectedPreviewResult) { result in
                QuickAddPreviewSheet(
                    result: result,
                    selectedSentiment: $viewModel.selectedSentiment,
                    selectedApproxDate: $viewModel.selectedApproxDate,
                    onAdd: {
                        viewModel.addTMDBResult(
                            result,
                            ownerId: user.id,
                            modelContext: modelContext
                        )
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isSearchFocused = true
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Build your history fast.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Search, preview, and add past watches with real metadata.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "bolt.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 38, height: 38)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
            }

            Text(viewModel.addedCountText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var searchCard: some View {
        QuickAddSectionCard(
            title: "Find a title",
            subtitle: "TMDB results add posters, release years, genres, and better QuickPick signals."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                QuickAddSearchBar(
                    query: $viewModel.query,
                    isSearching: viewModel.isSearchingTMDB,
                    onSubmit: {
                        viewModel.runSearchImmediately()
                    },
                    onClear: {
                        viewModel.clearSearch()
                    }
                )
                .focused($isSearchFocused)
                .onChange(of: viewModel.query) { _, _ in
                    viewModel.scheduleSearch()
                }

                QuickReactionChips(
                    selectedSentiment: $viewModel.selectedSentiment
                )

                RoughDateSelector(
                    selectedDate: $viewModel.selectedApproxDate
                )
            }
        }
    }

    @ViewBuilder
    private var statusMessages: some View {
        if let lastAdded = viewModel.lastAddedEntry {
            QuickAddStatusBanner(
                message: "Added to your history: \(lastAdded.title)",
                systemImage: "checkmark.circle.fill",
                foregroundColor: CloseCutColors.synced
            )
        }

        if let duplicate = viewModel.lastDuplicateEntry {
            QuickAddStatusBanner(
                message: "Already in your history: \(duplicate.title)",
                systemImage: "checkmark.circle",
                foregroundColor: CloseCutColors.textSecondary
            )
        }

        if let errorMessage = viewModel.errorMessage {
            QuickAddStatusBanner(
                message: errorMessage,
                systemImage: "exclamationmark.triangle.fill",
                foregroundColor: CloseCutColors.failed,
                backgroundColor: CloseCutColors.failedBackground
            )
        }
    }

    @ViewBuilder
    private var tmdbResultsSection: some View {
        if viewModel.isSearchingTMDB {
            QuickAddSectionCard(
                title: "Searching TMDB",
                subtitle: "Finding matching movies and series."
            ) {
                HStack(spacing: 10) {
                    ProgressView()

                    Text("Searching…")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)

                    Spacer()
                }
                .frame(minHeight: 44)
            }
        } else if viewModel.tmdbResults.isEmpty == false {
            QuickAddSectionCard(
                title: "Best matches",
                subtitle: "Preview the right title before adding it to your history."
            ) {
                VStack(spacing: 10) {
                    ForEach(viewModel.tmdbResults) { result in
                        QuickAddTMDBResultRow(
                            result: result,
                            state: rowState(for: result),
                            action: {
                                selectedPreviewResult = result
                            }
                        )
                    }
                }
            }
        } else if let searchErrorMessage = viewModel.searchErrorMessage,
                  viewModel.cleanedQuery.isEmpty == false {
            QuickAddStatusBanner(
                message: "TMDB search unavailable. You can still add this manually.",
                systemImage: "wifi.exclamationmark",
                foregroundColor: CloseCutColors.textSecondary
            )

            #if DEBUG
            Text(searchErrorMessage)
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
            #endif
        }
    }

    private var suggestionsSection: some View {
        QuickAddSectionCard(
            title: viewModel.cleanedQuery.isEmpty ? "Starter suggestions" : "Local fallback",
            subtitle: viewModel.cleanedQuery.isEmpty
                ? "A few titles to help seed your archive."
                : "No exact TMDB match yet. You can still add a remembered title."
        ) {
            if viewModel.filteredSuggestions.isEmpty {
                EmptyStateView(
                    title: "Add it manually",
                    message: "Your history can include it even without metadata.",
                    systemImage: "plus.circle",
                    actionTitle: "Add manual title",
                    action: {
                        viewModel.addManualTitle(
                            ownerId: user.id,
                            modelContext: modelContext
                        )
                    }
                )
                .frame(minHeight: 220)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.filteredSuggestions) { suggestion in
                        QuickAddResultRow(
                            title: suggestion.title,
                            metadata: suggestion.metadata,
                            state: rowState(for: suggestion),
                            action: {
                                viewModel.addSuggestion(
                                    suggestion,
                                    ownerId: user.id,
                                    modelContext: modelContext
                                )
                            }
                        )
                    }
                }
            }
        }
    }

    private var manualAddButton: some View {
        Button {
            viewModel.addManualTitle(
                ownerId: user.id,
                modelContext: modelContext
            )
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Add “\(viewModel.cleanedQuery)” without metadata")
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(CloseCutColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(viewModel.cleanedQuery) without metadata")
    }

    private func rowState(for suggestion: QuickAddSuggestion) -> QuickAddRowState {
        if viewModel.hasAdded(suggestion) {
            return .added
        }

        if let duplicate = viewModel.lastDuplicateEntry,
           DuplicateDetector.isDuplicate(
                title: suggestion.title,
                type: suggestion.type,
                releaseYear: suggestion.releaseYear,
                existingEntry: duplicate
           ) {
            return .duplicate
        }

        return .normal
    }

    private func rowState(for result: TMDBMediaSearchResult) -> QuickAddRowState {
        if viewModel.hasAdded(result) {
            return .added
        }

        if let duplicate = viewModel.lastDuplicateEntry,
           DuplicateDetector.isDuplicate(
                title: result.title,
                type: result.entryType,
                releaseYear: result.releaseYear,
                existingEntry: duplicate
           ) {
            return .duplicate
        }

        return .normal
    }
}

private struct QuickAddStatusBanner: View {
    let message: String
    let systemImage: String
    let foregroundColor: Color
    var backgroundColor: Color = CloseCutColors.input

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foregroundColor)
                .padding(.top, 1)

            Text(message)
                .font(.caption)
                .foregroundStyle(foregroundColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}
