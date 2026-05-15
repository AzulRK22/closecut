//
//  BattleCircleSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 15/05/26.
//

import SwiftUI

struct BattleCircleSheet: View {
    let archiveEntries: [Entry]
    let initialSelection: [BattleCandidate]
    let onCancel: () -> Void
    let onWinnerSelected: (BattleCandidate, [BattleCandidate]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCandidates: [BattleCandidate] = []
    @State private var showPicker = false
    @State private var winner: BattleCandidate?
    @State private var selectedStrategy: CircleBattleStrategy = .crowdPleaser

    private var canPick: Bool {
        selectedCandidates.count >= 2
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

                        strategySection

                        if let winner {
                            winnerSection(winner)
                        }

                        productNote

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Circle Battle")
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
                initialSelection: selectedCandidates,
                onCancel: {
                    showPicker = false
                },
                onConfirm: { candidates in
                    selectedCandidates = BattleCandidateMapper.dedupe(candidates)
                    winner = nil
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
                    Text("Pick for the group.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Use a shared shortlist and choose the kind of group night you want. Real Circle voting can come later; this already helps the group decide.")
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

                    Image(systemName: "person.3.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }

            HStack(spacing: 8) {
                infoPill(icon: "person.3.fill", text: "Group mode")
                infoPill(icon: "lock.fill", text: "Private")
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
            title: canPick ? "Group shortlist" : "Build a group shortlist",
            subtitle: canPick ? "Ready to generate a group pick." : "Add at least two options."
        ) {
            VStack(spacing: 12) {
                if selectedCandidates.isEmpty {
                    Text("Start with archive titles, TMDB discoveries, or manual ideas. Later this can use real Circle-shared entries and member votes.")
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
                    Label(canPick ? "Edit shortlist" : "Choose options", systemImage: "plus.circle")
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

    // MARK: - Strategy

    private var strategySection: some View {
        BattleSectionCard(
            title: "Group strategy",
            subtitle: "Choose how CloseCut should resolve the group night."
        ) {
            VStack(spacing: 12) {
                ForEach(CircleBattleStrategy.allCases) { strategy in
                    strategyRow(strategy)
                }

                Button {
                    pickWinner()
                } label: {
                    Label("Pick group winner", systemImage: "person.3.sequence.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(canPick ? .white : CloseCutColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canPick ? CloseCutColors.accent : CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(canPick == false)
                .padding(.top, 2)
            }
        }
    }

    private func strategyRow(
        _ strategy: CircleBattleStrategy
    ) -> some View {
        let isSelected = strategy == selectedStrategy

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedStrategy = strategy
                winner = nil
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: strategy.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                    .frame(width: 34, height: 34)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(strategy.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(strategy.subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
            }
            .padding(12)
            .background(isSelected ? CloseCutColors.accent.opacity(0.10) : CloseCutColors.input.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? CloseCutColors.accentLight.opacity(0.65) : CloseCutColors.separator, lineWidth: isSelected ? 0.8 : 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Winner

    private func winnerSection(
        _ winner: BattleCandidate
    ) -> some View {
        BattleSectionCard(
            title: "Circle pick",
            subtitle: selectedStrategy.resultSubtitle
        ) {
            BattlePickResultCard(
                winner: winner,
                optionCount: selectedCandidates.count,
                onPickAgain: {
                    pickWinner()
                },
                onClear: {
                    self.winner = nil
                    selectedCandidates = []
                }
            )
        }
    }

    // MARK: - Product Note

    private var productNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("This is a local group picker. It does not publish votes yet. Later it can connect to real Circle members and Firestore voting.")
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

    // MARK: - Actions

    private func pickWinner() {
        guard selectedCandidates.count >= 2 else {
            winner = nil
            return
        }

        let ranked = selectedCandidates.sorted { first, second in
            score(first) > score(second)
        }

        guard let resolvedWinner = ranked.first else {
            winner = nil
            return
        }

        winner = resolvedWinner
        onWinnerSelected(resolvedWinner, selectedCandidates)
    }

    private func score(
        _ candidate: BattleCandidate
    ) -> Int {
        var score = 0

        switch selectedStrategy {
        case .crowdPleaser:
            score += Int((candidate.tmdbRating ?? 0).rounded())
            score += candidate.source == .archive ? 2 : 1
            score += candidate.isShared ? 3 : 0

        case .safeChoice:
            score += candidate.tmdbRating ?? 0 >= 7.0 ? 4 : 0
            score += candidate.source == .archive ? 3 : 1
            score += candidate.overview == nil ? 0 : 1

        case .wildcard:
            score += candidate.source == .tmdb ? 5 : 0
            score += candidate.source == .manual ? 4 : 0
            score += Int(candidate.tmdbPopularity ?? 0) % 5

        case .sharedMemory:
            score += candidate.isShared ? 6 : 0
            score += candidate.quickSentiment == .loved ? 4 : 0
            score += candidate.quickSentiment == .stayedWithMe ? 4 : 0
            score += candidate.source == .archive ? 2 : 0
        }

        return score
    }
}

private enum CircleBattleStrategy: String, CaseIterable, Identifiable {
    case crowdPleaser
    case safeChoice
    case wildcard
    case sharedMemory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .crowdPleaser:
            return "Crowd pleaser"
        case .safeChoice:
            return "Safe choice"
        case .wildcard:
            return "Wildcard"
        case .sharedMemory:
            return "Shared memory"
        }
    }

    var subtitle: String {
        switch self {
        case .crowdPleaser:
            return "Best all-around group option."
        case .safeChoice:
            return "Lowest-risk pick for everyone."
        case .wildcard:
            return "More spontaneous, less obvious."
        case .sharedMemory:
            return "Favors titles with personal or shared taste signals."
        }
    }

    var resultSubtitle: String {
        switch self {
        case .crowdPleaser:
            return "Best all-around group option."
        case .safeChoice:
            return "The safest group pick."
        case .wildcard:
            return "The group wildcard."
        case .sharedMemory:
            return "Chosen from shared taste signals."
        }
    }

    var systemImage: String {
        switch self {
        case .crowdPleaser:
            return "person.3.fill"
        case .safeChoice:
            return "checkmark.shield.fill"
        case .wildcard:
            return "die.face.5.fill"
        case .sharedMemory:
            return "sparkles"
        }
    }
}
