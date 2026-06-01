//
//  BattlePickTonightSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import SwiftUI

struct BattlePickTonightSheet: View {
    let archiveEntries: [Entry]
    let watchlistItems: [WatchlistItem]
    let initialSelection: [BattleCandidate]
    let onCancel: () -> Void
    let onConfirm: ([BattleCandidate]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var selectedCandidates: [BattleCandidate] = []
    @State private var tmdbResults: [BattleCandidate] = []
    @State private var didSearch = false
    @State private var isSearching = false
    @State private var searchErrorMessage: String?
    @State private var manualTitle = ""
    @State private var manualType: EntryType = .movie

    @FocusState private var focusedField: Field?

    private let tmdbRepository = TMDBMediaRepository()

    private enum Field {
        case search
        case manual
    }

    private var archiveCandidates: [BattleCandidate] {
        BattleCandidateMapper.candidates(from: archiveEntries)
            .sorted { first, second in
                let firstDate = first.watchedAt ?? .distantPast
                let secondDate = second.watchedAt ?? .distantPast
                return firstDate > secondDate
            }
    }

    private var cleanedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanedManualTitle: String {
        manualTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canConfirm: Bool {
        selectedCandidates.count >= 2
    }

    private var canAddManual: Bool {
        cleanedManualTitle.isEmpty == false
    }

    private var canSearch: Bool {
        cleanedQuery.count >= 2 && isSearching == false
    }

    private var confirmTitle: String {
        canConfirm
            ? "Pick from \(selectedCandidates.count) options"
            : selectedCandidates.count == 1
                ? "Add 1 more option"
                : "Add at least 2 options"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            header

                            shortlistCard
                            
                            watchlistSection

                            searchSection

                            tmdbResultsOrEmptySection

                            manualSection

                            archiveSection

                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    footer
                }
            }
            .navigationTitle("Pick for Tonight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        confirm()
                    }
                    .disabled(canConfirm == false)
                    .foregroundStyle(canConfirm ? CloseCutColors.accent : CloseCutColors.inactive)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            selectedCandidates = BattleCandidateMapper.dedupe(initialSelection)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusedField = .search
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Build tonight’s shortlist.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Mix your archive, TMDB discoveries, or quick manual ideas. Then let CloseCut break the endless scrolling loop.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    SwiftUI.Circle()
                        .fill(CloseCutColors.accent.opacity(0.18))
                        .frame(width: 50, height: 50)

                    Image(systemName: "shuffle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }

            HStack(spacing: 8) {
                infoPill(
                    icon: "film.stack",
                    text: "\(archiveCandidates.count) archive"
                )

                infoPill(
                    icon: "bookmark.fill",
                    text: "\(watchlistCandidates.count) watchlist"
                )

                infoPill(
                    icon: "checkmark.circle.fill",
                    text: "\(selectedCandidates.count) selected"
                )
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    CloseCutColors.card,
                    CloseCutColors.card.opacity(0.94),
                    CloseCutColors.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func infoPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
    private var watchlistCandidates: [BattleCandidate] {
        BattleCandidateMapper.candidates(from: watchlistItems)
            .sorted { first, second in
                first.displayTitle.localizedCaseInsensitiveCompare(second.displayTitle) == .orderedAscending
            }
    }
    // MARK: - Watchlist

    private var watchlistSection: some View {
        BattleSectionCard(
            title: "From Want to Watch",
            subtitle: "Titles you already saved for the right moment."
        ) {
            if watchlistCandidates.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "bookmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .padding(.top, 2)

                    Text("Save titles from Discover to use them here as Battle options.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(watchlistCandidates) { candidate in
                        BattleCandidateRow(
                            candidate: candidate,
                            isSelected: isSelected(candidate)
                        ) {
                            toggleCandidate(candidate)
                        }
                    }
                }
            }
        }
    }
    // MARK: - Shortlist

    private var shortlistCard: some View {
        BattleSectionCard(
            title: canConfirm ? "Shortlist ready" : "Shortlist",
            subtitle: canConfirm
                ? "You can pick now, clear the list, or keep adding options."
                : "Add at least two options to start."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if selectedCandidates.isEmpty {
                    emptyShortlist
                } else {
                    VStack(spacing: 10) {
                        ForEach(selectedCandidates) { candidate in
                            selectedCandidateRow(candidate)
                        }
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedCandidates = []
                        }
                    } label: {
                        Label("Clear shortlist", systemImage: "trash")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyShortlist: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 2)

            Text("Start by adding anything you’re considering tonight. It does not need to be in your archive yet.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func selectedCandidateRow(
        _ candidate: BattleCandidate
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BattleCandidatePosterView(
                candidate: candidate,
                width: 42,
                height: 62,
                cornerRadius: 10
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)

                Text(candidate.metadataText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)

                Text(candidate.sourceLabelText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    removeCandidate(candidate)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(candidate.displayTitle)")
        }
        .padding(10)
        .background(CloseCutColors.input.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Search

    private var searchSection: some View {
        BattleSectionCard(
            title: "Search anything",
            subtitle: "Use TMDB when the title is not in your archive yet."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)

                    TextField("Search movies or series", text: $query)
                        .focused($focusedField, equals: .search)
                        .font(.body)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await searchTMDB()
                            }
                        }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.75)
                    } else if cleanedQuery.isEmpty == false {
                        Button {
                            query = ""
                            tmdbResults = []
                            didSearch = false
                            searchErrorMessage = nil
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

                Button {
                    Task {
                        await searchTMDB()
                    }
                } label: {
                    Label(isSearching ? "Searching…" : "Search TMDB", systemImage: "sparkles.tv")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(canSearch ? .white : CloseCutColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(canSearch ? CloseCutColors.accent : CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(canSearch == false)

                if let searchErrorMessage {
                    Text(searchErrorMessage)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.failed)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var tmdbResultsOrEmptySection: some View {
        if tmdbResults.isEmpty == false {
            tmdbResultsSection
        } else if didSearch && isSearching == false && searchErrorMessage == nil {
            BattleSectionCard(
                title: "No TMDB matches",
                subtitle: "Try the original title, a shorter query, or add it manually."
            ) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .padding(.top, 2)

                    Text("No results found for “\(cleanedQuery)”.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var tmdbResultsSection: some View {
        BattleSectionCard(
            title: "TMDB results",
            subtitle: "Tap to add options to tonight’s shortlist."
        ) {
            VStack(spacing: 10) {
                ForEach(tmdbResults) { candidate in
                    BattleCandidateRow(
                        candidate: candidate,
                        isSelected: isSelected(candidate)
                    ) {
                        toggleCandidate(candidate)
                    }
                }
            }
        }
    }

    // MARK: - Manual

    private var manualSection: some View {
        BattleSectionCard(
            title: "Quick manual idea",
            subtitle: "For titles you remember but do not want to search right now."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Manual type", selection: $manualType) {
                    Text("Movie")
                        .tag(EntryType.movie)

                    Text("Series")
                        .tag(EntryType.series)
                }
                .pickerStyle(.segmented)

                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)

                    TextField("Type a title", text: $manualTitle)
                        .focused($focusedField, equals: .manual)
                        .font(.body)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit {
                            addManualCandidate()
                        }
                }
                .padding(14)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    addManualCandidate()
                } label: {
                    Label("Add manual option", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(canAddManual ? .white : CloseCutColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(canAddManual ? CloseCutColors.accent : CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(canAddManual == false)
            }
        }
    }

    // MARK: - Archive

    private var archiveSection: some View {
        BattleSectionCard(
            title: "From your archive",
            subtitle: "Your Personal Timeline is still the best signal for taste."
        ) {
            if archiveCandidates.isEmpty {
                EmptyStateView(
                    title: "No archive options yet",
                    message: "You can still use TMDB search or manual options for tonight.",
                    systemImage: "film.stack",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(archiveCandidates) { candidate in
                        BattleCandidateRow(
                            candidate: candidate,
                            isSelected: isSelected(candidate)
                        ) {
                            toggleCandidate(candidate)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Divider()
                .overlay(CloseCutColors.separator)

            Button {
                confirm()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: canConfirm ? "shuffle" : "plus.circle")
                        .font(.subheadline.weight(.semibold))

                    Text(confirmTitle)
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(canConfirm ? .white : CloseCutColors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canConfirm ? CloseCutColors.accent : CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(canConfirm == false)

            Text("External titles are used for this Battle. You can decide later if they belong in your Timeline.")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Actions

    private func searchTMDB() async {
        guard canSearch else {
            return
        }

        isSearching = true
        didSearch = true
        searchErrorMessage = nil

        do {
            let results = try await tmdbRepository.searchMedia(
                query: cleanedQuery
            )

            let candidates = results
                .prefix(10)
                .map { BattleCandidateMapper.candidate(from: $0) }

            tmdbResults = BattleCandidateMapper.dedupe(candidates)
        } catch {
            searchErrorMessage = "Couldn’t search TMDB right now. You can still add a manual option."

            #if DEBUG
            print("⚠️ Battle TMDB search failed:", error.localizedDescription)
            #endif
        }

        isSearching = false
    }
    

    private func addManualCandidate() {
        guard canAddManual else {
            return
        }

        let candidate = BattleCandidateMapper.manualCandidate(
            title: cleanedManualTitle,
            type: manualType
        )

        withAnimation(.easeInOut(duration: 0.18)) {
            addCandidate(candidate)
            manualTitle = ""
        }
    }

    private func toggleCandidate(
        _ candidate: BattleCandidate
    ) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if isSelected(candidate) {
                removeCandidate(candidate)
            } else {
                addCandidate(candidate)
            }
        }
    }

    private func addCandidate(
        _ candidate: BattleCandidate
    ) {
        var next = selectedCandidates
        next.append(candidate)
        selectedCandidates = BattleCandidateMapper.dedupe(next)
    }

    private func removeCandidate(
        _ candidate: BattleCandidate
    ) {
        selectedCandidates.removeAll {
            $0.normalizedIdentityKey == candidate.normalizedIdentityKey
        }
    }

    private func isSelected(
        _ candidate: BattleCandidate
    ) -> Bool {
        selectedCandidates.contains {
            $0.normalizedIdentityKey == candidate.normalizedIdentityKey
        }
    }

    private func confirm() {
        guard canConfirm else {
            return
        }

        onConfirm(BattleCandidateMapper.dedupe(selectedCandidates))
        dismiss()
    }
}
