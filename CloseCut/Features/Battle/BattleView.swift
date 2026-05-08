//
//  BattleView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/05/26.
//

import SwiftUI
import SwiftData

struct BattleView: View {
    @Environment(\.modelContext) private var modelContext

    let user: AuthUser
    let profile: UserProfile

    @State private var showOptionSelector = false
    @State private var selectedEntries: [Entry] = []
    @State private var pickedEntry: Entry?
    @State private var showHeadToHeadBattle = false
    @State private var battleErrorMessage: String?
    @State private var showClearResultsConfirmation = false
    @State private var isClearingResults = false

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalBattleResult.createdAt, order: .reverse)
    private var localBattleResults: [LocalBattleResult]

    private let battleResultRepository = BattleResultRepository()

    private var selectedEntryIds: Set<String> {
        Set(selectedEntries.map { $0.id })
    }

    private var canPickRandomWinner: Bool {
        selectedEntries.count >= 2
    }

    private var recentBattleResults: [BattleResult] {
        localBattleResults
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
            .filter {
                $0.winnerTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
                $0.optionTitles.isEmpty == false
            }
            .prefix(5)
            .map { $0 }
    }

    private var entries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    private var eligibleEntries: [Entry] {
        entries.filter { entry in
            entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    private var canStartLocalBattle: Bool {
        eligibleEntries.count >= 2
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection

                        readinessCard

                        if let battleErrorMessage {
                            SyncResultBanner(
                                message: battleErrorMessage,
                                style: .warning
                            )
                        }

                        if let pickedEntry {
                            BattlePickResultCard(
                                winner: pickedEntry,
                                optionCount: selectedEntries.count,
                                onPickAgain: pickRandomWinner,
                                onClear: clearBattleSelection
                            )
                        }

                        if selectedEntries.isEmpty == false {
                            selectedOptionsSection
                        }

                        if recentBattleResults.isEmpty == false {
                            recentResultsSection
                        }

                        battleModesSection

                        futureSocialSection

                        whyItMattersSection

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Battle")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showOptionSelector) {
                BattleOptionSelectorSheet(
                    entries: eligibleEntries,
                    initialSelection: selectedEntryIds,
                    onCancel: {
                        showOptionSelector = false
                    },
                    onConfirm: { entries in
                        selectedEntries = entries
                        pickedEntry = nil
                        battleErrorMessage = nil
                        showOptionSelector = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showHeadToHeadBattle) {
                BattleHeadToHeadSheet(
                    entries: eligibleEntries,
                    currentUserId: user.id,
                    onCancel: {
                        showHeadToHeadBattle = false
                    },
                    onWinnerSelected: { winner, options in
                        saveHeadToHeadResult(
                            winner: winner,
                            options: options
                        )
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Clear Battle results?",
                isPresented: $showClearResultsConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear results", role: .destructive) {
                    clearRecentResults()
                }
                .disabled(isClearingResults)

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This only clears your local Battle history. Your entries are not deleted.")
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Turn taste into a game.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Compare picks with yourself, a friend, or your Circle.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Start with your own archive. Friend and Circle Battles will build on trusted sharing later.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "bolt.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 42, height: 42)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
            }

            HStack(spacing: 10) {
                battleStatPill(
                    value: "\(eligibleEntries.count)",
                    label: "eligible",
                    icon: "film.stack"
                )

                battleStatPill(
                    value: canStartLocalBattle ? "Ready" : "Soon",
                    label: "status",
                    icon: canStartLocalBattle ? "checkmark.circle.fill" : "clock.fill"
                )
            }
        }
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: canStartLocalBattle ? "checkmark.circle.fill" : "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(canStartLocalBattle ? CloseCutColors.synced : CloseCutColors.accentLight)
                    .frame(width: 40, height: 40)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(canStartLocalBattle ? "Your archive is ready" : "Battle needs two options")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(canStartLocalBattle ? "You have enough memories to start comparing titles or picking what to watch." : "Add one more movie or series to unlock random picks and Movie vs Movie.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button {
                showOptionSelector = true
            } label: {
                HStack {
                    Image(systemName: "shuffle")

                    Text(canStartLocalBattle ? "Start with random pick" : "Need 2 entries")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canStartLocalBattle ? .white : CloseCutColors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(canStartLocalBattle ? CloseCutColors.accent : CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(canStartLocalBattle == false)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var selectedOptionsSection: some View {
        battleSection(title: "Selected options") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(selectedEntries) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        EntryPosterThumbnailView(
                            entry: entry,
                            width: 42,
                            height: 62,
                            cornerRadius: 10
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)
                                .lineLimit(2)

                            Text(optionSubtitle(for: entry))
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }

                    if entry.id != selectedEntries.last?.id {
                        Divider()
                            .overlay(CloseCutColors.separator)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        showOptionSelector = true
                    } label: {
                        Text("Edit options")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        pickRandomWinner()
                    } label: {
                        Label("Pick one", systemImage: "shuffle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(canPickRandomWinner ? .white : CloseCutColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(canPickRandomWinner ? CloseCutColors.accent : CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(canPickRandomWinner == false)
                }
                .padding(.top, 2)
            }
        }
    }

    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RECENT RESULTS")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.horizontal, 2)

                Spacer()

                Button {
                    showClearResultsConfirmation = true
                } label: {
                    Text(isClearingResults ? "Clearing…" : "Clear")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(isClearingResults)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(recentBattleResults) { result in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: result.mode.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .frame(width: 32, height: 32)
                            .background(CloseCutColors.input)
                            .clipShape(SwiftUI.Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.winnerTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)
                                .lineLimit(2)

                            Text(resultSubtitle(for: result))
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(result.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(CloseCutColors.textTertiary)
                        }

                        Spacer()
                    }

                    if result.id != recentBattleResults.last?.id {
                        Divider()
                            .overlay(CloseCutColors.separator)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    private var battleModesSection: some View {
        battleSection(title: "Personal battles") {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    showOptionSelector = true
                } label: {
                    battleModeRow(
                        icon: "shuffle",
                        title: "Pick what to watch",
                        status: canStartLocalBattle ? "Available now" : "Need 2 entries",
                        message: "Choose 2+ options and let CloseCut randomly pick one."
                    )
                }
                .buttonStyle(.plain)
                .disabled(canStartLocalBattle == false)

                Divider()
                    .overlay(CloseCutColors.separator)

                Button {
                    showHeadToHeadBattle = true
                } label: {
                    battleModeRow(
                        icon: "bolt.fill",
                        title: "Movie vs Movie",
                        status: canStartLocalBattle ? "Available now" : "Need 2 entries",
                        message: "Put two titles head-to-head and choose what wins for you."
                    )
                }
                .buttonStyle(.plain)
                .disabled(canStartLocalBattle == false)
            }
        }
    }

    private var futureSocialSection: some View {
        battleSection(title: "Social battles") {
            VStack(alignment: .leading, spacing: 14) {
                battleModeRow(
                    icon: "person.2.fill",
                    title: "Friend Battle",
                    status: "Coming later",
                    message: "Compare two picks with one trusted person. Best for a two-person Circle."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                battleModeRow(
                    icon: "person.3.fill",
                    title: "Circle Battle",
                    status: "Coming later",
                    message: "Vote privately with your Circle and pick a group winner."
                )
            }
        }
    }

    private var whyItMattersSection: some View {
        battleSection(title: "Why Battle exists") {
            Text("Battle turns your archive into a decision game. Use it to pick what to watch, compare favorites, and eventually decide with trusted people without turning CloseCut into a public social app.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func battleStatPill(
        value: String,
        label: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
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
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func battleModeRow(
        icon: String,
        title: String,
        status: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 32, height: 32)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Spacer()

                    Text(status)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func battleSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    private func optionSubtitle(for entry: Entry) -> String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }
        if let rating = entry.tmdbRating, rating > 0 {
            parts.append(String(format: "%.1f TMDB", rating))
        }

        if entry.visibility == .circle {
            parts.append("Shared")
        }

        return parts.joined(separator: " • ")
    }

    private func resultSubtitle(for result: BattleResult) -> String {
        switch result.mode {
        case .randomPick:
            return "Picked from \(result.optionTitles.count) options"

        case .headToHead:
            let opponents = result.optionTitles
                .filter { $0 != result.winnerTitle }

            if let opponent = opponents.first {
                return "Won against \(opponent)"
            }

            return "Won a head-to-head Battle"

        case .friend:
            return "Won a Friend Battle"

        case .circle:
            return "Won a Circle Battle"
        }
    }

    private func pickRandomWinner() {
        guard selectedEntries.count >= 2 else {
            pickedEntry = nil
            return
        }

        let possibleWinners: [Entry]

        if let pickedEntry,
           selectedEntries.count > 1 {
            let alternatives = selectedEntries.filter { $0.id != pickedEntry.id }
            possibleWinners = alternatives.isEmpty ? selectedEntries : alternatives
        } else {
            possibleWinners = selectedEntries
        }

        guard let winner = possibleWinners.randomElement() else {
            pickedEntry = nil
            return
        }

        pickedEntry = winner
        battleErrorMessage = nil

        do {
            _ = try battleResultRepository.createRandomPickResult(
                ownerId: user.id,
                options: selectedEntries,
                winner: winner,
                modelContext: modelContext
            )
        } catch BattleResultRepositoryError.duplicateRecentResult {
            #if DEBUG
            print("ℹ️ Skipped duplicate random Battle result.")
            #endif
        } catch {
            battleErrorMessage = "Couldn’t save Battle result."

            #if DEBUG
            print("❌ Failed to save random Battle result:", error.localizedDescription)
            #endif
        }
    }
    private func clearRecentResults() {
        guard isClearingResults == false else {
            return
        }

        isClearingResults = true
        battleErrorMessage = nil

        do {
            let deletedCount = try battleResultRepository.deleteAllResults(
                ownerId: user.id,
                modelContext: modelContext
            )

            isClearingResults = false

            #if DEBUG
            print("✅ Cleared \(deletedCount) Battle results.")
            #endif
        } catch {
            isClearingResults = false
            battleErrorMessage = "Couldn’t clear Battle results."

            #if DEBUG
            print("❌ Failed to clear Battle results:", error.localizedDescription)
            #endif
        }
    }

    private func saveHeadToHeadResult(
        winner: Entry,
        options: [Entry]
    ) {
        battleErrorMessage = nil

        do {
            _ = try battleResultRepository.createHeadToHeadResult(
                ownerId: user.id,
                options: options,
                winner: winner,
                modelContext: modelContext
            )
        } catch BattleResultRepositoryError.duplicateRecentResult {
            #if DEBUG
            print("ℹ️ Skipped duplicate head-to-head Battle result.")
            #endif
        } catch {
            battleErrorMessage = "Couldn’t save Movie vs Movie result."

            #if DEBUG
            print("❌ Failed to save head-to-head Battle result:", error.localizedDescription)
            #endif
        }
    }

    private func clearBattleSelection() {
        pickedEntry = nil
        selectedEntries = []
    }
}

#Preview {
    BattleView(
        user: AuthUser(
            id: "preview-user",
            email: "preview@closecut.dev",
            displayName: "Preview",
            photoURL: nil
        ),
        profile: UserProfile(
            id: "preview-user",
            displayName: "Preview User",
            email: "preview@closecut.dev",
            photoURL: nil,
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
    .modelContainer(for: [
        LocalEntry.self,
        LocalReaction.self,
        LocalComment.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self,
        LocalBattleResult.self
    ], inMemory: true)
}
