//
//  BattlePickResultCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct BattlePickResultCard: View {
    let winner: Entry
    let optionCount: Int
    let onPickAgain: () -> Void
    let onClear: () -> Void

    private var subtitle: String {
        var parts: [String] = []

        if let releaseYear = winner.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(winner.type.displayName)

        if let rating = winner.tmdbRating, rating > 0 {
            parts.append(String(format: "%.1f TMDB", rating))
        }

        if winner.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    private var moodText: String {
        let cleanedMood = winner.mood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedMood.isEmpty {
            return winner.quickSentiment?.displayName ?? "Selected memory"
        }

        return cleanedMood
    }

    private var resultDescription: String {
        if let takeaway = cleanOptional(winner.takeaway) {
            return takeaway
        }

        if let overview = cleanOptional(winner.overview) {
            return overview
        }

        return "CloseCut picked from your shortlist. Keep it, reroll, or clear the result and build a new Battle."
    }

    private var revealLabel: String {
        optionCount == 2 ? "Head-to-head energy" : "Picked from \(optionCount) options"
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
        .accessibilityLabel("Tonight’s pick is \(winner.displayTitle). \(subtitle).")
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
                EntryPosterThumbnailView(
                    entry: winner,
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

                Text(subtitle)
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

                if winner.sourceType == .quickAdd {
                    resultPill(
                        icon: "bolt.fill",
                        text: "Quick Add memory",
                        isHighlighted: true
                    )
                }
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
                    text: moodText,
                    isHighlighted: true
                )

                if let rating = winner.tmdbRating, rating > 0 {
                    resultPill(
                        icon: "star.fill",
                        text: String(format: "%.1f TMDB", rating)
                    )
                }

                if winner.visibility == .circle {
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

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }
}
