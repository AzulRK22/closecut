//
//  WatchPlanPosterView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchPlanPosterView: View {
    let media: WatchPlanMediaSnapshot
    var width: CGFloat = 58
    var height: CGFloat = 86
    var cornerRadius: CGFloat = 13

    private var fallbackIcon: String {
        media.type == .movie ? "film.fill" : "tv.fill"
    }

    private var fallbackInitials: String {
        let words = media.displayTitle
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(media.displayTitle.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(CloseCutColors.input)

            if let posterURL = media.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.7)

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
