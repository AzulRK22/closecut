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

    @State private var showPickTonightSheet = false
    @State private var selectedCandidates: [BattleCandidate] = []
    @State private var pickedCandidate: BattleCandidate?

    @State private var showHeadToHeadBattle = false
    @State private var battleErrorMessage: String?
    @State private var showClearResultsConfirmation = false
    @State private var isClearingResults = false

    @State private var noRepeatPolicy = BattleNoRepeatPolicy()

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalBattleResult.createdAt, order: .reverse)
    private var localBattleResults: [LocalBattleResult]

    private let battleResultRepository = BattleResultRepository()

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

    private var archiveCandidates: [BattleCandidate] {
        BattleCandidateMapper.candidates(from: eligibleEntries)
    }

    private var canStartLocalBattle: Bool {
        archiveCandidates.count >= 2
    }

    private var canPickRandomWinner: Bool {
        selectedCandidates.count >= 2
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
        archiveCandidates.count >= 2
            ? "Ready to play"
            : "Use TMDB or add another title"
    }

    private var readinessMessage: String {
        archiveCandidates.count >= 2
            ? "Your archive is ready, and you can also add new TMDB or manual options."
            : "You can still use Pick for Tonight with TMDB or manual ideas even if your archive is small."
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

                    if let pickedCandidate {
                        BattlePickResultCard(
                            winner: pickedCandidate,
                            optionCount: selectedCandidates.count,
                            onPickAgain: pickRandomWinner,
                            onClear: clearBattleSelection
                        )
                    }

                    if selectedCandidates.isEmpty == false {
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
        .sheet(isPresented: $showPickTonightSheet) {
            BattlePickTonightSheet(
                archiveEntries: eligibleEntries,
                initialSelection: selectedCandidates,
                onCancel: {
                    showPickTonightSheet = false
                },
                onConfirm: { candidates in
                    selectedCandidates = BattleCandidateMapper.dedupe(candidates)
                    pickedCandidate = nil
                    battleErrorMessage = nil
                    showPickTonightSheet = false

                    if selectedCandidates.count >= 2 {
                        pickRandomWinner()
                    }
                }
            )
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
                    Text("Tonight, make choosing feel like a game.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Use your archive, search anything on TMDB, or add a quick idea. Battle helps you stop scrolling and pick.")
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

                    Image(systemName: "gamecontroller.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }

            HStack(spacing: 10) {
                battleStatPill(
                    value: "\(archiveCandidates.count)",
                    label: "archive",
                    icon: "film.stack"
                )

                battleStatPill(
                    value: "\(selectedCandidates.count)",
                    label: "shortlist",
                    icon: "checkmark.circle.fill"
                )

                battleStatPill(
                    value: "\(recentBattleResults.count)",
                    label: "results",
                    icon: "trophy.fill"
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
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
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

    private func latestResultStrip(
        _ result: BattleResult
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: result.mode.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("Last result")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("\(result.winnerTitle) • \(BattleResultDisplayHelper.subtitle(for: result))")
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

    // MARK: - Primary Modes

    private var primaryBattleCard: some View {
        BattleSectionCard(
            title: "Choose a game mode",
            subtitle: "Battle should feel fast, playful, and useful."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                BattleModeCard(
                    mode: .pickTonight,
                    isPrimary: true,
                    isEnabled: true
                ) {
                    showPickTonightSheet = true
                }

                Divider()
                    .overlay(CloseCutColors.separator)

                BattleModeCard(
                    mode: .headToHead,
                    isPrimary: false,
                    isEnabled: canStartLocalBattle
                ) {
                    showHeadToHeadBattle = true
                }
            }
        }
    }

    // MARK: - Selected Options

    private var selectedOptionsSection: some View {
        BattleSectionCard(
            title: "Current shortlist",
            subtitle: "\(selectedCandidates.count) options selected"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(selectedCandidates) { candidate in
                    BattleCandidateRow(
                        candidate: candidate,
                        isSelected: true,
                        trailingStyle: .none
                    ) {}

                    if candidate.id != selectedCandidates.last?.id {
                        Divider()
                            .overlay(CloseCutColors.separator)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        showPickTonightSheet = true
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
                    Text("Recent archive results")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Saved results from archive-based Battles.")
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
                    recentResultRow(result)

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

    private func recentResultRow(
        _ result: BattleResult
    ) -> some View {
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

                Text(BattleResultDisplayHelper.subtitle(for: result))
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(result.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Social Preview

    private var socialPreviewSection: some View {
        BattleSectionCard(
            title: "Social battles",
            subtitle: "Coming later"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                compactFutureRow(
                    icon: "person.2.fill",
                    title: "Friend Battle",
                    message: "Compare options with one trusted person."
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

            Text("Battle does not publish anything. TMDB and manual options are only used to help you decide unless you later save them to your Timeline.")
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

    // MARK: - Actions

    private func pickRandomWinner() {
        guard selectedCandidates.count >= 2 else {
            pickedCandidate = nil
            return
        }

        let currentWinnerId = pickedCandidate?.id

        guard let winner = noRepeatPolicy.pickRandom(
            from: selectedCandidates,
            avoiding: currentWinnerId
        ) else {
            pickedCandidate = nil
            return
        }

        pickedCandidate = winner
        battleErrorMessage = nil

        saveRandomPickIfArchiveOnly(
            winner: winner,
            options: selectedCandidates
        )
    }

    private func saveRandomPickIfArchiveOnly(
        winner: BattleCandidate,
        options: [BattleCandidate]
    ) {
        guard winner.source == .archive,
              let winnerEntryId = winner.sourceEntryId else {
            return
        }

        let archiveOptionEntryIds = options.compactMap { candidate in
            candidate.source == .archive ? candidate.sourceEntryId : nil
        }

        guard archiveOptionEntryIds.count == options.count else {
            return
        }

        let entriesById = Dictionary(
            uniqueKeysWithValues: eligibleEntries.map { ($0.id, $0) }
        )

        guard let winnerEntry = entriesById[winnerEntryId] else {
            return
        }

        let optionEntries = archiveOptionEntryIds.compactMap { entriesById[$0] }

        guard optionEntries.count >= 2 else {
            return
        }

        do {
            _ = try battleResultRepository.createRandomPickResult(
                ownerId: user.id,
                options: optionEntries,
                winner: winnerEntry,
                modelContext: modelContext
            )
        } catch BattleResultRepositoryError.duplicateRecentResult {
            #if DEBUG
            print("ℹ️ Skipped duplicate random Battle result.")
            #endif
        } catch {
            battleErrorMessage = "Couldn’t save archive Battle result."

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
        pickedCandidate = nil
        selectedCandidates = []
        noRepeatPolicy.reset()
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
