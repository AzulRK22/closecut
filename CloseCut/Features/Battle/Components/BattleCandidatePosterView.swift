//
//  BattleCandidatePosterView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import SwiftUI

struct BattleCandidatePosterView: View {
    let candidate: BattleCandidate
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    private var fallbackIcon: String {
        candidate.type == .movie ? "film.fill" : "tv.fill"
    }

    private var fallbackInitials: String {
        let words = candidate.displayTitle
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(candidate.displayTitle.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(CloseCutColors.input)

            if let posterURL = candidate.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        loadingPoster

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        fallbackPoster

                    @unknown default:
                        fallbackPoster
                    }
                }
            } else {
                fallbackPoster
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityHidden(true)
    }

    private var loadingPoster: some View {
        ProgressView()
            .scaleEffect(0.7)
    }

    private var fallbackPoster: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.22),
                    CloseCutColors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 7) {
                Image(systemName: fallbackIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)

                Text(fallbackInitials)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(8)
        }
    }
}
