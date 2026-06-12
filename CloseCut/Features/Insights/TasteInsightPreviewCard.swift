//
//  TasteInsightPreviewCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import SwiftUI

struct TasteInsightPreviewCard: View {
    let entries: [Entry]
    let watchlistItems: [WatchlistItem]
    let onOpen: () -> Void

    private var summary: InsightsSummary {
        InsightsGenerator().generate(
            entries: entries,
            watchlistItems: watchlistItems
        )
    }

    var body: some View {
        Button {
            onOpen()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(CloseCutColors.accent.opacity(0.18))
                            .frame(width: 44, height: 44)

                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Taste")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text(previewText)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .padding(.top, 14)
                }

                HStack(spacing: 8) {
                    previewPill(
                        icon: "film.fill",
                        text: "\(summary.totalWatchedCount) watched"
                    )

                    previewPill(
                        icon: "bookmark.fill",
                        text: "\(summary.savedWatchlistCount) saved"
                    )
                }

                if summary.tasteProfile.traits.isEmpty == false {
                    HStack(spacing: 8) {
                        ForEach(summary.tasteProfile.traits.prefix(2)) { trait in
                            Text(trait.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(CloseCutColors.accentLight)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(CloseCutColors.input.opacity(0.78))
                                .clipShape(Capsule())
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var previewText: String {
        if summary.hasEnoughData {
            return summary.tasteProfile.summary
        }

        if summary.totalWatchedCount == 0 && summary.savedWatchlistCount == 0 {
            return "Start adding watches and saved picks to unlock your private taste profile."
        }

        return "Your profile is starting to form from your watched titles and saved picks."
    }

    private func previewPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(CloseCutColors.textTertiary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input.opacity(0.78))
        .clipShape(Capsule())
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.cardElevated,
                    CloseCutColors.card,
                    CloseCutColors.accent.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 220
            )
        }
    }
}
