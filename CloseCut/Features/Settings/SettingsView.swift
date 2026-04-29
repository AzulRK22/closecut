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
    @Environment(\.modelContext) private var modelContext

    @State private var isSyncing = false
    @State private var lastSyncMessage: String?
    @State private var lastSyncBannerStyle: SyncResultBannerStyle = .neutral

    @Query(sort: \PendingAction.updatedAt, order: .reverse)
    private var pendingActions: [PendingAction]

    @Query(sort: \LocalEntry.updatedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    let user: AuthUser
    let profile: UserProfile

    private let entrySyncService = EntrySyncService()

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

    private var currentUserPendingEntries: [LocalEntry] {
        localEntries.filter {
            $0.ownerId == user.id &&
            $0.syncStatusRaw == SyncStatus.pending.rawValue
        }
    }

    private var visiblePendingCount: Int {
        max(currentUserPendingActions.count, currentUserPendingEntries.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ProfileHeaderCard(
                            user: user,
                            profile: profile
                        )

                        syncSection

                        privacySection

                        localFirstSection

                        accountSection

                        appInfoSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
        }
    }

    private var syncSection: some View {
        VStack(spacing: 10) {
            SyncStatusSummaryCard(
                pendingCount: visiblePendingCount,
                failedCount: currentUserFailedActions.count,
                isSyncing: isSyncing
            )

            if visiblePendingCount > 0 || currentUserFailedActions.isEmpty == false {
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
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSyncing)
            }

            if let lastSyncMessage {
                SyncResultBanner(
                    message: lastSyncMessage,
                    style: lastSyncBannerStyle
                )
            }
        }
    }

    private var privacySection: some View {
        settingsSection(title: "Privacy") {
            VStack(alignment: .leading, spacing: 10) {
                settingsRow(
                    icon: "lock.fill",
                    title: "Default visibility",
                    value: profile.defaultVisibility.displayName
                )

                Text("Entries are private by default. Circle sharing will only apply when you explicitly choose it.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var localFirstSection: some View {
        settingsSection(title: "Offline-first") {
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

                Text("You can add and edit memories offline. Sync actions are tracked locally and pending entries can be pushed when sync is available.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var accountSection: some View {
        settingsSection(title: "Account") {
            Button {
                authService.signOut()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .frame(width: 24)

                    Text("Sign Out")
                        .font(.subheadline.weight(.semibold))

                    Spacer()
                }
                .foregroundStyle(CloseCutColors.failed)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var appInfoSection: some View {
        settingsSection(title: "App") {
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

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption2)
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textPrimary)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(1)
        }
        .frame(minHeight: 32)
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
    private var syncButtonTitle: String {
        if isSyncing {
            return "Syncing..."
        }
        if currentUserFailedActions.isEmpty == false {
            return "Retry sync"
        }
        return "Sync now"
    }
}
