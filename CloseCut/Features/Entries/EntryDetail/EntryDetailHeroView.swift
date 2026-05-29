//
//  EntryDetailHeroView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct EntryDetailHeroView: View {
    let entry: Entry
    let profile: UserProfile
    let metadataText: String
    let sharingText: String
    let syncText: String
    let shouldShowSyncStatus: Bool

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    private var mood: Mood? {
        let cleanedMood = entry.mood.trimmed

        guard cleanedMood.isEmpty == false else {
            return nil
        }

        return Mood.from(cleanedMood)
    }

    private var moodDisplayText: String? {
        let cleanedMood = entry.mood.trimmed

        if cleanedMood.isEmpty == false {
            return Mood.from(cleanedMood).label
        }

        return entry.quickSentiment?.displayName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            heroCard

            if entry.sourceType == .quickAdd {
                quickAddSignal
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            backdropSection

            contentSection
        }
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.displayTitle), \(metadataText), \(sharingText)")
    }

    // MARK: - Backdrop

    private var backdropSection: some View {
        ZStack(alignment: .bottomLeading) {
            backdropLayer

            LinearGradient(
                colors: [
                    .clear,
                    CloseCutColors.card.opacity(0.45),
                    CloseCutColors.card
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            chipRow
                .padding(14)
        }
        .frame(height: 210)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    @ViewBuilder
    private var backdropLayer: some View {
        if let backdropURL = entry.backdropURL {
            AsyncImage(url: backdropURL) { phase in
                switch phase {
                case .empty:
                    fallbackBackdrop

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 210)
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

    private var fallbackBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.26),
                    CloseCutColors.card.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: entry.type == .movie ? "film.fill" : "tv.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(CloseCutColors.textTertiary.opacity(0.28))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 14) {
                EntryPosterThumbnailView(
                    entry: entry,
                    width: 92,
                    height: 138,
                    cornerRadius: 17
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.displayTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(metadataText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    watchedDateRow

                    moodView
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            }

            if shouldShowSyncStatus {
                heroChip(
                    icon: entry.syncStatus == .failed ? "exclamationmark.triangle.fill" : "clock.fill",
                    text: syncText,
                    isHighlighted: false,
                    isWarning: entry.syncStatus == .failed
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var watchedDateRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text(watchedDateText)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.86)
        }
    }

    @ViewBuilder
    private var moodView: some View {
        if let mood {
            MoodPill(
                mood: mood,
                size: .small,
                isSelected: false,
                showLabel: true
            )
        } else if let moodDisplayText {
            heroChip(
                icon: "sparkles",
                text: moodDisplayText,
                isHighlighted: true,
                isWarning: false
            )
        }
    }

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                heroChip(
                    icon: entry.type == .movie ? "film.fill" : "tv.fill",
                    text: entry.type.displayName,
                    isHighlighted: false,
                    isWarning: false
                )

                if entry.sourceType == .quickAdd {
                    heroChip(
                        icon: "bolt.fill",
                        text: "Quick Add",
                        isHighlighted: true,
                        isWarning: false
                    )
                }

                if isShared {
                    heroChip(
                        icon: "person.2.fill",
                        text: "Shared",
                        isHighlighted: true,
                        isWarning: false
                    )
                }
            }
        }
    }

    private var quickAddSignal: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text("This memory started fast.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Complete it anytime with a takeaway, tags, and more personal context.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var watchedDateText: String {
        if let watchedDateApprox = entry.watchedDateApprox {
            return watchedDateApprox.displayLabel
        }

        return entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
    }

    private func heroChip(
        icon: String,
        text: String,
        isHighlighted: Bool,
        isWarning: Bool
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(chipForegroundColor(isHighlighted: isHighlighted, isWarning: isWarning))
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input.opacity(0.92))
        .clipShape(Capsule())
    }

    private func chipForegroundColor(
        isHighlighted: Bool,
        isWarning: Bool
    ) -> Color {
        if isWarning {
            return CloseCutColors.failed
        }

        if isHighlighted {
            return CloseCutColors.accentLight
        }

        return CloseCutColors.textTertiary
    }
}
