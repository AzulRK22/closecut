//
//  MediaPosterView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct MediaPosterView: View {
    let posterPath: String?
    var mediaType: TMDBMediaType = .movie
    var width: CGFloat = 54
    var height: CGFloat = 80
    var cornerRadius: CGFloat = 10

    private var posterURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: posterPath,
            size: .posterMedium
        )
    }

    private var fallbackIcon: String {
        mediaType == .tv ? "tv.fill" : "film.fill"
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
        VStack(spacing: 6) {
            Image(systemName: fallbackIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text("No poster")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(6)
    }
}
