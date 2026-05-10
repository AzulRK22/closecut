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

    private var activeEntries: [Entry] {
        entries
            .filter { $0.deletedAt == nil }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var timelineSections: [TimelineSection] {
        TimelineSectionBuilder.buildSections(from: activeEntries)
    }

    private var isLowHistory: Bool {
        activeEntries.count > 0 && activeEntries.count < quickPickTargetCount
    }

    var body: some View {
        Group {
            if activeEntries.isEmpty {
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
                    entries: activeEntries,
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
                    entries: activeEntries,
                    onQuickAdd: onQuickAdd,
                    onCreateEntry: onCreateEntry
                )

                if isLowHistory {
                    HistoryProgressModule(
                        currentCount: activeEntries.count,
                        targetCount: quickPickTargetCount,
                        onQuickAdd: onQuickAdd,
                        onOpenQuickPick: onOpenQuickPick
                    )
                }

                ForEach(timelineSections) { section in
                    timelineSectionView(section)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func timelineSectionView(
        _ section: TimelineSection
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TimelineSectionHeader(
                title: section.title,
                subtitle: section.subtitle
            )

            LazyVStack(spacing: 14) {
                ForEach(section.entries) { entry in
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
            circleIds: [],
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
