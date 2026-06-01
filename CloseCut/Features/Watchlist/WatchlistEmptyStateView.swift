//
//  WatchlistEmptyStateView.swift
//  CloseCut
//

import SwiftUI

struct WatchlistEmptyStateView: View {
    let filter: WatchlistStatusFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: filter.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 46, height: 46)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var title: String {
        switch filter {
        case .saved:
            return "No saved titles yet"
        case .watched:
            return "Nothing marked watched yet"
        case .dismissed:
            return "No dismissed titles"
        }
    }

    private var message: String {
        switch filter {
        case .saved:
            return "Save titles from Discover when they look interesting. They will appear here until you mark them as watched."
        case .watched:
            return "When you mark a saved title as watched, CloseCut adds it to Personal and keeps a record here."
        case .dismissed:
            return "Dismissed titles will appear here when you remove them from your queue."
        }
    }
}
