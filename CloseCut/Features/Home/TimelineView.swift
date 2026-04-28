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
    let onQuickAdd: () -> Void
    let onCreateEntry: () -> Void

    var body: some View {
        Group {
            if entries.isEmpty {
                VStack(spacing: 16) {
                    EmptyStateView(
                        title: "Start your taste history",
                        message: "Add past watches fast or log what you just watched.",
                        systemImage: "film.stack",
                        actionTitle: "Add past watches",
                        action: onQuickAdd
                    )

                    Button("Log a new watch") {
                        onCreateEntry()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .frame(minHeight: 44)
                }
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
        onQuickAdd: {},
        onCreateEntry: {}
    )
}
