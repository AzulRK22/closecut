//
//  WrapStoriesView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import SwiftUI

struct WrapStoriesView: View {
    @Environment(\.dismiss) private var dismiss

    let summary: WrapSummary
    let onOpenShare: (() -> Void)?

    @State private var currentIndex = 0

    private var pages: [WrapStoryPage] {
        WrapStoryPageFactory.pages(
            for: summary
        )
    }

    var body: some View {
        ZStack {
            storyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader

                ZStack {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        if index == currentIndex {
                            storyPage(page)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.22), value: currentIndex)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomControls
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(spacing: 14) {
            HStack(spacing: 5) {
                ForEach(0..<pages.count, id: \.self) { index in
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.20))

                            Capsule()
                                .fill(.white.opacity(index <= currentIndex ? 0.95 : 0.0))
                                .frame(
                                    width: index < currentIndex
                                        ? proxy.size.width
                                        : index == currentIndex
                                            ? proxy.size.width
                                            : 0
                                )
                        }
                    }
                    .frame(height: 4)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.period.kind.displayName.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))
                        .tracking(1.1)

                    Text(summary.period.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.88))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Story Page

    private func storyPage(
        _ page: WrapStoryPage
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 12)

            if page.kind == .cover {
                coverArtwork
            } else if page.kind == .posters {
                posterCollage
            } else {
                iconBadge(page.systemImage)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(page.eyebrow)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text(page.title)
                    .font(.system(size: page.isBigNumber ? 72 : 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.58)
                    .fixedSize(horizontal: false, vertical: true)

                Text(page.subtitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if page.items.isEmpty == false {
                VStack(spacing: 10) {
                    ForEach(page.items) { item in
                        wrapStoryItemRow(item)
                    }
                }
                .padding(.top, 4)
            }

            if page.kind == .share {
                shareCTA
                    .padding(.top, 8)
            }

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            goNext()
        }
    }

    private func iconBadge(
        _ systemImage: String
    ) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 72, height: 72)

            Image(systemName: systemImage)
                .font(.title.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private var coverArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.10))
                .frame(height: 210)

            if summary.posterHighlights.isEmpty {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                HStack(spacing: -18) {
                    ForEach(summary.posterHighlights.prefix(4)) { poster in
                        posterTile(
                            posterPath: poster.posterPath,
                            title: poster.title,
                            width: 92,
                            height: 138
                        )
                        .rotationEffect(.degrees(rotation(for: poster.id)))
                    }
                }
            }
        }
    }

    private var posterCollage: some View {
        VStack(alignment: .leading, spacing: 12) {
            if summary.posterHighlights.isEmpty {
                iconBadge("film.stack.fill")
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(summary.posterHighlights.prefix(6)) { poster in
                        posterTile(
                            posterPath: poster.posterPath,
                            title: poster.title,
                            width: nil,
                            height: 138
                        )
                    }
                }
            }
        }
    }

    private func posterTile(
        posterPath: String?,
        title: String,
        width: CGFloat?,
        height: CGFloat
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.13))

            if let url = TMDBImageURLBuilder.imageURL(
                path: posterPath,
                size: .posterMedium
            ) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        posterFallback(title)

                    @unknown default:
                        posterFallback(title)
                    }
                }
            } else {
                posterFallback(title)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 14, x: 0, y: 8)
    }

    private func posterFallback(
        _ title: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "film.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.74))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 8)
        }
    }

    private func wrapStoryItemRow(
        _ item: WrapStoryPageItem
    ) -> some View {
        HStack(spacing: 11) {
            Image(systemName: item.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.66))
                        .lineLimit(2)
                }
            }

            Spacer()

            if let value = item.value {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var shareCTA: some View {
        Button {
            onOpenShare?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.subheadline.weight(.semibold))

                Text("Customize share card")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.black)
            .padding(15)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom

    private var bottomControls: some View {
        HStack(spacing: 12) {
            Button {
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(currentIndex == 0 ? 0.34 : 0.92))
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 0)

            Button {
                goNext()
            } label: {
                HStack(spacing: 8) {
                    Text(currentIndex == pages.count - 1 ? "Done" : "Next")
                        .font(.subheadline.weight(.semibold))

                    Image(systemName: currentIndex == pages.count - 1 ? "checkmark" : "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var storyBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    CloseCutColors.backgroundPrimary,
                    CloseCutColors.accent.opacity(0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.30),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 360
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.28),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 360
            )
        }
    }

    // MARK: - Actions

    private func goNext() {
        if currentIndex < pages.count - 1 {
            currentIndex += 1
        } else {
            dismiss()
        }
    }

    private func goBack() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    private func rotation(
        for id: String
    ) -> Double {
        let value = abs(id.hashValue % 10)
        return Double(value - 5)
    }
}

// MARK: - Story Data

private enum WrapStoryPageKind: Equatable {
    case cover
    case count
    case emotion
    case genres
    case context
    case posters
    case highlight
    case share
}

private struct WrapStoryPage: Identifiable, Equatable {
    let id: String
    let kind: WrapStoryPageKind
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let isBigNumber: Bool
    let items: [WrapStoryPageItem]
}

