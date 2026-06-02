//
//  SettingsView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var sessionSyncViewModel: SessionSyncViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var isSyncing = false
    @State private var isPullingFromCloud = false
    @State private var lastSyncMessage: String?
    @State private var lastSyncBannerStyle: SyncResultBannerStyle = .neutral
    @State private var showSignOutConfirmation = false

    @State private var showEditProfileSheet = false
    @State private var isSavingProfile = false
    @State private var localDisplayNameOverride: String?
    @State private var selectedAvatarPreset: AvatarPreset = .defaultPreset
    @State private var profileActionMessage: String?
    @State private var profileActionBannerStyle: SyncResultBannerStyle = .neutral

    @Query(sort: \PendingAction.updatedAt, order: .reverse)
    private var pendingActions: [PendingAction]

    @Query(sort: \LocalEntry.updatedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    @Query(sort: \LocalWatchlistItem.updatedAt, order: .reverse)
    private var localWatchlistItems: [LocalWatchlistItem]

    @Query(sort: \LocalCircle.updatedAt, order: .reverse)
    private var localCircles: [LocalCircle]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    let user: AuthUser
    let profile: UserProfile

    private let entrySyncService = EntrySyncService()
    private let watchlistSyncService = WatchlistSyncService()
    private let pendingActionQueue = PendingActionQueue()

    // MARK: - Local Domain State

    private var currentUserEntries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    private var allCurrentUserWatchlistItems: [WatchlistItem] {
        localWatchlistItems
            .filter { $0.ownerId == user.id }
            .map { $0.domain }
    }

    private var currentUserWatchlistItems: [WatchlistItem] {
        allCurrentUserWatchlistItems
            .filter { $0.deletedAt == nil }
    }

    private var currentUserSavedWatchlistItems: [WatchlistItem] {
        currentUserWatchlistItems
            .filter { $0.status == .saved }
    }

    private var currentUserWatchedWatchlistItems: [WatchlistItem] {
        currentUserWatchlistItems
            .filter { $0.status == .watched }
    }

    private var currentUserDismissedWatchlistItems: [WatchlistItem] {
        allCurrentUserWatchlistItems
            .filter { $0.status == .dismissed || $0.deletedAt != nil }
    }

    // MARK: - Pending / Failed Work

    private var currentUserPendingActions: [PendingAction] {
        pendingActions.filter {
            $0.userId == user.id &&
            $0.statusRaw == PendingActionStatus.pending.rawValue
        }
    }

    private var currentUserFailedActions: [PendingAction] {
        pendingActions.filter {
            $0.userId == user.id &&
            $0.statusRaw == PendingActionStatus.failed.rawValue
        }
    }

    private var currentUserCompletedActions: [PendingAction] {
        pendingActions.filter {
            $0.userId == user.id &&
            $0.statusRaw == PendingActionStatus.completed.rawValue
        }
    }

    private var currentUserPendingEntries: [LocalEntry] {
        localEntries.filter {
            $0.ownerId == user.id &&
            $0.syncStatusRaw == SyncStatus.pending.rawValue
        }
    }

    private var currentUserFailedEntries: [LocalEntry] {
        localEntries.filter {
            $0.ownerId == user.id &&
            $0.syncStatusRaw == SyncStatus.failed.rawValue
        }
    }

    private var currentUserPendingWatchlistItems: [LocalWatchlistItem] {
        localWatchlistItems.filter {
            $0.ownerId == user.id &&
            $0.syncStatusRaw == SyncStatus.pending.rawValue
        }
    }

    private var currentUserFailedWatchlistItems: [LocalWatchlistItem] {
        localWatchlistItems.filter {
            $0.ownerId == user.id &&
            $0.syncStatusRaw == SyncStatus.failed.rawValue
        }
    }

    private var currentUserPendingWatchlistActions: [PendingAction] {
        currentUserPendingActions.filter {
            $0.actionType.isWatchlistAction
        }
    }

    private var currentUserPendingEntryActions: [PendingAction] {
        currentUserPendingActions.filter {
            $0.actionType.isEntryAction
        }
    }

    private var currentUserFailedWatchlistActions: [PendingAction] {
        currentUserFailedActions.filter {
            $0.actionType.isWatchlistAction
        }
    }

    private var currentUserFailedEntryActions: [PendingAction] {
        currentUserFailedActions.filter {
            $0.actionType.isEntryAction
        }
    }

    private var visiblePendingCount: Int {
        let actionBackedCount = currentUserPendingActions.count
        let orphanCount = currentUserPendingEntries.count + currentUserPendingWatchlistItems.count

        return max(
            actionBackedCount,
            orphanCount
        )
    }

    private var visibleFailedCount: Int {
        let actionBackedCount = currentUserFailedActions.count
        let orphanCount = currentUserFailedEntries.count + currentUserFailedWatchlistItems.count

        return max(
            actionBackedCount,
            orphanCount
        )
    }

    private var hasPendingOrFailedWork: Bool {
        visiblePendingCount > 0 || visibleFailedCount > 0
    }

    // MARK: - Circle / Privacy Counts

    private var currentUserCircleCount: Int {
        let activeMembershipCircleIds = Set(
            localMemberships
                .filter { $0.userId == user.id }
                .map { $0.domain }
                .filter { $0.isActive }
                .map { $0.circleId }
        )

        return localCircles
            .map { $0.domain }
            .filter { activeMembershipCircleIds.contains($0.id) }
            .filter { $0.deletedAt == nil }
            .count
    }

    private var currentUserSharedEntryCount: Int {
        currentUserEntries.filter {
            $0.visibility == .circle && $0.sharedCircleIds.isEmpty == false
        }.count
    }

    private var currentUserPrivateEntryCount: Int {
        max(currentUserEntries.count - currentUserSharedEntryCount, 0)
    }

    // MARK: - Profile Display

    private var effectiveDisplayName: String {
        if let localDisplayNameOverride,
           localDisplayNameOverride.trimmed.isEmpty == false {
            return localDisplayNameOverride
        }

        let profileName = profile.displayName.trimmed

        if profileName.isEmpty == false {
            return profileName
        }

        if let userDisplayName = user.displayName?.trimmed,
           userDisplayName.isEmpty == false {
            return userDisplayName
        }

        return "CloseCut user"
    }

    private var displayProfile: UserProfile {
        UserProfile(
            id: profile.id,
            displayName: effectiveDisplayName,
            email: profile.email,
            photoURL: profile.photoURL,
            circleId: profile.circleId,
            circleIds: profile.circleIds,
            defaultVisibility: profile.defaultVisibility,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            syncStatus: profile.syncStatus
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SettingsHeroCard(
                            entriesCount: currentUserEntries.count,
                            circleCount: currentUserCircleCount,
                            pendingCount: visiblePendingCount,
                            failedCount: visibleFailedCount
                        )

                        ProfileHeaderCard(
                            user: user,
                            profile: displayProfile,
                            avatarPreset: selectedAvatarPreset,
                            onEditProfile: {
                                showEditProfileSheet = true
                            }
                        )

                        if let profileActionMessage {
                            SyncResultBanner(
                                message: profileActionMessage,
                                style: profileActionBannerStyle
                            )
                        }

                        ArchiveHealthCard(
                            entries: currentUserEntries,
                            pendingCount: visiblePendingCount,
                            failedCount: visibleFailedCount
                        )

                        CloseCutSystemStatusCard(
                            entriesCount: currentUserEntries.count,
                            circleCount: currentUserCircleCount,
                            pendingCount: visiblePendingCount,
                            failedCount: visibleFailedCount
                        )

                        syncSection

                        privacySection

                        watchlistSection
                        
                        shareSection

                        localDataSection

                        accountSection

                        appInfoSection

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .confirmationDialog(
                "Sign out?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign out", role: .destructive) {
                    authService.signOut()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can sign back in later. Your synced entries and saved titles remain in your private cloud database.")
            }
            .sheet(isPresented: $showEditProfileSheet) {
                EditProfileSheet(
                    currentDisplayName: effectiveDisplayName,
                    currentAvatarPreset: selectedAvatarPreset,
                    isSaving: isSavingProfile,
                    onCancel: {
                        showEditProfileSheet = false
                    },
                    onSave: { displayName, avatarPreset in
                        saveProfileLocallyForNow(
                            displayName: displayName,
                            avatarPreset: avatarPreset
                        )
                    }
                )
            }
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        SettingsSectionCard(
            title: "Sync",
            subtitle: "Control cloud refresh, retries, entries, and Want to Watch changes."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if sessionSyncViewModel.isInitialCloudRefreshRunning {
                    SyncResultBanner(
                        message: "Refreshing your cloud data…",
                        style: .neutral
                    )
                }

                if let initialRefreshError = sessionSyncViewModel.lastInitialCloudRefreshError {
                    SyncResultBanner(
                        message: initialRefreshError,
                        style: .warning
                    )
                }

                SyncStatusSummaryCard(
                    pendingCount: visiblePendingCount,
                    failedCount: visibleFailedCount,
                    isSyncing: isSyncing
                )

                syncDebugBreakdown

                if hasPendingOrFailedWork {
                    Button {
                        Task {
                            await syncNow()
                        }
                    } label: {
                        HStack {
                            if isSyncing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(
                                    systemName: visibleFailedCount == 0
                                        ? "arrow.triangle.2.circlepath"
                                        : "exclamationmark.arrow.triangle.2.circlepath"
                                )
                            }

                            Text(syncButtonTitle)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(visibleFailedCount == 0 ? CloseCutColors.accent : CloseCutColors.failed)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSyncing || isPullingFromCloud)
                }

                Button {
                    Task {
                        await pullFromCloud()
                    }
                } label: {
                    HStack {
                        if isPullingFromCloud {
                            ProgressView()
                                .tint(CloseCutColors.textSecondary)
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                        }

                        Text(isPullingFromCloud ? "Refreshing..." : "Refresh from cloud")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isPullingFromCloud || isSyncing)

                if let lastSyncMessage {
                    SyncResultBanner(
                        message: lastSyncMessage,
                        style: lastSyncBannerStyle
                    )
                }
            }
        }
    }

    private var syncDebugBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsRow(
                icon: "film.stack",
                title: "Pending entry actions",
                value: "\(currentUserPendingEntryActions.count)"
            )

            SettingsRow(
                icon: "bookmark.fill",
                title: "Pending Watchlist actions",
                value: "\(currentUserPendingWatchlistActions.count)"
            )

            SettingsRow(
                icon: "exclamationmark.triangle.fill",
                title: "Failed entry actions",
                value: "\(currentUserFailedEntryActions.count)"
            )

            SettingsRow(
                icon: "bookmark.slash.fill",
                title: "Failed Watchlist actions",
                value: "\(currentUserFailedWatchlistActions.count)"
            )

            SettingsRow(
                icon: "clock.fill",
                title: "Pending local entries",
                value: "\(currentUserPendingEntries.count)"
            )

            SettingsRow(
                icon: "clock.badge.questionmark.fill",
                title: "Pending local Watchlist",
                value: "\(currentUserPendingWatchlistItems.count)"
            )
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        SettingsSectionCard(
            title: "Privacy & sharing",
            subtitle: "Understand what stays private and what can be shared."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsRow(
                    icon: "lock.fill",
                    title: "Default visibility",
                    value: profile.defaultVisibility.displayName
                )

                SettingsRow(
                    icon: "film.stack",
                    title: "Private memories",
                    value: "\(currentUserPrivateEntryCount)"
                )

                SettingsRow(
                    icon: "person.2.fill",
                    title: "Shared memories",
                    value: "\(currentUserSharedEntryCount)"
                )

                SettingsRow(
                    icon: "circle.grid.2x2.fill",
                    title: "Active Circles",
                    value: "\(currentUserCircleCount)"
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                privacySignalRow(
                    icon: "eye.slash.fill",
                    title: "No public profile",
                    message: "CloseCut does not expose your taste history publicly."
                )

                privacySignalRow(
                    icon: "person.crop.circle.badge.xmark",
                    title: "No followers",
                    message: "Sharing happens through selected private Circles only."
                )

                privacySignalRow(
                    icon: "hand.tap.fill",
                    title: "Manual sharing",
                    message: "Entries stay private unless you intentionally select one or more Circles."
                )
            }
        }
    }

    // MARK: - Watchlist Section

    private var watchlistSection: some View {
        SettingsSectionCard(
            title: "Want to Watch",
            subtitle: "Saved titles from Discover, Search, Battle, or Circle recommendations."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsRow(
                    icon: "bookmark.fill",
                    title: "Saved titles",
                    value: "\(currentUserSavedWatchlistItems.count)"
                )

                SettingsRow(
                    icon: "checkmark.circle.fill",
                    title: "Marked watched",
                    value: "\(currentUserWatchedWatchlistItems.count)"
                )

                SettingsRow(
                    icon: "xmark.circle.fill",
                    title: "Dismissed",
                    value: "\(currentUserDismissedWatchlistItems.count)"
                )

                SettingsRow(
                    icon: "clock.fill",
                    title: "Pending Watchlist sync",
                    value: "\(currentUserPendingWatchlistItems.count)"
                )

                SettingsRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Failed Watchlist sync",
                    value: "\(currentUserFailedWatchlistItems.count)"
                )

                Text("Want to Watch is private by default. Saving a title from Discover creates a local Watchlist item first, then syncs it to Firestore when cloud sync runs.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Local Data Section

    private var localDataSection: some View {
        SettingsSectionCard(
            title: "Local data",
            subtitle: "Your device keeps CloseCut usable even before cloud sync finishes."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsRow(
                    icon: "iphone",
                    title: "Local journal",
                    value: "Enabled"
                )

                SettingsRow(
                    icon: "film.stack",
                    title: "Local entries",
                    value: "\(currentUserEntries.count)"
                )

                SettingsRow(
                    icon: "bookmark.fill",
                    title: "Local Want to Watch",
                    value: "\(currentUserWatchlistItems.count)"
                )

                SettingsRow(
                    icon: "clock.fill",
                    title: "Pending local entries",
                    value: "\(currentUserPendingEntries.count)"
                )

                SettingsRow(
                    icon: "bookmark.circle.fill",
                    title: "Pending Watchlist items",
                    value: "\(currentUserPendingWatchlistItems.count)"
                )

                SettingsRow(
                    icon: "tray.full.fill",
                    title: "Queued actions",
                    value: "\(currentUserPendingActions.count)"
                )

                SettingsRow(
                    icon: "checkmark.circle.fill",
                    title: "Completed sync actions",
                    value: "\(currentUserCompletedActions.count)"
                )

                Text("You can add, edit, delete memories, and save titles offline. CloseCut keeps local changes queued until you sync them with the cloud.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if currentUserCompletedActions.isEmpty == false {
                    Button {
                        cleanupCompletedActions()
                    } label: {
                        Text("Clear completed sync history")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        SettingsSectionCard(
            title: "Account",
            subtitle: "Manage access to this CloseCut session."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsRow(
                    icon: "person.crop.circle.fill",
                    title: "Signed in as",
                    value: effectiveDisplayName
                )

                Button {
                    showSignOutConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.failed)
                            .frame(width: 30, height: 30)
                            .background(CloseCutColors.input)
                            .clipShape(SwiftUI.Circle())

                        Text("Sign out")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.failed)

                        Spacer()
                    }
                    .frame(minHeight: 38)
                }
                .buttonStyle(.plain)

                Text("Signing out does not delete your local data or cloud entries.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    // MARK: - Share Section

    private var shareSection: some View {
        SettingsSectionCard(
            title: "Share CloseCut",
            subtitle: "Invite someone who would actually use a private movie and series journal."
        ) {
            CloseCutShareActionCard(
                item: CloseCutShareTextBuilder.appInvite(
                    displayName: effectiveDisplayName
                ),
                buttonTitle: "Share CloseCut",
                note: "This only opens the system share sheet. Nothing from your Personal archive, Watchlist, or Circles is shared."
            )
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        SettingsSectionCard(
            title: "App info",
            subtitle: "Build and product information."
        ) {
            VStack(spacing: 10) {
                SettingsRow(
                    icon: "sparkles",
                    title: "CloseCut MVP",
                    value: "Local-first"
                )

                SettingsRow(
                    icon: "number",
                    title: "Version",
                    value: AppBuildInfo.displayVersion
                )

                SettingsRow(
                    icon: "shippingbox",
                    title: "Bundle",
                    value: AppBuildInfo.bundleIdentifier
                )
            }
        }
    }

    // MARK: - UI Helpers

    private var syncButtonTitle: String {
        if isSyncing {
            return "Syncing..."
        }

        if visibleFailedCount > 0 {
            return "Retry sync"
        }

        return "Sync now"
    }

    private func privacySignalRow(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - Profile

    private func saveProfileLocallyForNow(
        displayName: String,
        avatarPreset: AvatarPreset
    ) {
        let cleanedDisplayName = displayName.trimmed

        guard cleanedDisplayName.isEmpty == false else {
            profileActionBannerStyle = .warning
            profileActionMessage = "Add a display name before saving."
            return
        }

        guard cleanedDisplayName.count <= 40 else {
            profileActionBannerStyle = .warning
            profileActionMessage = "Display name must be 40 characters or less."
            return
        }

        isSavingProfile = true
        profileActionMessage = nil

        withAnimation(.easeInOut(duration: 0.2)) {
            localDisplayNameOverride = cleanedDisplayName
            selectedAvatarPreset = avatarPreset
        }

        isSavingProfile = false
        showEditProfileSheet = false

        profileActionBannerStyle = .success
        profileActionMessage = "Profile preview updated on this device."

        #if DEBUG
        print("ℹ️ Profile preview updated locally. Persist avatar/display name in the next block.")
        #endif
    }

    // MARK: - Sync Actions

    private func syncNow() async {
        guard isSyncing == false else {
            return
        }

        isSyncing = true
        lastSyncMessage = nil
        defer { isSyncing = false }

        let entrySummary = await entrySyncService.syncPendingEntries(
            userId: user.id,
            modelContext: modelContext
        )

        let watchlistSummary = await watchlistSyncService.syncPendingWatchlistItems(
            userId: user.id,
            modelContext: modelContext
        )

        let syncedCount = entrySummary.syncedCount + watchlistSummary.syncedCount
        let failedCount = entrySummary.failedCount + watchlistSummary.failedCount

        if failedCount > 0 {
            lastSyncBannerStyle = .warning
            lastSyncMessage = "Synced \(syncedCount) changes. \(failedCount) still need retry."
        } else if syncedCount > 0 {
            lastSyncBannerStyle = .success
            lastSyncMessage = "Synced \(syncedCount) local changes."
        } else {
            lastSyncBannerStyle = .neutral
            lastSyncMessage = "Nothing new to sync."
        }
    }

    private func pullFromCloud() async {
        guard isPullingFromCloud == false else {
            return
        }

        isPullingFromCloud = true
        lastSyncMessage = nil
        defer { isPullingFromCloud = false }

        let entrySummary = await entrySyncService.pullRemoteEntries(
            userId: user.id,
            modelContext: modelContext
        )

        let watchlistSummary = await watchlistSyncService.pullRemoteWatchlistItems(
            userId: user.id,
            modelContext: modelContext
        )

        let pulledCount = entrySummary.pulledCount + watchlistSummary.pulledCount
        let failedCount = entrySummary.failedCount + watchlistSummary.failedCount

        if failedCount > 0 {
            lastSyncBannerStyle = .warning
            lastSyncMessage = "Couldn’t fully refresh from cloud. Check your connection and Firestore rules."
        } else if pulledCount > 0 {
            lastSyncBannerStyle = .success
            lastSyncMessage = "Refreshed \(pulledCount) cloud items."
        } else {
            lastSyncBannerStyle = .neutral
            lastSyncMessage = "No cloud updates found yet."
        }
    }

    private func cleanupCompletedActions() {
        do {
            let deletedCount = try pendingActionQueue.cleanupAllCompletedActions(
                userId: user.id,
                modelContext: modelContext
            )

            lastSyncBannerStyle = .success
            lastSyncMessage = "Cleared \(deletedCount) completed sync actions."
        } catch {
            lastSyncBannerStyle = .warning
            lastSyncMessage = "Couldn’t clear completed sync history."

            #if DEBUG
            print("⚠️ Failed to clear completed sync history:", error.localizedDescription)
            #endif
        }
    }
}

#Preview {
    SettingsView(
        user: AuthUser(
            id: "preview-user",
            email: "preview@closecut.dev",
            displayName: "Preview",
            photoURL: nil
        ),
        profile: UserProfile(
            id: "preview-user",
            displayName: "Preview",
            email: "preview@closecut.dev",
            photoURL: nil,
            circleId: nil,
            circleIds: [],
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
    .environmentObject(AuthService())
    .environmentObject(SessionSyncViewModel())
    .modelContainer(for: [
        LocalEntry.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self,
        LocalBattleResult.self,
        LocalWatchlistItem.self
    ], inMemory: true)
}
