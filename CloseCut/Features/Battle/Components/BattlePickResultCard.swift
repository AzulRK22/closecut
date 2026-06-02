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

    private var winnerHeadline: String {
        switch winner.source {
        case .archive:
            return "Your archive chose this energy."
        case .watchlist:
            return "This was already waiting for the right moment."
        case .tmdb:
            return "A discovery contender stole the night."
        case .manual:
            return "Your manual wildcard survived."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            revealHeader

            hero

            Text(winnerHeadline)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(resultDescription)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            signalRow

            actionRow
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.20), radius: 20, x: 0, y: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tonight’s winner is \(winner.displayTitle). \(winner.metadataText).")
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                CloseCutColors.card,
                CloseCutColors.card.opacity(0.96),
                CloseCutColors.accent.opacity(0.16)
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
                    .frame(width: 38, height: 38)

                Image(systemName: "crown.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Battle winner")
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
                    width: 98,
                    height: 146,
                    cornerRadius: 20
                )

                ZStack {
                    SwiftUI.Circle()
                        .fill(CloseCutColors.backgroundPrimary)
                        .frame(width: 34, height: 34)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
                .offset(x: 6, y: 6)
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(winner.displayTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(4)
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
        VStack(alignment: .leading, spacing: 9) {
            Text("Winning signals")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    signalContent
                }

                VStack(alignment: .leading, spacing: 8) {
                    signalContent
                }
            }
        }
    }

    @ViewBuilder
    private var signalContent: some View {
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

        if winner.hasUsefulMetadata {
            resultPill(
                icon: "photo.on.rectangle",
                text: "Metadata"
            )
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                onPickAgain()
            } label: {
                Label("Rematch", systemImage: "arrow.triangle.2.circlepath")
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
