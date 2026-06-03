//
//  WatchPlanDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI
import SwiftData

struct WatchPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let initialPlan: WatchPlan
    let currentUserId: String
    let currentUserDisplayName: String

    @Query(sort: \LocalWatchPlan.updatedAt, order: .reverse)
    private var localPlans: [LocalWatchPlan]

    @Query(sort: \LocalWatchPlanResponse.updatedAt, order: .reverse)
    private var localResponses: [LocalWatchPlanResponse]

    @State private var actionMessage: String?
    @State private var actionBannerStyle: SyncResultBannerStyle = .neutral
    @State private var isPerformingAction = false
    @State private var showCancelConfirmation = false
    @State private var showDeleteConfirmation = false

    private let repository = WatchPlanRepository()

    private var plan: WatchPlan {
        localPlans
            .first { $0.id == initialPlan.id }?
            .domain ?? initialPlan
    }

    private var responses: [WatchPlanResponse] {
        localResponses
            .map { $0.domain }
            .filter { response in
                response.planId == plan.id &&
                response.deletedAt == nil
            }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var currentUserResponse: WatchPlanResponse? {
        responses.first { $0.userId == currentUserId }
    }

    private var isOwner: Bool {
        plan.isOwned(by: currentUserId)
    }

    private var canRespond: Bool {
        plan.isActive &&
        plan.status != .canceled &&
        plan.status != .watched &&
        isOwner == false &&
        plan.isInvited(memberId: currentUserId)
    }

    private var canConfirm: Bool {
        isOwner && plan.canBeConfirmed
    }

    private var canMarkWatched: Bool {
        isOwner && plan.canBeMarkedWatched
    }

    private var canCancel: Bool {
        isOwner &&
        plan.isActive &&
        plan.status != .canceled &&
        plan.status != .watched
    }

    private var canDelete: Bool {
        isOwner && plan.isActive
    }

    private var metadataText: String {
        plan.media.metadataText
    }

    private var statusColor: Color {
        switch plan.status {
        case .draft:
            return CloseCutColors.textTertiary
        case .proposed:
            return CloseCutColors.accentLight
        case .confirmed:
            return CloseCutColors.synced
        case .watched:
            return CloseCutColors.textSecondary
        case .canceled:
            return CloseCutColors.failed
        }
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroSection

                    if let actionMessage {
                        SyncResultBanner(
                            message: actionMessage,
                            style: actionBannerStyle
                        )
                    }

                    responseSummarySection

                    if canRespond {
                        respondSection
                    }

                    if isOwner {
                        ownerActionsSection
                    }

                    planDetailsSection

                    responsesSection

                    privacySection

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(CloseCutColors.accent)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isOwner {
                    ownerMenu
                }
            }
        }
        .confirmationDialog(
            "Cancel plan?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel plan", role: .destructive) {
                Task {
                    await cancelPlan()
                }
            }

            Button("Keep plan", role: .cancel) {}
        } message: {
            Text("Members will still see the plan as canceled after sync.")
        }
        .confirmationDialog(
            "Delete plan?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete plan", role: .destructive) {
                Task {
                    await deletePlan()
                }
            }

            Button("Keep plan", role: .cancel) {}
        } message: {
            Text("This archives the plan locally and queues the delete for cloud sync.")
        }
    }

    // MARK: - Toolbar

    private var ownerMenu: some View {
        Menu {
            if canConfirm {
                Button {
                    Task {
                        await confirmPlan()
                    }
                } label: {
                    Label("Confirm plan", systemImage: "checkmark.seal.fill")
                }
            }

            if canMarkWatched {
                Button {
                    Task {
                        await markWatched()
                    }
                } label: {
                    Label("Mark watched", systemImage: "film.fill")
                }
            }

            if canCancel {
                Button(role: .destructive) {
                    showCancelConfirmation = true
                } label: {
                    Label("Cancel plan", systemImage: "xmark.circle.fill")
                }
            }

            if canDelete {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete plan", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(CloseCutColors.accent)
        }
        .disabled(isPerformingAction)
        .accessibilityLabel("Watch Together actions")
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                posterView

                VStack(alignment: .leading, spacing: 8) {
                    statusPills

                    Text(plan.displayTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(metadataText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)

                    Text(plan.media.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)

                    Text("Created by \(plan.displayOwnerName)")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            if let note = plan.displayNote {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CloseCutColors.input.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(18)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 10)
    }

    private var posterView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(CloseCutColors.input)

            if let posterURL = plan.media.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.75)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        fallbackPoster

                    @unknown default:
                        fallbackPoster
                    }
                }
            } else {
                fallbackPoster
            }
        }
        .frame(width: 88, height: 132)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityHidden(true)
    }

    private var fallbackPoster: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.22),
                    CloseCutColors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: plan.media.type == .movie ? "film.fill" : "tv.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)

                Text(String(plan.media.displayTitle.prefix(2)).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CloseCutColors.textSecondary)
            }
            .padding(10)
        }
    }

    private var statusPills: some View {
        HStack(spacing: 7) {
            planStatusPill(
                icon: plan.status.systemImage,
                text: plan.status.displayName,
                foreground: statusColor
            )

            planStatusPill(
                icon: "circle.grid.2x2.fill",
                text: plan.displayCircleName,
                foreground: CloseCutColors.textTertiary
            )
        }
    }

    private func planStatusPill(
        icon: String,
        text: String,
        foreground: Color
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input.opacity(0.88))
        .clipShape(Capsule())
    }

    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.cardElevated,
                    CloseCutColors.card,
                    CloseCutColors.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.13),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 260
            )
        }
    }

    // MARK: - Summary

    private var responseSummarySection: some View {
        DetailSectionCard(title: "Plan status") {
            VStack(alignment: .leading, spacing: 12) {
                WatchPlanInfoRow(
                    icon: "calendar",
                    title: "Schedule",
                    value: plan.scheduleText
                )

                WatchPlanInfoRow(
                    icon: plan.locationType.systemImage,
                    title: "Location",
                    value: plan.locationText
                )

                WatchPlanInfoRow(
                    icon: "person.2.fill",
                    title: "Responses",
                    value: plan.responseSummaryText
                )

                WatchPlanInfoRow(
                    icon: "checkmark.seal.fill",
                    title: "Confirmation",
                    value: plan.confirmationRequirementText
                )

                if plan.syncStatus != .synced {
                    Divider()
                        .overlay(CloseCutColors.separator)

                    WatchPlanInfoRow(
                        icon: "icloud.and.arrow.up",
                        title: "Sync",
                        value: plan.syncStatus.displayName
                    )
                }
            }
        }
    }

    // MARK: - Respond

    private var respondSection: some View {
        DetailSectionCard(title: "Your response") {
            VStack(alignment: .leading, spacing: 14) {
                if let currentUserResponse {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: currentUserResponse.responseType.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("You answered \(currentUserResponse.responseType.displayName)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)

                            if let note = currentUserResponse.displayNote {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(CloseCutColors.textSecondary)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(CloseCutColors.input.opacity(0.74))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }

                HStack(spacing: 10) {
                    responseButton(
                        type: .accepted,
                        title: "Yes"
                    )

                    responseButton(
                        type: .maybe,
                        title: "Maybe"
                    )

                    responseButton(
                        type: .declined,
                        title: "No"
                    )
                }

                Text("Your response updates the plan locally first and syncs when CloseCut refreshes cloud data.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func responseButton(
        type: WatchPlanResponseType,
        title: String
    ) -> some View {
        let isSelected = currentUserResponse?.responseType == type

        return Button {
            Task {
                await respond(type)
            }
        } label: {
            VStack(spacing: 7) {
                Image(systemName: type.systemImage)
                    .font(.subheadline.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : CloseCutColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(isSelected ? CloseCutColors.accent : CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(isPerformingAction)
    }

    // MARK: - Owner Actions

    private var ownerActionsSection: some View {
        DetailSectionCard(title: "Owner actions") {
            VStack(alignment: .leading, spacing: 10) {
                if canConfirm {
                    actionButton(
                        title: "Confirm plan",
                        icon: "checkmark.seal.fill",
                        isPrimary: true,
                        isDestructive: false
                    ) {
                        Task {
                            await confirmPlan()
                        }
                    }
                }

                if canMarkWatched {
                    actionButton(
                        title: "Mark watched together",
                        icon: "film.fill",
                        isPrimary: true,
                        isDestructive: false
                    ) {
                        Task {
                            await markWatched()
                        }
                    }
                }

                if canCancel {
                    actionButton(
                        title: "Cancel plan",
                        icon: "xmark.circle.fill",
                        isPrimary: false,
                        isDestructive: true
                    ) {
                        showCancelConfirmation = true
                    }
                }

                if canDelete {
                    actionButton(
                        title: "Delete plan",
                        icon: "trash",
                        isPrimary: false,
                        isDestructive: true
                    ) {
                        showDeleteConfirmation = true
                    }
                }

                if canConfirm == false && canMarkWatched == false && canCancel == false && canDelete == false {
                    Text("No owner actions are available for this plan right now.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func actionButton(
        title: String,
        icon: String,
        isPrimary: Bool,
        isDestructive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 9) {
                if isPerformingAction {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 0)
            }
            .foregroundStyle(actionForegroundColor(isPrimary: isPrimary, isDestructive: isDestructive))
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(isPrimary ? CloseCutColors.accent : CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isPerformingAction)
    }

    private func actionForegroundColor(
        isPrimary: Bool,
        isDestructive: Bool
    ) -> Color {
        if isPrimary {
            return .white
        }

        if isDestructive {
            return CloseCutColors.failed
        }

        return CloseCutColors.textSecondary
    }

    // MARK: - Plan Details

    private var planDetailsSection: some View {
        DetailSectionCard(title: "Details") {
            VStack(alignment: .leading, spacing: 12) {
                WatchPlanInfoRow(
                    icon: "play.rectangle.fill",
                    title: "Media",
                    value: plan.media.displayTitle
                )

                WatchPlanInfoRow(
                    icon: plan.media.source.systemImage,
                    title: "Source",
                    value: plan.source.displayName
                )

                WatchPlanInfoRow(
                    icon: "person.crop.circle.fill",
                    title: "Owner",
                    value: plan.displayOwnerName
                )

                WatchPlanInfoRow(
                    icon: "clock.fill",
                    title: "Updated",
                    value: plan.updatedAt.formatted(date: .abbreviated, time: .shortened)
                )

                if let locationAddress = plan.locationAddress?.trimmed.nilIfBlank {
                    WatchPlanInfoRow(
                        icon: "mappin.and.ellipse",
                        title: "Address",
                        value: locationAddress
                    )
                }

                if let overview = plan.media.overview?.trimmed.nilIfBlank {
                    Divider()
                        .overlay(CloseCutColors.separator)

                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Responses

    private var responsesSection: some View {
        DetailSectionCard(title: "Responses") {
            VStack(alignment: .leading, spacing: 12) {
                if responses.isEmpty {
                    Text("No detailed responses yet.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(responses) { response in
                        WatchPlanResponseRow(
                            response: response,
                            isCurrentUser: response.userId == currentUserId
                        )

                        if response.id != responses.last?.id {
                            Divider()
                                .overlay(CloseCutColors.separator)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        DetailSectionCard(title: "Privacy") {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.top, 2)

                Text("Watch Together plans live inside a private Circle. They do not expose your Personal Timeline or Want to Watch list automatically.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Actions

    private func respond(
        _ responseType: WatchPlanResponseType
    ) async {
        guard isPerformingAction == false else {
            return
        }

        isPerformingAction = true
        actionMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            _ = try repository.respondToPlan(
                planId: plan.id,
                circleId: plan.circleId,
                userId: currentUserId,
                userDisplayName: currentUserDisplayName,
                responseType: responseType,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "Response saved. It will sync with the Circle."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func confirmPlan() async {
        guard isPerformingAction == false else {
            return
        }

        isPerformingAction = true
        actionMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            _ = try repository.confirmPlan(
                planId: plan.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "Plan confirmed."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func cancelPlan() async {
        guard isPerformingAction == false else {
            return
        }

        isPerformingAction = true
        actionMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            _ = try repository.cancelPlan(
                planId: plan.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "Plan canceled."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func markWatched() async {
        guard isPerformingAction == false else {
            return
        }

        isPerformingAction = true
        actionMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            _ = try repository.markPlanWatched(
                planId: plan.id,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "Marked as watched together."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func deletePlan() async {
        guard isPerformingAction == false else {
            return
        }

        isPerformingAction = true
        actionMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            _ = try repository.softDeletePlan(
                planId: plan.id,
                modelContext: modelContext
            )

            dismiss()
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }
}

// MARK: - Info Row

private struct WatchPlanInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.7)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Response Row

private struct WatchPlanResponseRow: View {
    let response: WatchPlanResponse
    let isCurrentUser: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: response.responseType.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(response.displayUserName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    if isCurrentUser {
                        Text("You")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                }

                Text(response.responseType.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                if let suggestedTimeText = response.suggestedTimeText {
                    Text("Suggested: \(suggestedTimeText)")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                if let note = response.displayNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
    }
}
