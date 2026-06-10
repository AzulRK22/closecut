//
//  WatchlistRailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/06/26.
//

import SwiftUI

struct WatchlistRailView: View {
    let title: String
    let subtitle: String?
    let items: [WatchlistItem]
    let user: AuthUser
    let profile: UserProfile
    let onMarkWatched: (WatchlistItem) async -> Void
    let onPlanWithCircle: (WatchlistItem) -> Void
    let onDismiss: (WatchlistItem) async -> Void

    @State private var selectedItem: WatchlistItem?
    @State private var activeActionItemId: String?

    private var displayedItems: [WatchlistItem] {
        Array(
            items
                .filter { $0.status == .saved && $0.deletedAt == nil }
                .prefix(12)
        )
    }

    var body: some View {
        if displayedItems.isEmpty == false {
            VStack(alignment: .leading, spacing: 12) {
                header

                if displayedItems.count <= 2 {
                    compactList
                        .padding(.horizontal, 20)
                } else {
                    horizontalRail
                }
            }
            .sheet(item: $selectedItem) { item in
                WatchlistItemDetailSheet(
                    item: item,
                    isProcessing: activeActionItemId == item.id,
                    onMarkWatched: {
                        Task {
                            await runAction(for: item) {
                                await onMarkWatched(item)
                            }
                        }
                    },
                    onPlanWithCircle: {
                        selectedItem = nil

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            onPlanWithCircle(item)
                        }
                    },
                    onDismiss: {
                        Task {
                            await runAction(for: item) {
                                await onDismiss(item)
                            }
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            Text("\(displayedItems.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(CloseCutColors.input)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
    }

    private var compactList: some View {
        VStack(spacing: 12) {
            ForEach(displayedItems) { item in
                Button {
                    selectedItem = item
                } label: {
                    WatchlistCompactCardView(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var horizontalRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(displayedItems) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        WatchlistRailItemView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func runAction(
        for item: WatchlistItem,
        operation: () async -> Void
    ) async {
        guard activeActionItemId == nil else {
            return
        }

        activeActionItemId = item.id
        await operation()
        activeActionItemId = nil
        selectedItem = nil
    }
}

private struct WatchlistCompactCardView: View {
    let item: WatchlistItem

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
                width: 74,
                height: 110,
                cornerRadius: 16
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.displayTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .padding(.top, 3)
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

                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2.weight(.semibold))

                    Text("Ready when you are")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(CloseCutColors.input)
                .clipShape(Capsule())
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
    }
}

private struct WatchlistRailItemView: View {
    let item: WatchlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                WatchlistPosterView(
                    item: item,
                    width: 116,
                    height: 172,
                    cornerRadius: 16
                )

                Image(systemName: "bookmark.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 26, height: 26)
                    .background(CloseCutColors.input.opacity(0.92))
                    .clipShape(SwiftUI.Circle())
                    .padding(7)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.metadataText)
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                Text("Want to Watch")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 116, alignment: .leading)
        }
        .frame(width: 116, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.displayTitle), \(item.metadataText), Want to Watch")
    }
}
