//
//  BattlePickResultCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct BattlePickResultCard: View {
    let winner: BattleCandidate
    let optionCount: Int
    let onPickAgain: () -> Void
    let onClear: () -> Void

    private var resultDescription: String {
        winner.descriptionText
    }

    private var revealLabel: String {
        BattleResultDisplayHelper.resultLabel(
            optionCount: optionCount
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            revealHeader

            hero

            Text(resultDescription)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            signalRow

            actionRow
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.65), lineWidth: 0.9)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tonight’s pick is \(winner.displayTitle). \(winner.metadataText).")
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                CloseCutColors.card,
                CloseCutColors.card.opacity(0.96),
                CloseCutColors.accent.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var revealHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.accent.opacity(0.20))
                    .frame(width: 34, height: 34)

                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Tonight’s pick")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .tracking(0.8)
                    .textCase(.uppercase)

                Text(revealLabel)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text("Winner")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(CloseCutColors.accent)
                .clipShape(Capsule())
        }
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                BattleCandidatePosterView(
                    candidate: winner,
                    width: 88,
                    height: 130,
                    cornerRadius: 18
                )

                ZStack {
                    SwiftUI.Circle()
                        .fill(CloseCutColors.backgroundPrimary)
                        .frame(width: 30, height: 30)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
                .offset(x: 6, y: 6)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(winner.displayTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(winner.metadataText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 7) {
                    resultPill(
                        icon: "shuffle",
                        text: "From \(optionCount)"
                    )

                    resultPill(
                        icon: winner.type == .movie ? "film.fill" : "tv.fill",
                        text: winner.type.displayName
                    )
                }

                resultPill(
                    icon: winner.source.systemImage,
                    text: winner.sourceLabelText,
                    isHighlighted: winner.source != .archive
                )
            }

            Spacer(minLength: 0)
        }
    }

    private var signalRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why this works")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            HStack(spacing: 8) {
                resultPill(
                    icon: "sparkle",
                    text: winner.primarySignalText,
                    isHighlighted: true
                )

                if let rating = winner.tmdbRating, rating > 0 {
                    resultPill(
                        icon: "star.fill",
                        text: String(format: "%.1f TMDB", rating)
                    )
                }

                if winner.isShared {
                    resultPill(
                        icon: "person.2.fill",
                        text: "Shared"
                    )
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                onPickAgain()
            } label: {
                Label("Pick again", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onClear()
            } label: {
                Text("Clear")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .frame(width: 92)
                    .frame(height: 46)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func resultPill(
        icon: String,
        text: String,
        isHighlighted: Bool = false
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isHighlighted ? CloseCutColors.accentLight : CloseCutColors.textSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
}