private struct WrapStoryPageItem: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let value: String?
    let systemImage: String
}

private enum WrapStoryPageFactory {
    static func pages(
        for summary: WrapSummary
    ) -> [WrapStoryPage] {
        var pages: [WrapStoryPage] = []

        pages.append(
            WrapStoryPage(
                id: "cover",
                kind: .cover,
                eyebrow: summary.period.kind.displayName,
                title: summary.period.title,
                subtitle: summary.period.subtitle,
                systemImage: "sparkles.rectangle.stack.fill",
                isBigNumber: false,
                items: []
            )
        )

        pages.append(
            WrapStoryPage(
                id: "count",
                kind: .count,
                eyebrow: "Your count",
                title: "\(summary.watchedCount)",
                subtitle: summary.wrappedCountText,
                systemImage: "play.rectangle.fill",
                isBigNumber: true,
                items: [
                    WrapStoryPageItem(
                        id: "movies",
                        title: "Movies",
                        subtitle: "Watched films",
                        value: "\(summary.movieCount)",
                        systemImage: "film.fill"
                    ),
                    WrapStoryPageItem(
                        id: "series",
                        title: "Series",
                        subtitle: "Watched shows",
                        value: "\(summary.seriesCount)",
                        systemImage: "tv.fill"
                    ),
                    WrapStoryPageItem(
                        id: "saved",
                        title: "Saved",
                        subtitle: "Added for later",
                        value: "\(summary.savedCount)",
                        systemImage: "bookmark.fill"
                    )
                ]
            )
        )

        pages.append(
            WrapStoryPage(
                id: "emotion",
                kind: .emotion,
                eyebrow: "Your month felt",
                title: summary.emotionalTitle,
                subtitle: summary.emotionalSummary,
                systemImage: "heart.text.square.fill",
                isBigNumber: false,
                items: summary.moodSignals.prefix(3).map { item in
                    WrapStoryPageItem(
                        id: item.id,
                        title: item.title,
                        subtitle: item.percentageText,
                        value: "\(item.count)",
                        systemImage: item.systemImage
                    )
                }
            )
        )

        if summary.topGenres.isEmpty == false {
            pages.append(
                WrapStoryPage(
                    id: "genres",
                    kind: .genres,
                    eyebrow: "Top genres",
                    title: summary.topGenre?.title ?? "Your genres",
                    subtitle: "These genres shaped this period.",
                    systemImage: "square.stack.3d.up.fill",
                    isBigNumber: false,
                    items: summary.topGenres.prefix(4).map { item in
                        WrapStoryPageItem(
                            id: item.id,
                            title: item.title,
                            subtitle: item.percentageText,
                            value: "\(item.count)",
                            systemImage: item.systemImage
                        )
                    }
                )
            )
        }

        if summary.watchContexts.isEmpty == false {
            pages.append(
                WrapStoryPage(
                    id: "context",
                    kind: .context,
                    eyebrow: "Where it happened",
                    title: summary.watchContexts.first?.title ?? "Your watch context",
                    subtitle: "The places and contexts behind your memories.",
                    systemImage: "location.fill",
                    isBigNumber: false,
                    items: summary.watchContexts.prefix(3).map { item in
                        WrapStoryPageItem(
                            id: item.id,
                            title: item.title,
                            subtitle: item.percentageText,
                            value: "\(item.count)",
                            systemImage: item.systemImage
                        )
                    }
                )
            )
        }

        if summary.posterHighlights.isEmpty == false {
            pages.append(
                WrapStoryPage(
                    id: "posters",
                    kind: .posters,
                    eyebrow: "The visual memory",
                    title: "Your poster wall",
                    subtitle: "A few titles that shaped this period.",
                    systemImage: "rectangle.stack.fill",
                    isBigNumber: false,
                    items: []
                )
            )
        }

        if let strongestEntry = summary.strongestEntry ?? summary.topEntry {
            pages.append(
                WrapStoryPage(
                    id: "highlight",
                    kind: .highlight,
                    eyebrow: "Strongest memory",
                    title: strongestEntry.title,
                    subtitle: strongestEntry.reason,
                    systemImage: "star.fill",
                    isBigNumber: false,
                    items: [
                        WrapStoryPageItem(
                            id: "intensity",
                            title: "Intensity",
                            subtitle: strongestEntry.subtitle,
                            value: strongestEntry.intensity > 0 ? "\(strongestEntry.intensity)/5" : nil,
                            systemImage: "waveform.path.ecg"
                        )
                    ]
                )
            )
        }

        pages.append(
            WrapStoryPage(
                id: "share",
                kind: .share,
                eyebrow: "Share safely",
                title: "Choose what stays private.",
                subtitle: "Your Wrap can be shared as a privacy-safe card. Titles and posters stay hidden unless you turn them on.",
                systemImage: "lock.fill",
                isBigNumber: false,
                items: [
                    WrapStoryPageItem(
                        id: "private",
                        title: "Private by default",
                        subtitle: "Notes, quotes, Circle names, and personal takeaways are never included.",
                        value: nil,
                        systemImage: "lock.fill"
                    )
                ]
            )
        )

        return pages
    }
}
