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

    @State private var copiedInviteCode = false
    @State private var showCreateCircleSheet = false
    @State private var showJoinCircleSheet = false

    @State private var circleName = ""
    @State private var inviteCodeToJoin = ""

    @State private var isCreatingCircle = false
    @State private var isJoiningCircle = false
    @State private var isRefreshingCircle = false

    @State private var circleErrorMessage: String?
    @State private var activeCircleOverride: CloseCircle?

    private let circleService = CircleService()
    private let circleRepository = CircleRepository()
    private let circleRemoteDataSource = CircleRemoteDataSource()

    private var currentCircle: CloseCircle? {
        if let activeCircleOverride {
            return activeCircleOverride
        }

        guard let circleId = profile.circleId else {
            return nil
        }

        return localCircles.first { $0.id == circleId }?.domain
    }

    private var fallbackInviteCode: String {
        CircleInviteCodeGenerator.generate(
            displayName: profile.displayName,
            userId: user.id
        )
    }

    private var displayedInviteCode: String {
        currentCircle?.inviteCode ?? fallbackInviteCode
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection

                        if let currentCircle {
                            activeCircleSection(currentCircle)
                        } else {
                            createCircleSection
                        }

                        if copiedInviteCode {
                            Text("Invite code copied")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.synced)
                                .padding(.horizontal, 4)
                                .transition(.opacity)
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
                await refreshCurrentCircleIfNeeded()
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Share only with the people who matter.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your Circle is a small private space for reactions and short comments on selected entries.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private func activeCircleSection(_ circle: CloseCircle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            CircleInviteCard(
                inviteCode: circle.inviteCode,
                onCopy: copyInviteCode,
                onJoin: {
                    inviteCodeToJoin = ""
                    showJoinCircleSheet = true
                }
            )

            DetailSectionCard(title: "Circle") {
                VStack(spacing: 8) {
                    DetailInfoRow(
                        label: "Name",
                        value: circle.name
                    )

                    DetailInfoRow(
                        label: "Members",
                        value: "\(circle.memberIds.count)"
                    )

                    DetailInfoRow(
                        label: "Owner",
                        value: circle.ownerDisplayName
                    )

                    if isRefreshingCircle {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)

                            Text("Refreshing Circle…")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private var createCircleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Create your private Circle")
                    .font(.headline)
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Start with yourself. You’ll get an invite code and connect join flow later.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Suggested invite code")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack {
                Text(fallbackInviteCode)
                    .font(.title3.monospaced().weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Spacer()

                Button {
                    copyInviteCode()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Copy suggested invite code")
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                circleName = "\(profile.displayName)'s Circle"
                showCreateCircleSheet = true
            } label: {
                Text("Create my Circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                inviteCodeToJoin = ""
                showJoinCircleSheet = true
            } label: {
                Text("Join a Circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
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
                    icon: "heart.circle.fill",
                    title: "One active reaction",
                    message: "Each friend will have one current reaction per entry. Changing it replaces the previous one."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                CircleComingSoonRow(
                    icon: "text.bubble.fill",
                    title: "Short comments",
                    message: "Small notes, not a chat thread. The goal is memory, not noise."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                CircleComingSoonRow(
                    icon: "clock.badge.exclamationmark.fill",
                    title: "Pending sync",
                    message: "Social actions will be saved locally first and synced when available."
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

                    Text("Keep it small and personal. You can invite trusted friends later.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)

                    TextField("Circle name", text: $circleName)
                        .font(.body)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite code")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(fallbackInviteCode)
                            .font(.title3.monospaced().weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                    .disabled(isCreatingCircle)
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

                VStack(alignment: .leading, spacing: 18) {
                    Text("Join a Circle")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Enter the invite code from someone you trust. CloseCut Circles are small and private.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

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
                        }

                    Text("Example: AZULR-12345")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)

                    if isJoiningCircle {
                        HStack(spacing: 10) {
                            ProgressView()

                            Text("Joining Circle…")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Join Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showJoinCircleSheet = false
                    }
                    .disabled(isJoiningCircle)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Join") {
                        Task {
                            await joinCircle()
                        }
                    }
                    .disabled(isJoiningCircle || inviteCodeToJoin.normalizedInviteCode.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func copyInviteCode() {
        UIPasteboard.general.string = displayedInviteCode

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedInviteCode = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    copiedInviteCode = false
                }
            }
        }
    }

    private func createCircle() async {
        isCreatingCircle = true
        circleErrorMessage = nil
        defer { isCreatingCircle = false }

        do {
            let circle = try await circleService.createCircle(
                user: user,
                profile: profile,
                circleName: circleName,
                modelContext: modelContext
            )

            activeCircleOverride = circle
            showCreateCircleSheet = false

            await refreshCurrentCircleIfNeeded()
        } catch {
            circleErrorMessage = error.localizedDescription
        }
    }

    private func joinCircle() async {
        isJoiningCircle = true
        circleErrorMessage = nil
        defer { isJoiningCircle = false }

        do {
            let circle = try await circleService.joinCircle(
                user: user,
                profile: profile,
                inviteCode: inviteCodeToJoin,
                modelContext: modelContext
            )

            activeCircleOverride = circle
            showJoinCircleSheet = false

            await refreshCurrentCircleIfNeeded()
        } catch {
            circleErrorMessage = error.localizedDescription
        }
    }

    private func refreshCurrentCircleIfNeeded() async {
        guard isRefreshingCircle == false else {
            return
        }

        let circleId: String?

        if let activeCircleOverride {
            circleId = activeCircleOverride.id
        } else {
            circleId = profile.circleId
        }

        guard let circleId else {
            return
        }

        isRefreshingCircle = true
        defer { isRefreshingCircle = false }

        do {
            let remoteCircle = try await circleRemoteDataSource.fetchCircle(
                circleId: circleId
            )

            let localCircle = try circleRepository.upsertRemoteCircle(
                remoteCircle,
                modelContext: modelContext
            )

            activeCircleOverride = localCircle
        } catch {
            #if DEBUG
            print("⚠️ Failed to refresh Circle:", error.localizedDescription)
            #endif
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
