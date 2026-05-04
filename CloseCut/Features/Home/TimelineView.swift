//
//  TimelineView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct TimelineView: View {
    let entries: [Entry]
    let user: AuthUser
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
        ScrollView {
            VStack(spacing: 18) {
                PersonalTimelineSummaryCard(
                    entries: entries,
                    onQuickAdd: onQuickAdd,
                    onCreateEntry: onCreateEntry
                )

                EmptyStateView(
                    title: "Start your private taste history",
                    message: "Quick Add a few movies or series you already watched, then let CloseCut help you remember, decide, and share selectively.",
                    systemImage: "film.stack",
                    actionTitle: "Add past watches",
                    action: onQuickAdd
                )

                Button {
                    onCreateEntry()
                } label: {
                    Text("Log a new watch instead")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private var populatedTimeline: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                PersonalTimelineSummaryCard(
                    entries: entries,
                    onQuickAdd: onQuickAdd,
                    onCreateEntry: onCreateEntry
                )
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
                    subtitle: isLowHistory
                        ? "Add a few more memories to unlock stronger picks."
                        : "Your latest memories, quick adds, and shared moments."
                )

                LazyVStack(spacing: 14) {
                    ForEach(sortedEntries) { entry in
                        NavigationLink {
                            EntryDetailView(
                                entry: entry,
                                user: user,
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
        user: AuthUser(
            id: "preview-user",
            email: "preview@closecut.dev",
            displayName: "Preview",
            photoURL: nil
        ),
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
