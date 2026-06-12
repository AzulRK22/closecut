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
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(CloseCutColors.accent.opacity(0.18))
                            .frame(width: 46, height: 46)

                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Taste Dashboard")
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

                HStack(alignment: .bottom, spacing: 14) {
                    previewBigNumber(
                        value: "\(summary.overviewStats.watchedCount)",
                        label: "watched"
                    )

                    previewBigNumber(
                        value: "\(summary.overviewStats.movieCount)",
                        label: "movies"
                    )

                    previewBigNumber(
                        value: "\(summary.overviewStats.seriesCount)",
                        label: "series"
                    )

                    previewBigNumber(
                        value: "\(summary.overviewStats.savedCount)",
                        label: "saved"
                    )
                }

                segmentedPreviewBar

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
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var previewText: String {
        if summary.hasEnoughData {
            return "A visual snapshot of your movies, series, moods, genres, and rewatch signals."
        }

        if summary.totalWatchedCount == 0 && summary.savedWatchlistCount == 0 {
            return "Start adding watches and saved picks to unlock your private taste profile."
        }

        return "Your profile is starting to form from your watched titles and saved picks."
    }

    private func previewBigNumber(
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var segmentedPreviewBar: some View {
        GeometryReader { proxy in
            let total = max(
                summary.overviewStats.movieCount + summary.overviewStats.seriesCount,
                1
            )

            let movieWidth = proxy.size.width * CGFloat(summary.overviewStats.movieCount) / CGFloat(total)
            let seriesWidth = proxy.size.width * CGFloat(summary.overviewStats.seriesCount) / CGFloat(total)

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(CloseCutColors.accent)
                    .frame(width: max(8, movieWidth))

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(CloseCutColors.accentLight.opacity(0.72))
                    .frame(width: max(8, seriesWidth))
            }
        }
        .frame(height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.cardElevated,
                    CloseCutColors.card,
                    CloseCutColors.accent.opacity(0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.14),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 220
            )
        }
    }
}
