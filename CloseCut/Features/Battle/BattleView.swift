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

    @State private var battleMessage: String?
    @State private var battleBannerStyle: SyncResultBannerStyle = .neutral

    @State private var showClearResultsConfirmation = false
    @State private var isClearingResults = false
    @State private var isProcessingWinnerAction = false

    @State private var noRepeatPolicy = BattleNoRepeatPolicy()

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalWatchlistItem.updatedAt, order: .reverse)
    private var localWatchlistItems: [LocalWatchlistItem]

    @Query(sort: \LocalBattleResult.createdAt, order: .reverse)
    private var localBattleResults: [LocalBattleResult]

    private let battleResultRepository = BattleResultRepository()
    private let entryRepository = EntryRepository()
    private let watchlistRepository = WatchlistRepository()

    private var entries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    private var eligibleEntries: [Entry] {
        entries
            .filter { entry in
                entry.displayTitle
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty == false
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
        canUseArchiveModes ? "Game lobby ready" : "Game lobby open"
    }

    private var readinessMessage: String {
        if canUseArchiveModes {
            return "Your Personal archive can power smarter Battles. Want to Watch, TMDB, and manual wildcards can join the arena too."
        }

        return "Battle can still run with Want to Watch, TMDB, and manual options. Add more Personal entries later for stronger taste signals."
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    heroSection

                    if let battleMessage {
                        SyncResultBanner(
                            message: battleMessage,
                            style: battleBannerStyle
                        )
                    }

                    gameModesSection

                    if selectedCandidates.isEmpty == false || pickedCandidate != nil {
                        BattleArenaCard(
                            candidates: selectedCandidates,
                            winner: pickedCandidate,
                            onEdit: {
                                showPickTonightSheet = true
                            },
                            onPickAgain: pickRandomCandidate,
                            onClear: clearBattleSelection
                        )
                    }

                    if let pickedCandidate {
                        BattlePickResultCard(
                            winner: pickedCandidate,
                            optionCount: selectedCandidates.count,
                            onPickAgain: pickRandomCandidate,
                            onClear: clearBattleSelection
                        )

                        BattleWinnerActionCard(
                            winner: pickedCandidate,
                            canAddToPersonal: pickedCandidate.canBeSavedToTimeline,
                            canSaveToWatchlist: pickedCandidate.source == .tmdb || pickedCandidate.source == .manual,
                            isProcessing: isProcessingWinnerAction,
                            onAddToPersonal: {
                                Task {
                                    await addWinnerToPersonal(pickedCandidate)
                                }
                            },
                            onSaveToWatchlist: {
                                Task {
                                    await saveWinnerToWatchlist(pickedCandidate)
                                }
                            }
                        )
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
                    battleMessage = nil
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
                    handleWinnerSelected(
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
                    handleWinnerSelected(
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
                    handleWinnerSelected(
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
                    Text("Enter the Battle lobby.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Build an arena from Personal, Want to Watch, TMDB, or manual wildcards. Then let CloseCut crown tonight’s winner.")
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
                    label: "personal",
                    icon: "film.stack"
                )

                battleStatPill(
                    value: "\(savedWatchlistItems.count)",
                    label: "watchlist",
                    icon: "bookmark.fill"
                )

                battleStatPill(
                    value: "\(selectedCandidates.count)",
                    label: "arena",
                    icon: "gamecontroller.fill"
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
            title: "Choose your Battle mode",
            subtitle: "Different ways to turn indecision into a game."
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

    // MARK: - Recent Results

    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Recent results")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Saved local Battle decisions from Personal, Want to Watch, TMDB, and manual contenders.")
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

            Text("Battle is private by default. External contenders help you decide, but nothing is added to Personal or shared with Circles unless you explicitly choose that later.")
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

    // MARK: - Winner Handling

    private func handleWinnerSelected(
        winner: BattleCandidate,
        options: [BattleCandidate],
        mode: BattleMode
    ) {
        pickedCandidate = winner
        selectedCandidates = BattleCandidateMapper.dedupe(options)
        battleMessage = nil

        saveCandidateBattleResultIfPossible(
            winner: winner,
            options: options,
            mode: mode
        )
    }

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
        battleMessage = nil

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
        let cleanedOptions = BattleCandidateMapper.dedupe(options)

        guard cleanedOptions.count >= 2 else {
            return
        }

        do {
            _ = try battleResultRepository.createCandidateResult(
                ownerId: user.id,
                mode: mode,
                options: cleanedOptions,
                winner: winner,
                modelContext: modelContext
            )
        } catch BattleResultRepositoryError.duplicateRecentResult {
            #if DEBUG
            print("ℹ️ Skipped duplicate Battle result.")
            #endif
        } catch {
            battleBannerStyle = .warning
            battleMessage = "Couldn’t save Battle result."

            #if DEBUG
            print("❌ Failed to save Battle result:", error.localizedDescription)
            #endif
        }
    }

    // MARK: - Winner Actions

    private func addWinnerToPersonal(
        _ winner: BattleCandidate
    ) async {
        guard isProcessingWinnerAction == false else {
            return
        }

        guard winner.canBeSavedToTimeline else {
            battleBannerStyle = .neutral
            battleMessage = "This winner is already in Personal."
            return
        }

        isProcessingWinnerAction = true
        defer { isProcessingWinnerAction = false }

        let draft = QuickAddDraft(
            title: winner.displayTitle,
            type: winner.type,
            releaseYear: winner.releaseYear,
            quickSentiment: nil,
            watchedDateApprox: .unknown,
            externalMetadata: externalMetadata(from: winner)
        )

        do {
            let entry = try entryRepository.createQuickAddEntry(
                ownerId: user.id,
                draft: draft,
                visibility: .privateOnly,
                modelContext: modelContext
            )

            if winner.source == .watchlist {
                markMatchingWatchlistItemWatched(for: winner)
            }

            battleBannerStyle = .success
            battleMessage = "\(entry.displayTitle) was added to Personal."
        } catch {
            battleBannerStyle = .warning
            battleMessage = error.localizedDescription
        }
    }

    private func saveWinnerToWatchlist(
        _ winner: BattleCandidate
    ) async {
        guard isProcessingWinnerAction == false else {
            return
        }

        guard winner.source == .tmdb || winner.source == .manual else {
            battleBannerStyle = .neutral
            battleMessage = "Only TMDB or manual Battle winners can be saved to Want to Watch."
            return
        }

        isProcessingWinnerAction = true
        defer { isProcessingWinnerAction = false }

        do {
            let item = try watchlistRepository.createLocalWatchlistItem(
                ownerId: user.id,
                media: tmdbLikeResult(from: winner),
                source: .battle,
                modelContext: modelContext
            )

            battleBannerStyle = .success
            battleMessage = "\(item.displayTitle) was saved to Want to Watch."
        } catch {
            battleBannerStyle = .warning
            battleMessage = error.localizedDescription
        }
    }

    private func markMatchingWatchlistItemWatched(
        for winner: BattleCandidate
    ) {
        guard winner.source == .watchlist else {
            return
        }

        guard let matchingItem = savedWatchlistItems.first(where: {
            $0.displayTitle.normalizedTitleKey == winner.displayTitle.normalizedTitleKey &&
            $0.type == winner.type
        }) else {
            return
        }

        do {
            _ = try watchlistRepository.markLocalWatchlistItemWatched(
                itemId: matchingItem.id,
                modelContext: modelContext
            )
        } catch {
            #if DEBUG
            print("⚠️ Could not mark watchlist item watched from Battle:", error.localizedDescription)
            #endif
        }
    }

    private func externalMetadata(
        from candidate: BattleCandidate
    ) -> EntryExternalMetadata? {
        guard candidate.tmdbId != nil,
              candidate.tmdbMediaTypeRaw != nil else {
            return nil
        }

        return EntryExternalMetadata(
            tmdbResult: tmdbLikeResult(from: candidate)
        )
    }

    private func tmdbLikeResult(
        from candidate: BattleCandidate
    ) -> TMDBMediaSearchResult {
        let resolvedTMDBId = candidate.tmdbId ?? abs(candidate.id.hashValue)
        let resolvedMediaType = resolvedMediaType(from: candidate)

        return TMDBMediaSearchResult(
            id: "battle-\(resolvedMediaType.rawValue)-\(resolvedTMDBId)",
            tmdbId: resolvedTMDBId,
            mediaType: resolvedMediaType,
            title: candidate.displayTitle,
            releaseYear: candidate.releaseYear,
            overview: candidate.overview,
            posterPath: candidate.posterPath,
            backdropPath: candidate.backdropPath,
            voteAverage: candidate.tmdbRating,
            popularity: candidate.tmdbPopularity,
            genreIds: candidate.tmdbGenreIds
        )
    }

    private func resolvedMediaType(
        from candidate: BattleCandidate
    ) -> TMDBMediaType {
        if let raw = candidate.tmdbMediaTypeRaw,
           let mediaType = TMDBMediaType(rawValue: raw) {
            return mediaType
        }

        return candidate.type == .series ? .tv : .movie
    }

    // MARK: - Clear

    private func clearRecentResults() {
        guard isClearingResults == false else {
            return
        }

        isClearingResults = true
        battleMessage = nil

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
            battleBannerStyle = .warning
            battleMessage = "Couldn’t clear Battle results."

            #if DEBUG
            print("❌ Failed to clear Battle results:", error.localizedDescription)
            #endif
        }
    }

    private func clearBattleSelection() {
        pickedCandidate = nil
        selectedCandidates = []
        battleMessage = nil
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
