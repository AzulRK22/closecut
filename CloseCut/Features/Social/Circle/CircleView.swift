//
//  CircleView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct CircleView: View {
    @Environment(\.modelContext) private var modelContext

    let user: AuthUser
    let profile: UserProfile

    @Query(sort: \LocalCircle.updatedAt, order: .reverse)
    private var localCircles: [LocalCircle]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalWatchPlan.updatedAt, order: .reverse)
    private var localWatchPlans: [LocalWatchPlan]

    @State private var showCircleActions = false
    @State private var showCreateCircleSheet = false
    @State private var showJoinCircleSheet = false

    @State private var inviteCodeToJoin = ""
    @State private var circlePreview: CirclePreview?

    @State private var isCreatingCircle = false
    @State private var isPreviewingCircle = false
    @State private var isJoiningCircle = false
    @State private var isPullingRemoteMemberships = false
    @State private var isRefreshingCircleDetails = false
    @State private var isPullingWatchTogetherItems = false
    @State private var hasLoadedInitialCircles = false

    @State private var circleErrorMessage: String?
    @State private var circleInlineMessage: String?

    @State private var selectedWatchTogetherCircleId: String?
    @State private var selectedWatchPlanIdForDetail: String?
    @State private var showCreateWatchPlanSheet = false
    @State private var isCreatingWatchPlan = false
    @State private var watchPlanErrorMessage: String?

    private let circleService = CircleService()
    private let circleRepository = CircleRepository()
    private let circleRemoteDataSource = CircleRemoteDataSource()
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

    private var ownedCircleCount: Int {
        circleRows.filter { $0.membership.isOwner }.count
    }

    private var joinedCircleCount: Int {
        circleRows.filter { $0.membership.isOwner == false }.count
    }

    private var activeSharedEntries: [Entry] {
        localEntries
            .map { $0.domain }
            .filter { entry in
                entry.deletedAt == nil &&
                entry.visibility == .circle &&
                entry.sharedCircleIds.isEmpty == false
            }
    }

    private var totalSharedMemoryCount: Int {
        activeSharedEntries.count
    }

    private var watchTogetherPlans: [WatchPlan] {
        let activeCircleIds = Set(circleRows.map { $0.circle.id })

        return localWatchPlans
            .map { $0.domain }
            .filter { plan in
                activeCircleIds.contains(plan.circleId) &&
                plan.deletedAt == nil
            }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var selectedWatchPlanForDetail: WatchPlan? {
        guard let selectedWatchPlanIdForDetail else {
            return nil
        }

        return watchTogetherPlans.first { plan in
            plan.id == selectedWatchPlanIdForDetail
        }
    }

    private func sharedMemoryCount(
        for circleId: String
    ) -> Int {
        activeSharedEntries.filter {
            $0.sharedCircleIds.contains(circleId)
        }.count
    }

    private var isLoadingCircles: Bool {
        isPullingRemoteMemberships ||
        isRefreshingCircleDetails ||
        isPullingWatchTogetherItems
    }

    private var loadingMessage: String {
        if isPullingRemoteMemberships {
            return "Finding your Circles…"
        }

        if isPullingWatchTogetherItems {
            return "Refreshing Watch Together…"
        }

        return "Refreshing your Circles…"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        CircleHubHeroView(
                            circleCount: circleRows.count,
                            sharedMemoryCount: totalSharedMemoryCount,
                            onCreate: openCreateCircle,
                            onJoin: openJoinCircle
                        )

                        statusSection

                        WatchTogetherHubSection(
                            circleRows: circleRows,
                            plans: watchTogetherPlans,
                            currentUserId: user.id,
                            selectedCircleId: $selectedWatchTogetherCircleId,
                            onCreatePlan: openCreateWatchPlan,
                            onCreateCircle: openCreateCircle,
                            onOpenPlan: openWatchPlan
                        )

                        if circleRows.isEmpty {
                            CircleEmptyStateView(
                                onCreateCircle: openCreateCircle,
                                onJoinCircle: openJoinCircle
                            )
                        } else {
                            CircleHubSummaryCard(
                                circleCount: circleRows.count,
                                ownedCount: ownedCircleCount,
                                joinedCount: joinedCircleCount,
                                sharedMemoryCount: totalSharedMemoryCount
                            )

                            circlesListSection

                            CircleSocialPulseCard(
                                sharedMemoryCount: totalSharedMemoryCount,
                                hasCircles: true
                            )
                        }

                        CirclePrivacyCard()

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await loadCircles(force: true)
                }
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCircleActions = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Add")
                }
            }
            .sheet(isPresented: $showCircleActions) {
                SocialActionSheet(
                    hasCircles: circleRows.isEmpty == false,
                    onCreateWatchPlan: {
                        showCircleActions = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            openCreateWatchPlan()
                        }
                    },
                    onCreateCircle: {
                        showCircleActions = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            openCreateCircle()
                        }
                    },
                    onJoinCircle: {
                        showCircleActions = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            openJoinCircle()
                        }
                    }
                )
            }
            .sheet(isPresented: $showCreateCircleSheet) {
                CreateCircleSheet(
                    isCreating: isCreatingCircle,
                    onCreate: { name, description in
                        Task {
                            await createCircle(
                                name: name,
                                description: description
                            )
                        }
                    }
                )
            }
            .sheet(isPresented: $showJoinCircleSheet) {
                JoinCircleSheet(
                    inviteCode: $inviteCodeToJoin,
                    preview: circlePreview,
                    isPreviewing: isPreviewingCircle,
                    isJoining: isJoiningCircle,
                    onPreview: {
                        Task {
                            await previewCircle()
                        }
                    },
                    onJoin: {
                        Task {
                            await joinCircle()
                        }
                    },
                    onCancel: {
                        showJoinCircleSheet = false
                    },
                    onInviteCodeChanged: { normalizedCode in
                        if circlePreview?.circle.inviteCodeNormalized != normalizedCode {
                            circlePreview = nil
                        }
                    }
                )
            }
            .sheet(isPresented: $showCreateWatchPlanSheet) {
                CreateWatchPlanSheet(
                    circleRows: circleRows,
                    selectedCircleId: selectedWatchTogetherCircleId,
                    isCreating: isCreatingWatchPlan,
                    onCancel: {
                        showCreateWatchPlanSheet = false
                    },
                    onCreate: { draft in
                        Task {
                            await createWatchPlan(draft)
                        }
                    }
                )
            }
            .alert("Circle action failed", isPresented: Binding(
                get: { circleErrorMessage != nil },
                set: { if !$0 { circleErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(circleErrorMessage ?? "Unknown error.")
            }
            .alert("Watch Together failed", isPresented: Binding(
                get: { watchPlanErrorMessage != nil },
                set: { if !$0 { watchPlanErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(watchPlanErrorMessage ?? "Unknown error.")
            }
            .navigationDestination(item: $selectedWatchPlanIdForDetail) { planId in
                WatchPlanDetailLoaderView(
                    planId: planId,
                    currentUserId: user.id,
                    currentUserDisplayName: profile.displayName
                )
            }
            .task {
                await loadCirclesIfNeeded()
            }
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
        if isLoadingCircles {
            SyncResultBanner(
                message: loadingMessage,
                style: .neutral
            )
        }

        if let circleInlineMessage {
            SyncResultBanner(
                message: circleInlineMessage,
                style: .warning
            )
        }
    }

    // MARK: - Circle List

    private var circlesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Circles")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(circleRows.count == 1 ? "1 private space" : "\(circleRows.count) private spaces")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }

                Spacer()

                Text("Tap to open")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
            .padding(.horizontal, 2)

            LazyVStack(spacing: 12) {
                ForEach(circleRows, id: \.membership.id) { row in
                    NavigationLink {
                        CircleDetailView(
                            circle: row.circle,
                            membership: row.membership,
                            currentUserId: user.id,
                            currentUserDisplayName: profile.displayName
                        )
                    } label: {
                        CircleCardView(
                            circle: row.circle,
                            membership: row.membership,
                            sharedMemoryCount: sharedMemoryCount(
                                for: row.circle.id
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sheet Openers

    private func openCreateCircle() {
        circleErrorMessage = nil
        circleInlineMessage = nil
        showCreateCircleSheet = true
    }

    private func openJoinCircle() {
        inviteCodeToJoin = ""
        circlePreview = nil
        circleErrorMessage = nil
        circleInlineMessage = nil
        showJoinCircleSheet = true
    }

    private func openCreateWatchPlan() {
        guard circleRows.isEmpty == false else {
            openCreateCircle()
            return
        }

        watchPlanErrorMessage = nil
        showCreateWatchPlanSheet = true
    }

    private func openWatchPlan(
        _ plan: WatchPlan
    ) {
        selectedWatchPlanIdForDetail = plan.id
    }

    // MARK: - Watch Together Actions

    private func createWatchPlan(
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

        let media = draft.media
        let cleanedMediaTitle = media.displayTitle.trimmed

        guard cleanedMediaTitle.isEmpty == false else {
            watchPlanErrorMessage = "Choose a movie or series before creating the plan."
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
                media: media,
                proposedStartAt: nil,
                proposedEndAt: nil,
                proposedDateText: draft.proposedDateText,
                locationType: draft.locationType,
                locationName: draft.locationName,
                locationAddress: draft.locationAddress,
                streamingService: draft.streamingService,
                invitedMemberIds: invitedMemberIds,
                source: .circle,
                modelContext: modelContext
            )

            #if DEBUG
            print("✅ Created local WatchPlan:", createdPlan.id)
            print("🎬 Media:", createdPlan.media.displayTitle)
            print("🎞️ TMDB:", createdPlan.media.tmdbId ?? -1)
            print("🖼️ Poster:", createdPlan.media.posterPath ?? "nil")
            print("📍 Circle:", createdPlan.circleId)
            print("👥 Invited:", createdPlan.invitedMemberIds)
            print("☁️ Sync status before push:", createdPlan.syncStatus.displayName)
            #endif

            let syncSummary = await watchPlanSyncService.syncPendingWatchTogetherItems(
                userId: user.id,
                modelContext: modelContext
            )

            #if DEBUG
            print("☁️ Watch Together push summary:")
            print("Synced:", syncSummary.syncedCount)
            print("Failed:", syncSummary.failedCount)
            #endif

            if syncSummary.hasFailures {
                watchPlanErrorMessage = "Plan created locally, but it could not sync yet. It will retry later."
            }

            selectedWatchTogetherCircleId = selectedRow.circle.id
            showCreateWatchPlanSheet = false

            try? await Task.sleep(nanoseconds: 250_000_000)

            selectedWatchPlanIdForDetail = createdPlan.id
        } catch {
            watchPlanErrorMessage = error.localizedDescription

            #if DEBUG
            print("❌ Failed to create Watch Together plan:", error.localizedDescription)
            #endif
        }
    }

    // MARK: - Circle Actions

    private func previewCircle() async {
        guard isPreviewingCircle == false else {
            return
        }

        let cleanedInviteCode = inviteCodeToJoin.normalizedInviteCode

        guard cleanedInviteCode.isEmpty == false else {
            circleErrorMessage = "Enter a valid invite code."
            return
        }

        isPreviewingCircle = true
        circleErrorMessage = nil
        circleInlineMessage = nil
        circlePreview = nil

        defer {
            isPreviewingCircle = false
        }

        do {
            let preview = try await circleService.previewCircle(
                inviteCode: cleanedInviteCode,
                currentUserId: user.id
            )

            circlePreview = preview
        } catch {
            circleErrorMessage = error.localizedDescription
        }
    }

    private func createCircle(
        name: String,
        description: String
    ) async {
        guard isCreatingCircle == false else {
            return
        }

        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedName.isEmpty == false else {
            circleErrorMessage = "Circle name is required."
            return
        }

        isCreatingCircle = true
        circleErrorMessage = nil
        circleInlineMessage = nil

        defer {
            isCreatingCircle = false
        }

        do {
            _ = try await circleService.createCircle(
                user: user,
                profile: profile,
                circleName: cleanedName,
                circleDescription: cleanedDescription,
                modelContext: modelContext
            )

            showCreateCircleSheet = false

            await loadCircles(force: true)
        } catch {
            circleErrorMessage = error.localizedDescription
        }
    }

    private func joinCircle() async {
        guard isJoiningCircle == false else {
            return
        }

        let resolvedInviteCode = circlePreview?.circle.inviteCodeNormalized ?? inviteCodeToJoin
        let cleanedInviteCode = resolvedInviteCode.normalizedInviteCode

        guard cleanedInviteCode.isEmpty == false else {
            circleErrorMessage = "Enter a valid invite code."
            return
        }

        isJoiningCircle = true
        circleErrorMessage = nil
        circleInlineMessage = nil

        defer {
            isJoiningCircle = false
        }

        do {
            _ = try await circleService.joinCircle(
                user: user,
                profile: profile,
                inviteCode: cleanedInviteCode,
                modelContext: modelContext
            )

            showJoinCircleSheet = false
            inviteCodeToJoin = ""
            circlePreview = nil

            await loadCircles(force: true)
        } catch {
            circleErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Loading

    private func loadCirclesIfNeeded() async {
        guard hasLoadedInitialCircles == false else {
            return
        }

        hasLoadedInitialCircles = true
        await loadCircles(force: false)
    }

    private func loadCircles(force: Bool) async {
        circleInlineMessage = nil

        if force || memberships.isEmpty {
            await pullRemoteCirclesForCurrentUser()
        }

        await refreshLocalCirclesFromRemote()

        await pullWatchTogetherItemsForCurrentCircles()

        if force && circleRows.isEmpty {
            circleInlineMessage = nil
        }
    }

    private func pullWatchTogetherItemsForCurrentCircles() async {
        guard isPullingWatchTogetherItems == false else {
            return
        }

        let circleIds = circleRows.map { $0.circle.id }

        guard circleIds.isEmpty == false else {
            return
        }

        isPullingWatchTogetherItems = true

        defer {
            isPullingWatchTogetherItems = false
        }

        let summary = await watchPlanSyncService.pullRemoteWatchTogetherItems(
            circleIds: circleIds,
            modelContext: modelContext
        )

        #if DEBUG
        print("☁️ Watch Together pull summary:")
        print("Pulled:", summary.pulledCount)
        print("Failed:", summary.failedCount)
        #endif

        if summary.hasFailures {
            circleInlineMessage = "Couldn’t refresh some Watch Together plans."
        }
    }

    private func pullRemoteCirclesForCurrentUser() async {
        guard isPullingRemoteMemberships == false else {
            return
        }

        isPullingRemoteMemberships = true

        defer {
            isPullingRemoteMemberships = false
        }

        do {
            let remoteMemberships = try await circleRemoteDataSource.fetchMembershipsForUser(
                userId: user.id
            )

            for item in remoteMemberships {
                let circle = try circleRepository.upsertRemoteCircle(
                    item.circle,
                    modelContext: modelContext
                )

                _ = try circleRepository.upsertLocalMembership(
                    circle: circle,
                    member: item.member,
                    modelContext: modelContext
                )
            }
        } catch {
            circleInlineMessage = "Couldn’t refresh your Circle memberships."

            #if DEBUG
            print("⚠️ Failed to pull remote Circles:", error.localizedDescription)
            #endif
        }
    }

    private func refreshLocalCirclesFromRemote() async {
        guard isRefreshingCircleDetails == false else {
            return
        }

        guard memberships.isEmpty == false else {
            return
        }

        isRefreshingCircleDetails = true

        defer {
            isRefreshingCircleDetails = false
        }

        for membership in memberships {
            do {
                let remoteCircle = try await circleRemoteDataSource.fetchCircle(
                    circleId: membership.circleId
                )

                if remoteCircle.deletedAt != nil {
                    try circleRepository.removeLocalCircleCompletely(
                        circleId: membership.circleId,
                        userId: user.id,
                        modelContext: modelContext
                    )
                    continue
                }

                _ = try circleRepository.upsertRemoteCircle(
                    remoteCircle,
                    modelContext: modelContext
                )
            } catch {
                #if DEBUG
                print("⚠️ Failed to refresh Circle \(membership.circleId):", error.localizedDescription)
                #endif

                if shouldRemoveLocalCircleAfterRefreshFailure(error) {
                    do {
                        try circleRepository.removeLocalCircleCompletely(
                            circleId: membership.circleId,
                            userId: user.id,
                            modelContext: modelContext
                        )
                    } catch {
                        #if DEBUG
                        print("⚠️ Failed to remove stale local Circle:", error.localizedDescription)
                        #endif
                    }
                }
            }
        }
    }

    private func shouldRemoveLocalCircleAfterRefreshFailure(_ error: Error) -> Bool {
        if let remoteError = error as? CircleRemoteDataSourceError {
            switch remoteError {
            case .circleDocumentMissing, .circleDocumentIncomplete:
                return true
            }
        }

        let message = error.localizedDescription.lowercased()

        return message.contains("missing")
            || message.contains("couldn’t be read")
            || message.contains("couldn't be read")
            || message.contains("incomplete")
    }
}

#Preview {
    CircleView(
        user: AuthUser(
            id: "preview-user-1234",
            email: "preview@closecut.dev",
            displayName: "Preview",
            photoURL: nil
        ),
        profile: UserProfile(
            id: "preview-user",
            displayName: "Preview",
            email: "preview@closecut.dev",
            photoURL: nil,
            circleIds: [],
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
    .modelContainer(for: [
        LocalEntry.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self,
        LocalBattleResult.self,
        LocalWatchlistItem.self,
        LocalWatchPlan.self,
        LocalWatchPlanResponse.self
    ], inMemory: true)
}
