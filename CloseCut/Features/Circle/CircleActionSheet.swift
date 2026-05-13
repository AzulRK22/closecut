//
//  CircleActionSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI

struct CircleActionSheet: View {
    let onCreate: () -> Void
    let onJoin: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(spacing: 12) {
                        CircleQuickActionCard(
                            icon: "plus.circle.fill",
                            title: "Create a Circle",
                            message: "Start a private space for people you actually watch and talk with.",
                            isPrimary: true,
                            action: onCreate
                        )

                        CircleQuickActionCard(
                            icon: "ticket.fill",
                            title: "Join with invite code",
                            message: "Enter a code from someone you trust and preview the Circle before joining.",
                            isPrimary: false,
                            action: onJoin
                        )
                    }

                    privacyNote

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationTitle("Add Circle")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a trusted space.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text("Circles are intentionally private. Each space can have its own people, shared memories, reactions, and comments.")
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

            Text("Your Personal library stays private. A Circle only sees entries you explicitly share.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
