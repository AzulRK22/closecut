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

    @Query(sort: \PendingAction.updatedAt, order: .reverse)
    private var pendingActions: [PendingAction]

    @Query(sort: \LocalEntry.updatedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    let user: AuthUser
    let profile: UserProfile

    private let entrySyncService = EntrySyncService()
    private let pendingActionQueue = PendingActionQueue()

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

    private var visiblePendingCount: Int {
        max(currentUserPendingActions.count, currentUserPendingEntries.count)
    }

    private var hasPendingOrFailedWork: Bool {
        visiblePendingCount > 0 || currentUserFailedActions.isEmpty == false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        settingsHeader

                        ProfileHeaderCard(
                            user: user,
                            profile: profile
                        )

                        syncSection

                        privacySection

                        localDataSection

                        accountSection

                        appInfoSection
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
                Text("You can sign back in later. Your synced entries remain in your private cloud database.")
            }
        }
    }

    private var settingsHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Control center")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Manage your account, privacy, and local-first sync.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "gearshape.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 38, height: 38)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())
        }
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYNC")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.horizontal, 2)

            if sessionSyncViewModel.isInitialCloudRefreshRunning {
                SyncResultBanner(
                    message: "Refreshing your cloud entries…",
                    style: .neutral
                )
            }

            SyncStatusSummaryCard(
                pendingCount: visiblePendingCount,
                failedCount: currentUserFailedActions.count,
                isSyncing: isSyncing
            )

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
                            Image(systemName: currentUserFailedActions.isEmpty ? "arrow.triangle.2.circlepath" : "exclamationmark.arrow.triangle.2.circlepath")
                        }

                        Text(syncButtonTitle)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(currentUserFailedActions.isEmpty ? CloseCutColors.accent : CloseCutColors.failed)
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

    private var privacySection: some View {
        settingsSection(title: "Privacy & sharing") {
            VStack(alignment: .leading, spacing: 10) {
                settingsRow(
                    icon: "lock.fill",
                    title: "Default visibility",
                    value: profile.defaultVisibility.displayName
                )

                Text("Your Personal Timeline is private by default. Sharing only happens when you intentionally choose one or more Circles.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var localDataSection: some View {
        settingsSection(title: "Local data") {
            VStack(alignment: .leading, spacing: 10) {
                settingsRow(
                    icon: "iphone",
                    title: "Local journal",
                    value: "Enabled"
                )

                settingsRow(
                    icon: "clock.fill",
                    title: "Pending local entries",
                    value: "\(currentUserPendingEntries.count)"
                )

                settingsRow(
                    icon: "tray.full.fill",
                    title: "Queued actions",
                    value: "\(currentUserPendingActions.count)"
                )

                settingsRow(
                    icon: "checkmark.circle.fill",
                    title: "Completed sync actions",
                    value: "\(currentUserCompletedActions.count)"
                )

                Text("You can add, edit, and delete memories offline. CloseCut keeps local changes queued until you sync them with the cloud.")
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

    private var accountSection: some View {
        settingsSection(title: "Account") {
            VStack(alignment: .leading, spacing: 10) {
                settingsRow(
                    icon: "person.crop.circle.fill",
                    title: "Signed in as",
                    value: profile.displayName
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

    private var appInfoSection: some View {
        settingsSection(title: "App info") {
            VStack(spacing: 10) {
                settingsRow(
                    icon: "sparkles",
                    title: "CloseCut MVP",
                    value: "Local-first"
                )

                settingsRow(
                    icon: "number",
                    title: "Version",
                    value: appVersion
                )

                settingsRow(
                    icon: "shippingbox",
                    title: "Bundle",
                    value: AppBuildInfo.bundleIdentifier
                )
            }
        }
    }

    private var appVersion: String {
        AppBuildInfo.displayVersion
    }

    private var syncButtonTitle: String {
        if isSyncing {
            return "Syncing..."
        }

        if currentUserFailedActions.isEmpty == false {
            return "Retry sync"
        }

        return "Sync now"
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            Text(title)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 12)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(1)
        }
        .frame(minHeight: 36)
    }

    private func syncNow() async {
        isSyncing = true
        lastSyncMessage = nil
        defer { isSyncing = false }

        let summary = await entrySyncService.syncPendingEntries(
            userId: user.id,
            modelContext: modelContext
        )

        if summary.failedCount > 0 {
            lastSyncBannerStyle = .warning
            lastSyncMessage = "Synced \(summary.syncedCount) changes. \(summary.failedCount) still need retry."
        } else if summary.syncedCount > 0 {
            lastSyncBannerStyle = .success
            lastSyncMessage = "Synced \(summary.syncedCount) local changes."
        } else {
            lastSyncBannerStyle = .neutral
            lastSyncMessage = "Nothing new to sync."
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
        }
    }

    private func pullFromCloud() async {
        isPullingFromCloud = true
        lastSyncMessage = nil
        defer { isPullingFromCloud = false }

        let summary = await entrySyncService.pullRemoteEntries(
            userId: user.id,
            modelContext: modelContext
        )

        if summary.failedCount > 0 {
            lastSyncBannerStyle = .warning
            lastSyncMessage = "Couldn’t refresh from cloud. Check your connection and Firestore rules."
        } else if summary.pulledCount > 0 {
            lastSyncBannerStyle = .success
            lastSyncMessage = "Refreshed \(summary.pulledCount) entries from cloud."
        } else {
            lastSyncBannerStyle = .neutral
            lastSyncMessage = "No cloud entries found yet."
        }
    }
}
