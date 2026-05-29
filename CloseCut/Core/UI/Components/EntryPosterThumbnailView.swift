//
//  EntryPosterThumbnailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 07/05/26.
//

import SwiftUI

enum EntryPosterContentMode {
    case fill
    case fit
}

struct EntryPosterThumbnailView: View {
    let entry: Entry
    var width: CGFloat = 66
    var height: CGFloat = 96
    var cornerRadius: CGFloat = 14
    var contentMode: EntryPosterContentMode = .fill

    private var posterURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: entry.posterPath,
            size: .posterMedium
        )
    }

    private var fallbackIcon: String {
        entry.type == .movie ? "film.fill" : "tv.fill"
    }

    private var fallbackInitials: String {
        let words = entry.displayTitle
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(entry.displayTitle.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(CloseCutColors.input)

            if let posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        loadingPoster

                    case .success(let image):
                        posterImage(image)

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
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 5)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func posterImage(_ image: Image) -> some View {
        switch contentMode {
        case .fill:
            image
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()

        case .fit:
            image
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .background(CloseCutColors.input)
        }
    }

    private var loadingPoster: some View {
        ProgressView()
            .scaleEffect(0.7)
            .tint(CloseCutColors.accentLight)
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
