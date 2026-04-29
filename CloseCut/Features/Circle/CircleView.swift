//
//  CircleView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct CircleView: View {
    let user: AuthUser
    let profile: UserProfile

    @State private var copiedInviteCode = false
    @State private var showJoinComingSoon = false

    private var inviteCode: String {
        let base = profile.displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()

        let prefix = String(base.prefix(4))
        let userSuffix = String(user.id.suffix(4)).uppercased()

        if prefix.isEmpty {
            return "CLOSE-\(userSuffix)"
        }

        return "\(prefix)-\(userSuffix)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection

                        CircleInviteCard(
                            inviteCode: inviteCode,
                            onCopy: copyInviteCode,
                            onJoin: {
                                showJoinComingSoon = true
                            }
                        )

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
            .alert("Circle invites are coming soon", isPresented: $showJoinComingSoon) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("For this MVP, your journal works locally first. Circle sync and invite code joining will be connected later.")
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Share only with the people who matter.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your Circle will be a small private space for reactions and short comments on selected entries.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
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

    private func copyInviteCode() {
        UIPasteboard.general.string = inviteCode

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
}
