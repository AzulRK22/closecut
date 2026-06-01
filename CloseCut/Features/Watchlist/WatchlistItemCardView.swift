//
//  WatchlistItemCardView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 31/05/26.
//

import SwiftUI

struct WatchlistItemCardView: View {
    let item: WatchlistItem
    let onMarkWatched: () -> Void
    let onAddToHistory: () -> Void
    let onDismiss: () -> Void

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

    private var sourceText: String {
        "Saved from \(item.source.displayName)"
    }

    private var syncText: String? {
        switch item.syncStatus {
        case .pending:
            return "Pending sync"
        case .failed:
            return "Sync failed"
        case .synced:
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                WatchlistPosterView(
                    item: item,
                    width: 76,
                    height: 114,
                    cornerRadius: 15
                )

                VStack(alignment: .leading, spacing: 8) {
                    header

                    Text(item.metadataText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)

                    if let overview = item.overview?.trimmed,
                       overview.isEmpty == false {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(sourceText)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(2)
                    }

                    chipsRow
                }

                Spacer(minLength: 0)
            }

            actionRow
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
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

            Spacer(minLength: 8)

            Menu {
                if item.status == .saved {
                    Button {
                        onMarkWatched()
                    } label: {
                        Label("Mark as watched", systemImage: "checkmark.circle")
                    }

                    Button {
                        onAddToHistory()
                    } label: {
                        Label("Add to history", systemImage: "film.stack")
                    }
                }

                if item.status != .dismissed {
                    Button(role: .destructive) {
                        onDismiss()
                    } label: {
                        Label("Remove from Want to Watch", systemImage: "xmark.circle")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private var chipsRow: some View {
        HStack(spacing: 8) {
            chip(
                icon: statusIcon,
                text: item.status.displayName,
                color: statusColor
            )

            chip(
                icon: "tray.fill",
                text: item.source.displayName,
                color: CloseCutColors.textTertiary
            )

            if let syncText {
                chip(
                    icon: item.syncStatus == .failed ? "exclamationmark.triangle.fill" : "clock.fill",
                    text: syncText,
                    color: item.syncStatus == .failed ? CloseCutColors.failed : CloseCutColors.pending
                )
            }

            Spacer(minLength: 0)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            if item.status == .saved {
                Button {
                    onAddToHistory()
                } label: {
                    Label("Add to history", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onMarkWatched()
                } label: {
                    Text("Mark watched")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Text(item.status == .watched ? "Already marked as watched." : "Dismissed from your list.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Spacer()
            }
        }
    }

    private func chip(
        icon: String,
        text: String,
        color: Color
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
}
