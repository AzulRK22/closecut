//
//  CircleDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI
import SwiftData

private enum CircleDetailSegment: String, CaseIterable, Identifiable {
    case watchTogether
    case timeline
    case quickPick
    case members
    case activity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .watchTogether:
            return "Plans"
        case .timeline:
            return "Memories"
        case .quickPick:
            return "Watch Next"
        case .members:
            return "People"
        case .activity:
            return "Activity"
        }
    }

    var systemImage: String {
        switch self {
        case .watchTogether:
            return "calendar.badge.clock"
        case .timeline:
            return "film.stack.fill"
        case .quickPick:
            return "sparkles"
        case .members:
            return "person.2.fill"
        case .activity:
            return "bolt.fill"
        }
    }
}

struct CircleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let circle: CloseCircle
    let membership: CircleMembership
    let currentUserId: String
    let currentUserDisplayName: String

    @State private var selectedSegment: CircleDetailSegment = .watchTogether
    @State private var copiedInviteCode = false
    @State private var showShareInviteSheet = false

    @State private var isRefreshing = false
    @State private var isPullingSharedEntries = false
    @State private var isPullingWatchTogetherItems = false

    @State private var refreshedCircle: CloseCircle?
    @State private var members: [CircleMember] = []
    @State private var activities: [CircleActivity] = []

    @State private var refreshErrorMessage: String?
    @State private var sharedEntriesErrorMessage: String?
    @State private var membersErrorMessage: String?
    @State private var activityErrorMessage: String?
    @State private var watchTogetherErrorMessage: String?

    @State private var showLeaveConfirmation = false
    @State private var isLeavingCircle = false

    @State private var showEditCircleSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isSavingCircle = false
    @State private var isDeletingCircle = false

    @State private var circleActionErrorMessage: String?

    @State private var selectedWatchTogetherCircleId: String?
    @State private var selectedWatchPlanIdForDetail: String?
    @State private var showCreateWatchPlanSheet = false
    @State private var isCreatingWatchPlan = false
    @State private var watchPlanErrorMessage: String?
    @State private var watchPlanInlineMessage: String?
    @State private var watchPlanBannerStyle: SyncResultBannerStyle = .neutral

    @StateObject private var circleQuickPickViewModel = HomeQuickPickViewModel()

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalWatchPlan.updatedAt, order: .reverse)
    private var localWatchPlans: [LocalWatchPlan]

    private let circleRemoteDataSource = CircleRemoteDataSource()
    private let circleService = CircleService()
    private let circleRepository = CircleRepository()
    private let entryRemoteDataSource = EntryRemoteDataSource()
    private let entryRepository = EntryRepository()
    private let watchPlanRepository = WatchPlanRepository()
    private let watchPlanSyncService = WatchPlanSyncService()

    private var displayedCircle: CloseCircle {
        refreshedCircle ?? circle
    }

    private var displayedCircleId: String {
        displayedCircle.id.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canUseCircle: Bool {
        displayedCircleId.isEmpty == false &&
        membership.isActive &&
        displayedCircle.deletedAt == nil
    }

    private var canShareInvite: Bool {
        canUseCircle &&
        displayedCircle.cleanedInviteCodeNormalized.isEmpty == false
    }

    private var singleCircleRows: [(circle: CloseCircle, membership: CircleMembership)] {
        guard canUseCircle else {
            return []
        }

        return [(displayedCircle, membership)]
    }

    private var sharedEntries: [Entry] {
        localEntries
            .map { $0.domain }
            .filter { entry in
                entry.deletedAt == nil &&
                entry.visibility == .circle &&
                entry.sharedCircleIds.contains(displayedCircleId)
            }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var circleWatchPlans: [WatchPlan] {
        localWatchPlans
            .map { $0.domain }
            .filter { plan in
                plan.circleId == displayedCircleId &&
                plan.deletedAt == nil
            }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var activeCircleWatchPlans: [WatchPlan] {
        circleWatchPlans.filter { $0.isActive }
    }

    private var displayedMemberCount: Int {
        if members.isEmpty == false {
            return members.count
        }

        return max(displayedCircle.memberIds.count, 1)
    }

    private var displayedMemberCountText: String {
        displayedMemberCount == 1 ? "1 member" : "\(displayedMemberCount) members"
    }

    private var circleDescriptionText: String {
        if let description = displayedCircle.description,
           description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return description
        }

        return "A private space for shared watch memories and Watch Together plans."
    }

    private var sortedMembers: [CircleMember] {
        members.sorted { first, second in
            if first.role != second.role {
                return first.role == .owner
            }

            if first.userId == currentUserId {
                return true
            }

            if second.userId == currentUserId {
                return false
            }

            return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
        }
    }

    private var canShowOwnerActions: Bool {
        membership.isOwner && canUseCircle
    }

    private var canShowMemberActions: Bool {
        membership.isOwner == false && canUseCircle
    }

    private var circleQuickPickStableUserId: String {
        "circle-\(displayedCircleId)"
    }

    private var circleQuickPickRefreshKey: String {
        sharedEntries
            .map { entry in
                [
                    entry.id,
                    "\(entry.updatedAt.timeIntervalSince1970)",
                    "\(entry.tmdbId ?? -1)",
                    entry.quickSentiment?.rawValue ?? "",
                    entry.visibility.rawValue,
                    entry.sharedCircleIds.joined(separator: ",")
                ]
                .joined(separator: "-")
            }
            .joined(separator: "|")
    }

    private var recentSharedEntries: [Entry] {
        Array(sharedEntries.prefix(3))
    }

    private var heroInitials: String {
        let words = displayedCircle.name
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(displayedCircle.name.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    hero

                    statusBanners

                    quickStatsStrip

                    if canUseCircle {
                        primaryCircleActions
                        premiumSegmentControl
                    }

                    selectedContent

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable {
                await refreshCircleDetail()
                generateStableCircleQuickPick()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(CloseCutColors.accent)
        .preferredColorScheme(.dark)
        .task {
            selectedWatchTogetherCircleId = displayedCircleId
            await refreshCircleDetail()
            generateStableCircleQuickPick()
        }
        .onAppear {
            selectedWatchTogetherCircleId = displayedCircleId
            generateStableCircleQuickPick()
        }
        .onChange(of: circleQuickPickRefreshKey) { _, _ in
            generateStableCircleQuickPick()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                actionsMenu
            }
        }
        .sheet(isPresented: $showCreateWatchPlanSheet) {
            CreateWatchPlanSheet(
                circleRows: singleCircleRows,
                selectedCircleId: displayedCircleId,
                initialMedia: nil,
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
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditCircleSheet) {
            CircleEditSheet(
                circle: displayedCircle,
                isSaving: isSavingCircle,
                onCancel: {
                    showEditCircleSheet = false
                },
                onSave: { name, description in
                    Task {
                        await updateCircleDetails(
                            name: name,
                            description: description
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showShareInviteSheet) {
            CircleInviteShareSheet(
                circle: displayedCircle,
                ownerDisplayName: currentUserDisplayName,
                onDone: {
                    showShareInviteSheet = false
                }
            )
        }
        .confirmationDialog(
            "Leave Circle?",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave Circle", role: .destructive) {
                Task {
                    await leaveCircle()
                }
            }
            .disabled(isLeavingCircle)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You’ll stop seeing this Circle in your list. Entries shared with this Circle will no longer appear in your Circle space.")
        }
        .confirmationDialog(
            "Delete Circle?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Circle", role: .destructive) {
                Task {
                    await deleteCircle()
                }
            }
            .disabled(isDeletingCircle)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will archive the Circle and remove it from members’ active Circle lists. Personal entries remain private and are not deleted.")
        }
        .alert("Circle action failed", isPresented: Binding(
            get: { circleActionErrorMessage != nil },
            set: { if !$0 { circleActionErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(circleActionErrorMessage ?? "Unknown error.")
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
                currentUserId: currentUserId,
                currentUserDisplayName: currentUserDisplayName
            )
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var actionsMenu: some View {
        if canUseCircle {
            Menu {
                Button {
                    openCreateWatchPlan()
                } label: {
                    Label("Create Watch Plan", systemImage: "calendar.badge.plus")
                }
                .disabled(isCreatingWatchPlan)

                Divider()

                if canShareInvite {
                    Button {
                        showShareInviteSheet = true
                    } label: {
                        Label("Share Invite", systemImage: "square.and.arrow.up")
                    }

                    Divider()
                }

                if canShowOwnerActions {
                    Button {
                        showEditCircleSheet = true
                    } label: {
                        Label("Edit Circle", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(
                            isDeletingCircle ? "Deleting..." : "Delete Circle",
                            systemImage: "trash"
                        )
                    }
                }

                if canShowMemberActions {
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        Label(
                            isLeavingCircle ? "Leaving..." : "Leave Circle",
                            systemImage: "rectangle.portrait.and.arrow.right"
                        )
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CloseCutColors.accent)
            }
            .accessibilityLabel("Circle actions")
            .disabled(isLeavingCircle || isSavingCircle || isDeletingCircle)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    CloseCutColors.accent.opacity(0.28),
                                    CloseCutColors.input
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 62, height: 62)

                    Text(heroInitials)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        rolePill

                        Text(displayedMemberCountText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())

                        if canUseCircle == false {
                            Text("Inactive")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(CloseCutColors.failed)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(CloseCutColors.failedBackground)
                                .clipShape(Capsule())
                        }
                    }

                    Text(displayedCircle.name)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(circleDescriptionText)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if activeCircleWatchPlans.isEmpty == false {
                activePlansPreview
            } else if recentSharedEntries.isEmpty == false {
                recentSharedPosterStrip
            }

            inviteCodeBlock
        }
        .padding(18)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private var rolePill: some View {
        Text(membership.role.displayName)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(membership.isOwner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(CloseCutColors.input)
            .clipShape(Capsule())
    }

    private var activePlansPreview: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSegment = .watchTogether
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 34, height: 34)
                    .background(CloseCutColors.card)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Watch Together")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(activeCircleWatchPlans.count == 1 ? "1 active plan in this Circle" : "\(activeCircleWatchPlans.count) active plans in this Circle")
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
            .padding(12)
            .background(CloseCutColors.input.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var recentSharedPosterStrip: some View {
        HStack(spacing: 10) {
            HStack(spacing: -10) {
                ForEach(recentSharedEntries) { entry in
                    CircleSharedPosterView(
                        entry: entry,
                        width: 42,
                        height: 62,
                        cornerRadius: 10
                    )
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Recently shared")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(sharedEntries.count == 1 ? "1 memory in this Circle" : "\(sharedEntries.count) memories in this Circle")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var inviteCodeBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "ticket.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 30, height: 30)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Invite code")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(displayedCircle.inviteCode)
                        .font(.subheadline.monospaced().weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer()

                Button {
                    copyInviteCode()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copiedInviteCode ? "checkmark" : "doc.on.doc")
                            .font(.caption.weight(.semibold))

                        Text(copiedInviteCode ? "Copied" : "Copy")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(CloseCutColors.accentLight)
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(CloseCutColors.card)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(displayedCircle.inviteCode.trimmed.isEmpty)
                .accessibilityLabel("Copy invite code")
            }

            if canShareInvite {
                Button {
                    showShareInviteSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption.weight(.semibold))

                        Text("Share invite")
                            .font(.caption.weight(.semibold))

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(CloseCutColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Stats

    private var quickStatsStrip: some View {
        HStack(spacing: 10) {
            statPill(
                value: "\(activeCircleWatchPlans.count)",
                label: activeCircleWatchPlans.count == 1 ? "plan" : "plans",
                icon: "calendar.badge.clock"
            )

            statPill(
                value: "\(sharedEntries.count)",
                label: sharedEntries.count == 1 ? "memory" : "memories",
                icon: "film.stack.fill"
            )

            statPill(
                value: "\(displayedMemberCount)",
                label: displayedMemberCount == 1 ? "person" : "people",
                icon: "person.2.fill"
            )
        }
    }

    private func statPill(
        value: String,
        label: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
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
        .padding(12)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var primaryCircleActions: some View {
        HStack(spacing: 10) {
            Button {
                openCreateWatchPlan()
            } label: {
                HStack(spacing: 8) {
                    if isCreatingWatchPlan {
                        ProgressView()
                            .scaleEffect(0.85)
                            .tint(.white)
                    } else {
                        Image(systemName: "calendar.badge.plus")
                    }

                    Text(isCreatingWatchPlan ? "Creating…" : "Create Plan")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(CloseCutColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isCreatingWatchPlan)

            Button {
                showShareInviteSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                    Text("Invite")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(CloseCutColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(CloseCutColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(CloseCutColors.separator, lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
            .disabled(canShareInvite == false)
        }
    }

    // MARK: - Segment Control

    private var premiumSegmentControl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CircleDetailSegment.allCases) { segment in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedSegment = segment
                        }
                    } label: {
                        segmentChip(segment)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(segment.title)
                    .accessibilityAddTraits(selectedSegment == segment ? .isSelected : [])
                }
            }
        }
    }

    private func segmentChip(
        _ segment: CircleDetailSegment
    ) -> some View {
        let isSelected = selectedSegment == segment

        return HStack(spacing: 7) {
            Image(systemName: segment.systemImage)
                .font(.caption.weight(.semibold))

            Text(segment.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? .white : CloseCutColors.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(isSelected ? CloseCutColors.accent : CloseCutColors.card)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(isSelected ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    // MARK: - Status Banners

    @ViewBuilder
    private var statusBanners: some View {
        if isRefreshing {
            SyncResultBanner(
                message: "Refreshing Circle…",
                style: .neutral
            )
        }

        if isPullingSharedEntries {
            SyncResultBanner(
                message: "Loading shared entries…",
                style: .neutral
            )
        }

        if isPullingWatchTogetherItems {
            SyncResultBanner(
                message: "Refreshing Watch Together plans…",
                style: .neutral
            )
        }

        if let watchPlanInlineMessage {
            SyncResultBanner(
                message: watchPlanInlineMessage,
                style: watchPlanBannerStyle
            )
        }

        if let refreshErrorMessage {
            SyncResultBanner(
                message: refreshErrorMessage,
                style: .warning
            )
        }

        if let sharedEntriesErrorMessage {
            SyncResultBanner(
                message: sharedEntriesErrorMessage,
                style: .warning
            )
        }

        if let watchTogetherErrorMessage {
            SyncResultBanner(
                message: watchTogetherErrorMessage,
                style: .warning
            )
        }

        if let membersErrorMessage {
            SyncResultBanner(
                message: membersErrorMessage,
                style: .warning
            )
        }

        if let activityErrorMessage {
            SyncResultBanner(
                message: activityErrorMessage,
                style: .warning
            )
        }
    }

    // MARK: - Selected Content

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedSegment {
        case .watchTogether:
            watchTogetherSection

        case .timeline:
            timelineSection

        case .quickPick:
            CircleQuickPickView(
                sharedEntries: sharedEntries,
                memberCount: displayedMemberCount,
                state: circleQuickPickViewModel.state,
                onShowAnother: {
                    Task {
                        _ = await circleQuickPickViewModel.showAnotherAndReturnState(
                            history: sharedEntries
                        )
                    }
                },
                onOpenTimeline: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSegment = .timeline
                    }
                }
            )

        case .members:
            membersSection

        case .activity:
            activitySection
        }
    }

    private var watchTogetherSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                title: "Watch Together",
                subtitle: "Plans created specifically for this Circle.",
                trailing: activeCircleWatchPlans.isEmpty ? nil : "\(activeCircleWatchPlans.count) active"
            )

            WatchTogetherHubSection(
                circleRows: singleCircleRows,
                plans: circleWatchPlans,
                currentUserId: currentUserId,
                selectedCircleId: $selectedWatchTogetherCircleId,
                onCreatePlan: {
                    openCreateWatchPlan()
                },
                onCreateCircle: {
                    watchPlanBannerStyle = .warning
                    watchPlanInlineMessage = "This Circle is not available for new plans right now."
                },
                onOpenPlan: { plan in
                    selectedWatchPlanIdForDetail = plan.id
                }
            )

            if circleWatchPlans.isEmpty {
                circlePlanEducationCard
            }
        }
    }

    private var circlePlanEducationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles.tv")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 34, height: 34)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("Start with one plan.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Pick a title, invite Circle members, and let everyone respond. After watching, you can add it back to Personal.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                title: "Shared memories",
                subtitle: sharedEntries.count == 1
                    ? "1 title shared with this Circle"
                    : "\(sharedEntries.count) titles shared with this Circle",
                trailing: sharedEntries.isEmpty ? nil : "Newest first"
            )

            if isPullingSharedEntries && sharedEntries.isEmpty {
                loadingSharedEntriesCard
            } else if sharedEntries.isEmpty {
                EmptyStateView(
                    title: "No shared memories yet",
                    message: "Share a title from your Personal Timeline to make this Circle feel alive. Only selected entries appear here.",
                    systemImage: "film.stack",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sharedEntries) { entry in
                        NavigationLink {
                            CircleEntryReadOnlyDetailView(
                                entry: entry,
                                currentUserId: currentUserId,
                                currentUserDisplayName: currentUserDisplayName,
                                circleId: displayedCircleId
                            )
                        } label: {
                            CircleTimelineEntryCard(
                                entry: entry,
                                currentUserId: currentUserId
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var loadingSharedEntriesCard: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text("Loading entries shared with this Circle…")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            Spacer()
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                title: "People",
                subtitle: "Only these members can see entries and plans shared with this Circle.",
                trailing: displayedMemberCountText
            )

            DetailSectionCard(title: displayedMemberCountText) {
                VStack(spacing: 12) {
                    if members.isEmpty && isRefreshing {
                        HStack(spacing: 10) {
                            ProgressView()

                            Text("Loading members…")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)

                            Spacer()
                        }
                    } else if members.isEmpty {
                        Text("Circle members will appear here once this space is refreshed.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(sortedMembers) { member in
                            CircleMemberRowView(
                                member: member,
                                currentUserId: currentUserId
                            )

                            if member.id != sortedMembers.last?.id {
                                Divider()
                                    .overlay(CloseCutColors.separator)
                            }
                        }
                    }
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                title: "Recent activity",
                subtitle: "A lightweight history of changes inside this Circle.",
                trailing: activities.isEmpty ? nil : "\(activities.count)"
            )

            DetailSectionCard(title: "Activity") {
                VStack(spacing: 12) {
                    if activities.isEmpty && isRefreshing {
                        HStack(spacing: 10) {
                            ProgressView()

                            Text("Loading activity…")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)

                            Spacer()
                        }
                    } else if activities.isEmpty {
                        Text("Circle updates, joins, edits, and sharing activity will appear here.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(activities) { activity in
                            CircleActivityRowView(activity: activity)

                            if activity.id != activities.last?.id {
                                Divider()
                                    .overlay(CloseCutColors.separator)
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionTitle(
        title: String,
        subtitle: String,
        trailing: String?
    ) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - QuickPick

    private func generateStableCircleQuickPick() {
        circleQuickPickViewModel.generateStablePick(
            userId: circleQuickPickStableUserId,
            history: sharedEntries
        )
    }

    // MARK: - Watch Together Actions

    private func openCreateWatchPlan() {
        guard canUseCircle else {
            watchPlanBannerStyle = .warning
            watchPlanInlineMessage = "This Circle is not available for new plans right now."
            return
        }

        selectedWatchTogetherCircleId = displayedCircleId
        watchPlanErrorMessage = nil
        showCreateWatchPlanSheet = true
    }

    private func createWatchPlan(
        _ draft: WatchPlanCreationDraft
    ) async {
        guard isCreatingWatchPlan == false else {
            return
        }

        guard canUseCircle else {
            watchPlanErrorMessage = "This Circle is not available for new plans right now."
            return
        }

        let invitedMemberIds = draft.invitedMemberIds.filter { memberId in
            memberId.trimmed.isEmpty == false &&
            memberId.trimmed != currentUserId.trimmed
        }

        guard invitedMemberIds.isEmpty == false else {
            watchPlanErrorMessage = "Select at least one Circle member to invite."
            return
        }

        isCreatingWatchPlan = true
        watchPlanErrorMessage = nil
        watchPlanInlineMessage = nil

        defer {
            isCreatingWatchPlan = false
        }

        do {
            let createdPlan = try watchPlanRepository.createLocalPlan(
                ownerId: currentUserId,
                ownerDisplayName: currentUserDisplayName,
                circleId: displayedCircle.id,
                circleName: displayedCircle.displayName,
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
                source: .circle,
                modelContext: modelContext
            )

            let syncSummary = await watchPlanSyncService.syncPendingWatchTogetherItems(
                userId: currentUserId,
                modelContext: modelContext
            )

            await MainActor.run {
                showCreateWatchPlanSheet = false
                selectedSegment = .watchTogether
                selectedWatchTogetherCircleId = displayedCircleId

                withAnimation(.easeInOut(duration: 0.18)) {
                    if syncSummary.hasFailures {
                        watchPlanBannerStyle = .warning
                        watchPlanInlineMessage = "Plan created locally, but it could not sync yet. It will retry later."
                    } else {
                        watchPlanBannerStyle = .success
                        watchPlanInlineMessage = "\(createdPlan.media.displayTitle) was added to this Circle."
                    }
                }
            }
        } catch {
            await MainActor.run {
                watchPlanErrorMessage = error.localizedDescription
            }
        }
    }

    private func pullWatchTogetherItems(circleId: String) async {
        guard isPullingWatchTogetherItems == false else {
            return
        }

        guard circleId.trimmed.isEmpty == false else {
            return
        }

        isPullingWatchTogetherItems = true
        watchTogetherErrorMessage = nil

        defer {
            isPullingWatchTogetherItems = false
        }

        let summary = await watchPlanSyncService.pullRemoteWatchTogetherItems(
            circleIds: [circleId],
            modelContext: modelContext
        )

        if summary.hasFailures {
            watchTogetherErrorMessage = "Couldn’t refresh Watch Together plans."
        }
    }

    // MARK: - Data Loading

    private func refreshCircleDetail() async {
        guard isRefreshing == false else {
            return
        }

        let circleId = displayedCircleId

        guard circleId.isEmpty == false else {
            refreshErrorMessage = "Couldn’t refresh Circle details."
            return
        }

        isRefreshing = true
        refreshErrorMessage = nil
        sharedEntriesErrorMessage = nil
        membersErrorMessage = nil
        activityErrorMessage = nil
        watchTogetherErrorMessage = nil

        defer { isRefreshing = false }

        do {
            let remoteCircle = try await circleRemoteDataSource.fetchCircle(
                circleId: circleId
            )

            if remoteCircle.deletedAt != nil {
                try? circleRepository.removeLocalCircleCompletely(
                    circleId: circleId,
                    userId: currentUserId,
                    modelContext: modelContext
                )

                await MainActor.run {
                    dismiss()
                }

                return
            }

            let localCircle = try circleRepository.upsertRemoteCircle(
                remoteCircle,
                modelContext: modelContext
            )

            refreshedCircle = localCircle
        } catch {
            refreshErrorMessage = "Couldn’t refresh Circle details."

            #if DEBUG
            print("⚠️ Failed to refresh Circle:", error.localizedDescription)
            #endif
        }

        await pullSharedEntries(circleId: circleId)
        await pullWatchTogetherItems(circleId: circleId)
        await refreshMembers(circleId: circleId)
        await refreshActivities(circleId: circleId)
    }

    private func pullSharedEntries(circleId: String) async {
        guard isPullingSharedEntries == false else {
            return
        }

        guard circleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return
        }

        isPullingSharedEntries = true
        sharedEntriesErrorMessage = nil

        defer { isPullingSharedEntries = false }

        do {
            let remoteEntries = try await entryRemoteDataSource.fetchSharedEntries(
                circleId: circleId
            )

            for remoteEntry in remoteEntries {
                _ = try entryRepository.upsertRemoteEntry(
                    remoteEntry,
                    modelContext: modelContext
                )
            }
        } catch {
            sharedEntriesErrorMessage = "Couldn’t load shared entries."

            #if DEBUG
            print("⚠️ Failed to pull shared Circle entries:", error.localizedDescription)
            #endif
        }
    }

    private func refreshMembers(circleId: String) async {
        do {
            members = try await circleRemoteDataSource.fetchMembers(
                circleId: circleId
            )
            membersErrorMessage = nil
        } catch {
            membersErrorMessage = "Couldn’t refresh Circle members."

            #if DEBUG
            print("⚠️ Failed to refresh Circle members:", error.localizedDescription)
            #endif
        }
    }

    private func refreshActivities(circleId: String) async {
        do {
            activities = try await circleRemoteDataSource.fetchActivities(
                circleId: circleId
            )
            activityErrorMessage = nil
        } catch {
            activityErrorMessage = "Couldn’t refresh Circle activity."

            #if DEBUG
            print("⚠️ Failed to refresh Circle activity:", error.localizedDescription)
            #endif
        }
    }

    // MARK: - Circle Actions

    private func copyInviteCode() {
        let inviteCode = displayedCircle.inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard inviteCode.isEmpty == false else {
            return
        }

        UIPasteboard.general.string = inviteCode

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedInviteCode = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    copiedInviteCode = false
                }
            }
        }
    }

    private func leaveCircle() async {
        guard isLeavingCircle == false else {
            return
        }

        isLeavingCircle = true
        circleActionErrorMessage = nil

        do {
            try await circleService.leaveCircle(
                circle: displayedCircle,
                membership: membership,
                actorDisplayName: currentUserDisplayName,
                modelContext: modelContext
            )

            isLeavingCircle = false

            try? await Task.sleep(nanoseconds: 250_000_000)

            await MainActor.run {
                dismiss()
            }
        } catch {
            isLeavingCircle = false
            circleActionErrorMessage = error.localizedDescription

            #if DEBUG
            print("❌ Failed to leave Circle:", error.localizedDescription)
            #endif
        }
    }

    private func updateCircleDetails(
        name: String,
        description: String?
    ) async {
        guard isSavingCircle == false else {
            return
        }

        isSavingCircle = true
        circleActionErrorMessage = nil

        do {
            let updatedCircle = try await circleService.updateCircleDetails(
                circle: displayedCircle,
                membership: membership,
                name: name,
                description: description,
                modelContext: modelContext
            )

            refreshedCircle = updatedCircle
            showEditCircleSheet = false
            isSavingCircle = false

            await refreshCircleDetail()
        } catch {
            isSavingCircle = false
            circleActionErrorMessage = error.localizedDescription

            #if DEBUG
            print("❌ Failed to update Circle:", error.localizedDescription)
            #endif
        }
    }

    private func deleteCircle() async {
        guard isDeletingCircle == false else {
            return
        }

        isDeletingCircle = true
        circleActionErrorMessage = nil

        do {
            try await circleService.deleteCircle(
                circle: displayedCircle,
                membership: membership,
                modelContext: modelContext
            )

            isDeletingCircle = false

            try? await Task.sleep(nanoseconds: 250_000_000)

            await MainActor.run {
                dismiss()
            }
        } catch {
            isDeletingCircle = false
            circleActionErrorMessage = error.localizedDescription

            #if DEBUG
            print("❌ Failed to delete Circle:", error.localizedDescription)
            #endif
        }
    }
}
