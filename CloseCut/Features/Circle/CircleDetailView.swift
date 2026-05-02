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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timeline:
            return "Timeline"
        case .quickPick:
            return "QuickPick"
        case .members:
            return "Members"
        }
    }
}

struct CircleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let circle: CloseCircle
    let membership: CircleMembership
    let currentUserId: String

    @State private var selectedSegment: CircleDetailSegment = .timeline
    @State private var copiedInviteCode = false

    @State private var isRefreshing = false
    @State private var refreshedCircle: CloseCircle?
    @State private var members: [CircleMember] = []
    @State private var refreshErrorMessage: String?

    @State private var showLeaveConfirmation = false
    @State private var isLeavingCircle = false
    @State private var circleActionErrorMessage: String?

    private let circleRemoteDataSource = CircleRemoteDataSource()
    private let circleService = CircleService()

    private var displayedCircle: CloseCircle {
        refreshedCircle ?? circle
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

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if isRefreshing {
                        SyncResultBanner(
                            message: "Refreshing Circle…",
                            style: .neutral
                        )
                    }

                    if let refreshErrorMessage {
                        SyncResultBanner(
                            message: refreshErrorMessage,
                            style: .warning
                        )
                    }

                    Picker("Circle detail section", selection: $selectedSegment) {
                        ForEach(CircleDetailSegment.allCases) { segment in
                            Text(segment.title)
                                .tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)

                    selectedContent

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(displayedCircle.name)
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
                Menu {
                    if membership.isOwner {
                        Button {
                            // Owner edit/delete comes next.
                        } label: {
                            Label("Manage Circle", systemImage: "slider.horizontal.3")
                        }
                        .disabled(true)
                    } else {
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
                .disabled(isLeavingCircle)
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
        .alert("Circle action failed", isPresented: Binding(
            get: { circleActionErrorMessage != nil },
            set: { if !$0 { circleActionErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(circleActionErrorMessage ?? "Unknown error.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayedCircle.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let description = displayedCircle.description,
                       description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("A private Circle for shared watch memories.")
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                    }
                }

                Spacer()

                Text(membership.role.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(membership.isOwner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(CloseCutColors.input)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Label("\(displayedCircle.memberIds.count) members", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("Owner: \(displayedCircle.ownerDisplayName)")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

            inviteCodeBlock
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var inviteCodeBlock: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invite code")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(displayedCircle.inviteCode)
                    .font(.subheadline.monospaced().weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
            }

            Spacer()

            Button {
                copyInviteCode()
            } label: {
                Image(systemName: copiedInviteCode ? "checkmark" : "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Copy invite code")
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedSegment {
        case .timeline:
            timelinePlaceholder

        case .quickPick:
            quickPickPlaceholder

        case .members:
            membersSection
        }
    }

    private var timelinePlaceholder: some View {
        EmptyStateView(
            title: "Nothing shared yet",
            message: "Entries intentionally shared with this Circle will appear here.",
            systemImage: "film.stack",
            actionTitle: nil,
            action: nil
        )
    }

    private var quickPickPlaceholder: some View {
        EmptyStateView(
            title: "Not enough group history yet",
            message: "Group QuickPick will use entries shared with this Circle, separate from your private archive.",
            systemImage: "sparkles",
            actionTitle: nil,
            action: nil
        )
    }

    private var membersSection: some View {
        DetailSectionCard(title: "Members") {
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
                    Text("Members will appear here once Circle membership is refreshed.")
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

    private func copyInviteCode() {
        UIPasteboard.general.string = displayedCircle.inviteCode

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

    private func refreshCircleDetail() async {
        guard isRefreshing == false else {
            return
        }

        isRefreshing = true
        refreshErrorMessage = nil
        defer { isRefreshing = false }

        do {
            async let circleTask = circleRemoteDataSource.fetchCircle(
                circleId: displayedCircle.id
            )

            async let membersTask = circleRemoteDataSource.fetchMembers(
                circleId: displayedCircle.id
            )

            let (remoteCircle, remoteMembers) = try await (circleTask, membersTask)

            refreshedCircle = remoteCircle
            members = remoteMembers
        } catch {
            refreshErrorMessage = error.localizedDescription

            #if DEBUG
            print("⚠️ Failed to refresh Circle detail:", error.localizedDescription)
            #endif
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
}
