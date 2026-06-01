//
//  WatchlistView.swift
//  CloseCut
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \LocalWatchlistItem.updatedAt, order: .reverse)
    private var localWatchlistItems: [LocalWatchlistItem]

    let user: AuthUser
    let profile: UserProfile

    @State private var selectedFilter: WatchlistStatusFilter = .saved
    @State private var selectedItem: WatchlistItem?
    @State private var actionMessage: String?
    @State private var actionBannerStyle: SyncResultBannerStyle = .neutral
    @State private var activeActionItemId: String?

    private let entryRepository = EntryRepository()
    private let watchlistRepository = WatchlistRepository()

    private var allItems: [WatchlistItem] {
        localWatchlistItems
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var filteredItems: [WatchlistItem] {
        allItems.filter { item in
            switch selectedFilter {
            case .saved:
                return item.status == .saved && item.deletedAt == nil
            case .watched:
                return item.status == .watched && item.deletedAt == nil
            case .dismissed:
                return item.status == .dismissed || item.deletedAt != nil
            }
        }
    }

    private var savedCount: Int {
        allItems.filter { $0.status == .saved && $0.deletedAt == nil }.count
    }

    private var watchedCount: Int {
        allItems.filter { $0.status == .watched && $0.deletedAt == nil }.count
    }

    private var dismissedCount: Int {
        allItems.filter { $0.status == .dismissed || $0.deletedAt != nil }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header

                        filterPicker

                        if let actionMessage {
                            SyncResultBanner(
                                message: actionMessage,
                                style: actionBannerStyle
                            )
                        }

                        content

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Want to Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                    .accessibilityLabel("Close Want to Watch")
                }
            }
            .sheet(item: $selectedItem) { item in
                WatchlistItemDetailSheet(
                    item: item,
                    isProcessing: activeActionItemId == item.id,
                    onMarkWatched: {
                        Task {
                            await markAsWatched(item)
                        }
                    },
                    onDismiss: {
                        Task {
                            await dismissItem(item)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .preferredColorScheme(.dark)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Want to Watch")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Your private queue of titles waiting for the right moment.")
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
                watchlistStat(
                    value: "\(savedCount)",
                    label: "saved"
                )

                watchlistStat(
                    value: "\(watchedCount)",
                    label: "watched"
                )

                watchlistStat(
                    value: "\(dismissedCount)",
                    label: "dismissed"
                )
            }
        }
    }

    private func watchlistStat(
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(WatchlistStatusFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: filter.systemImage)
                            .font(.caption2.weight(.semibold))

                        Text(filter.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedFilter == filter ? .white : CloseCutColors.textSecondary)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(selectedFilter == filter ? CloseCutColors.accent : CloseCutColors.input)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var content: some View {
        if filteredItems.isEmpty {
            WatchlistEmptyStateView(filter: selectedFilter)
        } else {
            LazyVStack(spacing: 14) {
                ForEach(filteredItems) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        WatchlistItemCardView(
                            item: item,
                            isProcessing: activeActionItemId == item.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func markAsWatched(_ item: WatchlistItem) async {
        guard activeActionItemId == nil else {
            return
        }

        activeActionItemId = item.id
        defer { activeActionItemId = nil }

        let draft = QuickAddDraft(
            title: item.displayTitle,
            type: item.type,
            releaseYear: item.releaseYear,
            quickSentiment: nil,
            watchedDateApprox: .unknown,
            externalMetadata: item.externalMetadata
        )

        do {
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
            actionMessage = "\(entry.displayTitle) moved to Personal."
            selectedItem = nil

            withAnimation(.easeInOut(duration: 0.18)) {
                selectedFilter = .saved
            }
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func dismissItem(_ item: WatchlistItem) async {
        guard activeActionItemId == nil else {
            return
        }

        activeActionItemId = item.id
        defer { activeActionItemId = nil }

        do {
            _ = try watchlistRepository.softDeleteLocalWatchlistItem(
                itemId: item.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(item.displayTitle) was removed from Want to Watch."
            selectedItem = nil
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }
}
