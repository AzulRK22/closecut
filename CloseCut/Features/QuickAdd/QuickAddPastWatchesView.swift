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

    @State private var showMediaSearch = false

    let user: AuthUser

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            tmdbSearchCard

                            QuickAddSearchBar(
                                query: $viewModel.query,
                                onSubmit: {
                                    viewModel.addManualTitle(
                                        ownerId: user.id,
                                        modelContext: modelContext
                                    )
                                }
                            )
                            .focused($isSearchFocused)

                            QuickReactionChips(
                                selectedSentiment: $viewModel.selectedSentiment
                            )

                            RoughDateSelector(
                                selectedDate: $viewModel.selectedApproxDate
                            )

                            statusMessages

                            suggestionsSection

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
            .navigationTitle("Add past watches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.accent)
                }
            }
            .sheet(isPresented: $showMediaSearch) {
                MediaSearchView(
                    title: "Search TMDB",
                    subtitle: "Find a movie or series and add it to your personal history fast.",
                    placeholder: "Search movies or series",
                    onCancel: {
                        showMediaSearch = false
                    },
                    onSelect: { result in
                        viewModel.addTMDBResult(
                            result,
                            ownerId: user.id,
                            modelContext: modelContext
                        )

                        showMediaSearch = false
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Search, tap, done.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text("Add a few titles you remember. You can add details later.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)

            Text(viewModel.addedCountText)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var tmdbSearchCard: some View {
        Button {
            showMediaSearch = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 38, height: 38)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Search with TMDB")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Use posters, release years, and real movie/series metadata.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.top, 6)
            }
            .padding(14)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusMessages: some View {
        if let lastAdded = viewModel.lastAddedEntry {
            Text("Added: \(lastAdded.title)")
                .font(.caption)
                .foregroundStyle(CloseCutColors.synced)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }

        if let duplicate = viewModel.lastDuplicateEntry {
            Text("Already in your history: \(duplicate.title)")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }

        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(CloseCutColors.failed)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CloseCutColors.failedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.query.isEmpty ? "Suggested fallback" : "Local fallback results")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            if viewModel.filteredSuggestions.isEmpty {
                EmptyStateView(
                    title: "Add it manually",
                    message: "Search did not find it, but your history can still include it.",
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
                Text("Add “\(viewModel.query)” manually")
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
        .accessibilityLabel("Add \(viewModel.query) manually")
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
}
