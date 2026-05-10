//
//  CircleDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI
import SwiftData

private enum CircleDetailSegment: String, CaseIterable, Identifiable {
    case timeline
    case quickPick
    case members
    case activity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timeline:
            return "Timeline"
        case .quickPick:
            return "QuickPick"
        case .members:
            return "Members"
        case .activity:
            return "Activity"
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
    
    @State private var selectedSegment: CircleDetailSegment = .timeline
    @State private var copiedInviteCode = false
    
    @State private var isRefreshing = false
    @State private var isPullingSharedEntries = false
    
    @State private var refreshedCircle: CloseCircle?
    @State private var members: [CircleMember] = []
    @State private var activities: [CircleActivity] = []
    
    @State private var refreshErrorMessage: String?
    @State private var sharedEntriesErrorMessage: String?
    @State private var membersErrorMessage: String?
    @State private var activityErrorMessage: String?
    
    @State private var showLeaveConfirmation = false
    @State private var isLeavingCircle = false
    
    @State private var showEditCircleSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isSavingCircle = false
    @State private var isDeletingCircle = false
    
    @State private var circleActionErrorMessage: String?
    
    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]
    
    private let circleRemoteDataSource = CircleRemoteDataSource()
    private let circleService = CircleService()
    private let circleRepository = CircleRepository()
    private let entryRemoteDataSource = EntryRemoteDataSource()
    private let entryRepository = EntryRepository()
    
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
        
        return "A private space for shared watch memories."
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
    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    
                    statusBanners
                    
                    Picker("Circle detail section", selection: $selectedSegment) {
                        ForEach(CircleDetailSegment.allCases) { segment in
                            Text(segment.title)
                                .tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(canUseCircle == false)
                    
                    selectedContent
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Circle")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task {
            await refreshCircleDetail()
        }
        .refreshable {
            await refreshCircleDetail()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                actionsMenu
            }
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
    }
    
    // MARK: - Toolbar
    
    @ViewBuilder
    private var actionsMenu: some View {
        if canShowOwnerActions || canShowMemberActions {
            Menu {
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
                    .font(.system(size: 17, weight: .semibold))
            }
            .accessibilityLabel("Circle actions")
            .disabled(isLeavingCircle || isSavingCircle || isDeletingCircle)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 42, height: 42)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(membership.role.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(membership.isOwner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                        
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
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(circleDescriptionText)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                
                Text("Owner: \(displayedCircle.ownerDisplayName)")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            inviteCodeBlock
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
    
    private var inviteCodeBlock: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invite code")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                
                Text(displayedCircle.inviteCode)
                    .font(.subheadline.monospaced().weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)
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
            .disabled(displayedCircle.inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Copy invite code")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        case .timeline:
            timelineSection
            
        case .quickPick:
            quickPickPlaceholder
            
        case .members:
            membersSection
            
        case .activity:
            activitySection
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isPullingSharedEntries && sharedEntries.isEmpty {
                DetailSectionCard(title: "Shared timeline") {
                    HStack(spacing: 10) {
                        ProgressView()
                        
                        Text("Loading entries shared with this Circle…")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                        
                        Spacer()
                    }
                }
            } else if sharedEntries.isEmpty {
                EmptyStateView(
                    title: "Nothing shared yet",
                    message: "Share entries from your Personal Timeline to start building this Circle’s shared history.",
                    systemImage: "film.stack",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                DetailSectionCard(title: "Shared timeline") {
                    VStack(spacing: 12) {
                        ForEach(sharedEntries) { entry in
                            NavigationLink {
                                CircleEntryReadOnlyDetailView(
                                    entry: entry,
                                    currentUserId: currentUserId,
                                    currentUserDisplayName: currentUserDisplayName,
                                    circleId: displayedCircleId
                                )
                            } label: {
                                CircleTimelineEntryRow(
                                    entry: entry,
                                    currentUserId: currentUserId
                                )
                            }
                            .buttonStyle(.plain)
                            
                            if entry.id != sharedEntries.last?.id {
                                Divider()
                                    .overlay(CloseCutColors.separator)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var quickPickPlaceholder: some View {
        EmptyStateView(
            title: "Group QuickPick is coming",
            message: "Once this Circle has enough shared taste history, CloseCut will suggest what this group may want to watch together.",
            systemImage: "sparkles",
            actionTitle: nil,
            action: nil
        )
    }
    
    private var membersSection: some View {
        DetailSectionCard(title: displayedMemberCountText) {
            VStack(spacing: 12) {
                Text("People who can see entries intentionally shared with this Circle.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
    
    private var activitySection: some View {
        DetailSectionCard(title: "Recent activity") {
            VStack(spacing: 12) {
                Text("A lightweight history of changes inside this Circle.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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

    // MARK: - Actions

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
