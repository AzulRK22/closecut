//
//  WrapPreviewCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import SwiftUI

struct WrapPreviewCard: View {
    let summary: WrapSummary
    let isPromoted: Bool
    let onOpen: () -> Void

    var body: some View {
        Button {
            onOpen()
        } label: {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top, spacing: 12) {
                    posterStack

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            if isPromoted {
                                Text("NEW")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(CloseCutColors.accentLight)
                                    .clipShape(Capsule())
                            }

                            Text(summary.period.kind.displayName.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(CloseCutColors.textTertiary)
                                .tracking(0.8)
                        }

                        Text(summary.period.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text(summary.emotionalTitle)
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
                    previewNumber(
                        value: "\(summary.watchedCount)",
                        label: "watched"
                    )

                    previewNumber(
                        value: "\(summary.movieCount)",
                        label: "movies"
                    )

                    previewNumber(
                        value: "\(summary.seriesCount)",
                        label: "series"
                    )

                    previewNumber(
                        value: "\(summary.savedCount)",
                        label: "saved"
                    )
                }

                if let topGenre = summary.topGenre {
                    Text("Top genre: \(topGenre.title)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(CloseCutColors.input.opacity(0.74))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var posterStack: some View {
        ZStack {
            if summary.posterHighlights.isEmpty {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(CloseCutColors.input)

                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
                .frame(width: 54, height: 74)
            } else {
                ForEach(Array(summary.posterHighlights.prefix(3).enumerated()), id: \.element.id) { index, poster in
                    posterTile(poster)
                        .offset(x: CGFloat(index) * 9, y: CGFloat(index) * 3)
                        .rotationEffect(.degrees(Double(index - 1) * 5))
                }
            }
        }
        .frame(width: 76, height: 82, alignment: .leading)
    }

    private func posterTile(
        _ poster: WrapPosterHighlight
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CloseCutColors.input)

            if let url = TMDBImageURLBuilder.imageURL(
                path: poster.posterPath,
                size: .posterMedium
            ) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.65)
                            .tint(CloseCutColors.accentLight)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        Image(systemName: "film.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)

                    @unknown default:
                        Image(systemName: "film.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                    }
                }
            } else {
                Image(systemName: "film.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }
        }
        .frame(width: 48, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func previewNumber(
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.cardElevated,
                    CloseCutColors.card,
                    CloseCutColors.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.16),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 220
            )
        }
    }
}
