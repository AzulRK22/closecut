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
    @State private var showHeadToHeadBattle = false
    @State private var showFriendBattle = false
    @State private var showCircleBattle = false

    @State private var selectedCandidates: [BattleCandidate] = []
    @State private var pickedCandidate: BattleCandidate?

    @State private var battleErrorMessage: String?
    @State private var showClearResultsConfirmation = false
    @State private var isClearingResults = false

    @State private var noRepeatPolicy = BattleNoRepeatPolicy()

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]
    
    @Query(sort: \LocalWatchlistItem.updatedAt, order: .reverse)
    private var localWatchlistItems: [LocalWatchlistItem]

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
                entry.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }
    private var savedWatchlistItems: [WatchlistItem] {
        localWatchlistItems
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
            .filter { item in
                item.status == .saved &&
                item.deletedAt == nil
            }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var watchlistCandidates: [BattleCandidate] {
        BattleCandidateMapper.candidates(from: savedWatchlistItems)
    }

    private var canUseArchiveModes: Bool {
        eligibleEntries.count >= 2
    }

    private var canPickTonight: Bool {
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
        canUseArchiveModes ? "Ready to play" : "Battle is open"
    }

    private var readinessMessage: String {
        if canUseArchiveModes {
            return "Your archive can power duels, and every mode can also use TMDB or manual ideas."
        }

        return "Use Pick for Tonight, Friend Battle, or Circle Battle with TMDB/manual options. Add two archive entries to unlock archive-only history saving."
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

                    gameModesSection

                    if let pickedCandidate {
                        BattlePickResultCard(
                            winner: pickedCandidate,
                            optionCount: selectedCandidates.count,
                            onPickAgain: pickRandomCandidate,
                            onClear: clearBattleSelection
                        )
                    }

                    if selectedCandidates.isEmpty == false {
                        currentShortlistSection
                    }

                    if recentBattleResults.isEmpty == false {
                        recentResultsSection
                    }

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
                watchlistItems: savedWatchlistItems,
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
                        pickRandomCandidate()
                    }
                }
            )
        }
        .sheet(isPresented: $showHeadToHeadBattle) {
            BattleHeadToHeadSheet(
                archiveEntries: eligibleEntries,
                watchlistItems: savedWatchlistItems,
                initialCandidates: selectedCandidates,
                onCancel: {
                    showHeadToHeadBattle = false
                },
                onWinnerSelected: { winner, options in
                    pickedCandidate = winner
                    selectedCandidates = BattleCandidateMapper.dedupe(options)
                    saveCandidateBattleResultIfPossible(
                        winner: winner,
                        options: options,
                        mode: .headToHead
                    )
                }
            )
        }
        .sheet(isPresented: $showFriendBattle) {
            BattleFriendSheet(
                archiveEntries: eligibleEntries,
                watchlistItems: savedWatchlistItems,
                initialSelection: selectedCandidates,
                onCancel: {
                    showFriendBattle = false
                },
                onWinnerSelected: { winner, options in
                    pickedCandidate = winner
                    selectedCandidates = BattleCandidateMapper.dedupe(options)
                    saveCandidateBattleResultIfPossible(
                        winner: winner,
                        options: options,
                        mode: .friend
                    )
                }
            )
        }
        .sheet(isPresented: $showCircleBattle) {
            BattleCircleSheet(
                archiveEntries: eligibleEntries,
                watchlistItems: savedWatchlistItems,
                initialSelection: selectedCandidates,
                onCancel: {
                    showCircleBattle = false
                },
                onWinnerSelected: { winner, options in
                    pickedCandidate = winner
                    selectedCandidates = BattleCandidateMapper.dedupe(options)
                    saveCandidateBattleResultIfPossible(
                        winner: winner,
                        options: options,
                        mode: .circle
                    )
                }
            )
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
                    Text("Make choosing feel like a game.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Use your archive, search TMDB, add quick ideas, or make it social. CloseCut helps you stop scrolling and actually pick something.")
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

                    Image(systemName: "gamecontroller.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }

            HStack(spacing: 10) {
                battleStatPill(
                    value: "\(eligibleEntries.count)",
                    label: "archive",
                    icon: "film.stack"
                )

                battleStatPill(
                    value: "\(savedWatchlistItems.count)",
                    label: "watchlist",
                    icon: "bookmark.fill"
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

    private var readinessStrip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: canUseArchiveModes ? "bolt.fill" : "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(canUseArchiveModes ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
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

    // MARK: - Game Modes

    private var gameModesSection: some View {
        BattleSectionCard(
            title: "Game modes",
            subtitle: "Each mode solves a different kind of watch decision."
        ) {
            VStack(spacing: 14) {
                BattleModeCard(
                    mode: .pickTonight,
                    isPrimary: true,
                    isEnabled: true,
                    action: {
                        showPickTonightSheet = true
                    }
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                BattleModeCard(
                    mode: .headToHead,
                    isPrimary: false,
                    isEnabled: true,
                    action: {
                        showHeadToHeadBattle = true
                    }
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                BattleModeCard(
                    mode: .friend,
                    isPrimary: false,
                    isEnabled: true,
                    action: {
                        showFriendBattle = true
                    }
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                BattleModeCard(
                    mode: .circle,
                    isPrimary: false,
                    isEnabled: true,
                    action: {
                        showCircleBattle = true
                    }
                )
            }
        }
    }

    // MARK: - Shortlist

    private var currentShortlistSection: some View {
        BattleSectionCard(
            title: "Current shortlist",
            subtitle: "\(selectedCandidates.count) options selected"
        ) {
            VStack(spacing: 10) {
                ForEach(selectedCandidates) { candidate in
                    BattleCandidateRow(
                        candidate: candidate,
                        isSelected: candidate.id == pickedCandidate?.id,
                        trailingStyle: .none
                    ) {}
                }

                HStack(spacing: 10) {
                    Button {
                        showPickTonightSheet = true
                    } label: {
                        Text("Edit shortlist")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        pickRandomCandidate()
                    } label: {
                        Label("Pick again", systemImage: "shuffle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(canPickTonight ? .white : CloseCutColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(canPickTonight ? CloseCutColors.accent : CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(canPickTonight == false)
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

                    Text("Saved local Battle decisions from archive-backed results.")
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

    // MARK: - Product Note

    private var productNoteSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Battle is private by default. TMDB and manual options help with decision-making, but nothing is added to your Timeline unless you explicitly log it later.")
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

    private func pickRandomCandidate() {
        guard selectedCandidates.count >= 2 else {
            pickedCandidate = nil
            return
        }

        let picked = noRepeatPolicy.pickRandom(
            from: selectedCandidates,
            avoiding: pickedCandidate?.id
        )

        guard let picked else {
            pickedCandidate = nil
            return
        }

        pickedCandidate = picked
        battleErrorMessage = nil

        saveCandidateBattleResultIfPossible(
            winner: picked,
            options: selectedCandidates,
            mode: .randomPick
        )
    }

    private func saveCandidateBattleResultIfPossible(
        winner: BattleCandidate,
        options: [BattleCandidate],
        mode: BattleMode
    ) {
        guard let winnerEntry = BattleCandidateMapper.entry(
            from: winner,
            eligibleEntries: eligibleEntries
        ) else {
            return
        }

        let optionEntries = BattleCandidateMapper.entries(
            from: options,
            eligibleEntries: eligibleEntries
        )

        guard optionEntries.count >= 2 else {
            return
        }

        do {
            switch mode {
            case .randomPick:
                _ = try battleResultRepository.createRandomPickResult(
                    ownerId: user.id,
                    options: optionEntries,
                    winner: winnerEntry,
                    modelContext: modelContext
                )

            case .headToHead:
                _ = try battleResultRepository.createHeadToHeadResult(
                    ownerId: user.id,
                    options: optionEntries,
                    winner: winnerEntry,
                    modelContext: modelContext
                )

            case .friend:
                _ = try battleResultRepository.createFriendResult(
                    ownerId: user.id,
                    options: optionEntries,
                    winner: winnerEntry,
                    modelContext: modelContext
                )

            case .circle:
                _ = try battleResultRepository.createCircleResult(
                    ownerId: user.id,
                    options: optionEntries,
                    winner: winnerEntry,
                    modelContext: modelContext
                )
            }
        } catch BattleResultRepositoryError.duplicateRecentResult {
            #if DEBUG
            print("ℹ️ Skipped duplicate Battle result.")
            #endif
        } catch {
            battleErrorMessage = "Couldn’t save Battle result."

            #if DEBUG
            print("❌ Failed to save Battle result:", error.localizedDescription)
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
        LocalBattleResult.self,
        LocalWatchlistItem.self
    ], inMemory: true)
}
