//
//  WatchlistEmptyStateView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 31/05/26.
//

import SwiftUI

struct WatchlistEmptyStateView: View {
    let filter: WatchlistStatusFilter
    let onOpenDiscover: () -> Void

    private var title: String {
        switch filter {
        case .saved:
            return "No saved titles yet"
        case .watched:
            return "No watched titles from your list yet"
        case .dismissed:
            return "No dismissed titles"
        case .all:
            return "Your Watchlist is empty"
        }
    }

    private var message: String {
        switch filter {
        case .saved:
            return "Save titles from Discover when something looks interesting but you are not ready to add it to your watched history."
        case .watched:
            return "When you mark Watchlist titles as watched, they will appear here."
        case .dismissed:
            return "Removed titles will appear here if you want to review them later."
        case .all:
            return "Use Discover to save movies or series you may want to watch later."
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 52, height: 52)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                onOpenDiscover()
            } label: {
                Text("Open Discover")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
