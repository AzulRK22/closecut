//
//  DiscoverMediaDetailSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/05/26.
//

import SwiftUI

struct DiscoverMediaDetailSheet: View {
    let media: TMDBMediaSearchResult
    let isSavingWatched: Bool
    let onAddWatched: () -> Void
    let onSaveForLater: () -> Void
    let onStartBattle: () -> Void

    private var posterURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: media.posterPath,
            size: .posterLarge
        )
    }

    private var backdropURL: URL? {
        TMDBImageURLBuilder.imageURL(
            path: media.backdropPath,
            size: .backdropLarge
        )
    }

    private var genresText: String {
        let names = TMDBGenreNameMapper.displayNames(
            for: media.genreIds
        )

        return names.isEmpty ? "No genres available" : names.prefix(3).joined(separator: " • ")
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero

                    VStack(alignment: .leading, spacing: 18) {
                        metadata

                        if let overview = media.overview?.trimmed,
                           overview.isEmpty == false {
                            overviewSection(overview)
                        }

                        actionSection

                        privacyNote
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            backdrop

            LinearGradient(
                colors: [
                    .clear,
                    CloseCutColors.backgroundPrimary.opacity(0.96)
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            HStack(alignment: .bottom, spacing: 14) {
                poster

                VStack(alignment: .leading, spacing: 8) {
                    Text(media.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(media.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)

                    Text(genresText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .frame(height: 292)
    }

    private var backdrop: some View {
        ZStack {
            CloseCutColors.card

            if let backdropURL {
                AsyncImage(url: backdropURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(CloseCutColors.accentLight)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(CloseCutColors.textTertiary)

                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .clipped()
    }

    private var poster: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CloseCutColors.input)

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
        }
        .frame(width: 92, height: 138)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var fallbackPoster: some View {
        Image(systemName: media.entryType == .movie ? "film.fill" : "tv.fill")
            .font(.title2.weight(.semibold))
            .foregroundStyle(CloseCutColors.textTertiary)
    }

    private var metadata: some View {
        HStack(spacing: 10) {
            metadataPill(
                icon: media.entryType == .movie ? "film.fill" : "tv.fill",
                text: media.entryType.displayName
            )

            if let releaseYear = media.releaseYear {
                metadataPill(
                    icon: "calendar",
                    text: "\(releaseYear)"
                )
            }

            if let rating = media.voteAverage,
               rating > 0 {
                metadataPill(
                    icon: "star.fill",
                    text: String(format: "%.1f", rating)
                )
            }
        }
    }

    private func metadataPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private func overviewSection(_ overview: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why it may be worth noticing")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(overview)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            Button {
                onAddWatched()
            } label: {
                HStack {
                    if isSavingWatched {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }

                    Text(isSavingWatched ? "Adding..." : "Add as watched")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(CloseCutColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSavingWatched)

            HStack(spacing: 10) {
                Button {
                    onSaveForLater()
                } label: {
                    actionButtonLabel(
                        icon: "bookmark.fill",
                        text: "Want to Watch"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onStartBattle()
                } label: {
                    actionButtonLabel(
                        icon: "bolt.fill",
                        text: "Battle"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func actionButtonLabel(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Adding this as watched saves it privately first. You choose later if it belongs in a Circle.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
