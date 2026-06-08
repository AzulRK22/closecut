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

    @Query(sort: \LocalEntry.updatedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @State private var actionMessage: String?
    @State private var actionBannerStyle: SyncResultBannerStyle = .neutral
    @State private var isPerformingAction = false

    @State private var showCancelConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showSuggestTimeSheet = false
    @State private var showEditPlanSheet = false

    private let syncService = WatchPlanSyncService()
    private let repository = WatchPlanRepository()
    private let entryRepository = EntryRepository()

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

    private var currentUserEntries: [Entry] {
        localEntries
            .filter { $0.ownerId == currentUserId }
            .map { $0.domain }
            .filter { $0.deletedAt == nil }
    }

    private var matchingPersonalEntry: Entry? {
        currentUserEntries.first { entry in
            if let planTMDBId = plan.media.tmdbId,
               let planMediaTypeRaw = plan.media.tmdbMediaTypeRaw,
               let entryTMDBId = entry.tmdbId,
               let entryMediaTypeRaw = entry.tmdbMediaTypeRaw {
                return planTMDBId == entryTMDBId &&
                    planMediaTypeRaw == entryMediaTypeRaw
            }

            return entry.displayTitle.normalizedTitleKey == plan.media.displayTitle.normalizedTitleKey &&
                entry.type == plan.media.type &&
                yearsAreCompatible(entry.releaseYear, plan.media.releaseYear)
        }
    }

    private var isAlreadyInPersonal: Bool {
        matchingPersonalEntry != nil
    }

    private var canAddToPersonal: Bool {
        plan.isActive &&
        plan.status == .watched &&
        isAlreadyInPersonal == false &&
        isPerformingAction == false
    }

    private var isOwner: Bool {
        plan.isOwned(by: currentUserId)
    }

    private var isInvitedUser: Bool {
        plan.isInvited(memberId: currentUserId)
    }

    private var canRespond: Bool {
        plan.isActive &&
        plan.status != .canceled &&
        plan.status != .watched &&
        isOwner == false &&
        isInvitedUser
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

                    participantAccessSection

                    if canRespond {
                        respondSection
                    }

                    if isOwner {
                        ownerActionsSection
                    }

                    personalTimelineSection

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
        .sheet(isPresented: $showSuggestTimeSheet) {
            WatchPlanSuggestTimeSheet(
                currentResponse: currentUserResponse,
                isSaving: isPerformingAction,
                onCancel: {
                    showSuggestTimeSheet = false
                },
                onSave: { suggestedDateText, note in
                    Task {
                        await suggestAnotherTime(
                            suggestedDateText: suggestedDateText,
                            note: note
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showEditPlanSheet) {
            EditWatchPlanSheet(
                plan: plan,
                isSaving: isPerformingAction,
                onCancel: {
                    showEditPlanSheet = false
                },
                onSave: { title, note, proposedDateText, locationType, locationName, locationAddress, streamingService in
                    Task {
                        await updatePlan(
                            title: title,
                            note: note,
                            proposedDateText: proposedDateText,
                            locationType: locationType,
                            locationName: locationName,
                            locationAddress: locationAddress,
                            streamingService: streamingService
                        )
                    }
                }
            )
        }
    }

    // MARK: - Toolbar

    private var ownerMenu: some View {
        Menu {
            Button {
                showEditPlanSheet = true
            } label: {
                Label("Edit plan", systemImage: "pencil")
            }

            Divider()

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

    private var participantAccessSection: some View {
        DetailSectionCard(title: "Access") {
            VStack(alignment: .leading, spacing: 12) {
                if isOwner {
                    WatchPlanInfoRow(
                        icon: "crown.fill",
                        title: "Your role",
                        value: "Owner"
                    )

                    Text("You can edit, confirm, cancel, delete, or mark this plan as watched once the plan is ready.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if isInvitedUser {
                    WatchPlanInfoRow(
                        icon: "person.fill.checkmark",
                        title: "Your role",
                        value: "Invited"
                    )

                    Text("You can respond to this plan. Your response is saved locally first and then synced with the Circle.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    WatchPlanInfoRow(
                        icon: "eye.fill",
                        title: "Your role",
                        value: "Viewer"
                    )

                    Text("You can view this plan because it belongs to one of your Circles, but you are not listed as an invitee.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Respond

    private var respondSection: some View {
        DetailSectionCard(title: "Your response") {
            VStack(alignment: .leading, spacing: 14) {
                if let currentUserResponse {
                    currentResponseCard(currentUserResponse)
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

                Button {
                    showSuggestTimeSheet = true
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: WatchPlanResponseType.suggestAnotherTime.systemImage)
                            .font(.caption.weight(.semibold))

                        Text("Suggest another time")
                            .font(.subheadline.weight(.semibold))

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isPerformingAction)

                Text("Your response updates locally first, then syncs with the Circle.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func currentResponseCard(
        _ response: WatchPlanResponse
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: response.responseType.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("You answered \(response.responseType.displayName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                if let suggestedTimeText = response.suggestedTimeText {
                    Text("Suggested: \(suggestedTimeText)")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
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
        .padding(12)
        .background(CloseCutColors.input.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
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
                actionButton(
                    title: "Edit plan",
                    icon: "pencil",
                    isPrimary: false,
                    isDestructive: false
                ) {
                    showEditPlanSheet = true
                }

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

    // MARK: - Personal Timeline

    private var personalTimelineSection: some View {
        DetailSectionCard(title: "Personal Timeline") {
            VStack(alignment: .leading, spacing: 12) {
                WatchPlanInfoRow(
                    icon: isAlreadyInPersonal ? "checkmark.circle.fill" : "person.crop.square.filled.and.at.rectangle",
                    title: "Personal memory",
                    value: personalTimelineStatusText
                )

                Text(personalTimelineHelperText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                if isAlreadyInPersonal {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.top, 2)

                        Text("This title already exists in your private Personal Timeline. The Circle plan stays separate from your personal memory.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(CloseCutColors.input.opacity(0.74))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Button {
                        Task {
                            await addPlanToPersonalTimeline()
                        }
                    } label: {
                        HStack(spacing: 9) {
                            if isPerformingAction {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption.weight(.semibold))
                            }

                            Text("Add to Personal Timeline")
                                .font(.subheadline.weight(.semibold))

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(canAddToPersonal ? .white : CloseCutColors.textTertiary)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(canAddToPersonal ? CloseCutColors.accent : CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(canAddToPersonal == false)
                }
            }
        }
    }

    private var personalTimelineStatusText: String {
        if isAlreadyInPersonal {
            return "Already saved in Personal"
        }

        if plan.status == .watched {
            return "Ready to save privately"
        }

        if plan.status == .confirmed {
            return "Mark watched first"
        }

        if plan.status == .canceled {
            return "Canceled plans cannot be added"
        }

        return "Available after watching"
    }

    private var personalTimelineHelperText: String {
        if isAlreadyInPersonal {
            return "CloseCut found a matching title in your Personal Timeline."
        }

        if plan.status == .watched {
            return "Save this watched plan as a private Personal memory with its title, type, poster, year, overview, rating, and TMDB metadata."
        }

        return "Once this plan is marked as watched, you can add it to your private Personal Timeline."
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
                    title: "Media source",
                    value: plan.media.source.displayName
                )

                WatchPlanInfoRow(
                    icon: "square.stack.3d.up.fill",
                    title: "Plan source",
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

    // MARK: - Sync

    private func syncWatchTogetherChanges(
        successMessage: String
    ) async {
        actionBannerStyle = .neutral
        actionMessage = "Syncing with the Circle…"

        let summary = await syncService.syncPendingWatchTogetherItems(
            userId: currentUserId,
            modelContext: modelContext
        )

        if summary.hasFailures {
            actionBannerStyle = .warning
            actionMessage = "Saved locally, but it could not sync yet. It will retry later."
        } else {
            actionBannerStyle = .success
            actionMessage = successMessage
        }
    }

    // MARK: - Actions

    private func addPlanToPersonalTimeline() async {
        guard isPerformingAction == false else {
            return
        }

        guard plan.status == .watched else {
            actionBannerStyle = .warning
            actionMessage = "Mark this plan as watched before adding it to Personal."
            return
        }

        guard isAlreadyInPersonal == false else {
            actionBannerStyle = .neutral
            actionMessage = "\(plan.media.displayTitle) is already in your Personal Timeline."
            return
        }

        isPerformingAction = true
        actionMessage = nil

        defer {
            isPerformingAction = false
        }

        let draft = EntryDraftFactory.quickAddFromWatchPlan(plan)

        do {
            let entry = try entryRepository.createQuickAddEntry(
                ownerId: currentUserId,
                draft: draft,
                visibility: .privateOnly,
                modelContext: modelContext
            )

            actionBannerStyle = .success
            actionMessage = "\(entry.displayTitle) was added to your Personal Timeline."
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

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

            await syncWatchTogetherChanges(
                successMessage: "Response synced with the Circle."
            )
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func suggestAnotherTime(
        suggestedDateText: String,
        note: String?
    ) async {
        guard isPerformingAction == false else {
            return
        }

        let cleanedSuggestedDateText = suggestedDateText.trimmed
        let cleanedNote = note?.trimmed.nilIfBlank

        guard cleanedSuggestedDateText.isEmpty == false || cleanedNote != nil else {
            actionBannerStyle = .warning
            actionMessage = "Add a suggested time or a short note."
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
                responseType: .suggestAnotherTime,
                note: cleanedNote,
                suggestedDateText: cleanedSuggestedDateText.nilIfBlank,
                modelContext: modelContext
            )

            showSuggestTimeSheet = false

            await syncWatchTogetherChanges(
                successMessage: "Suggestion synced with the Circle."
            )
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func updatePlan(
        title: String,
        note: String?,
        proposedDateText: String?,
        locationType: WatchPlanLocationType,
        locationName: String?,
        locationAddress: String?,
        streamingService: String?
    ) async {
        guard isPerformingAction == false else {
            return
        }

        let cleanedTitle = title.trimmed

        guard cleanedTitle.isEmpty == false else {
            actionBannerStyle = .warning
            actionMessage = "Plan title is required."
            return
        }

        isPerformingAction = true
        actionMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            _ = try repository.updateLocalPlan(
                planId: plan.id,
                title: cleanedTitle,
                note: note?.trimmed.nilIfBlank,
                proposedDateText: proposedDateText?.trimmed.nilIfBlank,
                locationType: locationType,
                locationName: locationName?.trimmed.nilIfBlank,
                locationAddress: locationAddress?.trimmed.nilIfBlank,
                streamingService: streamingService?.trimmed.nilIfBlank,
                modelContext: modelContext
            )

            showEditPlanSheet = false

            await syncWatchTogetherChanges(
                successMessage: "Plan changes synced with the Circle."
            )
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

            await syncWatchTogetherChanges(
                successMessage: "Plan confirmed and synced with the Circle."
            )
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

            await syncWatchTogetherChanges(
                successMessage: "Plan canceled and synced with the Circle."
            )
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

            await syncWatchTogetherChanges(
                successMessage: "Marked as watched together and synced."
            )
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

            await syncWatchTogetherChanges(
                successMessage: "Plan deleted and synced with the Circle."
            )

            if actionBannerStyle != .warning {
                dismiss()
            }
        } catch {
            actionBannerStyle = .warning
            actionMessage = error.localizedDescription
        }
    }

    private func yearsAreCompatible(
        _ first: Int?,
        _ second: Int?
    ) -> Bool {
        if let first, let second {
            return first == second
        }

        return first == nil || second == nil
    }
}

// MARK: - Suggest Time Sheet

private struct WatchPlanSuggestTimeSheet: View {
    let currentResponse: WatchPlanResponse?
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: (_ suggestedDateText: String, _ note: String?) -> Void

    @State private var suggestedDateText: String
    @State private var note: String

    @FocusState private var focusedField: Field?

    private enum Field {
        case suggestedDate
        case note
    }

    init(
        currentResponse: WatchPlanResponse?,
        isSaving: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping (_ suggestedDateText: String, _ note: String?) -> Void
    ) {
        self.currentResponse = currentResponse
        self.isSaving = isSaving
        self.onCancel = onCancel
        self.onSave = onSave

        _suggestedDateText = State(initialValue: currentResponse?.suggestedDateText ?? "")
        _note = State(initialValue: currentResponse?.note ?? "")
    }

    private var cleanedSuggestedDateText: String {
        suggestedDateText.trimmed
    }

    private var cleanedNote: String {
        note.trimmed
    }

    private var canSave: Bool {
        isSaving == false &&
        (
            cleanedSuggestedDateText.isEmpty == false ||
            cleanedNote.isEmpty == false
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(alignment: .leading, spacing: 14) {
                        inputSection(
                            title: "Suggested time",
                            subtitle: "Use natural language for now.",
                            placeholder: "Friday night, Sunday afternoon, next week…",
                            text: $suggestedDateText,
                            focusedField: .suggestedDate
                        )

                        inputSection(
                            title: "Note optional",
                            subtitle: "Keep it short and useful.",
                            placeholder: "I can’t that day, but Saturday works.",
                            text: $note,
                            focusedField: .note
                        )
                    }
                    .padding(16)
                    .background(CloseCutColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(CloseCutColors.separator, lineWidth: 0.5)
                    }

                    privacyNote

                    if isSaving {
                        HStack(spacing: 10) {
                            ProgressView()

                            Text("Saving suggestion…")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)

                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationTitle("Suggest Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            cleanedSuggestedDateText,
                            cleanedNote.nilIfBlank
                        )
                    }
                    .disabled(canSave == false)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusedField = .suggestedDate
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 46, height: 46)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            Text("Suggest another time.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text("This keeps the plan alive without forcing a yes or no.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func inputSection(
        title: String,
        subtitle: String,
        placeholder: String,
        text: Binding<String>,
        focusedField: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
            }

            TextField(placeholder, text: text, axis: .vertical)
                .focused($focusedField, equals: focusedField)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .textInputAutocapitalization(.sentences)
                .lineLimit(1...3)
                .padding(14)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Your suggestion is visible only inside this private Circle plan.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(13)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
