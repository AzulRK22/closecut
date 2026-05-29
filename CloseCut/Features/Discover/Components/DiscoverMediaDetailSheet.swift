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
    let isSavingWatchlist: Bool
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

        return names.isEmpty
            ? "No genres available"
            : names.prefix(3).joined(separator: " • ")
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard

                    metadata

                    if let overview = media.overview?.trimmed,
                       overview.isEmpty == false {
                        overviewSection(overview)
                    }

                    actionSection

                    privacyNote

                    Spacer(minLength: 28)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            backdropHero

            HStack(alignment: .bottom, spacing: 14) {
                poster

                VStack(alignment: .leading, spacing: 7) {
                    Text(media.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(media.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(genresText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            }
            .padding(16)
        }
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            backdropHero

            titleBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 12)
    }

    private var backdropHero: some View {
        ZStack(alignment: .bottomLeading) {
            backdropImage

            LinearGradient(
                colors: [
                    .clear,
                    CloseCutColors.card.opacity(0.68),
                    CloseCutColors.card
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 230)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var backdropImage: some View {
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
                            .frame(maxWidth: .infinity)
                            .frame(height: 230)
                            .clipped()

                    case .failure:
                        fallbackBackdrop

                    @unknown default:
                        fallbackBackdrop
                    }
                }
            } else {
                fallbackBackdrop
            }
        }
    }

    private var fallbackBackdrop: some View {
        LinearGradient(
            colors: [
                CloseCutColors.accent.opacity(0.24),
                CloseCutColors.card,
                CloseCutColors.backgroundPrimary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(CloseCutColors.textTertiary)
        }
    }

    // MARK: - Title

    private var titleBlock: some View {
        HStack(alignment: .top, spacing: 14) {
            poster

            VStack(alignment: .leading, spacing: 8) {
                Text(media.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text(media.subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(genresText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                            .scaledToFit()
                            .frame(width: 92, height: 138)
                            .background(CloseCutColors.input)

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
        VStack(spacing: 8) {
            Image(systemName: media.entryType == .movie ? "film.fill" : "tv.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)

            Text(media.entryType.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(10)
    }

    // MARK: - Metadata

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            }

            if let rating = media.voteAverage,
               rating > 0 {
                metadataPill(
                    icon: "star.fill",
                    text: String(format: "%.1f TMDB", rating)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    // MARK: - Overview

    private func overviewSection(_ overview: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Why it may be worth noticing")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(overview)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: 10) {
            Button {
                onAddWatched()
            } label: {
                HStack(spacing: 8) {
                    if isSavingWatched {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }

                    Text(isSavingWatched ? "Adding..." : "Add as watched")
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(CloseCutColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSavingWatched || isSavingWatchlist)

            HStack(spacing: 10) {
                Button {
                    onSaveForLater()
                } label: {
                    actionButtonLabel(
                        icon: isSavingWatchlist ? nil : "bookmark.fill",
                        text: isSavingWatchlist ? "Saving..." : "Want to Watch",
                        showsProgress: isSavingWatchlist
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSavingWatched || isSavingWatchlist)

                Button {
                    onStartBattle()
                } label: {
                    actionButtonLabel(
                        icon: "bolt.fill",
                        text: "Battle",
                        showsProgress: false
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSavingWatched || isSavingWatchlist)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButtonLabel(
        icon: String?,
        text: String,
        showsProgress: Bool
    ) -> some View {
        HStack(spacing: 7) {
            if showsProgress {
                ProgressView()
                    .scaleEffect(0.72)
                    .tint(CloseCutColors.accentLight)
            } else if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
            }

            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Privacy

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Adding this as watched or saving it for later stays private first. You choose later if it belongs in a Circle.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }
}
