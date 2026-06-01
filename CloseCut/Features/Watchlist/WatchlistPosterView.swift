//
//  WatchlistPosterView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 31/05/26.
//

import SwiftUI

struct WatchlistPosterView: View {
    let item: WatchlistItem

    var width: CGFloat = 74
    var height: CGFloat = 110
    var cornerRadius: CGFloat = 14

    private var posterURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: item.posterPath,
            size: .posterMedium
        )
    }

    private var fallbackIcon: String {
        item.type == .movie ? "film.fill" : "tv.fill"
    }

    private var fallbackInitials: String {
        let words = item.displayTitle
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(item.displayTitle.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(CloseCutColors.input)

            if let posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(CloseCutColors.accentLight)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: height)
                            .clipped()

                    case .failure:
                        fallbackContent

                    @unknown default:
                        fallbackContent
                    }
                }
            } else {
                fallbackContent
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 5)
        .accessibilityHidden(true)
    }

    private var fallbackContent: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.20),
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
