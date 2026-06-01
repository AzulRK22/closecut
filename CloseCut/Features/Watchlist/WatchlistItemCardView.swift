//
//  WatchlistItemCardView.swift
//  CloseCut
//

import SwiftUI

struct WatchlistItemCardView: View {
    let item: WatchlistItem
    var isProcessing: Bool = false

    private var overviewText: String? {
        guard let overview = item.overview?.trimmed,
              overview.isEmpty == false else {
            return nil
        }

        return overview
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            WatchlistPosterView(
                item: item,
                width: 78,
                height: 116,
                cornerRadius: 16
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.displayTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(CloseCutColors.accentLight)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.top, 3)
                    }
                }

                Text(item.metadataText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                if let overviewText {
                    Text(overviewText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                footer
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.displayTitle), \(item.metadataText), \(item.status.displayName)")
    }

    private var footer: some View {
        HStack(spacing: 8) {
            statusChip

            Text("Saved from \(item.source.displayName)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }

    private var statusChip: some View {
        HStack(spacing: 5) {
            Image(systemName: statusIcon)
                .font(.caption2.weight(.semibold))

            Text(statusText)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
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
            return "Saved"
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
