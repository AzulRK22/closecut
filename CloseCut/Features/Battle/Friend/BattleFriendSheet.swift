//
//  BattleFriendSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 15/05/26.
//

import SwiftUI

struct BattleFriendSheet: View {
    let archiveEntries: [Entry]
    let watchlistItems: [WatchlistItem]
    let initialSelection: [BattleCandidate]
    let onCancel: () -> Void
    let onWinnerSelected: (BattleCandidate, [BattleCandidate]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCandidates: [BattleCandidate] = []
    @State private var showPicker = false
    @State private var currentRoundIndex = 0
    @State private var scores: [String: Int] = [:]
    @State private var winner: BattleCandidate?
    @State private var lastAnswerTitle: String?

    private let rounds: [FriendRound] = [
        FriendRound(
            id: "safe-pick",
            title: "Safe pick",
            question: "Which one feels safest for both of you?",
            systemImage: "checkmark.shield.fill"
        ),
        FriendRound(
            id: "fun-energy",
            title: "Fun energy",
            question: "Which one sounds more fun tonight?",
            systemImage: "sparkles"
        ),
        FriendRound(
            id: "bold-choice",
            title: "Bold choice",
            question: "Which one is the better wildcard?",
            systemImage: "die.face.5.fill"
        ),
        FriendRound(
            id: "final-vote",
            title: "Final vote",
            question: "Pass the phone. Which one wins?",
            systemImage: "hand.tap.fill"
        )
    ]

    private var currentRound: FriendRound {
        rounds[min(currentRoundIndex, rounds.count - 1)]
    }

    private var canPlay: Bool {
        selectedCandidates.count >= 2
    }

    private var progressText: String {
        if winner != nil {
            return "Final result"
        }

        return "Round \(min(currentRoundIndex + 1, rounds.count)) of \(rounds.count)"
    }

    private var progressValue: Double {
        if winner != nil {
            return 1
        }

        return Double(min(currentRoundIndex + 1, rounds.count)) / Double(rounds.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header

                        shortlistSection

                        if canPlay {
                            scoreboardSection
                            feedbackSection
                            roundSection
                        }

                        if let winner {
                            winnerSection(winner)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Friend Battle")
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
        .sheet(isPresented: $showPicker) {
            BattlePickTonightSheet(
                archiveEntries: archiveEntries,
                watchlistItems: watchlistItems,
                initialSelection: selectedCandidates,
                onCancel: {
                    showPicker = false
                },
                onConfirm: { candidates in
                    selectedCandidates = BattleCandidateMapper.dedupe(candidates)
                    resetGame()
                    showPicker = false
                }
            )
        }
        .onAppear {
            selectedCandidates = BattleCandidateMapper.dedupe(initialSelection)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Pass the phone.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Build a shared shortlist, answer quick rounds, and let CloseCut pick the best option for two people.")
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

                    Image(systemName: "person.2.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }

            HStack(spacing: 8) {
                infoPill(icon: "hand.tap.fill", text: "Pass & play")
                infoPill(icon: "lock.fill", text: "Local")
                infoPill(icon: "checkmark.circle.fill", text: "\(selectedCandidates.count) options")
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

    // MARK: - Shortlist

    private var shortlistSection: some View {
        BattleSectionCard(
            title: canPlay ? "Friend shortlist" : "Build a shortlist",
            subtitle: canPlay ? "Ready for pass-and-play rounds." : "Add at least two options."
        ) {
            VStack(spacing: 12) {
                if selectedCandidates.isEmpty {
                    Text("Start with titles from archive, TMDB, or manual ideas.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    ForEach(selectedCandidates) { candidate in
                        BattleCandidateRow(
                            candidate: candidate,
                            isSelected: candidate.id == winner?.id,
                            trailingStyle: .none
                        ) {}
                    }
                }

                Button {
                    showPicker = true
                } label: {
                    Label(canPlay ? "Edit shortlist" : "Choose options", systemImage: "plus.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Scoreboard

    private var scoreboardSection: some View {
        BattleSectionCard(
            title: "Scoreboard",
            subtitle: progressText
        ) {
            VStack(spacing: 12) {
                ProgressView(value: progressValue)
                    .tint(CloseCutColors.accent)

                ForEach(selectedCandidates) { candidate in
                    scoreRow(candidate)
                }
            }
        }
    }

    private func scoreRow(
        _ candidate: BattleCandidate
    ) -> some View {
        let score = scores[candidate.id, default: 0]
        let isLeading = score > 0 && score == scores.values.max()

        return HStack(spacing: 10) {
            BattleCandidatePosterView(
                candidate: candidate,
                width: 34,
                height: 50,
                cornerRadius: 8
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.displayTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)

                Text(candidate.source.shortDisplayName)
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer()

            Text("\(score)")
                .font(.headline.weight(.bold))
                .foregroundStyle(isLeading ? CloseCutColors.accentLight : CloseCutColors.textSecondary)
        }
        .padding(10)
        .background(isLeading ? CloseCutColors.accent.opacity(0.10) : CloseCutColors.input.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Feedback

    @ViewBuilder
    private var feedbackSection: some View {
        if let lastAnswerTitle, winner == nil {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .padding(.top, 2)

                Text("\(lastAnswerTitle) got the last vote.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }

    // MARK: - Round

    @ViewBuilder
    private var roundSection: some View {
        if winner == nil {
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

                            Text("Tap the option that wins this friend round.")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }

                    VStack(spacing: 10) {
                        ForEach(selectedCandidates) { candidate in
                            BattleCandidateRow(
                                candidate: candidate,
                                isSelected: false,
                                trailingStyle: .chevron
                            ) {
                                answerRound(with: candidate)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Winner

    private func winnerSection(
        _ winner: BattleCandidate
    ) -> some View {
        BattleSectionCard(
            title: "Friend pick",
            subtitle: "CloseCut chose the strongest shared option."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                BattlePickResultCard(
                    winner: winner,
                    optionCount: selectedCandidates.count,
                    onPickAgain: {
                        rerollWinner()
                    },
                    onClear: {
                        selectedCandidates = []
                        resetGame()
                    }
                )

                Button {
                    resetGame()
                } label: {
                    Label("Play again", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func answerRound(
        with candidate: BattleCandidate
    ) {
        scores[candidate.id, default: 0] += 1
        lastAnswerTitle = candidate.displayTitle

        if currentRoundIndex < rounds.count - 1 {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentRoundIndex += 1
            }
        } else {
            resolveWinner()
        }
    }

    private func resolveWinner() {
        let sorted = selectedCandidates.sorted { first, second in
            let firstScore = scores[first.id, default: 0]
            let secondScore = scores[second.id, default: 0]

            if firstScore != secondScore {
                return firstScore > secondScore
            }

            return (first.tmdbRating ?? 0) > (second.tmdbRating ?? 0)
        }

        guard let resolvedWinner = sorted.first else {
            return
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            winner = resolvedWinner
        }

        onWinnerSelected(resolvedWinner, selectedCandidates)
    }

    private func rerollWinner() {
        let alternatives = selectedCandidates.filter {
            $0.id != winner?.id
        }

        if let newWinner = alternatives.randomElement() ?? selectedCandidates.randomElement() {
            winner = newWinner
            onWinnerSelected(newWinner, selectedCandidates)
        }
    }

    private func resetGame() {
        currentRoundIndex = 0
        scores = [:]
        winner = nil
        lastAnswerTitle = nil
    }
}

private struct FriendRound: Identifiable {
    let id: String
    let title: String
    let question: String
    let systemImage: String
}
