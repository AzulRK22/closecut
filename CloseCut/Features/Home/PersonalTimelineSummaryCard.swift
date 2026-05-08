//
//  PersonalTimelineSummaryCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/05/26.
//

import SwiftUI

struct PersonalTimelineSummaryCard: View {
    let entries: [Entry]
    let onQuickAdd: () -> Void
    let onCreateEntry: () -> Void

    private var activeEntries: [Entry] {
        entries.filter { $0.deletedAt == nil }
    }

    private var totalCount: Int {
        activeEntries.count
    }

    private var sharedCount: Int {
        activeEntries.filter {
            $0.visibility == .circle && $0.sharedCircleIds.isEmpty == false
        }.count
    }

    private var quickAddCount: Int {
        activeEntries.filter { $0.sourceType == .quickAdd }.count
    }

    private var enrichableQuickAddCount: Int {
        activeEntries.filter {
            $0.sourceType == .quickAdd &&
            (
                $0.mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                $0.takeaway.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                $0.tags.isEmpty
            )
        }.count
    }

    private var privateCount: Int {
        max(totalCount - sharedCount, 0)
    }

    private var tmdbEnrichedCount: Int {
        activeEntries.filter { $0.tmdbId != nil || $0.posterPath != nil }.count
    }

    private var dominantGenreName: String? {
        let genreIds = activeEntries.flatMap { $0.tmdbGenreIds }

        guard genreIds.isEmpty == false else {
            return nil
        }

        let counts = Dictionary(grouping: genreIds, by: { $0 })
            .mapValues { $0.count }

        guard let dominantGenreId = counts
            .sorted(by: { first, second in
                if first.value != second.value {
                    return first.value > second.value
                }

                return first.key < second.key
            })
            .first?
            .key else {
            return nil
        }

        return TMDBGenreNameMapper.displayName(for: dominantGenreId)
    }

    private var metadataProgressText: String {
        guard totalCount > 0 else {
            return "No metadata yet"
        }

        return "\(tmdbEnrichedCount)/\(totalCount) enriched"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            HStack(spacing: 10) {
                statPill(
                    value: "\(totalCount)",
                    label: totalCount == 1 ? "memory" : "memories",
                    icon: "film.stack"
                )

                statPill(
                    value: "\(privateCount)",
                    label: "private",
                    icon: "lock.fill"
                )

                statPill(
                    value: "\(sharedCount)",
                    label: "shared",
                    icon: "person.2.fill"
                )
            }

            insightCard

            HStack(spacing: 10) {
                Button {
                    onQuickAdd()
                } label: {
                    Label("Quick Add", systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onCreateEntry()
                } label: {
                    Label("New Entry", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text("Private by default. Share only the memories that belong in a Circle.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Your archive")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 34, height: 34)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())
        }
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Archive signals")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                insightPill(
                    icon: "sparkles",
                    text: dominantGenreName ?? "Building taste"
                )

                insightPill(
                    icon: "photo.on.rectangle",
                    text: metadataProgressText
                )
            }

            if enrichableQuickAddCount > 0 {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.top, 1)

                    Text("\(enrichableQuickAddCount) quick \(enrichableQuickAddCount == 1 ? "add is" : "adds are") ready to become richer memories.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var summaryText: String {
        if totalCount == 0 {
            return "Start building your private taste history."
        }

        if let dominantGenreName, totalCount >= 3 {
            return "Your archive is starting to lean toward \(dominantGenreName.lowercased())."
        }

        if quickAddCount > 0 {
            return "\(quickAddCount) quick adds are ready to become richer memories."
        }

        if sharedCount > 0 {
            return "\(sharedCount) memories are shared with trusted Circles."
        }

        return "Your personal watch history is taking shape."
    }

    private func statPill(
        value: String,
        label: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func insightPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.card)
        .clipShape(Capsule())
    }
}
