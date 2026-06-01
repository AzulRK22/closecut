//
//  WatchlistItemCardView.swift
//  CloseCut
//

import SwiftUI

struct WatchlistItemCardView: View {
    let item: WatchlistItem
    let isProcessing: Bool
    let onMarkWatched: () -> Void
    let onDismiss: () -> Void

    private var canMarkWatched: Bool {
        item.status == .saved && item.deletedAt == nil
    }

    private var canDismiss: Bool {
        item.status == .saved && item.deletedAt == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                WatchlistPosterView(
                    item: item,
                    width: 82,
                    height: 122,
                    cornerRadius: 16
                )

                VStack(alignment: .leading, spacing: 8) {
                    header

                    Text(item.metadataText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    sourceRow

                    if let overview = item.overview?.trimmed,
                       overview.isEmpty == false {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(3)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }

            actionArea
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

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(item.displayTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            statusChip
        }
    }

    private var statusChip: some View {
        HStack(spacing: 5) {
            Image(systemName: statusIcon)
                .font(.caption2.weight(.semibold))

            Text(item.status.displayName)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(statusForeground)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private var sourceRow: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)

            Text("Saved from \(item.source.displayName)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        if canMarkWatched {
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
                    .frame(height: 46)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)

                if canDismiss {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Dismiss")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }
            }
        } else if item.status == .watched {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.synced)

                Text("Added to Personal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                Spacer()
            }
            .padding(10)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("Dismissed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                Spacer()
            }
            .padding(10)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private var statusForeground: Color {
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
