//
//  SocialActionSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct SocialActionSheet: View {
    let hasCircles: Bool
    let onCreateWatchPlan: () -> Void
    let onCreateCircle: () -> Void
    let onJoinCircle: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(spacing: 12) {
                        CircleQuickActionCard(
                            icon: "calendar.badge.plus",
                            title: "Create a Watch Together plan",
                            message: hasCircles
                                ? "Pick a title, choose a Circle, and propose when or where to watch."
                                : "Create or join a Circle first, then start planning watches together.",
                            isPrimary: true,
                            action: onCreateWatchPlan
                        )

                        CircleQuickActionCard(
                            icon: "plus.circle.fill",
                            title: "Create a Circle",
                            message: "Start a private space for friends, family, your partner, or a movie club.",
                            isPrimary: false,
                            action: onCreateCircle
                        )

                        CircleQuickActionCard(
                            icon: "ticket.fill",
                            title: "Join with invite code",
                            message: "Enter a code from someone you trust and preview the Circle before joining.",
                            isPrimary: false,
                            action: onJoinCircle
                        )
                    }

                    privacyNote

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationTitle("Add")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add to your Social space.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text("Create plans, create private Circles, or join a trusted space. Social stays intentional and private.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 1)

            Text("Your Personal Timeline and Want to Watch list are never exposed automatically. You choose what becomes social.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
