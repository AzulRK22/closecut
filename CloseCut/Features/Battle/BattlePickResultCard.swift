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
        if let overview = cleanOptional(winner.overview) {
            return overview
        }

        return "CloseCut picked one option from your selected memories. Pick again if you want another possibility."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                EntryPosterThumbnailView(
                    entry: winner,
                    width: 76,
                    height: 112,
                    cornerRadius: 15
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tonight’s pick")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(winner.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        resultPill(
                            icon: "shuffle",
                            text: "From \(optionCount)"
                        )

                        resultPill(
                            icon: "sparkle",
                            text: moodText
                        )
                    }
                }

                Spacer()
            }

            Text(resultDescription)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    onPickAgain()
                } label: {
                    Label("Pick again", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onClear()
                } label: {
                    Text("Clear")
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
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.55), lineWidth: 0.8)
        }
    }

    private func resultPill(
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
