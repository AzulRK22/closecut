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

    @Query(sort: \PendingAction.updatedAt, order: .reverse)
    private var pendingActions: [PendingAction]

    let user: AuthUser
    let profile: UserProfile

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

                        SyncStatusSummaryCard(
                            pendingCount: currentUserPendingActions.count,
                            failedCount: currentUserFailedActions.count
                        )

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

                Text("You can add and edit memories offline. Sync actions are tracked locally and will be used when backend sync is connected.")
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
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        return "\(version) (\(build))"
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
}
