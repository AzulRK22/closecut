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
    @State private var isRefreshingCircles = false

    @State private var circleErrorMessage: String?

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
            guard let circle = circlesById[membership.circleId] else {
                return nil
            }

            return (circle, membership)
        }
    }
    private var membershipRefreshKey: String {
        localMemberships
            .filter { $0.userId == user.id }
            .map { membership in
                "\(membership.id)-\(membership.statusRaw)-\(membership.updatedAt.timeIntervalSince1970)"
            }
            .joined(separator: "|")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection

                        if isRefreshingCircles {
                            SyncResultBanner(
                                message: "Refreshing your Circles…",
                                style: .neutral
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
            .task(id: membershipRefreshKey) {
                await refreshLocalCirclesFromRemote()
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Share only with the people who matter.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Create private spaces for friends, family, your partner, or movie clubs. Your personal history stays private unless you choose to share.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private var circlesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Circles")
                        .font(.headline)
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("\(circleRows.count) private spaces")
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
            Text("Coming soon")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 16) {
                CircleComingSoonRow(
                    icon: "film.stack.fill",
                    title: "Shared timeline",
                    message: "Each Circle will have its own shared movie and series history."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                CircleComingSoonRow(
                    icon: "sparkles",
                    title: "Group QuickPick",
                    message: "Recommendations based on what that group shares, not your private archive."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                CircleComingSoonRow(
                    icon: "heart.circle.fill",
                    title: "Reactions and comments",
                    message: "Small trusted signals from the people in that Circle."
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
                    .disabled(isCreatingCircle || circleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        showCreateCircleSheet = true
    }

    private func openJoinCircle() {
        inviteCodeToJoin = ""
        circlePreview = nil
        showJoinCircleSheet = true
    }
    private func previewCircle() async {
        isPreviewingCircle = true
        circleErrorMessage = nil
        circlePreview = nil
        defer { isPreviewingCircle = false }

        do {
            let preview = try await circleService.previewCircle(
                inviteCode: inviteCodeToJoin,
                currentUserId: user.id
            )

            circlePreview = preview
        } catch {
            circleErrorMessage = error.localizedDescription
        }
    }

    private func createCircle() async {
        isCreatingCircle = true
        circleErrorMessage = nil
        defer { isCreatingCircle = false }

        do {
            _ = try await circleService.createCircle(
                user: user,
                profile: profile,
                circleName: circleName,
                circleDescription: circleDescription,
                modelContext: modelContext
            )

            showCreateCircleSheet = false
            await refreshLocalCirclesFromRemote()
        } catch {
            circleErrorMessage = error.localizedDescription
        }
    }

    private func joinCircle() async {
        isJoiningCircle = true
        circleErrorMessage = nil
        defer { isJoiningCircle = false }

        do {
            _ = try await circleService.joinCircle(
                user: user,
                profile: profile,
                inviteCode: circlePreview?.circle.inviteCodeNormalized ?? inviteCodeToJoin,
                modelContext: modelContext
            )

            showJoinCircleSheet = false
            circlePreview = nil

            await refreshLocalCirclesFromRemote()
        } catch {
            circleErrorMessage = error.localizedDescription
        }
    }
    private func refreshLocalCirclesFromRemote() async {
        guard isRefreshingCircles == false else {
            return
        }

        isRefreshingCircles = true
        defer { isRefreshingCircles = false }

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
            id: "preview-user-1234",
            displayName: "Preview User",
            email: "preview@closecut.dev",
            photoURL: nil,
            circleId: nil,
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
    .modelContainer(for: [
        LocalEntry.self,
        LocalReaction.self,
        LocalComment.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self
    ], inMemory: true)
}
