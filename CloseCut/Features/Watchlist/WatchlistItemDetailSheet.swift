//
//  WatchlistItemDetailSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/06/26.
//

import SwiftUI

struct WatchlistItemDetailSheet: View {
    let item: WatchlistItem
    let isProcessing: Bool
    let onMarkWatched: () -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var canActOnItem: Bool {
        item.status == .saved && item.deletedAt == nil
    }

    private var overviewText: String? {
        guard let overview = item.overview?.trimmed,
              overview.isEmpty == false else {
            return nil
        }

        return overview
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        hero

                        metadataSection

                        if let overviewText {
                            overviewSection(overviewText)
                        }

                        actionSection

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Want to Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                WatchlistPosterView(
                    item: item,
                    width: 118,
                    height: 176,
                    cornerRadius: 22
                )

                VStack(alignment: .leading, spacing: 10) {
                    statusChip

                    Text(item.displayTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.metadataText)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    sourceChip
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var heroBackground: some View {
        ZStack {
            CloseCutColors.card

            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.14),
                    CloseCutColors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var statusChip: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
                .font(.caption2.weight(.semibold))

            Text(statusText)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private var sourceChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption2.weight(.semibold))

            Text("Saved from \(item.source.displayName)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Details")

            VStack(spacing: 10) {
                detailRow(
                    icon: item.type == .movie ? "film.fill" : "tv.fill",
                    title: "Type",
                    value: item.type.displayName
                )

                if let releaseYear = item.releaseYear {
                    detailRow(
                        icon: "calendar",
                        title: "Year",
                        value: "\(releaseYear)"
                    )
                }

                if let rating = item.tmdbRating,
                   rating > 0 {
                    detailRow(
                        icon: "star.fill",
                        title: "TMDB",
                        value: String(format: "%.1f", rating)
                    )
                }

                detailRow(
                    icon: "bookmark.fill",
                    title: "Status",
                    value: item.status.displayName
                )
            }
            .padding(14)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    private func overviewSection(_ overview: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Overview")

            Text(overview)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CloseCutColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(CloseCutColors.separator, lineWidth: 0.5)
                }
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Next step")

            if canActOnItem {
                VStack(spacing: 10) {
                    Button {
                        onMarkWatched()
                    } label: {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }

                            Text(isProcessing ? "Adding to Personal..." : "Mark as Watched")
                                .lineLimit(1)
                                .minimumScaleFactor(0.86)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)

                    Button {
                        onDismiss()
                    } label: {
                        Text("Dismiss")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)

                    Text("Marking as watched moves this title into Personal as a Quick Add. You can complete mood, tags, and notes later.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if item.status == .watched {
                stateMessage(
                    icon: "checkmark.circle.fill",
                    title: "Already added to Personal",
                    message: "This title has been moved into your watch history."
                )
            } else {
                stateMessage(
                    icon: "xmark.circle.fill",
                    title: "Dismissed",
                    message: "This title is no longer in your active Want to Watch queue."
                )
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(CloseCutColors.textTertiary)
            .textCase(.uppercase)
    }

    private func detailRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)

            Spacer()

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1)
        }
    }

    private func stateMessage(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
                .frame(width: 34, height: 34)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var statusIcon: String {
        switch item.status {
        case .saved:
            return "bookmark.fill"
        case .watched:
            return "checkmark.circle.fill"
        case .dismissed:
            return "xmark.circle.fill"
        }
    }

    private var statusText: String {
        switch item.status {
        case .saved:
            return "Want to Watch"
        case .watched:
            return "Watched"
        case .dismissed:
            return "Dismissed"
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .saved:
            return CloseCutColors.accentLight
        case .watched:
            return CloseCutColors.synced
        case .dismissed:
            return CloseCutColors.textTertiary
        }
    }
}
