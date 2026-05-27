//
//  DiscoverMediaPosterCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/05/26.
//

import SwiftUI

struct DiscoverMediaPosterCard: View {
    let media: TMDBMediaSearchResult
    let onTap: () -> Void

    private var posterURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: media.posterPath,
            size: .posterMedium
        )
    }

    private var fallbackIcon: String {
        media.entryType == .movie ? "film.fill" : "tv.fill"
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                poster

                VStack(alignment: .leading, spacing: 4) {
                    Text(media.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(media.subtitle)
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(width: 132, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(media.title), \(media.subtitle)")
    }

    private var poster: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CloseCutColors.card)

            if let posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.72)
                            .tint(CloseCutColors.accentLight)

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

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.34)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .frame(width: 132, height: 198)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text(media.entryType.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .padding(8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var fallbackPoster: some View {
        VStack(spacing: 10) {
            Image(systemName: fallbackIcon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text(media.entryType.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(12)
    }
}
