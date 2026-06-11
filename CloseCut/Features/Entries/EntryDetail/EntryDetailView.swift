//
//  EntryDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/04/26.
//

import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LocalCircle.updatedAt, order: .reverse)
    private var localCircles: [LocalCircle]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    let entry: Entry
    let user: AuthUser
    let profile: UserProfile

    @State private var isShowingEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeletingEntry = false
    @State private var deleteErrorMessage: String?

    @State private var selectedMediaForWatchPlan: WatchPlanMediaSnapshot?
    @State private var showCreateWatchPlanSheet = false
    @State private var isCreatingWatchPlan = false
    @State private var watchPlanErrorMessage: String?
    @State private var watchPlanMessage: String?
    @State private var watchPlanBannerStyle: SyncResultBannerStyle = .neutral

    private let entryRepository = EntryRepository()
    private let watchPlanRepository = WatchPlanRepository()
    private let watchPlanSyncService = WatchPlanSyncService()

    private var memberships: [CircleMembership] {
        localMemberships
            .filter { $0.userId == user.id }
            .map { $0.domain }
            .filter { $0.isActive }
            .sorted { first, second in
                if first.isOwner != second.isOwner {
                    return first.isOwner && !second.isOwner
                }

                return first.updatedAt > second.updatedAt
            }
    }

    private var circlesById: [String: CloseCircle] {
        Dictionary(
            uniqueKeysWithValues: localCircles.map { ($0.id, $0.domain) }
        )
    }

    private var circleRows: [(circle: CloseCircle, membership: CircleMembership)] {
        memberships.compactMap { membership in
            guard let circle = circlesById[membership.circleId],
                  circle.deletedAt == nil else {
                return nil
            }

            return (circle, membership)
        }
    }

    private var hasActiveCircleMemberships: Bool {
        circleRows.isEmpty == false
    }

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    private var sharingText: String {
        guard isShared else {
            return "Private memory"
        }

        if entry.sharedCircleIds.count == 1 {
            return "Shared with 1 Circle"
        }

        return "Shared with \(entry.sharedCircleIds.count) Circles"
    }

    private var syncText: String {
        switch entry.syncStatus {
        case .pending:
            return "Pending sync"
        case .synced:
            return "Synced"
        case .failed:
            return "Sync failed"
        }
    }

    private var shouldShowSyncStatus: Bool {
        entry.syncStatus != .synced
    }

    private var metadataText: String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if let rating = entry.tmdbRating, rating > 0 {
            parts.append(String(format: "%.1f TMDB", rating))
        }

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    EntryDetailHeroView(
                        entry: entry,
                        profile: profile,
                        metadataText: metadataText,
                        sharingText: sharingText,
                        syncText: syncText,
                        shouldShowSyncStatus: shouldShowSyncStatus
                    )

                    if entry.syncStatus == .failed {
                        SyncResultBanner(
                            message: "This entry failed to sync. Try syncing again from Settings.",
                            style: .warning
                        )
                    }

                    if isDeletingEntry {
                        SyncResultBanner(
                            message: "Deleting entry…",
                            style: .neutral
                        )
                    }

                    if let watchPlanMessage {
                        SyncResultBanner(
                            message: watchPlanMessage,
                            style: watchPlanBannerStyle
                        )
                    }

                    watchTogetherCard

                    EntryDetailMemoryCard(
                        entry: entry,
                        onCompleteMemory: {
                            isShowingEditSheet = true
                        }
                    )

                    if let quote = cleanOptional(entry.quote) {
                        keyMomentCard(quote)
                    }

                    EntryDetailSignalsCard(entry: entry)

                    EntryDetailMetadataCard(overview: entry.overview)

                    EntryDetailSharingCard(
                        entry: entry,
                        sharingText: sharingText,
                        syncText: syncText,
                        shouldShowSyncStatus: shouldShowSyncStatus,
                        onEditSharing: {
                            isShowingEditSheet = true
                        }
                    )

                    Spacer(minLength: 32)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(CloseCutColors.accent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        openCreateWatchPlanFromEntry()
                    } label: {
                        Label(
                            "Plan with Circle",
                            systemImage: "person.2.wave.2.fill"
                        )
                    }
                    .disabled(isDeletingEntry || isCreatingWatchPlan || entry.deletedAt != nil)

                    Button {
                        isShowingEditSheet = true
                    } label: {
                        Label(
                            entry.sourceType == .quickAdd ? "Complete memory" : "Edit memory",
                            systemImage: "pencil"
                        )
                    }
                    .disabled(isDeletingEntry)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(
                            isDeletingEntry ? "Deleting..." : "Delete memory",
                            systemImage: "trash"
                        )
                    }
                    .disabled(isDeletingEntry || entry.deletedAt != nil)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CloseCutColors.accent)
                }
                .accessibilityLabel("Entry actions")
                .disabled(isDeletingEntry)
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EntryEditorView(
                user: user,
                profile: profile,
                entryToEdit: entry,
                hasCircleMembers: entry.isSharedWithCircle
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showCreateWatchPlanSheet) {
            CreateWatchPlanSheet(
                circleRows: circleRows,
                selectedCircleId: circleRows.first?.circle.id,
                initialMedia: selectedMediaForWatchPlan,
                isCreating: isCreatingWatchPlan,
                onCancel: {
                    showCreateWatchPlanSheet = false
                    selectedMediaForWatchPlan = nil
                },
                onCreate: { draft in
                    Task {
                        await createWatchPlanFromEntry(draft)
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Delete this memory?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete memory", role: .destructive) {
                Task {
                    await deleteEntry()
                }
            }
            .disabled(isDeletingEntry)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes it from your Personal library and any Circle timelines where it was shared. The change will sync later if needed.")
        }
        .alert("Couldn’t delete memory", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "Unknown error.")
        }
        .alert("Watch Together failed", isPresented: Binding(
            get: { watchPlanErrorMessage != nil },
            set: { if !$0 { watchPlanErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(watchPlanErrorMessage ?? "Unknown error.")
        }
    }

    // MARK: - Watch Together

    private var watchTogetherCard: some View {
        EntryDetailSectionCard(
            title: "Watch Together",
            subtitle: "Turn this memory into a private Circle plan.",
            systemImage: "person.2.wave.2.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(width: 34, height: 34)
                        .background(CloseCutColors.input)
                        .clipShape(SwiftUI.Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plan a rewatch or share the experience.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text("This creates a Watch Together plan from this title. It does not change the original memory or share it automatically.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                Button {
                    openCreateWatchPlanFromEntry()
                } label: {
                    HStack(spacing: 8) {
                        if isCreatingWatchPlan {
                            ProgressView()
                                .scaleEffect(0.85)
                                .tint(.white)
                        } else {
                            Image(systemName: "calendar.badge.plus")
                        }

                        Text(isCreatingWatchPlan ? "Creating plan…" : "Plan with Circle")
                            .lineLimit(1)
                            .minimumScaleFactor(0.86)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isDeletingEntry || isCreatingWatchPlan || entry.deletedAt != nil)
            }
        }
    }

    private func openCreateWatchPlanFromEntry() {
        guard entry.deletedAt == nil else {
            return
        }

        guard circleRows.isEmpty == false else {
            withAnimation(.easeInOut(duration: 0.18)) {
                watchPlanBannerStyle = .warning
                watchPlanMessage = "Create or join a Circle before planning this title."
            }

            return
        }

        selectedMediaForWatchPlan = WatchPlanMediaSnapshotFactory.fromEntry(entry)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            showCreateWatchPlanSheet = true
        }
    }

    private func createWatchPlanFromEntry(
        _ draft: WatchPlanCreationDraft
    ) async {
        guard isCreatingWatchPlan == false else {
            return
        }

        guard let selectedRow = circleRows.first(where: { row in
            row.circle.id == draft.circleId
        }) else {
            watchPlanErrorMessage = "Choose a valid Circle before creating this plan."
            return
        }

        let invitedMemberIds = draft.invitedMemberIds.filter { memberId in
            memberId.trimmed.isEmpty == false &&
            memberId.trimmed != user.id.trimmed
        }

        guard invitedMemberIds.isEmpty == false else {
            watchPlanErrorMessage = "Select at least one Circle member to invite."
            return
        }

        isCreatingWatchPlan = true
        watchPlanErrorMessage = nil

        defer {
            isCreatingWatchPlan = false
        }

        do {
            let createdPlan = try watchPlanRepository.createLocalPlan(
                ownerId: user.id,
                ownerDisplayName: profile.displayName,
                circleId: selectedRow.circle.id,
                circleName: selectedRow.circle.displayName,
                title: draft.planTitle,
                note: draft.note,
                media: draft.media,
                proposedStartAt: nil,
                proposedEndAt: nil,
                proposedDateText: draft.proposedDateText,
                locationType: draft.locationType,
                locationName: draft.locationName,
                locationAddress: draft.locationAddress,
                streamingService: draft.streamingService,
                invitedMemberIds: invitedMemberIds,
                source: .entry,
                modelContext: modelContext
            )

            let syncSummary = await watchPlanSyncService.syncPendingWatchTogetherItems(
                userId: user.id,
                modelContext: modelContext
            )

            await MainActor.run {
                showCreateWatchPlanSheet = false
                selectedMediaForWatchPlan = nil

                withAnimation(.easeInOut(duration: 0.18)) {
                    if syncSummary.hasFailures {
                        watchPlanBannerStyle = .warning
                        watchPlanMessage = "Plan created locally, but it could not sync yet. It will retry later."
                    } else {
                        watchPlanBannerStyle = .success
                        watchPlanMessage = "\(createdPlan.media.displayTitle) was planned with your Circle."
                    }
                }
            }
        } catch {
            await MainActor.run {
                watchPlanErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Cards

    private func keyMomentCard(_ quote: String) -> some View {
        EntryDetailSectionCard(
            title: "Moment",
            subtitle: "A line, scene, or detail that stayed with you.",
            systemImage: "quote.opening"
        ) {
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(CloseCutColors.accent)
                    .frame(width: 3)

                Text("“\(quote)”")
                    .font(.body.italic())
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    // MARK: - Delete

    private func deleteEntry() async {
        guard isDeletingEntry == false else {
            return
        }

        guard entry.deletedAt == nil else {
            dismiss()
            return
        }

        isDeletingEntry = true
        deleteErrorMessage = nil

        do {
            _ = try entryRepository.softDeleteLocalEntry(
                entryId: entry.id,
                modelContext: modelContext
            )

            isDeletingEntry = false

            await MainActor.run {
                dismiss()
            }
        } catch {
            isDeletingEntry = false
            deleteErrorMessage = error.localizedDescription

            #if DEBUG
            print("❌ Failed to delete entry:", error.localizedDescription)
            #endif
        }
    }
}
