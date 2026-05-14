//
//  BattleHeadToHeadSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct BattleHeadToHeadSheet: View {
    let entries: [Entry]
    let onCancel: () -> Void
    let onWinnerSelected: (Entry, [Entry]) -> Void

    @State private var firstEntry: Entry?
    @State private var secondEntry: Entry?

    @State private var currentRoundIndex = 0
    @State private var firstScore = 0
    @State private var secondScore = 0
    @State private var winner: Entry?
    @State private var didSaveResult = false
    @State private var selectedRoundAnswers: [Int: String] = [:]

    private let rounds: [DuelRound] = [
        DuelRound(
            id: "tonight-fit",
            title: "Tonight’s vibe",
            question: "Which one fits tonight better?",
            systemImage: "moon.stars.fill"
        ),
        DuelRound(
            id: "stronger-memory",
            title: "Stronger memory",
            question: "Which one stayed with you more?",
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
            question: "Which one would you rewatch sooner?",
            systemImage: "arrow.clockwise.circle.fill"
        ),
        DuelRound(
            id: "final-instinct",
            title: "Final instinct",
            question: "No overthinking. Which one wins?",
            systemImage: "bolt.fill"
        )
    ]

    private var availableEntries: [Entry] {
        entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var canStartDuel: Bool {
        guard let firstEntry, let secondEntry else {
            return false
        }

        return firstEntry.id != secondEntry.id
    }

    private var isDuelComplete: Bool {
        winner != nil
    }

    private var currentRound: DuelRound {
        rounds[min(currentRoundIndex, rounds.count - 1)]
    }

    private var progressText: String {
        "Round \(min(currentRoundIndex + 1, rounds.count)) of \(rounds.count)"
    }

    private var progressValue: Double {
        guard rounds.isEmpty == false else {
            return 0
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

                        pickerSection

                        if canStartDuel {
                            scoreboardSection
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
            }
            .navigationTitle("Movie vs Movie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onCancel()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
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

                    Text("A fast taste duel. Answer simple prompts and CloseCut crowns the winner.")
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
                    text: "\(availableEntries.count) available"
                )

                infoPill(
                    icon: "gamecontroller.fill",
                    text: "5-round duel"
                )

                infoPill(
                    icon: "lock.fill",
                    text: "Private"
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

    // MARK: - Picker

    private var pickerSection: some View {
        BattleSectionCard(
            title: "Choose the matchup",
            subtitle: "Pick two archive entries and start the duel."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                entryPicker(
                    title: "Challenger A",
                    selectedEntry: $firstEntry,
                    excluding: secondEntry
                )

                entryPicker(
                    title: "Challenger B",
                    selectedEntry: $secondEntry,
                    excluding: firstEntry
                )

                if firstEntry?.id == secondEntry?.id && firstEntry != nil {
                    Text("Choose two different entries.")
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

    private func entryPicker(
        title: String,
        selectedEntry: Binding<Entry?>,
        excluding excludedEntry: Entry?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .tracking(0.8)

            Menu {
                ForEach(availableEntries.filter { $0.id != excludedEntry?.id }) { entry in
                    Button {
                        selectedEntry.wrappedValue = entry
                        resetDuelOnly()
                    } label: {
                        Text(entry.displayTitle)
                    }
                }
            } label: {
                selectedPickerLabel(
                    entry: selectedEntry.wrappedValue
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func selectedPickerLabel(
        entry: Entry?
    ) -> some View {
        HStack(spacing: 12) {
            if let entry {
                EntryPosterThumbnailView(
                    entry: entry,
                    width: 46,
                    height: 68,
                    cornerRadius: 11
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Text(subtitle(for: entry))
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(CloseCutColors.card)
                        .frame(width: 46, height: 68)

                    Image(systemName: "film.stack")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                Text("Select entry")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Scoreboard

    @ViewBuilder
    private var scoreboardSection: some View {
        if let firstEntry, let secondEntry {
            BattleSectionCard(
                title: "Scoreboard",
                subtitle: isDuelComplete ? "Final score" : progressText
            ) {
                VStack(spacing: 14) {
                    ProgressView(value: progressValue)
                        .tint(CloseCutColors.accent)

                    HStack(spacing: 12) {
                        scoreCard(
                            entry: firstEntry,
                            score: firstScore,
                            side: "A",
                            isLeading: firstScore >= secondScore && firstScore > 0
                        )

                        Text("VS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CloseCutColors.textTertiary)

                        scoreCard(
                            entry: secondEntry,
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
        entry: Entry,
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

            Text(entry.displayTitle)
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
                .stroke(isLeading ? CloseCutColors.accentLight.opacity(0.7) : CloseCutColors.separator, lineWidth: isLeading ? 0.9 : 0.5)
        }
    }

    // MARK: - Duel

    @ViewBuilder
    private var duelSection: some View {
        if let firstEntry, let secondEntry, winner == nil {
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

                            Text("Tap the title that wins this round.")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        duelOptionButton(
                            entry: firstEntry,
                            side: "A"
                        )

                        duelOptionButton(
                            entry: secondEntry,
                            side: "B"
                        )
                    }
                }
            }
        }
    }

    private func duelOptionButton(
        entry: Entry,
        side: String
    ) -> some View {
        let isSelected = selectedRoundAnswers[currentRoundIndex] == entry.id

        return Button {
            answerRound(with: entry)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    EntryPosterThumbnailView(
                        entry: entry,
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

                Text(entry.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(moodText(for: entry))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                if isSelected {
                    Label("Round won", systemImage: "checkmark.circle.fill")
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
                    .stroke(isSelected ? CloseCutColors.accentLight.opacity(0.85) : CloseCutColors.separator, lineWidth: isSelected ? 1 : 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Winner

    private func winnerSection(
        _ winner: Entry
    ) -> some View {
        BattleSectionCard(
            title: "Duel complete",
            subtitle: "CloseCut crowned a winner based on your answers."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        EntryPosterThumbnailView(
                            entry: winner,
                            width: 90,
                            height: 132,
                            cornerRadius: 18
                        )

                        ZStack {
                            SwiftUI.Circle()
                                .fill(CloseCutColors.backgroundPrimary)
                                .frame(width: 32, height: 32)

                            Image(systemName: "crown.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.accentLight)
                        }
                        .offset(x: 6, y: 6)
                    }

                    VStack(alignment: .leading, spacing: 7) {
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

                        Text(subtitle(for: winner))
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(2)

                        Text(winnerExplanation)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

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
                        firstEntry = nil
                        secondEntry = nil
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

    private var winnerExplanation: String {
        if firstScore == secondScore {
            return "The duel ended tied, so CloseCut used your final instinct as the tiebreaker."
        }

        let winningScore = max(firstScore, secondScore)
        return "Won \(winningScore) of \(rounds.count) rounds in this head-to-head taste battle."
    }

    // MARK: - Actions

    private func answerRound(
        with entry: Entry
    ) {
        guard let firstEntry, let secondEntry else {
            return
        }

        guard winner == nil else {
            return
        }

        selectedRoundAnswers[currentRoundIndex] = entry.id

        withAnimation(.easeInOut(duration: 0.18)) {
            if entry.id == firstEntry.id {
                firstScore += 1
            } else if entry.id == secondEntry.id {
                secondScore += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            advanceRound()
        }
    }

    private func advanceRound() {
        guard let firstEntry, let secondEntry else {
            return
        }

        if currentRoundIndex < rounds.count - 1 {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentRoundIndex += 1
            }
            return
        }

        let resolvedWinner: Entry

        if firstScore > secondScore {
            resolvedWinner = firstEntry
        } else if secondScore > firstScore {
            resolvedWinner = secondEntry
        } else {
            let finalAnswerId = selectedRoundAnswers[rounds.count - 1]
            resolvedWinner = finalAnswerId == secondEntry.id ? secondEntry : firstEntry
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            winner = resolvedWinner
        }

        saveWinnerIfNeeded(
            winner: resolvedWinner,
            options: [firstEntry, secondEntry]
        )
    }

    private func saveWinnerIfNeeded(
        winner: Entry,
        options: [Entry]
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
    }

    // MARK: - Text Helpers

    private func subtitle(
        for entry: Entry
    ) -> String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if let rating = entry.tmdbRating, rating > 0 {
            parts.append(String(format: "%.1f TMDB", rating))
        }

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    private func moodText(
        for entry: Entry
    ) -> String {
        let cleanedMood = entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedMood.isEmpty {
            return entry.quickSentiment?.displayName ?? "Memory"
        }

        return cleanedMood
    }
}

// MARK: - Duel Round

private struct DuelRound: Identifiable {
    let id: String
    let title: String
    let question: String
    let systemImage: String
}
