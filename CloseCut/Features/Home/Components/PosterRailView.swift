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
    var maxVisibleCount: Int = 12

    private var visibleEntries: [Entry] {
        Array(entries.prefix(maxVisibleCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimelineSectionHeader(
                title: title,
                subtitle: subtitle
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(visibleEntries) { entry in
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
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -20)
        }
    }
}
