//
//  BattleHeadToHeadSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct BattleHeadToHeadSheet: View {
    let archiveEntries: [Entry]
    let initialCandidates: [BattleCandidate]
    let onCancel: () -> Void
    let onWinnerSelected: (BattleCandidate, [BattleCandidate]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var firstCandidate: BattleCandidate?
    @State private var secondCandidate: BattleCandidate?

    @State private var query = ""
    @State private var tmdbResults: [BattleCandidate] = []
    @State private var isSearching = false
    @State private var searchErrorMessage: String?
    @State private var didSearch = false

    @State private var manualTitle = ""
    @State private var manualType: EntryType = .movie

    @State private var currentRoundIndex = 0
    @State private var firstScore = 0
    @State private var secondScore = 0
    @State private var winner: BattleCandidate?
    @State private var didSaveResult = false
    @State private var selectedRoundAnswers: [Int: String] = [:]
    @State private var isAdvancingRound = false
    @State private var lastRoundWinnerTitle: String?

    @FocusState private var focusedField: Field?

    private let tmdbRepository = TMDBMediaRepository()

    private enum Field {
        case search
        case manual
    }

    private let rounds: [DuelRound] = [
        DuelRound(
            id: "tonight-fit",
            title: "Tonight’s vibe",
            question: "Which one fits tonight better?",
            systemImage: "moon.stars.fill"
        ),
        DuelRound(
            id: "stronger-memory",
            title: "Stronger pull",
            question: "Which one feels more worth your time?",
            systemImage: "sparkles"
        ),
        DuelRound(
            id: "recommend-first",
            title: "Recommend first",
            question: "Which one would you recommend first?",
            systemImage: "person.crop.circle.badge.checkmark"
        ),
        DuelRound(
            id: "rewatch-energy",
            title: "Rewatch energy",
            question: "Which one would you revisit sooner?",
            systemImage: "arrow.clockwise.circle.fill"
        ),
        DuelRound(
            id: "final-instinct",
            title: "Final instinct",
            question: "No overthinking. Which one wins?",
            systemImage: "bolt.fill"
        )
    ]

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

    private var canSearch: Bool {
        cleanedQuery.count >= 2 && isSearching == false
    }

    private var canAddManual: Bool {
        cleanedManualTitle.isEmpty == false
    }

    private var canStartDuel: Bool {
        guard let firstCandidate, let secondCandidate else {
            return false
        }

        return firstCandidate.normalizedIdentityKey != secondCandidate.normalizedIdentityKey
    }

    private var isDuelComplete: Bool {
        winner != nil
    }

    private var currentRound: DuelRound {
        rounds[min(currentRoundIndex, rounds.count - 1)]
    }

    private var progressText: String {
        if isDuelComplete {
            return "Final result"
        }

        return "Round \(min(currentRoundIndex + 1, rounds.count)) of \(rounds.count)"
    }

    private var progressValue: Double {
        guard rounds.isEmpty == false else {
            return 0
        }

        if isDuelComplete {
            return 1
        }

        return Double(min(currentRoundIndex + 1, rounds.count)) / Double(rounds.count)
    }

    private var selectedAnswerIdForCurrentRound: String? {
        selectedRoundAnswers[currentRoundIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header

                        contenderSlotsSection

                        searchSection

                        tmdbResultsSection

                        manualSection

                        archiveSection

                        if canStartDuel {
                            scoreboardSection
                            roundFeedbackSection
                            duelSection
                        }

                        if let winner {
                            winnerSection(winner)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Movie vs Movie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            let deduped = BattleCandidateMapper.dedupe(initialCandidates)

            if firstCandidate == nil {
                firstCandidate = deduped.first
            }

            if secondCandidate == nil {
                secondCandidate = deduped.dropFirst().first
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Settle it in 5 rounds.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Choose two contenders from your archive, TMDB, or manual ideas. Then answer quick prompts and CloseCut crowns the winner.")
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

                    Image(systemName: "bolt.fill")
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
                    icon: "sparkles.tv",
                    text: "TMDB"
                )

                infoPill(
                    icon: "gamecontroller.fill",
                    text: "5 rounds"
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

    // MARK: - Contender Slots

    private var contenderSlotsSection: some View {
        BattleSectionCard(
            title: "Choose the matchup",
            subtitle: "Tap any result below to fill the next open challenger slot."
        ) {
            VStack(spacing: 12) {
                contenderSlot(
                    title: "Challenger A",
                    candidate: firstCandidate,
                    side: "A"
                ) {
                    firstCandidate = nil
                    resetDuelOnly()
                }

                contenderSlot(
                    title: "Challenger B",
                    candidate: secondCandidate,
                    side: "B"
                ) {
                    secondCandidate = nil
                    resetDuelOnly()
                }

                if let firstCandidate,
                   let secondCandidate,
                   firstCandidate.normalizedIdentityKey == secondCandidate.normalizedIdentityKey {
                    Text("Choose two different contenders.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.failed)
                }

                if canStartDuel {
                    Button {
                        resetDuelOnly()
                    } label: {
                        Label("Restart duel", systemImage: "arrow.counterclockwise")
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

    private func contenderSlot(
        title: String,
        candidate: BattleCandidate?,
        side: String,
        onRemove: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(side)
                .font(.caption2.weight(.bold))
                .foregroundStyle(candidate == nil ? CloseCutColors.textTertiary : .white)
                .frame(width: 28, height: 28)
                .background(candidate == nil ? CloseCutColors.input : CloseCutColors.accent)
                .clipShape(SwiftUI.Circle())

            if let candidate {
                BattleCandidatePosterView(
                    candidate: candidate,
                    width: 48,
                    height: 70,
                    cornerRadius: 11
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .tracking(0.8)

                    Text(candidate.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)

                    Text(candidate.metadataText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .tracking(0.8)

                    Text("Select a contender below")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Search

    private var searchSection: some View {
        BattleSectionCard(
            title: "Search contender",
            subtitle: "Use TMDB when the title is not in your archive."
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
    private var tmdbResultsSection: some View {
        if tmdbResults.isEmpty == false {
            BattleSectionCard(
                title: "TMDB results",
                subtitle: "Tap a title to assign it to the next open challenger slot."
            ) {
                VStack(spacing: 10) {
                    ForEach(tmdbResults) { candidate in
                        BattleCandidateRow(
                            candidate: candidate,
                            isSelected: isSelected(candidate)
                        ) {
                            selectCandidate(candidate)
                        }
                    }
                }
            }
        } else if didSearch && isSearching == false && searchErrorMessage == nil {
            BattleSectionCard(
                title: "No TMDB matches",
                subtitle: "Try a shorter query or add it manually."
            ) {
                Text("No results found for “\(cleanedQuery)”.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
            }
        }
    }

    // MARK: - Manual

    private var manualSection: some View {
        BattleSectionCard(
            title: "Manual contender",
            subtitle: "Add a quick title without searching."
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
                    Label("Add as contender", systemImage: "plus")
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
            subtitle: "Tap a title to assign it to the next open challenger slot."
        ) {
            if archiveCandidates.isEmpty {
                EmptyStateView(
                    title: "No archive options yet",
                    message: "Use TMDB search or manual contenders for this duel.",
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
                            selectCandidate(candidate)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Scoreboard

    @ViewBuilder
    private var scoreboardSection: some View {
        if let firstCandidate, let secondCandidate {
            BattleSectionCard(
                title: "Scoreboard",
                subtitle: progressText
            ) {
                VStack(spacing: 14) {
                    ProgressView(value: progressValue)
                        .tint(CloseCutColors.accent)

                    HStack(spacing: 12) {
                        scoreCard(
                            candidate: firstCandidate,
                            score: firstScore,
                            side: "A",
                            isLeading: firstScore >= secondScore && firstScore > 0
                        )

                        Text("VS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CloseCutColors.textTertiary)

                        scoreCard(
                            candidate: secondCandidate,
                            score: secondScore,
                            side: "B",
                            isLeading: secondScore >= firstScore && secondScore > 0
                        )
                    }
                }
            }
        }
    }

    private func scoreCard(
        candidate: BattleCandidate,
        score: Int,
        side: String,
        isLeading: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(side)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isLeading ? .white : CloseCutColors.textTertiary)
                    .frame(width: 24, height: 24)
                    .background(isLeading ? CloseCutColors.accent : CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                Spacer()

                Text("\(score)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(CloseCutColors.textPrimary)
            }

            Text(candidate.displayTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isLeading ? CloseCutColors.accent.opacity(0.12) : CloseCutColors.input.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isLeading ? CloseCutColors.accentLight.opacity(0.7) : CloseCutColors.separator,
                    lineWidth: isLeading ? 0.9 : 0.5
                )
        }
    }

    // MARK: - Round Feedback

    @ViewBuilder
    private var roundFeedbackSection: some View {
        if let lastRoundWinnerTitle, winner == nil {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .padding(.top, 2)

                Text("\(lastRoundWinnerTitle) took the last round.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Duel

    @ViewBuilder
    private var duelSection: some View {
        if let firstCandidate, let secondCandidate, winner == nil {
            BattleSectionCard(
                title: currentRound.title,
                subtitle: progressText
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            SwiftUI.Circle()
                                .fill(CloseCutColors.accent.opacity(0.18))
                                .frame(width: 38, height: 38)

                            Image(systemName: currentRound.systemImage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CloseCutColors.accentLight)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text(currentRound.question)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(isAdvancingRound ? "Locking answer…" : "Tap the title that wins this round.")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        duelOptionButton(
                            candidate: firstCandidate,
                            side: "A"
                        )

                        duelOptionButton(
                            candidate: secondCandidate,
                            side: "B"
                        )
                    }
                }
            }
        }
    }

    private func duelOptionButton(
        candidate: BattleCandidate,
        side: String
    ) -> some View {
        let isSelected = selectedAnswerIdForCurrentRound == candidate.id
        let isLockedOut = isAdvancingRound || winner != nil

        return Button {
            answerRound(with: candidate)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    BattleCandidatePosterView(
                        candidate: candidate,
                        width: 126,
                        height: 184,
                        cornerRadius: 18
                    )

                    Text(side)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(CloseCutColors.accent)
                        .clipShape(SwiftUI.Circle())
                        .padding(8)
                }
                .frame(maxWidth: .infinity)

                Text(candidate.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(candidate.primarySignalText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                if isSelected {
                    Label("Round locked", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? CloseCutColors.accent.opacity(0.12) : CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isSelected ? CloseCutColors.accentLight.opacity(0.85) : CloseCutColors.separator,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            }
            .scaleEffect(isSelected ? 0.98 : 1)
            .opacity(isLockedOut && isSelected == false ? 0.58 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLockedOut)
    }

    // MARK: - Winner

    private func winnerSection(
        _ winner: BattleCandidate
    ) -> some View {
        BattleSectionCard(
            title: "Duel complete",
            subtitle: "CloseCut crowned a winner based on your answers."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                winnerHero(winner)

                HStack(spacing: 10) {
                    Button {
                        resetDuelOnly()
                    } label: {
                        Label("Play again", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(CloseCutColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        firstCandidate = nil
                        secondCandidate = nil
                        resetDuelOnly()
                    } label: {
                        Text("New matchup")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func winnerHero(
        _ winner: BattleCandidate
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                BattleCandidatePosterView(
                    candidate: winner,
                    width: 94,
                    height: 138,
                    cornerRadius: 19
                )

                ZStack {
                    SwiftUI.Circle()
                        .fill(CloseCutColors.backgroundPrimary)
                        .frame(width: 34, height: 34)

                    Image(systemName: "crown.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
                .offset(x: 6, y: 6)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Winner")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .tracking(0.8)
                    .textCase(.uppercase)

                Text(winner.displayTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(winner.metadataText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)

                Text(winnerExplanation)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    winnerPill(
                        icon: "number",
                        text: "\(max(firstScore, secondScore)) / \(rounds.count)"
                    )

                    winnerPill(
                        icon: winner.source.systemImage,
                        text: winner.source.shortDisplayName
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    CloseCutColors.input.opacity(0.9),
                    CloseCutColors.accent.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.55), lineWidth: 0.8)
        }
    }

    private func winnerPill(
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
        .background(CloseCutColors.card)
        .clipShape(Capsule())
    }

    private var winnerExplanation: String {
        if firstScore == secondScore {
            return "The duel ended tied, so CloseCut used your final instinct as the tiebreaker."
        }

        let winningScore = max(firstScore, secondScore)
        return "Won \(winningScore) of \(rounds.count) rounds in this head-to-head taste battle."
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
            searchErrorMessage = "Couldn’t search TMDB right now. You can still add a manual contender."

            #if DEBUG
            print("⚠️ Duel TMDB search failed:", error.localizedDescription)
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

        selectCandidate(candidate)
        manualTitle = ""
    }

    private func selectCandidate(
        _ candidate: BattleCandidate
    ) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if firstCandidate == nil {
                firstCandidate = candidate
            } else if secondCandidate == nil {
                secondCandidate = candidate
            } else {
                secondCandidate = candidate
            }

            resetDuelOnly()
        }
    }

    private func isSelected(
        _ candidate: BattleCandidate
    ) -> Bool {
        firstCandidate?.normalizedIdentityKey == candidate.normalizedIdentityKey ||
        secondCandidate?.normalizedIdentityKey == candidate.normalizedIdentityKey
    }

    private func answerRound(
        with candidate: BattleCandidate
    ) {
        guard let firstCandidate, let secondCandidate else {
            return
        }

        guard winner == nil else {
            return
        }

        guard isAdvancingRound == false else {
            return
        }

        isAdvancingRound = true
        selectedRoundAnswers[currentRoundIndex] = candidate.id
        lastRoundWinnerTitle = candidate.displayTitle

        withAnimation(.easeInOut(duration: 0.18)) {
            if candidate.id == firstCandidate.id {
                firstScore += 1
            } else if candidate.id == secondCandidate.id {
                secondScore += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            advanceRound()
        }
    }

    private func advanceRound() {
        guard let firstCandidate, let secondCandidate else {
            isAdvancingRound = false
            return
        }

        if currentRoundIndex < rounds.count - 1 {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentRoundIndex += 1
                isAdvancingRound = false
            }
            return
        }

        let resolvedWinner: BattleCandidate

        if firstScore > secondScore {
            resolvedWinner = firstCandidate
        } else if secondScore > firstScore {
            resolvedWinner = secondCandidate
        } else {
            let finalAnswerId = selectedRoundAnswers[rounds.count - 1]
            resolvedWinner = finalAnswerId == secondCandidate.id ? secondCandidate : firstCandidate
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            winner = resolvedWinner
            isAdvancingRound = false
        }

        saveWinnerIfNeeded(
            winner: resolvedWinner,
            options: [firstCandidate, secondCandidate]
        )
    }

    private func saveWinnerIfNeeded(
        winner: BattleCandidate,
        options: [BattleCandidate]
    ) {
        guard didSaveResult == false else {
            return
        }

        didSaveResult = true
        onWinnerSelected(winner, options)
    }

    private func resetDuelOnly() {
        currentRoundIndex = 0
        firstScore = 0
        secondScore = 0
        winner = nil
        didSaveResult = false
        selectedRoundAnswers = [:]
        isAdvancingRound = false
        lastRoundWinnerTitle = nil
    }
}

// MARK: - Duel Round

private struct DuelRound: Identifiable {
    let id: String
    let title: String
    let question: String
    let systemImage: String
}
