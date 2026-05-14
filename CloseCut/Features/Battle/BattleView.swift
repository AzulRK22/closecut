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

    private var entries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    private var eligibleEntries: [Entry] {
        entries
            .filter { entry in
                entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var canStartLocalBattle: Bool {
        eligibleEntries.count >= 2
    }

    private var recentBattleResults: [BattleResult] {
        Array(
            localBattleResults
                .filter { $0.ownerId == user.id }
                .map { $0.domain }
                .filter {
                    $0.winnerTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
                    $0.optionTitles.isEmpty == false
                }
                .prefix(5)
        )
    }

    private var latestBattleResult: BattleResult? {
        recentBattleResults.first
    }

    private var readinessTitle: String {
        canStartLocalBattle ? "Ready to play" : "Add one more title"
    }

    private var readinessMessage: String {
        canStartLocalBattle
            ? "Your archive has enough memories to run a pick or compare two titles."
            : "Battle unlocks when your Personal Timeline has at least two movies or series."
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    heroSection

                    if let battleErrorMessage {
                        SyncResultBanner(
                            message: battleErrorMessage,
                            style: .warning
                        )
                    }

                    primaryBattleCard

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

                    socialPreviewSection

                    productNoteSection

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

                    if entries.count >= 2 {
                        pickRandomWinner()
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHeadToHeadBattle) {
            BattleHeadToHeadSheet(
                entries: eligibleEntries,
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Tonight, let your archive decide.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Turn your watch history into a game: pick what to watch, compare favorites, or settle a decision without endless scrolling.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    SwiftUI.Circle()
                        .fill(CloseCutColors.accent.opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: "bolt.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }

            HStack(spacing: 10) {
                battleStatPill(
                    value: "\(eligibleEntries.count)",
                    label: "eligible",
                    icon: "film.stack"
                )

                battleStatPill(
                    value: "\(recentBattleResults.count)",
                    label: "results",
                    icon: "trophy.fill"
                )

                battleStatPill(
                    value: canStartLocalBattle ? "Ready" : "Soon",
                    label: "status",
                    icon: canStartLocalBattle ? "checkmark.circle.fill" : "clock.fill"
                )
            }

            if let latestBattleResult {
                latestResultStrip(latestBattleResult)
            } else {
                readinessStrip
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    CloseCutColors.card,
                    CloseCutColors.card.opacity(0.92),
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

    private var readinessStrip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: canStartLocalBattle ? "gamecontroller.fill" : "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(canStartLocalBattle ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(readinessTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(readinessMessage)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func latestResultStrip(_ result: BattleResult) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: result.mode.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("Last result")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("\(result.winnerTitle) • \(resultSubtitle(for: result))")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    // MARK: - Primary Battle Card

    private var primaryBattleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose a mode")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Start simple. Battle works best when it feels like a quick decision, not another form.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                showOptionSelector = true
            } label: {
                premiumModeRow(
                    icon: "shuffle",
                    title: "Pick for tonight",
                    badge: canStartLocalBattle ? "Available now" : "Need 2 titles",
                    message: "Choose 2+ options from your archive and let CloseCut pick one.",
                    isPrimary: true,
                    isEnabled: canStartLocalBattle
                )
            }
            .buttonStyle(.plain)
            .disabled(canStartLocalBattle == false)

            Divider()
                .overlay(CloseCutColors.separator)

            Button {
                showHeadToHeadBattle = true
            } label: {
                premiumModeRow(
                    icon: "bolt.fill",
                    title: "Movie vs Movie",
                    badge: canStartLocalBattle ? "Available now" : "Need 2 titles",
                    message: "Put two titles head-to-head and choose what wins for you.",
                    isPrimary: false,
                    isEnabled: canStartLocalBattle
                )
            }
            .buttonStyle(.plain)
            .disabled(canStartLocalBattle == false)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func premiumModeRow(
        icon: String,
        title: String,
        badge: String,
        message: String,
        isPrimary: Bool,
        isEnabled: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(isPrimary && isEnabled ? CloseCutColors.accent.opacity(0.22) : CloseCutColors.input)
                    .frame(width: 46, height: 46)

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isEnabled ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isEnabled ? CloseCutColors.textPrimary : CloseCutColors.textTertiary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isEnabled ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(CloseCutColors.input)
                        .clipShape(Capsule())
                }

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isEnabled ? CloseCutColors.textTertiary : CloseCutColors.inactive)
                .padding(.top, 17)
        }
        .contentShape(Rectangle())
        .opacity(isEnabled ? 1 : 0.65)
    }

    // MARK: - Selected Options

    private var selectedOptionsSection: some View {
        battleSection(
            title: "Current shortlist",
            subtitle: "\(selectedEntries.count) options selected"
        ) {
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

                        Spacer(minLength: 0)
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
                        Text("Change options")
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
                        Label("Pick again", systemImage: "shuffle")
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

    // MARK: - Recent Results

    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Recent results")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Your last local Battle decisions.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }

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
            .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(recentBattleResults) { result in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: result.mode.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .frame(width: 34, height: 34)
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

                        Spacer(minLength: 0)
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
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    // MARK: - Social Preview

    private var socialPreviewSection: some View {
        battleSection(
            title: "Social battles",
            subtitle: "Coming later"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                compactFutureRow(
                    icon: "person.2.fill",
                    title: "Friend Battle",
                    message: "Compare picks with one trusted person."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                compactFutureRow(
                    icon: "person.3.fill",
                    title: "Circle Battle",
                    message: "Let a private Circle vote and choose a group winner."
                )
            }
        }
    }

    private func compactFutureRow(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .frame(width: 32, height: 32)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .opacity(0.86)
    }

    // MARK: - Product Note

    private var productNoteSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Battle uses your private local archive. Results help you remember decisions, but they do not publish anything publicly.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    // MARK: - Shared UI

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
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.input.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func battleSection<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }
            }
            .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    // MARK: - Text Helpers

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

    // MARK: - Actions

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
            showClearResultsConfirmation = false

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
    NavigationStack {
        BattleView(
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
    .modelContainer(for: [
        LocalEntry.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self,
        LocalBattleResult.self
    ], inMemory: true)
}
