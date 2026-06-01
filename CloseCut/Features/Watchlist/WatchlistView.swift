//
//  WatchlistView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 31/05/26.
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \LocalWatchlistItem.updatedAt, order: .reverse)
    private var localItems: [LocalWatchlistItem]

    let user: AuthUser
    let profile: UserProfile
    var onOpenDiscover: (() -> Void)? = nil

    @State private var selectedFilter: WatchlistStatusFilter = .saved
    @State private var actionMessage: String?
    @State private var actionBannerStyle: SyncResultBannerStyle = .neutral
    @State private var isRefreshing = false

    private let watchlistRepository = WatchlistRepository()
    private let watchlistSyncService = WatchlistSyncService()
    private let entryRepository = EntryRepository()

    private var userItems: [WatchlistItem] {
        localItems
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var visibleItems: [WatchlistItem] {
        userItems.filter { item in
            if let status = selectedFilter.status {
                return item.status == status
            }

            return true
        }
    }

    private var savedCount: Int {
        userItems.filter { $0.status == .saved && $0.deletedAt == nil }.count
    }

    private var watchedCount: Int {
        userItems.filter { $0.status == .watched }.count
    }

    private var pendingCount: Int {
        userItems.filter { $0.syncStatus == .pending || $0.syncStatus == .failed }.count
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header

                    if let actionMessage {
                        SyncResultBanner(
                            message: actionMessage,
                            style: actionBannerStyle
                        )
                    }

                    filterBar

                    if visibleItems.isEmpty {
                        WatchlistEmptyStateView(
                            filter: selectedFilter,
                            onOpenDiscover: {
                                dismiss()
                                onOpenDiscover?()
                            }
                        )
                    } else {
                        ForEach(visibleItems) { item in
                            WatchlistItemCardView(
                                item: item,
                                onMarkWatched: {
                                    markWatched(item)
                                },
                                onAddToHistory: {
                                    addToHistory(item)
                                },
                                onDismiss: {
                                    dismissItem(item)
                                }
                            )
                        }
                    }

                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable {
                await refreshFromCloud()
            }
        }
        .navigationTitle("Want to Watch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await refreshFromCloud()
                    }
                } label: {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .disabled(isRefreshing)
                .accessibilityLabel("Refresh Watchlist")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Want to Watch")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("A private queue for titles you may want to turn into memories later.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "bookmark.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 42, height: 42)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
            }

            HStack(spacing: 10) {
                statPill(
                    value: "\(savedCount)",
                    label: "saved",
                    icon: "bookmark.fill"
                )

                statPill(
                    value: "\(watchedCount)",
                    label: "watched",
                    icon: "checkmark.circle.fill"
                )

                statPill(
                    value: "\(pendingCount)",
                    label: "sync",
                    icon: "clock.fill"
                )
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WatchlistStatusFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedFilter == filter ? .white : CloseCutColors.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(selectedFilter == filter ? CloseCutColors.accent : CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statPill(
        value: String,
        label: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func markWatched(_ item: WatchlistItem) {
        do {
            let updatedItem = try watchlistRepository.markLocalWatchlistItemWatched(
                itemId: item.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(updatedItem.displayTitle) was marked as watched."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func addToHistory(_ item: WatchlistItem) {
        do {
            let draft = QuickAddDraft(
                title: item.displayTitle,
                type: item.type,
                releaseYear: item.releaseYear,
                quickSentiment: nil,
                watchedDateApprox: .unknown,
                externalMetadata: item.externalMetadata
            )

            let entry = try entryRepository.createQuickAddEntry(
                ownerId: user.id,
                draft: draft,
                visibility: .privateOnly,
                modelContext: modelContext
            )

            _ = try watchlistRepository.markLocalWatchlistItemWatched(
                itemId: item.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(entry.displayTitle) was added to your history."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func dismissItem(_ item: WatchlistItem) {
        do {
            let updatedItem = try watchlistRepository.softDeleteLocalWatchlistItem(
                itemId: item.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(updatedItem.displayTitle) was removed from Want to Watch."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func refreshFromCloud() async {
        guard isRefreshing == false else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        let pushSummary = await watchlistSyncService.syncPendingWatchlistItems(
            userId: user.id,
            modelContext: modelContext
        )

        let pullSummary = await watchlistSyncService.pullRemoteWatchlistItems(
            userId: user.id,
            modelContext: modelContext
        )

        let failedCount = pushSummary.failedCount + pullSummary.failedCount
        let changedCount = pushSummary.syncedCount + pullSummary.pulledCount

        if failedCount > 0 {
            actionBannerStyle = .warning
            actionMessage = "Watchlist refresh partially failed. \(failedCount) item(s) need retry."
        } else if changedCount > 0 {
            actionBannerStyle = .success
            actionMessage = "Watchlist refreshed."
        } else {
            actionBannerStyle = .neutral
            actionMessage = "Watchlist is already up to date."
        }
    }
}
