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
    let onOpenQuickPick: () -> Void

    private let quickPickTargetCount = 3

    private var sortedEntries: [Entry] {
        entries.sorted { first, second in
            first.watchedAt > second.watchedAt
        }
    }

    private var isLowHistory: Bool {
        entries.count > 0 && entries.count < quickPickTargetCount
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyTimelineState
            } else {
                populatedTimeline
            }
        }
        .background(CloseCutColors.backgroundPrimary)
    }

    private var emptyTimelineState: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                title: "Start your taste history",
                message: "Add past watches fast or log what you just watched.",
                systemImage: "film.stack",
                actionTitle: "Add past watches",
                action: onQuickAdd
            )

            Button {
                onCreateEntry()
            } label: {
                Text("Log a new watch")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var populatedTimeline: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if isLowHistory {
                    HistoryProgressModule(
                        currentCount: entries.count,
                        targetCount: quickPickTargetCount,
                        onQuickAdd: onQuickAdd,
                        onOpenQuickPick: onOpenQuickPick
                    )
                }

                TimelineSectionHeader(
                    title: "Recently watched",
                    subtitle: isLowHistory ? "Your archive is taking shape." : "Your latest memories and additions."
                )

                LazyVStack(spacing: 12) {
                    ForEach(sortedEntries) { entry in
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
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
        onCreateEntry: {},
        onOpenQuickPick: {}
    )
}
