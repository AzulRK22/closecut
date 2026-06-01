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

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(displayedItems) { item in
                            WatchlistRailItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private var header: some View {
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
        .padding(.horizontal, 20)
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 30, height: 30)
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
