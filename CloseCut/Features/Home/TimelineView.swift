//
//  TimelineView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct TimelineView: View {
    let entries: [Entry]
    let profile: UserProfile
    let onCreateEntry: () -> Void

    var body: some View {
        Group {
            if entries.isEmpty {
                EmptyStateView(
                    title: "Nothing here yet",
                    message: "Tap + to log your first watch.",
                    systemImage: "film.stack",
                    actionTitle: "Log a film",
                    action: onCreateEntry
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(entries) { entry in
                            NavigationLink {
                                EntryDetailView(
                                    entry: entry,
                                    profile: profile
                                )
                            } label: {
                                EntryCardView(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(CloseCutColors.backgroundPrimary)
    }
}

#Preview {
    TimelineView(
        entries: [],
        profile: UserProfile(
            id: "preview-user",
            displayName: "Preview",
            email: "preview@closecut.dev",
            photoURL: nil,
            circleId: nil,
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        ),
        onCreateEntry: {}
    )
}
