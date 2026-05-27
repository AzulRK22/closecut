//
//  DiscoverMediaRail.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/05/26.
//

import SwiftUI

struct DiscoverMediaRail: View {
    let title: String
    let subtitle: String
    let emptyMessage: String
    let items: [TMDBMediaSearchResult]
    let onSelect: (TMDBMediaSearchResult) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            if items.isEmpty {
                emptyRail
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(items.prefix(12)) { media in
                            DiscoverMediaPosterCard(
                                media: media,
                                onTap: {
                                    onSelect(media)
                                }
                            )
                        }
                    }
                    .padding(.trailing, 20)
                }
            }
        }
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyRail: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text(emptyMessage)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
