//
//  PosterRailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct PosterRailView: View {
    let title: String
    let subtitle: String?
    let entries: [Entry]
    let user: AuthUser
    let profile: UserProfile

    private var displayedEntries: [Entry] {
        Array(
            entries
                .filter { $0.deletedAt == nil }
                .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
                .prefix(12)
        )
    }

    var body: some View {
        if displayedEntries.isEmpty == false {
            VStack(alignment: .leading, spacing: 12) {
                header

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(displayedEntries) { entry in
                            NavigationLink {
                                EntryDetailView(
                                    entry: entry,
                                    user: user,
                                    profile: profile
                                )
                            } label: {
                                PosterRailItemView(entry: entry)
                            }
                            .buttonStyle(.plain)
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
