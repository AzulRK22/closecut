//
//  BattleArenaCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/06/26.
//

import SwiftUI

struct BattleArenaCard: View {
    let candidates: [BattleCandidate]
    let winner: BattleCandidate?
    let onEdit: () -> Void
    let onPickAgain: () -> Void
    let onClear: () -> Void

    private var visibleCandidates: [BattleCandidate] {
        Array(candidates.prefix(4))
    }

    private var canPick: Bool {
        candidates.count >= 2
    }

    var body: some View {
        BattleSectionCard(
            title: winner == nil ? "Tonight’s arena" : "Arena result",
            subtitle: arenaSubtitle
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if candidates.isEmpty {
                    emptyArena
                } else {
                    arenaGrid
                    actionRow
                }
            }
        }
    }

    private var arenaSubtitle: String {
        if let winner {
            return "\(winner.displayTitle) survived the shortlist."
        }

        if candidates.isEmpty {
            return "Build a shortlist to start the game."
        }

        if candidates.count == 1 {
            return "Add one more option to unlock Battle."
        }

        return "\(candidates.count) contenders ready."
    }

    private var emptyArena: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "gamecontroller.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 2)

            Text("No contenders yet. Add titles from Personal, Want to Watch, TMDB, or manual ideas.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var arenaGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            ForEach(visibleCandidates) { candidate in
                contenderTile(candidate)
            }

            if candidates.count > visibleCandidates.count {
                moreTile
            }
        }
    }

    private func contenderTile(
        _ candidate: BattleCandidate
    ) -> some View {
        let isWinner = candidate.normalizedIdentityKey == winner?.normalizedIdentityKey

        return VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .topTrailing) {
                BattleCandidatePosterView(
                    candidate: candidate,
                    width: 72,
                    height: 106,
                    cornerRadius: 14
                )
                .frame(maxWidth: .infinity)

                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(width: 26, height: 26)
                        .background(CloseCutColors.backgroundPrimary)
                        .clipShape(SwiftUI.Circle())
                        .offset(x: 4, y: -4)
                }
            }

            Text(candidate.displayTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            BattleGameStatusPill(
                icon: candidate.source.systemImage,
                text: candidate.source.shortDisplayName,
                isHighlighted: candidate.source != .archive
            )
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isWinner ? CloseCutColors.accent.opacity(0.12) : CloseCutColors.input.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isWinner ? CloseCutColors.accentLight.opacity(0.75) : CloseCutColors.separator,
                    lineWidth: isWinner ? 0.9 : 0.5
                )
        }
    }

    private var moreTile: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)

            Text("+\(candidates.count - visibleCandidates.count) more")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 178)
        .background(CloseCutColors.input.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                onEdit()
            } label: {
                Text("Edit arena")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onPickAgain()
            } label: {
                Label(winner == nil ? "Start Battle" : "Rematch", systemImage: winner == nil ? "play.fill" : "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(canPick ? .white : CloseCutColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(canPick ? CloseCutColors.accent : CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(canPick == false)

            Button {
                onClear()
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .frame(width: 44, height: 40)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}
