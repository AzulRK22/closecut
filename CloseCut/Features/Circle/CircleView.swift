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
    
    @State private var showCircleActions = false
    @State private var showCreateCircleSheet = false
    @State private var showJoinCircleSheet = false
    
    @State private var circleName = ""
    @State private var circleDescription = ""
    @State private var inviteCodeToJoin = ""
    @State private var circlePreview: CirclePreview?
    
    @State private var isCreatingCircle = false
    @State private var isPreviewingCircle = false
    @State private var isJoiningCircle = false
    @State private var isPullingRemoteMemberships = false
    @State private var isRefreshingCircleDetails = false
    @State private var hasLoadedInitialCircles = false
    
    @State private var circleErrorMessage: String?
    @State private var circleInlineMessage: String?
    
    private let circleService = CircleService()
    private let circleRepository = CircleRepository()
    private let circleRemoteDataSource = CircleRemoteDataSource()
    
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
    
    private var isLoadingCircles: Bool {
        isPullingRemoteMemberships || isRefreshingCircleDetails
    }
    
    private var loadingMessage: String {
        if isPullingRemoteMemberships {
            return "Finding your Circles…"
        }
        
        return "Refreshing your Circles…"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection
                        
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
                        
                        if circleRows.isEmpty {
                            CircleEmptyStateView(
                                onCreateCircle: openCreateCircle,
                                onJoinCircle: openJoinCircle
                            )
                        } else {
                            circlesListSection
                        }
                        
                        CirclePrivacyCard()
                        
                        comingSoonSection
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await loadCircles(force: true)
                }
            }
            .navigationTitle("Circle")
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
                    .accessibilityLabel("Add Circle")
                }
            }
            .sheet(isPresented: $showCircleActions) {
                CircleActionSheet(
                    onCreate: {
                        showCircleActions = false
                        openCreateCircle()
                    },
                    onJoin: {
                        showCircleActions = false
                        openJoinCircle()
                    }
                )
            }
            .sheet(isPresented: $showCreateCircleSheet) {
                createCircleSheet
            }
            .sheet(isPresented: $showJoinCircleSheet) {
                joinCircleSheet
            }
            .alert("Circle action failed", isPresented: Binding(
                get: { circleErrorMessage != nil },
                set: { if !$0 { circleErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(circleErrorMessage ?? "Unknown error.")
            }
            .task {
                await loadCirclesIfNeeded()
            }
        }
    }
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Share with the people who matter.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                    
                    Text("Create private spaces for friends, family, your partner, or movie clubs. Your personal Timeline stays private unless you choose to share.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 38, height: 38)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
            }
            
            if circleRows.isEmpty == false {
                HStack(spacing: 10) {
                    circleStatPill(
                        value: "\(circleRows.count)",
                        label: circleRows.count == 1 ? "circle" : "circles",
                        icon: "circle.grid.2x2.fill"
                    )
                    
                    circleStatPill(
                        value: "\(ownedCircleCount)",
                        label: "owned",
                        icon: "crown.fill"
                    )
                    
                    circleStatPill(
                        value: "\(joinedCircleCount)",
                        label: "joined",
                        icon: "person.badge.plus"
                    )
                }
            }
        }
    }
    
    private var circlesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Circles")
                        .font(.headline)
                        .foregroundStyle(CloseCutColors.textPrimary)
                    
                    Text(circleRows.count == 1 ? "1 private space" : "\(circleRows.count) private spaces")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }
                
                Spacer()
            }
            
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
                            membership: row.membership
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Circle features")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .padding(.horizontal, 2)
            
            VStack(alignment: .leading, spacing: 16) {
                CircleComingSoonRow(
                    icon: "film.stack.fill",
                    title: "Shared timeline",
                    message: "See memories intentionally shared with each Circle."
                )
                
                Divider()
                    .overlay(CloseCutColors.separator)
                
                CircleComingSoonRow(
                    icon: "heart.circle.fill",
                    title: "Reactions and comments",
                    message: "React once, leave short comments, and keep the signal lightweight."
                )
                
                Divider()
                    .overlay(CloseCutColors.separator)
                
                CircleComingSoonRow(
                    icon: "sparkles",
                    title: "Group QuickPick",
                    message: "Coming later: recommendations based on what that group shares."
                )
            }
            .padding(16)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }
    
    private var createCircleSheet: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 18) {
                    Text("Name your Circle")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                    
                    Text("Keep it small and personal. You decide what gets shared.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Circle name")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        
                        TextField("Friends, Family, Movie Club…", text: $circleName)
                            .font(.body)
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .textInputAutocapitalization(.words)
                            .padding(14)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description optional")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        
                        TextField("What is this Circle for?", text: $circleDescription)
                            .font(.body)
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .textInputAutocapitalization(.sentences)
                            .padding(14)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    if isCreatingCircle {
                        HStack(spacing: 10) {
                            ProgressView()
                            
                            Text("Creating Circle…")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCreateCircleSheet = false
                    }
                    .disabled(isCreatingCircle)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createCircle()
                        }
                    }
                    .disabled(
                        isCreatingCircle ||
                        circleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var joinCircleSheet: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Join a Circle")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                        
                        Text("Enter the invite code from someone you trust. You’ll preview the Circle before joining.")
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invite code")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            
                            TextField("Invite code", text: $inviteCodeToJoin)
                                .font(.title3.monospaced().weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(CloseCutColors.input)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .onChange(of: inviteCodeToJoin) { _, newValue in
                                    let normalized = newValue.normalizedInviteCode
                                    
                                    if normalized != newValue {
                                        inviteCodeToJoin = normalized
                                    }
                                    
                                    if circlePreview?.circle.inviteCodeNormalized != normalized {
                                        circlePreview = nil
                                    }
                                }
                            
                            Text("Example: AZULR-12345")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textTertiary)
                        }
                        
                        if isPreviewingCircle {
                            HStack(spacing: 10) {
                                ProgressView()
                                
                                Text("Finding Circle…")
                                    .font(.caption)
                                    .foregroundStyle(CloseCutColors.textSecondary)
                            }
                        }
                        
                        if let circlePreview {
                            CirclePreviewCard(preview: circlePreview)
                        }
                        
                        if isJoiningCircle {
                            HStack(spacing: 10) {
                                ProgressView()
                                
                                Text("Joining Circle…")
                                    .font(.caption)
                                    .foregroundStyle(CloseCutColors.textSecondary)
                            }
                        }
                        
                        Spacer(minLength: 24)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Join Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showJoinCircleSheet = false
                    }
                    .disabled(isJoiningCircle || isPreviewingCircle)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if let circlePreview {
                        Button(circlePreview.isAlreadyMember ? "Done" : "Join") {
                            Task {
                                if circlePreview.isAlreadyMember {
                                    showJoinCircleSheet = false
                                } else {
                                    await joinCircle()
                                }
                            }
                        }
                        .disabled(isJoiningCircle || isPreviewingCircle)
                    } else {
                        Button("Preview") {
                            Task {
                                await previewCircle()
                            }
                        }
                        .disabled(
                            isJoiningCircle ||
                            isPreviewingCircle ||
                            inviteCodeToJoin.normalizedInviteCode.isEmpty
                        )
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    private func openCreateCircle() {
        circleName = ""
        circleDescription = ""
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

    private func createCircle() async {
        guard isCreatingCircle == false else {
            return
        }

        let cleanedName = circleName.trimmingCharacters(in: .whitespacesAndNewlines)

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
                circleDescription: circleDescription,
                modelContext: modelContext
            )

            showCreateCircleSheet = false
            circleName = ""
            circleDescription = ""

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

        if force && circleRows.isEmpty {
            circleInlineMessage = nil
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

    private func circleStatPill(
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
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
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
        LocalBattleResult.self
    ], inMemory: true)
}
